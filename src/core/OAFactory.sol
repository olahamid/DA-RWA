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
 * @notice THIS IS AN DEMO CONTRACT THAT ISN'T AUDITED.
 * DO NOT USE THIS CODE IN PRODUCTION. (UNIT AND INTEGRATION TEST- WIP).
 */

 import {Ownable} from "../../lib/openzeppelin-contracts/contracts/access/Ownable.sol";
 import {IOARWARegistry} from "../interface/IOARWARegistry.sol";
 import {IOACreateAbleAsset1155} from "../interface/IOACreateAbleAsset1155.sol";
 import {OACreateAbleAsset1155} from "../core/OACreateAbleAsset1155.sol";
 import {OALibrary} from "../Library/OALibrary.sol";
import {OARWAFunctionSrc} from "../FunctionSources/OARWAFunctionSrc.sol";

contract OAFactory is Ownable {

    ////////////////////////
    /// State Variables ///
    ////////////////////////
    IOARWARegistry public immutable i_OARWARegistery;
    IOACreateAbleAsset1155 private immutable i_OACreateAbleAsset1155;
    OACreateAbleAsset1155 private s_Asset;
    OARWAFunctionSrc private s_FunctionSource;

    address private s_ChainLinkTokenAddr;
    address private s_ChainLinkOracle;

    uint256 private s_Fee;

    ///////////////////
    /// Constructor ///
    ///////////////////
    constructor (
        address _OARWARegistery,
        address _OACreateAbleAsset1155,
        address _chainLinkTOkenAddr,
        address _chainlinkOracle,
        uint256 _fee
    ) Ownable(msg.sender)
    {
        i_OARWARegistery = IOARWARegistry(_OARWARegistery);
        i_OACreateAbleAsset1155 = IOACreateAbleAsset1155(_OACreateAbleAsset1155);
        s_ChainLinkTokenAddr = _chainLinkTOkenAddr;
        s_ChainLinkOracle = _chainlinkOracle;
        s_Fee = _fee;

    }
    /////////////////////////////
    /// Main/CREATE Functions ///
    ////////////////////////////
    function createAsset(
        OALibrary.AssetCreationParams memory _assetCreationParams,
        OALibrary.APIAssetDetails memory _assetDetails
    ) external 
    returns(uint, bytes32 AssetCurrentPrice)
    {

        address FunctionSrc = _CreateFunctionSource(_assetCreationParams.jobId);

        AssetCurrentPrice = s_FunctionSource.requestAssetPrice(
            _assetDetails.assetName,
            _assetDetails.apiURL,
            _assetDetails.headerData,
            _assetDetails.endpointPath,
            _assetDetails.requestMethod
        );
        (,
        uint256 price,
        uint256 timestamp,
        ) = s_FunctionSource.getPrice(AssetCurrentPrice);
        _Create1155Asset(
            _assetCreationParams.asset,
            _assetCreationParams.ids,
            _assetCreationParams.amounts,
            _assetCreationParams.data,
            _assetCreationParams.uris,
            _assetCreationParams.rwaManager,
            _assetCreationParams.platformBytes,
            FunctionSrc
        );
        emit OALibrary.FunctionSourceCreated(_assetCreationParams.jobId, FunctionSrc);
        emit OALibrary.PriceRequested(AssetCurrentPrice, _assetDetails.assetName, price, timestamp);
        emit OALibrary.AssetCreated(
            msg.sender, 
            address(i_OACreateAbleAsset1155),
            _assetCreationParams.ids,
            _assetCreationParams.amounts
        );
        return (price, AssetCurrentPrice);

    }
    function _Create1155Asset(
        OALibrary.Asset memory _asset,
        uint256[] memory _id,
        uint256[] memory _amount,
        bytes memory _data,
        string[] memory _uri, 
        address _rwaMananger,
        bytes memory _platformBytes,
        address sourceAddr
    ) 
    private 
    {
        OALibrary.Platform memory platformInfo = i_OARWARegistery.getPlatform(_platformBytes);
        bool isPlatformRegistered = i_OARWARegistery.isPlatformActive(
            platformInfo.platformAddress,
            platformInfo.PlatformID
        );
        if (!isPlatformRegistered) {
            revert OALibrary.OARWA_InvalidPlatformRigistration(isPlatformRegistered);
        }
        bool isAssetRegistered = i_OARWARegistery.isAssetActive(
            platformInfo.platformAddress,
            _asset.AssetID
        );
        if (isAssetRegistered) {
            revert OALibrary.OARWA_InvalidAssetRegistration(isAssetRegistered);
        }
        i_OARWARegistery.assetRegistration(
            _asset,
            sourceAddr,
            platformInfo.PlatformID
        );
        s_Asset = new OACreateAbleAsset1155(
            _id,
            _amount,
            _data,
            _uri,
            _rwaMananger
        );
    }

    function _CreateFunctionSource(
        bytes32 _jobId
    ) internal returns(address){
        if (s_ChainLinkTokenAddr == address(0) || s_ChainLinkOracle == address(0)) {
            revert OALibrary.OARWA_ZeroAddress();
        }
        s_FunctionSource = new OARWAFunctionSrc(
            s_ChainLinkTokenAddr,
            s_ChainLinkOracle,
            _jobId,
            s_Fee
        );

        emit OALibrary.FunctionSourceCreated(address(s_FunctionSource), _jobId);
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
        return address(i_OARWARegistery);
    }

    function getAsset1155() 
    external 
    view 
    returns (address) {
        return address(i_OACreateAbleAsset1155);
    }
}
