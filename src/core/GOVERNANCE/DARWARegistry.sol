
// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

import {AccessControl} from "../../../lib/openzeppelin-contracts/contracts/access/AccessControl.sol";
import {Pausable} from "../../../lib/openzeppelin-contracts/contracts/utils/Pausable.sol";
import {DALibrary} from "../../Library/DALibrary.sol";
import {IDARWARegistry} from "../../interface/IDARWARegistry.sol";

/**
 * @title AlpacaSource.sol
 * @author Ola Hamid
 * @notice THIS IS AN DEMO CONTRACT THAT ISN'T AUDITED.
 * DO NOT USE THIS CODE IN PRODUCTION. (UNIT AND INTEGRATION TEST- WIP).
 */
contract DARWARegistry is AccessControl, Pausable, IDARWARegistry {

    mapping (bytes => DALibrary.Platform) s_Platforms;
    mapping (address => mapping (uint16 platormID => bytes platformBytes)) s_PlatformBytes;
    mapping (address => mapping (uint16 assetID => bytes platformBytes)) s_AssetBytes;
    mapping (bytes => DALibrary.Asset) s_Assets;
    mapping (address sourceAssets => bool isApproved) s_approveSourceAsset;

    bytes32 public constant s_DAAssetAdmins = keccak256("s_DAAssetAdmins");
    bytes32 public constant s_DAAssetPlatformAdmins = keccak256("s_DAAssetPlatformAdmins");

    uint16 private s_PlatformID = 0;
    uint16 private s_AssetsID = 0;
    uint256 private immutable s_FeeOnPlatform;
    uint256 private immutable s_FeeOnAsset;
    constructor (
        address _admin,
        uint256 _FeeOnPlatform,
        uint256 _FeeOnAsset
     )
     {
        _grantRole(s_DAAssetAdmins, _admin);
        _grantRole(s_DAAssetPlatformAdmins, _admin);

        s_FeeOnPlatform = _FeeOnPlatform;
        s_FeeOnAsset = _FeeOnAsset;
    }

    function PlatformRegistration (
        DALibrary.Platform memory _Platforms    
    ) 
    external
    payable
    onlyRole(s_DAAssetAdmins)
    returns(bytes memory)
    {
        address PlatformAddr = _Platforms.platformAddress;
        bytes memory PlatformBytes = abi.encode(PlatformAddr, _Platforms.PlatformName, _Platforms.PlatformID);
        if ( PlatformAddr == address(0)) {
           revert DALibrary.DARWA_ZeroAddress();
        }
        if ( _Platforms.isPlatformActive == true || (s_Platforms[PlatformBytes].isPlatformActive == true)) {
            revert DALibrary.DARWA_InvalidPlatformRigistration(s_Platforms[PlatformBytes].isPlatformActive);
        }
        if (msg.value < s_FeeOnPlatform ) {
            revert DALibrary.DARWA_insufficientFee();
        }
        s_Platforms[PlatformBytes] = DALibrary.Platform({
            PlatformName: _Platforms.PlatformName,
            PlatformID: s_PlatformID++,
            isPlatformActive: true,
            platformAddress:  PlatformAddr,
            assetCount: 0
    });
    _grantRole(s_DAAssetPlatformAdmins,  PlatformAddr);
    emit DALibrary.PlatformRegistered(PlatformAddr, _Platforms.PlatformName, s_Platforms[ PlatformBytes].PlatformID);

    return PlatformBytes;
    }

    function assetRegistration (
        DALibrary.Asset memory _asset,
        address assetContractAddr,
        uint16 platformId
    ) 
    external
    payable
    returns(bytes memory)
    {
        address platformAddr = _asset.PlatformAddress;
        //uint16 platform = s_Platforms[platformAddr].PlatformID;
        bytes memory platformBytes = s_PlatformBytes[platformAddr][platformId];
        bytes memory assetBytes = abi.encode(platformBytes, _asset.AssetName, _asset.AssetID);
        // check that the asset is not active and check that the platform is active 
        if (_asset.assetActive == true || 
            s_Platforms[platformBytes].isPlatformActive != true ||
            s_Platforms[platformBytes].platformAddress != _asset.PlatformAddress
        ) {
            revert DALibrary.DARWA_InvalidAssetRegistrastion(_asset.assetActive,s_Platforms[platformBytes].isPlatformActive);
        }
        if (msg.value < s_FeeOnAsset ) {
            revert DALibrary.DARWA_insufficientFee();
        }
        s_AssetBytes[_asset.PlatformAddress][s_AssetsID + 1] = assetBytes;
        //set to be asset active and set the remaining struct value
        s_Assets[assetBytes] = DALibrary.Asset({
            AssetName: _asset.AssetName,
            AssetID: s_AssetsID + 1,
            AssetTypes: _asset.AssetTypes,
            assetActive: _asset.assetActive,
            PlatformAddress: _asset.PlatformAddress
        });
        // set new source address to the mapping
        s_approveSourceAsset[assetContractAddr] = true;
        emit DALibrary.AssetRegistered(platformAddr, platformId, _asset.AssetName);

        return assetBytes;
    }

    function killPlatfrom(
        address _platformAddress,
        uint16 platformId
    ) 
    external 
    onlyRole(s_DAAssetAdmins)    
    {
        s_PlatformBytes[_platformAddress][platformId] = " ";
        emit DALibrary.PlatformKilled(_platformAddress);
    }

    function killAsset(
        address _platformAddress,
        uint16 platformId
    ) 
    external
    onlyRole(s_DAAssetAdmins) 
    {
        bytes memory platformBytes = s_PlatformBytes[_platformAddress][platformId];
        delete s_Assets[platformBytes];
        emit DALibrary.AssetKilled(_platformAddress, platformId);
    }

    function setAdmin(
        address _admin
    )
        external 
        onlyRole(s_DAAssetAdmins)
    {
        _grantRole(s_DAAssetAdmins, _admin);
    }

    function setPlatformAdmin(
        address _platformAdmin
    )
        external 
        onlyRole(s_DAAssetPlatformAdmins)
    {
        _grantRole(s_DAAssetPlatformAdmins, _platformAdmin);
    }

    function grantPlatformAdmin(
        address _platformAdmin
    ) 
    external 
    override 
    onlyRole(s_DAAssetAdmins) {
        _grantRole(s_DAAssetPlatformAdmins, _platformAdmin);
    }

    function revokePlatformAdmin(
        address _platformAdmin
    ) 
    external 
    override 
    onlyRole(s_DAAssetAdmins) {
        _revokeRole(s_DAAssetPlatformAdmins, _platformAdmin);
    }

    function grantAssetAdmin(
        address _assetAdmin
    )
    external 
    override 
    onlyRole(s_DAAssetAdmins) {
        _grantRole(s_DAAssetAdmins, _assetAdmin);
    }

    function revokeAssetAdmin(
        address _assetAdmin
    ) 
    external 
    override 
    onlyRole(s_DAAssetAdmins) {
        _revokeRole(s_DAAssetAdmins, _assetAdmin);
    }

    function getPlatform(
        bytes memory platformBytes
    ) 
    external 
    view 
    override 
    returns (DALibrary.Platform memory) {
        return s_Platforms[platformBytes];
    }

    function getAsset(
        address platformCreator,
         uint16 platformId
    ) 
    external 
    view 
    override 
    returns (DALibrary.Asset memory) {
        bytes memory platformBytes = s_PlatformBytes[platformCreator][platformId];
        return s_Assets[platformBytes];
    }
    function getAssetBytes(
        address platformCreator, 
        uint16 platformId
    ) 
    external 
    view 
    returns (bytes memory) {
        return s_AssetBytes[platformCreator][platformId];
    }
    function getPlatformBytes(
        address platformCreator, 
        uint16 platformId
    ) 
    external 
    view 
    returns (bytes memory) {
        return s_PlatformBytes[platformCreator][platformId];
    }

    function isPlatformActive(
        address platformAddress,
        uint16 _platformId
    ) 
    external 
    view 
    override 
    returns (bool) {
        bytes memory platformBytes = s_PlatformBytes[platformAddress][_platformId];
        return s_Platforms[platformBytes].isPlatformActive;
    }

    function isAssetActive( 
        address platformAddress,
        uint16 assetId
    ) external 
    view 
    override 
    returns (bool) {
        bytes memory platformBytes = s_PlatformBytes[platformAddress][assetId];
        return s_Assets[platformBytes].assetActive;
    }

    function getFeeOnPlatform(

    ) 
    external 
    view 
    override 
    returns (uint256) {
        return s_FeeOnPlatform;
    }

    function getFeeOnAsset(

    ) 
    external 
    view 
    override 
    returns (uint256) {
        return s_FeeOnAsset;
    }

    function pause(
    ) 
    external 
    onlyRole(s_DAAssetPlatformAdmins) {
        _pause();
    }

    function unPause(
    ) 
    external 
    onlyRole(s_DAAssetPlatformAdmins) {
        _unpause();
    }
    function _pause(
    ) 
    internal
    override {
        super._pause();
    }

    function _unpause(
    ) 
    internal 
    override {
        super._unpause();
    }
}