
// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;
/**
 * @title AlpacaSource.sol
 * @author Ola Hamid
 * @notice THIS IS AN DEMO CONTRACT THAT ISN'T AUDITED.
 * DO NOT USE THIS CODE IN PRODUCTION. (UNIT AND INTEGRATION TEST- WIP).
 */

 import {ERC1155Supply, ERC1155} from "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
 import {Ownable} from "../../lib/openzeppelin-contracts/contracts/access/Ownable.sol";
//import {AccessControlUpgradeable} from "../../lib/openzeppelin-contracts-upgradeable/contracts/access/AccessControlUpgradeable.sol";

 contract CreateAbleAsset1155 is ERC1155Supply{

      ///////////////////////
    /// State Variables ///
    ///////////////////////
  address private RWA_Manager;
   mapping (uint => string) public tokenURI;
   mapping (address _manager=> uint _ids) managerIDs;
   uint8 public MAX_MINTS = 10;
   
    //////////////
    /// Errors ///
    //////////////
  error invalidRetriveData();
  error invalid_Manager();
    ///////////////////
    /// Constructor ///
    ///////////////////
   constructor (
    address _to,
    uint256[] memory _id,
    uint256[] memory _amount,
    bytes memory _data,
    string memory _uri, 
    address _rwaMananger, 
    address _FactoryCA) ERC1155(_uri){
      _rwaMananger = RWA_Manager; //
      
    for (uint i = 0; i < MAX_MINTS; ++i) {
      _setURI(_id[i], _uri);
      managerIDs[_rwaMananger] = _id[i];
    }
    batchMint(_to, _id, _amount, _data);
   }
    function mint(
      address _to,
      uint256 _id,
      uint256 _amount, 
      bytes memory _data
    ) internal { 
      // if address ()
      if (msg.sender != RWA_Manager) {
        revert invalid_Manager();
      }
        _mint(_to, _id, _amount, _data);
    }

    function batchMint(
      address _to,
      uint256[] memory _id,
      uint256[] memory _amount,
      bytes memory _data
    ) internal {
      _mintBatch(_to, _id, _amount, _data);
    }


  
    function _setURI(
      uint _id, 
      string memory _uri
    ) private {
      tokenURI[_id] = _uri;
      super._setURI(_uri);
    }
    function setURI(
      uint _id, 
      string memory _uri
    ) external {
      if (msg.sender != RWA_Manager ) {
        revert invalid_Manager();
      }
      _setURI(_id,_uri);
    }
    
    function retriveURI(
      uint _id) 
      public view returns(string memory) {
      string memory _tokenURI = tokenURI[_id];
      if (bytes(_tokenURI).length == 0 ) {
        revert invalidRetriveData();
      }
      return _tokenURI;
    }

    function burn(
      address _manager,
      uint256 _id,
      uint256 _amount
    ) external {
      if (msg.sender != RWA_Manager ) {
        revert invalid_Manager();
      }
      _burn(_manager, _id, _amount);
    }
    
    function batchBurn(
      address _manager,
      uint256[] memory _id,
      uint256[] memory _amount
    ) external {
      if (msg.sender != RWA_Manager ) {
        revert invalid_Manager();
      } 
      _burnBatch(_manager, _id, _amount);
    }
 }