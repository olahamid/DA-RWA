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
 * @notice THIS IS AN DEMO CONTRACT THAT ISN'T AUDITED.
 * DO NOT USE THIS CODE IN PRODUCTION. (UNIT AND INTEGRATION TEST- WIP).
 */

import {Ownable} from "../../lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import {IDARWARegistry} from "../interface/IDARWARegistry.sol";
import {IDACreateAbleAsset1155} from "../interface/IDACreateAbleAsset1155.sol";
import {DACreateAbleAsset1155} from "../core/DACreateAbleAsset1155.sol";
import {DALibrary} from "../Library/DALibrary.sol";
import {DARWAFunctionSrc} from "../FunctionSources/DARWAFunctionSrc.sol";
import {DAEngine} from "../core/DAEngine.sol";
import { MonadexV1Types } from "../../monadex-v1-protocol/src/library/MonadexV1Types.sol";



contract DAFactory is Ownable {

    ////////////////////////
    /// State Variables ///
    ////////////////////////
    IDARWARegistry public immutable i_DARWARegistery;
    IDACreateAbleAsset1155 private immutable i_DACreateAbleAsset1155;
    DACreateAbleAsset1155 private s_Asset;
    DARWAFunctionSrc private s_FunctionSource;
    DAEngine[] public s_Engine;

    DALibrary.FunctionSourceConstructorArgs public functionSourceConstructorArgs;
    bytes public DARWAEngineBytecode;

    address private s_ChainLinkTokenAddr;
    address private s_ChainLinkOracle;
    address private i_engineAddress;
    uint256 private s_TotalAssetScore;

    uint256 private s_Fee;

    

    //////////////////////
    /////MAPPINGS/////////
    /////////////////////


    ///////////////////
    /// Constructor ///
    ///////////////////
    constructor (
        address _DARWARegistery

    ) Ownable(msg.sender)
    {
        i_DARWARegistery = IDARWARegistry(_DARWARegistery);

    }
    /////////////////////////////
    /// Main/CREATE Functions ///
    ////////////////////////////
    function createAsset(
        DALibrary.AssetCreationParams memory _assetCreationParams,
        DALibrary.APIAssetDetails memory _assetDetails,
        DALibrary.FunctionSourceConstructorArgs memory _functionSourceConstructorArgs,
        MonadexV1Types.AddLiquidity memory _addLiquidityParams
    ) external 
    returns(uint256, bytes32 AssetCurrentPrice)
    {

        address FunctionSrc = _CreateFunctionSource(
            _functionSourceConstructorArgs.ChainlinkToken,
            _functionSourceConstructorArgs.OracleToken,
            _functionSourceConstructorArgs.routerSource,
            _functionSourceConstructorArgs.JobId,
            _functionSourceConstructorArgs.Fee,
            _functionSourceConstructorArgs.donId,
            _functionSourceConstructorArgs.subId,
            _functionSourceConstructorArgs.secretVersion,
            _functionSourceConstructorArgs.secretSlot
        );

        AssetCurrentPrice = s_FunctionSource.requestAssetPrice(
            _assetDetails.assetName,
            _assetDetails.apiURL,
            _assetDetails.headerData,
            _assetDetails.endpointPath,
            _assetDetails.requestMethod
        );
        (,uint256 price,uint256 timestamp,) = s_FunctionSource.getPrice(AssetCurrentPrice);
        _Create1155Asset(
            _assetCreationParams.asset,
            _assetCreationParams.ids,
            _assetCreationParams.amounts,
            _assetCreationParams.data,
            _assetCreationParams.uris,
            _assetCreationParams.platformBytes,
            FunctionSrc
        );
        uint64 nonce = 0;
        DARWAEngine(FunctionSrc, nonce, _assetCreationParams, _addLiquidityParams);
        emit DALibrary.FunctionSourceCreated(_assetCreationParams.jobId, FunctionSrc);
        emit DALibrary.PriceRequested(AssetCurrentPrice, _assetDetails.assetName, price, timestamp);
        emit DALibrary.AssetCreated(
            msg.sender, 
            address(i_DACreateAbleAsset1155),
            _assetCreationParams.ids,
            _assetCreationParams.amounts
        );
        s_TotalAssetScore++;
        return (price, AssetCurrentPrice);
    }
    function _Create1155Asset(
        DALibrary.Asset memory _asset,
        uint256[] memory _id,
        uint256[] memory _amount,
        bytes memory _data,
        string[] memory _uri, 
        //address _rwaMananger,
        bytes memory _platformBytes,
        address sourceAddr
    ) 
    private 
    {
        DALibrary.Platform memory platformInfo = i_DARWARegistery.getPlatform(_platformBytes);
        bool isPlatformRegistered = i_DARWARegistery.isPlatformActive(
            platformInfo.platformAddress,
            platformInfo.PlatformID
        );
        if (!isPlatformRegistered) {
            revert DALibrary.DARWA_InvalidPlatformRigistration(isPlatformRegistered);
        }
        bool isAssetRegistered = i_DARWARegistery.isAssetActive(
            platformInfo.platformAddress,
            _asset.AssetID
        );
        if (isAssetRegistered) {
            revert DALibrary.DARWA_InvalidAssetRegistration(isAssetRegistered);
        }
        i_DARWARegistery.assetRegistration(
            _asset,
            sourceAddr,
            platformInfo.PlatformID
        );
        s_Asset = new DACreateAbleAsset1155(
            _id,
            _amount,
            _data,
            _uri,
            platformInfo.platformAddress,
            address(i_engineAddress)
        );

        // note send 20% of the total RWA asset to the RWA manager. 
        


    }

    function DARWAEngine(
        address FunctionSrc,
        uint64 nonce,
        DALibrary.AssetCreationParams memory _assetCreationParams,
        MonadexV1Types.AddLiquidity memory _addLiquidityParams
    ) public returns(DAEngine engine) {
        bytes32 salt = keccak256(abi.encodePacked(_assetCreationParams.ids, nonce++, s_TotalAssetScore));

        bytes memory bytecodeWithArgs = abi.encodePacked(DARWAEngineBytecode,
            abi.encode(
                _assetCreationParams.asset,
                _assetCreationParams.ids,
                _assetCreationParams.amounts,
                _assetCreationParams.data,
                _assetCreationParams.uris,
                _assetCreationParams.platformBytes,
                FunctionSrc
            ));
            assembly {
                engine := create2(0, add(bytecodeWithArgs, 0x20), mload(bytecodeWithArgs), salt)
                if iszero(extcodesize(engine)) { revert(0, 0) }          
            }
            s_Engine.push(engine);
            engine.addLiquid( _addLiquidityParams);
        // send the rest to the engine contract by adding LIQ

    }


    function _CreateFunctionSource(
        address _ChainlinkToken,
        address _OracleToken,
        address _routerSource,
        bytes32 _JobId,
        uint256 _Fee,
        bytes32 _donId,
        uint64 _subId,
        uint64 _secretVersion,
        uint8 _secretSlot
    ) internal returns(address){
        if (s_ChainLinkTokenAddr == address(0) || s_ChainLinkOracle == address(0)) {
            revert DALibrary.DARWA_ZeroAddress();
        }
        s_FunctionSource = new DARWAFunctionSrc(
            _ChainlinkToken,
            _OracleToken,
            _routerSource,
            _JobId,
            _Fee,
            _donId,
            _subId,
            _secretVersion,
            _secretSlot
        );

        emit DALibrary.FunctionSourceCreated(address(s_FunctionSource), _JobId);
        return address(s_FunctionSource);
    }


    function setChainlinkTokenAddress(
        address chainlinkAddr
    ) external onlyOwner {
        s_ChainLinkTokenAddr = chainlinkAddr;
    }

    function setChainlinkOracle(
        address chainlinkOracle
    ) external 
    onlyOwner {
        s_ChainLinkOracle = chainlinkOracle;
    }
    function setFee(
        uint256 fee
    ) external 
    onlyOwner {
        s_Fee = fee;
    }
        ////////////////////
    /// Getter Functions ///
    ////////////////////
    function getRegistry() 
    external 
    view 
    returns (address) {
        return address(i_DARWARegistery);
    }

    function getAsset1155() 
    external 
    view 
    returns (address) {
        return address(i_DACreateAbleAsset1155);
    }
    
}
