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
 import {IOACreateAbleAsset1155} from "../interface/IOACreateAbleAsset1155.sol";
 import {OALibrary} from "../Library/OALibrary.sol";
//import {AccessControlUpgradeable} from "../../lib/openzeppelin-contracts-upgradeable/contracts/access/AccessControlUpgradeable.sol";

 contract OACreateAbleAsset1155 is ERC1155Supply, IOACreateAbleAsset1155 {

    ///////////////////////
    /// State Variables ///
    ///////////////////////
  address private RWA_Manager;
   mapping (uint id => mapping (string uri => bool)) public TokenURI;
   mapping (address _manager=> uint _ids) managerIDs;
   uint8 public MAX_MINTS = 10;
   
    ///////////////////
    /// Constructor ///
    ///////////////////
  constructor (
    uint256[] memory _id,
    uint256[] memory _amount,
    bytes memory _data,
    string[] memory _uri, 
    address _rwaMananger
    // note- sort out a good way to input the right ERC1155 uri into the instance below.
  ) ERC1155(" "){

    if (_id.length != _amount.length || _uri.length != _id.length) {
      revert OALibrary.RWAInvalidArrayLength(_id.length, _amount.length, _uri.length);
    }
    if (_id.length > MAX_MINTS) {
      revert OALibrary.RWAExceedMaxMint(_id.length, MAX_MINTS);
    }
      _rwaMananger = RWA_Manager; //
      
    for (uint i = 0; i < _id.length; ++i) {
      uint256 assetID = _id[i];
      string memory assetURI = _uri[i];
      if (TokenURI[assetID][assetURI] == true) revert OALibrary.RWAAssetAlreadyExists(assetID, assetURI);
      managerIDs[_rwaMananger] = assetID;

      _setURI(_id[i], _uri[i]);
    }
    batchMint(_rwaMananger, _id, _amount, _data);
    emit OALibrary.BatchMinted(_rwaMananger, _id, _amount);
   }
    function mint(
      address _to,
      uint256 _id,
      uint256 _amount, 
      bytes memory _data
    ) external { 
      // if address ()
      if (msg.sender != RWA_Manager) {
        revert OALibrary.InvalidManager(msg.sender, RWA_Manager);
      }
        _mint(_to, _id, _amount, _data);
        emit OALibrary.SingleMinted(_to, _id, _amount);
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
      TokenURI[_id][_uri] = true;
      super._setURI(_uri);
    }
    function setURI(
      uint _id, 
      string memory _uri
    ) external {
      if (msg.sender != RWA_Manager ) {
        revert OALibrary.InvalidManager(msg.sender, RWA_Manager);
      }
      _setURI(_id,_uri);
      emit OALibrary.TokenURISet(_id, _uri);
    }

    function burn(
      address _manager,
      uint256 _id,
      uint256 _amount
    ) external {
      if (msg.sender != RWA_Manager ) {
        revert OALibrary.InvalidManager(msg.sender, RWA_Manager);
      }
      _burn(_manager, _id, _amount);
      emit OALibrary.SingleBurned(_manager, _id, _amount);
    }
    
    function batchBurn(
      address _manager,
      uint256[] memory _id,
      uint256[] memory _amount,
      string[] memory _uri
    ) external {
      for (uint i = 0; i < MAX_MINTS; ++i) {
        bool isAssetType = TokenURI[_id[i]][_uri[i]];
        if (isAssetType != true) {
          revert OALibrary.RWAInvalidBurnAsset(_id[i], _uri[i]);
        }
      }
      if (msg.sender != RWA_Manager ) {
        revert OALibrary.InvalidManager(msg.sender, RWA_Manager);
      } 
      _burnBatch(_manager, _id, _amount);
      emit OALibrary.BatchBurned(_manager, _id, _amount);
    }

    function SetRWAManager(
      address _newManager
    ) external {
      address oldManager = RWA_Manager;
      if (msg.sender != RWA_Manager) {
        revert OALibrary.InvalidManager(msg.sender, RWA_Manager);
      }
      RWA_Manager = _newManager;
      emit OALibrary.RWAManagerUpdated(oldManager, _newManager);
    }
 }