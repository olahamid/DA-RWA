// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

interface  IOACreateAbleAsset1155 {
    function mint(address _to,uint256 _id,uint256 _amount, bytes memory _data) external;

    function setURI(uint _id, string memory _uri) external;

    function burn(address _manager,uint256 _id,uint256 _amount) external;

    function batchBurn(address _manager,uint256[] memory _id,uint256[] memory _amount,string[] memory _uri) external;

    function SetRWAManager(address _newManager) external;
}