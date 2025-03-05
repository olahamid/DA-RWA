// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

import {DALibrary} from "../Library/DALibrary.sol";
interface IDARWARegistry {

    function s_DAAssetAdmins() external view returns(bytes32);

    function s_DAAssetPlatformAdmins() external view returns(bytes32);

    function assetRegistration(DALibrary.Asset memory _asset, address _assetContractAddr, uint16 assetID ) external payable returns(bytes memory);
    function grantPlatformAdmin(address _platformAdmin) external;
    function revokePlatformAdmin(address _platformAdmin) external;
    function grantAssetAdmin(address _assetAdmin) external;
    function revokeAssetAdmin(address _assetAdmin) external;

    // View Functions
    function getPlatform(bytes memory platformBytes) external view returns (DALibrary.Platform memory);
    function getAsset(address platformCreator, uint16 platformId) external view returns (DALibrary.Asset memory);
    function isPlatformActive(address platformAddress, uint16 _platformId) external view returns (bool);
    function isAssetActive(address platformAddress, uint16 assetId) external view returns (bool);

    // Asset Management
    function killAsset(address platformAddress, uint16 assetId) external;
    function getFeeOnPlatform() external view returns (uint256);
    function getFeeOnAsset() external view returns (uint256);
}
