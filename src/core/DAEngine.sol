// Layout:
//     - pragma
//     - imports
//     - interfaces, libraries, contracts
//     - type declarations
//     - state variables
//     - events
//     - errors
//     - modifiers
//     - functions
//         - constructor
//         - receive function (if exists)
//         - fallback function (if exists)
//         - external
//         - public
//         - internal
//         - private
//         - view and pure functions

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

/**
 * @title AlpacaSource.sol
 * @author Ola Hamid
 * @notice THIS IS AN DEMO CONTRACT THAT ISN'T AUDITED..
 */

import {OwnableUpgradeable} from "../../lib/openzeppelin-contracts-upgradeable/contracts/access/OwnableUpgradeable.sol";
import {DALibrary} from "../Library/DALibrary.sol";
import {DARWAFunctionSrc} from "../FunctionSources/DARWAFunctionSrc.sol";
import {DACreateAbleAsset1155} from "../core/DACreateAbleAsset1155.sol";
import {PausableUpgradeable} from "../../lib/openzeppelin-contracts-upgradeable/contracts/utils/PausableUpgradeable.sol";
import {ReentrancyGuard} from "../../lib/openzeppelin-contracts/contracts/utils/ReentrancyGuard.sol";
import {Initializable} from "../../lib/openzeppelin-contracts-upgradeable/contracts/proxy/utils/Initializable.sol";
import {UUPSUpgradeable} from "../../lib/openzeppelin-contracts-upgradeable/contracts/proxy/utils/UUPSUpgradeable.sol";
import {IERC1155} from "../../lib/openzeppelin-contracts/contracts/token/ERC1155/IERC1155.sol";
import {IERC20} from "../../lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {IMonadexV1Router} from "../../monadex-v1-protocol/src/interfaces/IMonadexV1Router.sol";
import { MonadexV1Types } from "../../monadex-v1-protocol/src/library/MonadexV1Types.sol";

