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
pragma solidity 0.8.22;

/**
 * @title AlpacaSource.sol
 * @author Ola Hamid
 * @notice THIS IS A DEMO CONTRACT THAT ISN'T AUDITED.
 * DO NOT USE THIS CODE IN PRODUCTION. (UNIT AND INTEGRATION TEST- WIP).
 */

 import {Ownable} from "../../lib/openzeppelin-contracts/contracts/access/Ownable.sol";
 import {ChainlinkClient} from "../../lib/chainlink-brownie-contracts/contracts/src/v0.8/ChainlinkClient.sol";
 import {Chainlink} from "../../lib/chainlink-brownie-contracts/contracts/src/v0.8/Chainlink.sol";
 import {OALibrary} from "../Library/OALibrary.sol";
contract OARWAFunctionSrc is ChainlinkClient, Ownable {
    using Chainlink for Chainlink.Request;
    ///////////////////////
    /// State Variables ///
    ///////////////////////
    address private s_Owner;
    bytes32 private s_JobId;
    uint256 private s_Fee;
    /////////////////////
    //////Events/////////
    /////////////////////
    event RequestFulfilled(bytes32 asset, uint256 price);

    error OARWA_FunctionSrcMethodError();
    error OARWA_PriceNotAvailable();
    ///////////////////
    /// Constructor ///
    ///////////////////

    mapping (bytes32 => OALibrary.AssetPrice) private s_AssetRequest;
  
    constructor (
        address _ChainlinkToken,
        address _OracleToken,
        bytes32 _JobId,
        uint256 _Fee
    ) 
    Ownable(msg.sender) 
    {
        setChainlinkToken(_ChainlinkToken); // // LINK token address (Sepolia)
        setChainlinkOracle(_OracleToken); // Oracle address (Sepolia)
        s_JobId = _JobId; // Job ID (Sepolia)
        s_Fee = _Fee;   // Fee (Sepolia)
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
        if (bytes(_assetName).length == 0 || 
        bytes(_assetAPIURL).length == 0 || 
        bytes(_assetPath).length == 0 ) {
            revert OALibrary.OARWA_ZeroAddress();
        }
        Chainlink.Request memory req = buildChainlinkRequest(
            s_JobId,
            address(this),
            this.fulfill.selector
        );

        if (keccak256(abi.encodePacked(_assetMethod)) == keccak256(abi.encodePacked("post"))) {
            req.add("post", _assetAPIURL);
            req.add("body", "{\"_assetName\": \"" "\"}");
        } else if (keccak256(abi.encodePacked(_assetMethod)) == keccak256(abi.encodePacked("get"))) {
            req.add("get", _assetAPIURL);
        } else {
            revert OARWA_FunctionSrcMethodError();
        }
        

        req.add("headers", _assetHeader);

        req.add("path", _assetPath);

        req.add("metadata", _assetName);

        s_AssetRequest[requestId] = OALibrary.AssetPrice({
            price: 0,
            timestamp: 0,
            assetName: _assetName,
            fulfilled: false
        });
        sendChainlinkRequest(req, s_Fee);

        return requestId;
    } 

    function fulfill(bytes32  _requestId, uint256 _price) public recordChainlinkFulfillment(_requestId) {
        OALibrary.AssetPrice storage request = s_AssetRequest[_requestId];
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
        OALibrary.AssetPrice memory request = s_AssetRequest[_requestId];
        if (!request.fulfilled) {
            revert OARWA_PriceNotAvailable();
        }
        if (bytes(request.assetName).length == 0) {
            revert OARWA_PriceNotAvailable();
        }
    return (
        request.fulfilled,
        request.price,
        request.timestamp,
        request.assetName
    );
    }
}