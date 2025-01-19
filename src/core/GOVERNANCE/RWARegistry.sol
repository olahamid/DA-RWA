
// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

import {AccessControl} from "../../../lib/openzeppelin-contracts/contracts/access/AccessControl.sol";
import {Pausable} from "../../../lib/openzeppelin-contracts/contracts/utils/Pausable.sol";

/**
 * @title AlpacaSource.sol
 * @author Ola Hamid
 * @notice THIS IS AN DEMO CONTRACT THAT ISN'T AUDITED.
 * DO NOT USE THIS CODE IN PRODUCTION. (UNIT AND INTEGRATION TEST- WIP).
 */
contract RWARegistry is AccessControl, Pausable {

    ///@notice these are various types of token asset on OA-RWAasset 
    enum AssetTypes {
        watches,
        vehicles,
        oilAndGas,
        stocks,
        realEstateAddress, 
        metalsAndStones,
        renewableEnergy
    }

    /// @notice datiled struct with diffeent properties for a creating a platform
    struct Platform {
        string PlatformName;
        uint16 PlatformID;
        bool isPlatformActive;
        address platformAddress;
        uint8 assetCount;
    }
    
    /// @notice datiled struct with diffeent properties for a creating an asset
    struct Asset {
        string AssetName;
        uint16 AssetID;
        AssetTypes AssetTypes;
        bool assetActive;
        address PlatformAddress;
    }

    error OARWA_InvalidPlatformRigistration(bool isActive);
    error OARWA_InvalidAssetRegistrastion(bool isAssetActive, bool isPlatfromActive);
    error OARWA_ZeroAddress();
    error OARWA_insufficientFee();

    event PlatformRegistered(address indexed platformAddress, string name, uint16 platformId);
    event AssetRegistered(address indexed platformAddress, uint16 assetId, string name);
    event PlatformKilled(address indexed platformAddress);
    event AssetKilled(address indexed platformAddress, uint16 assetId);


    mapping (address platformCreator => Platform) s_Platforms;
    mapping (address platformCreator => mapping (uint16 platormID => Asset)) s_Assets;
    mapping (address sourceAssets => bool isApproved) s_approveSourceAsset;

    bytes32 public s_OAAssetAdmins = keccak256("s_OAAssetAdmins");
    bytes32 public s_OAAssetPlatformAdmins = keccak256("s_OAAssetPlatformAdmins");

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
        Platform memory _Platforms    
    ) 
    public
    payable
    onlyRole(s_OAAssetAdmins)
    {
        address PlatformAddr = _Platforms.platformAddress;
        if ( PlatformAddr == address(0)) {
           revert OARWA_ZeroAddress();
        }
        if ( _Platforms.isPlatformActive == true || (s_Platforms[ PlatformAddr].isPlatformActive == true)) {
            revert OARWA_InvalidPlatformRigistration(s_Platforms[ PlatformAddr].isPlatformActive);
        }
        if (msg.value < s_FeeOnPlatform ) {
            revert OARWA_insufficientFee();
        }
        s_Platforms[ PlatformAddr] = Platform({
            PlatformName: _Platforms.PlatformName,
            PlatformID: s_PlatformID++,
            isPlatformActive: true,
            platformAddress:  PlatformAddr,
            assetCount: 0
    });
    _grantRole(s_OAAssetPlatformAdmins,  PlatformAddr);
    emit PlatformRegistered(PlatformAddr, _Platforms.PlatformName, s_Platforms[ PlatformAddr].PlatformID);

    }

    function assetRegistration (
        Asset memory _asset,
        address assetContractAddr
    ) 
    public 
    payable
    onlyRole(s_OAAssetPlatformAdmins)
    {
        address platformAddr = _asset.PlatformAddress;
        uint16 platformId = s_Platforms[platformAddr].PlatformID;
        // check that the asset is not active and check that the platform is active 
        if (_asset.assetActive == true || 
            s_Platforms[platformAddr].isPlatformActive != true ||
            s_Platforms[platformAddr].platformAddress != _asset.PlatformAddress
        ) {
            revert OARWA_InvalidAssetRegistrastion(_asset.assetActive,s_Platforms[platformAddr].isPlatformActive);
        }
        if (msg.value < s_FeeOnAsset ) {
            revert OARWA_insufficientFee();
        }
        //set to be asset active and set the remaining struct value
        s_Assets[platformAddr][platformId] = Asset({
            AssetName: _asset.AssetName,
            AssetID: s_AssetsID,
            AssetTypes: _asset.AssetTypes,
            assetActive: _asset.assetActive,
            PlatformAddress: _asset.PlatformAddress
        });
        // set new source address to the mapping
        s_approveSourceAsset[assetContractAddr] = true;
        emit AssetRegistered(platformAddr, platformId, _asset.AssetName);

    }

    function killPlatfrom(
        address _platformAddress
    ) 
    public 
    onlyRole(s_OAAssetAdmins)    
    {
        delete s_Platforms[_platformAddress];
        emit PlatformKilled(_platformAddress);
    }

    function killAssets(
        address _platformAddress
    ) 
    public 
    onlyRole(s_OAAssetAdmins) 
    {
        uint16 platformId = s_Platforms[_platformAddress].PlatformID;
        delete s_Assets[_platformAddress][platformId];
        emit AssetKilled(_platformAddress, platformId);
    }

    function setAdmin(
        address _admin
    )
        public 
        onlyRole(s_OAAssetAdmins)
    {
        _grantRole(s_OAAssetAdmins, _admin);
    }

    function setPlatformAdmin(
        address _platformAdmin
    )
        public 
        onlyRole(s_OAAssetPlatformAdmins)
    {
        _grantRole(s_OAAssetPlatformAdmins, _platformAdmin);
    }
    function _pause() internal override {
        super._pause();
    }

    function _unpause() internal override {
        super._unpause();
    }

}