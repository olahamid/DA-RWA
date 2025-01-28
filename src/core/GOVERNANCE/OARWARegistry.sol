
// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

import {AccessControl} from "../../../lib/openzeppelin-contracts/contracts/access/AccessControl.sol";
import {Pausable} from "../../../lib/openzeppelin-contracts/contracts/utils/Pausable.sol";
import {OALibrary} from "../../Library/OALibrary.sol";
import {IOARWARegistry} from "../../interface/IOARWARegistry.sol";

/**
 * @title AlpacaSource.sol
 * @author Ola Hamid
 * @notice THIS IS AN DEMO CONTRACT THAT ISN'T AUDITED.
 * DO NOT USE THIS CODE IN PRODUCTION. (UNIT AND INTEGRATION TEST- WIP).
 */
contract OARWARegistry is AccessControl, Pausable, IOARWARegistry {

    mapping (bytes => OALibrary.Platform) s_Platforms;
    mapping (address => mapping (uint16 platormID => bytes platformBytes)) s_PlatformBytes;
    mapping (address => mapping (uint16 assetID => bytes platformBytes)) s_AssetBytes;
    mapping (bytes => OALibrary.Asset) s_Assets;
    mapping (address sourceAssets => bool isApproved) s_approveSourceAsset;

    bytes32 public constant s_OAAssetAdmins = keccak256("s_OAAssetAdmins");
    bytes32 public constant s_OAAssetPlatformAdmins = keccak256("s_OAAssetPlatformAdmins");

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
        _grantRole(s_OAAssetAdmins, _admin);
        _grantRole(s_OAAssetPlatformAdmins, _admin);

        s_FeeOnPlatform = _FeeOnPlatform;
        s_FeeOnAsset = _FeeOnAsset;
    }

    function PlatformRegistration (
        OALibrary.Platform memory _Platforms    
    ) 
    external
    payable
    onlyRole(s_OAAssetAdmins)
    returns(bytes memory)
    {
        address PlatformAddr = _Platforms.platformAddress;
        bytes memory PlatformBytes = abi.encode(PlatformAddr, _Platforms.PlatformName, _Platforms.PlatformID);
        if ( PlatformAddr == address(0)) {
           revert OALibrary.OARWA_ZeroAddress();
        }
        if ( _Platforms.isPlatformActive == true || (s_Platforms[PlatformBytes].isPlatformActive == true)) {
            revert OALibrary.OARWA_InvalidPlatformRigistration(s_Platforms[PlatformBytes].isPlatformActive);
        }
        if (msg.value < s_FeeOnPlatform ) {
            revert OALibrary.OARWA_insufficientFee();
        }
        s_Platforms[PlatformBytes] = OALibrary.Platform({
            PlatformName: _Platforms.PlatformName,
            PlatformID: s_PlatformID++,
            isPlatformActive: true,
            platformAddress:  PlatformAddr,
            assetCount: 0
    });
    _grantRole(s_OAAssetPlatformAdmins,  PlatformAddr);
    emit OALibrary.PlatformRegistered(PlatformAddr, _Platforms.PlatformName, s_Platforms[ PlatformBytes].PlatformID);

    return PlatformBytes;
    }

    function assetRegistration (
        OALibrary.Asset memory _asset,
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
            revert OALibrary.OARWA_InvalidAssetRegistrastion(_asset.assetActive,s_Platforms[platformBytes].isPlatformActive);
        }
        if (msg.value < s_FeeOnAsset ) {
            revert OALibrary.OARWA_insufficientFee();
        }
        s_AssetBytes[_asset.PlatformAddress][s_AssetsID + 1] = assetBytes;
        //set to be asset active and set the remaining struct value
        s_Assets[assetBytes] = OALibrary.Asset({
            AssetName: _asset.AssetName,
            AssetID: s_AssetsID + 1,
            AssetTypes: _asset.AssetTypes,
            assetActive: _asset.assetActive,
            PlatformAddress: _asset.PlatformAddress
        });
        // set new source address to the mapping
        s_approveSourceAsset[assetContractAddr] = true;
        emit OALibrary.AssetRegistered(platformAddr, platformId, _asset.AssetName);

        return assetBytes;
    }

    function killPlatfrom(
        address _platformAddress,
        uint16 platformId
    ) 
    external 
    onlyRole(s_OAAssetAdmins)    
    {
        s_PlatformBytes[_platformAddress][platformId] = " ";
        emit OALibrary.PlatformKilled(_platformAddress);
    }

    function killAsset(
        address _platformAddress,
        uint16 platformId
    ) 
    external
    onlyRole(s_OAAssetAdmins) 
    {
        bytes memory platformBytes = s_PlatformBytes[_platformAddress][platformId];
        delete s_Assets[platformBytes];
        emit OALibrary.AssetKilled(_platformAddress, platformId);
    }

    function setAdmin(
        address _admin
    )
        external 
        onlyRole(s_OAAssetAdmins)
    {
        _grantRole(s_OAAssetAdmins, _admin);
    }

    function setPlatformAdmin(
        address _platformAdmin
    )
        external 
        onlyRole(s_OAAssetPlatformAdmins)
    {
        _grantRole(s_OAAssetPlatformAdmins, _platformAdmin);
    }

    function grantPlatformAdmin(
        address _platformAdmin
    ) 
    external 
    override 
    onlyRole(s_OAAssetAdmins) {
        _grantRole(s_OAAssetPlatformAdmins, _platformAdmin);
    }

    function revokePlatformAdmin(
        address _platformAdmin
    ) 
    external 
    override 
    onlyRole(s_OAAssetAdmins) {
        _revokeRole(s_OAAssetPlatformAdmins, _platformAdmin);
    }

    function grantAssetAdmin(
        address _assetAdmin
    )
    external 
    override 
    onlyRole(s_OAAssetAdmins) {
        _grantRole(s_OAAssetAdmins, _assetAdmin);
    }

    function revokeAssetAdmin(
        address _assetAdmin
    ) 
    external 
    override 
    onlyRole(s_OAAssetAdmins) {
        _revokeRole(s_OAAssetAdmins, _assetAdmin);
    }

    function getPlatform(
        bytes memory platformBytes
    ) 
    external 
    view 
    override 
    returns (OALibrary.Platform memory) {
        return s_Platforms[platformBytes];
    }

    function getAsset(
        address platformCreator,
         uint16 platformId
    ) 
    external 
    view 
    override 
    returns (OALibrary.Asset memory) {
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
    onlyRole(s_OAAssetPlatformAdmins) {
        _pause();
    }

    function unPause(
    ) 
    external 
    onlyRole(s_OAAssetPlatformAdmins) {
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