contract DAEngine is OwnableUpgradeable, PausableUpgradeable, UUPSUpgradeable {

    DACreateAbleAsset1155 public s_DAAsset1155;
    DARWAFunctionSrc public s_DARWAFunctionSrc;
    IERC20[] public s_supportedToken;
    IMonadexV1Router public monadexRouter;

    uint256 constant private precision = 1e18;
    uint256 constant private minSellOutInpercentile = 50;
    uint256 constant private maxSellOutInpercentile = 150;
    uint256 constant private percentile = 100;
    uint256 constant public protocolFee_precision = (precision * 5) / 100;
    //uint256 constant private sellOutCollateral = 1e18;
    uint256 public current1155Price;
    uint256 public totalAssetAmont;

    bytes32 private requestId;
    uint256  public assetId;
    string public assetName;
    address public pool;
    address public ERC1155Token;

    mapping (address => uint) public userAssets;


    enum healthStatus {
        good,
        bad
    }

    struct AssetDetails {
        uint256 _amountIn;
        uint256 _amountOutMin;
        address[] _path;
        address _receiver;
        uint256 _deadline;
        MonadexV1Types.Raffle _raffle;
    }
    
    modifier isSupportedToken(address _supportedTokenIn, address _supportedTokenOut) {
        for (uint256 i = 0; i < s_supportedToken.length; i++) {

            if (!((_supportedTokenIn == address(s_supportedToken[i]) && _supportedTokenOut == ERC1155Token) ||
            (_supportedTokenIn == ERC1155Token && _supportedTokenOut == address(s_supportedToken[i])))) {
            revert DALibrary.DARWA_InvalidSupportedToken(_supportedTokenIn, _supportedTokenOut);
        }
    }
        _;
    }
    //DARWAFunctionSrc public DARWAFunctionSrc;
    constructor () {
        _disableInitializers();
    }

    // this should be used to kick start the engine contracts, what are the var you think it should have?
    //  AssetCreationParams struct, Asset struct, 
    function Initialize(
        address _DAAsset1155,
        address _FunctionSrc,
        uint256 _AssetId,
        address _supportedToken,
        bytes32 _requestId,
        string memory _assetName
    ) external onlyOwner {
        s_DAAsset1155 = DACreateAbleAsset1155(_DAAsset1155);
        s_DARWAFunctionSrc = DARWAFunctionSrc(_FunctionSrc);
        assetId = _AssetId;
        requestId = _requestId;
        assetName = _assetName;
        //FIXME: make a defualt supported token or add a param to set this
        s_supportedToken.push(IERC20(_supportedToken));
    }

    function _checkNoZeroAddress(address _address) internal pure {
        if (_address == address(0)) revert DALibrary.DARWA_ZeroAddress();
    }

    function _checkZeroAmount(uint256 _amount) internal pure {
        if (_amount == 0) revert DALibrary.DARWA_ZEROAmount();
    }

    /* note: there are 4 main functions here 
    1. directBuy 
    2. directSell
    3. takePosition
    4. closePosition
    helthcheck
    */

    /*---------------------------------DirectBuy---------------------------------*/
    /*PARAM
    amountToBuy - amount to
    address receiving -
    uint ID
    */
   function directBuy(
        uint256 _amountIn,
        uint256 _amountOutMin,
        address[] memory _path,
        address _receiver,
        uint256 _deadline,
        MonadexV1Types.Raffle memory _raffle
   ) external /*isSupportedToken()*/ {
        //CHECKS 
    // check that the supported token to buy is RIGHT
    // 1. the asset most not be killed
    // 2. check for zero values and address  
    // check that the health is good
        //fixme: add a check tha the asset is nt dead
        _checkNoZeroAddress(_receiver);
        _checkZeroAmount(_amountIn);
        // check that the asset
        healthCheck(address(this));
        // my aiim for the next check is to make sure that the amount swaping out in supported token and amount swapping is the erc1155 token
        for (uint256 i=0; i< s_supportedToken.length; ++i) {
            if (_path[0] != address(s_supportedToken[i]) || _path[1] != address(ERC1155Token)) {
                revert DALibrary.DARWA_InvalidPathAddress(_path[0], _path[1]);
            }
        }
        
        // INTERACTIONS
        // 1. for direct buy users directly buy the asset from the engine contract by making a swap from the supported token to the desired RWA token. 
        // 2. send the reciever the asset token from the engine contract
        //3. also the function source contract make a buy for them
        // FIXME: i dont know how to make sure the path is taking USDC and giving the erc1155 token. need to fix that
        _swapBuy(_amountIn, _amountOutMin, _path, _receiver, _deadline, _raffle);
        s_DARWAFunctionSrc.requestBuyAsset(assetName, assetId, _receiver, _amountIn);

         // effect 
        // 1. store their address, id and to the amount bought in a maping
        // 2. check the total amount bought 
         uint256 previousAmout = userAssets[msg.sender];
        userAssets[msg.sender] = previousAmout + _amountIn;
        totalAssetAmont += _amountIn;
   }
    /*---------------------------------DirectSell---------------------------------*/
    function directSell(
        uint256 _amountIn,
        uint256 _amountOutMin,
        address[] memory _path,
        address _receiver,
        uint256 _deadline,
        MonadexV1Types.Raffle memory _raffle
    ) public {
        _checkNoZeroAddress(_receiver);
        _checkZeroAmount(_amountIn);
        // check that the user has enough bought in the mapping
        uint256 sellerBalance = userAssets[msg.sender];
        // check for zero values and address
        if ( _amountIn > sellerBalance ) {
            revert DALibrary.DARWA_InsufficientBalance(sellerBalance);
        }
        for (uint256 i=0; i< s_supportedToken.length; ++i) {
            if (_path[0] != address(ERC1155Token) || _path[1] != address(s_supportedToken[i])) {
                revert DALibrary.DARWA_InvalidPathAddress(_path[0], _path[1]);
            }
        }
        healthCheck(pool);
        
            // EFFECT
    // 1. store their address, id and to the amount sell in a maping
    // 2. update the total amount sell
        uint256 previousAmout = userAssets[msg.sender];
        userAssets[msg.sender] = previousAmout - _amountIn;
        totalAssetAmont -= _amountIn;
        
        // INTERACTIONS
        // INTERACTIONS
        // 1. for direct sell users directly sell asset from the engine contract by making a swap from desired RWA token to the supported asset. 
        // 2. send the reciever the supported asset 
        //3. also the function source contract make a sell for them
        
        // do an if statement to check that the path coming in for sell is the ERC1155 token and the path going out to the user is ERC20 supported token. if not revert on invalid Path address

        _swapBuy(_amountIn, _amountOutMin, _path, _receiver, _deadline, _raffle);
        s_DARWAFunctionSrc.requestSellAsset(assetName, assetId, _receiver, _amountIn);
    }
    /*---------------------------------TakePosition---------------------------------*/
       /*PARAM
    amountToBuy - amount to
    address receiving 
    uint ID
    BuyOutCollateral 
    SellOutCollateral
    */
    function takePosition(
        uint256 _buyOutCollateral,
        uint256 _sellOutCollateral,
        uint256 _amountIn,
        uint256 _amountOutMin,
        address[] memory _path,
        address _receiver,
        uint256 _deadline,
        MonadexV1Types.Raffle memory _raffle
    ) 
    public {
    //CHECKS 
    // check that the supported token to buy is RIGHT
    // 1. the asset most not be killed
    // 2. check for zero values and address 
    // check that the max buyout collateral and sell out collateral isnt reached yet.
    //fixme: add a check tha the asset is nt dead
    _checkNoZeroAddress(_receiver);
    _checkZeroAmount(_amountIn);
    uint256 minSellPrecision = (precision * minSellOutInpercentile) / percentile;
    uint256 maxSellOutPrecision = (precision * maxSellOutInpercentile) / percentile;
    if ((_buyOutCollateral < minSellPrecision) || (_sellOutCollateral > maxSellOutPrecision)) {
        revert DALibrary.DARWA_InvalidPrecision();
        }
    
    for (uint256 i=0; i< s_supportedToken.length; ++i) {
        // fixme can you check that my condition is correct and true?
        if ((_path[0] != address(ERC1155Token) || _path[1] != address(s_supportedToken[i])) && _path[0] != address(s_supportedToken[i]) || _path[1] != address(ERC1155Token))  {
            revert DALibrary.DARWA_InvalidPathAddress(_path[0], _path[1]);
        }
    }
            
    // INTERACTIONS
    // 1. for direct buy users directly buy the asset from the engine contract by making a swap from the supported token to the desired RWA token. 
    // 2. send the reciever the asset token from the engine contract
    //3. also the function source contract make a buy for them
    (uint256[] memory amountsOut, ) = _swapBuy(_amountIn, _amountOutMin, _path, _receiver, _deadline, _raffle);
    s_DARWAFunctionSrc.requestBuyAsset(assetName, assetId, _receiver, _amountIn);
    uint256 amountOut = amountsOut[amountsOut.length - 1];
    // effect
    uint256 minSellAmount = _amountIn *  minSellPrecision;
    uint256 maxSellAmount = _amountIn * maxSellOutPrecision;
    // i dont know how to make it autonomous in a way that every time an amont out gets less than the minSell it automatically sells, 
    
    if ( amountOut < minSellAmount * amountOut) {
        _swapBuy(_amountIn, _amountOutMin, _path, _receiver, _deadline, _raffle);
        s_DARWAFunctionSrc.requestSellAsset(assetName, assetId, _receiver, _amountIn);
    }
    if ( amountOut > maxSellAmount  * amountOut ) {
        _swapBuy(_amountIn, _amountOutMin, _path, _receiver, _deadline, _raffle);
        s_DARWAFunctionSrc.requestSellAsset(assetName, assetId, _receiver, _amountIn);
    }
        
    }

    // if the current price is more than the maxSellOut, sell.
    // if the current price is less than the minSellOut, sell.
    // update the current mapping
    // update the current total amount for this ID

    /*---------------------------------ClosePosition---------------------------------*/

    /*---------------------------------HealthCheck---------------------------------*/
    /*PARAM
    */

    // if the current 1155 price is less than the current price of the function source, substract the difference and mint more token
    // if the current 1155 token price is greater than the current price of the function source, substract the difference and burn more token.
    function healthCheck(
        address _pool
    ) private {
        uint256 PriceDiff;
        (, uint256 oraclePrice , , ) = s_DARWAFunctionSrc.getPrice(requestId);
        if ( oraclePrice < current1155Price) {
            // mint more token
            PriceDiff = current1155Price - oraclePrice;
            s_DAAsset1155.mint(_pool, assetId, PriceDiff, " ");
        } else if(oraclePrice > current1155Price) {
            // burn more token
            PriceDiff = oraclePrice - current1155Price;
            s_DAAsset1155.burn(_pool, assetId, PriceDiff);
        }
        else {
            return;
        }
    }

    /*Helper, private and internal functions
    1. _checkNoZeroAddress done 
    2. _checkZeroAmount done
    3. _addLiquid done 
    4. _removeLiquid done 
    5. _swap done 
    6. _authorizeUpgrade done
    7. _supportToken done
    */
    /*-------------------------------------------addLiquid-----------------------------------------------*/

    function addLiquid(
        // fixme add a check that only supported token and erc155 asset token can be added
        MonadexV1Types.AddLiquidity memory _addLiquidityParams
    ) public {
        monadexRouter.addLiquidity(_addLiquidityParams);
    }

    /*----------------------------------------------removeLiquid------------------------------------------*/

    function removeLiquid(
        address _tokenA,
        address _tokenB,
        uint256 _lpTokensToBurn,
        uint256 _amountAMin,
        uint256 _amountBMin,
        address _receiver,
        uint256 _deadline
    ) internal {
        monadexRouter.removeLiquidity(_tokenA, _tokenB, _lpTokensToBurn, _amountAMin, _amountBMin, _receiver, _deadline);
    }

    /*----------------------------------------------_swap--------------------------------------------*/
    function _swapBuy(
        uint256 _amountIn,
        uint256 _amountOutMin,
        address[] memory _path,
        address _receiver,
        uint256 _deadline,
        MonadexV1Types.Raffle memory _raffle
    ) internal returns (uint256[] memory _amountOut, uint256 _NFTId) {
        //FIXME: add a check that enure that the path isnt greater than 2
        (_amountOut, _NFTId) = monadexRouter.swapExactTokensForTokens(_amountIn,_amountOutMin, _path, _receiver, _deadline, _raffle);
    }


    function _authorizeUpgrade(
        address _newImplementation
    ) internal 
    override
    onlyOwner {}

    function setSuppotedToken(
        address _supportedToken
    ) external onlyOwner {
        s_supportedToken.push(IERC20(_supportedToken));
    }

    //*----------------------------------------Getter function-------------------------------------------*/
    function getERC1155TokenPrice(

    ) public view returns(uint256 _price){

    }
}

