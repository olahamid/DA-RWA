
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

/**
 * @title AlpacaSource.sol
 * @author Ola Hamid
 * @notice THIS IS A DEMO CONTRACT THAT ISN'T AUDITED.
 * DO NOT USE THIS CODE IN PRODUCTION. (UNIT AND INTEGRATION TEST- WIP).
 */

 import {Ownable} from "../../lib/openzeppelin-contracts/contracts/access/Ownable.sol";
 import {ChainlinkClient} from "../../lib/chainlink-brownie-contracts/contracts/src/v0.8/ChainlinkClient.sol";
 import {Chainlink} from "../../lib/chainlink-brownie-contracts/contracts/src/v0.8/Chainlink.sol";
 import {FunctionsClient} from "../../lib/chainlink-brownie-contracts/contracts/src/v0.8/functions/dev/v1_0_0/FunctionsClient.sol";
 import {FunctionsRequest} from "../../lib/chainlink-brownie-contracts/contracts/src/v0.8/functions/dev/v1_0_0/libraries/FunctionsRequest.sol";
 import {DALibrary} from "../Library/DALibrary.sol";
import {Strings} from "../../lib/openzeppelin-contracts/contracts/utils/Strings.sol";

contract DARWAFunctionSrc is ChainlinkClient, FunctionsClient, Ownable {
    using Chainlink for Chainlink.Request;
    using FunctionsRequest for FunctionsRequest.Request;
    ///////////////////////
    /// State Variables ///
    ///////////////////////
    address private s_Owner;
    uint256 private s_LastPrice;
    address private s_buySourceAddr;
    string private s_buySource;
    address private s_sellSourceAddr;
    string private s_sellSource;
    uint32 private GAS_LIMIT = 300_000;
    DALibrary.FunctionSourceConstructorArgs public functionSourceConstructorArgs;

    /////////////////////
    //////Events/////////
    /////////////////////
    event RequestFulfilled(bytes32 asset, uint256 price);

    error DARWA_FunctionSrcMethodError();
    error DARWA_PriceNotAvailable();
    
    ///////////////////
    /// Constructor ///
    ///////////////////

    mapping (bytes32 => DALibrary.AssetPrice) private s_AssetPriceRequest;
    mapping (bytes32 => DALibrary.assetTradeReq) private s_AssetTradeRequest; 
  
    constructor (
        address _ChainlinkToken,
        address _OracleToken,
        address _routerSource,
        bytes32 _JobId,
        uint256 _Fee,
        bytes32 _donId,
        uint64 _subId,
        uint64 _secretVersion,
        uint8 _secretSlot
    ) 
    
    Ownable(msg.sender) 
    FunctionsClient(_routerSource)
    {
        functionSourceConstructorArgs = DALibrary.FunctionSourceConstructorArgs({
            ChainlinkToken: _ChainlinkToken,
            OracleToken: _OracleToken,
            routerSource: _routerSource,
            JobId: _JobId,
            Fee: _Fee,
            donId: _donId,
            subId: _subId,
            secretVersion: _secretVersion,
            secretSlot: _secretSlot
        });
    }
    function setSecretVersion(uint64 _version) external onlyOwner {
        functionSourceConstructorArgs.secretVersion = _version;
    }

    function setSecretSlot(uint8 _slot) external onlyOwner {
        functionSourceConstructorArgs.secretSlot = _slot;
    }

    function setRouterAddress(address _router) external onlyOwner {
        functionSourceConstructorArgs.routerSource = _router;
    }

    function setBuySource(address _source) external onlyOwner {
        s_buySourceAddr = _source;
    }

    function setSellSource(address _source) external onlyOwner {
        s_sellSourceAddr = _source;
    }

    function setBuySourceCode(string memory _source) external onlyOwner {
        s_buySource = _source;
    }

    function setSellSourceCode(string memory _source) external onlyOwner {
        s_sellSource = _source;
    }
    // set the params 
    // check that the parameters are not zero bytes
    // set the get API endpoint
    // set the price to the price in api response
    // 
    /* NOTE- EXAMPLE USAGE OF THE PARAMETERS
    "TSLA", // Asset name
    "https://api.alpaca.markets/v2/stocks/TSLA/quotes/latest", // API URL
    "APCA-API-KEY-ID: YOUR_API_KEY, APCA-API-SECRET-KEY: YOUR_SECRET_KEY", // Headers
    "quote.bp", // Path to the price
    "get" // HTTP method
    */
   function requestBuyAsset(
    string memory assetName,
    uint256 assetId,
    address trader,
    uint256 amount
   )
   public
   returns(bytes32 requestId) {
    FunctionsRequest.Request memory req;
    req.initializeRequestForInlineJavaScript(s_buySource);
    req.addDONHostedSecrets(functionSourceConstructorArgs.secretSlot, functionSourceConstructorArgs.secretVersion);
    string[] memory args = new string[](3);
    args[1] = Strings.toString(amount);
    args[0] = assetName;
    args[1] = Strings.toString(amount);
    args[2] = Strings.toString(assetId);

    req.setArgs(args);
    requestId = _sendRequest(req.encodeCBOR(), functionSourceConstructorArgs.subId, GAS_LIMIT, functionSourceConstructorArgs.donId);

    s_AssetTradeRequest[requestId] = DALibrary.assetTradeReq({
        assetName: assetName,
        assetId: assetId,
        amount: amount,
        fulfiled: false,
        trader: trader,
        timestamp: 0,
        tradeType: DALibrary.TradeType.buy
    });
    // note emit an event for this
    return requestId;
   }

   function requestSellAsset(
    string memory assetName,
    uint256 assetId,
    address trader,
    uint256 amount 
   ) 
   public
   returns(bytes32 requestId) {
        FunctionsRequest.Request memory req;
        req.initializeRequestForInlineJavaScript(s_sellSource);
        req.addDONHostedSecrets(functionSourceConstructorArgs.secretSlot, functionSourceConstructorArgs.secretVersion);
        string[] memory args = new string[](3);
        args[1] = Strings.toString(amount);
        args[0] = assetName;
        args[1] = Strings.toString(amount);
        args[2] = Strings.toString(assetId);

        req.setArgs(args);
        requestId = _sendRequest(req.encodeCBOR(), functionSourceConstructorArgs.subId, GAS_LIMIT, functionSourceConstructorArgs.donId);

        s_AssetTradeRequest[requestId] = DALibrary.assetTradeReq({
            assetName: assetName,
            assetId: assetId,
            amount: amount,
            fulfiled: false,
            trader: trader,
            timestamp: 0,
            tradeType: DALibrary.TradeType.sell
        });
        // note emit an event for this
        return requestId;
   }

   function fulfillRequest(
    bytes32 requestId,
    bytes memory response,
    bytes memory err
   ) 
   internal 
   override {
         DALibrary.assetTradeReq storage _request = s_AssetTradeRequest[requestId];

         _request.fulfiled = true;
        _request.timestamp = block.timestamp;
        uint256 result = uint256(bytes32(response));
        if (err.length > 0 || result == 0) {
            revert DALibrary.DARWA_FunctionSrcRequestFulfilledError();
        }
   }

    function requestAssetPrice(
        string memory _assetName,
        string memory _assetAPIURL,
        string memory _assetHeader,
        string memory _assetPath,
        string memory _assetMethod
    )
    public 
    returns(bytes32 requestId)
    {
        Chainlink.Request memory req = buildChainlinkRequest(
            functionSourceConstructorArgs.JobId,
            address(this),
            this.fulfill.selector
        );
        if (keccak256(abi.encodePacked(_assetMethod)) == keccak256(abi.encodePacked("post"))) {
            req.add("post", _assetAPIURL);
            req.add("body", "{\"_assetName\": \"" "\"}");
        } else if (keccak256(abi.encodePacked(_assetMethod)) == keccak256(abi.encodePacked("get"))) {
            req.add("get", _assetAPIURL);
        } else {
            revert DARWA_FunctionSrcMethodError();
        }
        

        req.add("headers", _assetHeader);

        req.add("path", _assetPath);

        req.add("metadata", _assetName);

        s_AssetPriceRequest[requestId] = DALibrary.AssetPrice({
            price: 0,
            timestamp: 0,
            assetName: _assetName,
            fulfilled: false
        });
        sendChainlinkRequest(req, functionSourceConstructorArgs.Fee);

        return requestId;
    } 

    function fulfill(bytes32  _requestId, uint256 _price) public recordChainlinkFulfillment(_requestId) {
        DALibrary.AssetPrice storage request = s_AssetPriceRequest[_requestId];
        emit RequestFulfilled(_requestId, _price);

        request.price = _price;
        request.timestamp = block.timestamp;
        request.fulfilled = true;
    }

    function getPrice(
       bytes32 _requestId
    ) 
    public
    view 
    returns(
        bool fulfilled,
        uint256 price,
        uint256 timestamp,
        string memory assetName
    ) 
    {
        DALibrary.AssetPrice memory request = s_AssetPriceRequest[_requestId];
        if (!request.fulfilled) {
            revert DARWA_PriceNotAvailable();
        }
        if (bytes(request.assetName).length == 0) {
            revert DARWA_PriceNotAvailable();
        }
    return (
        request.fulfilled,
        request.price,
        request.timestamp,
        request.assetName
    );
    }

    function getOperationDetails(
        bytes32 requestID
    )
    external
    view 
    returns(DALibrary.assetTradeReq memory tradeReq) {
        return s_AssetTradeRequest[requestID];
    }

    function getRouterAddress() external view returns(address) {
        return functionSourceConstructorArgs.routerSource;
    }

    function getBuySource() external view returns(string memory) {
        return s_buySource;
    }

    function getSellSource() external view returns(string memory) {
        return s_sellSource;
    }

    function getSecretVersion() external view returns(uint64) {
        return functionSourceConstructorArgs.secretVersion;
    }

    function getSecretSlot() external view returns(uint8) {
        return functionSourceConstructorArgs.secretSlot;
    }

    function getBuySourceAddress() external view returns(address) {
        return s_buySourceAddr;
    }

    function getSellSourceAddress() external view returns(address) {
        return s_sellSourceAddr;
    }

}