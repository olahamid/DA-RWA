// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;
/**
 * @title AlpacaSource.sol
 * @author Ola Hamid
 * @notice THIS IS AN DEMO CONTRACT THAT ISN'T AUDITED.
 * DO NOT USE THIS CODE IN PRODUCTION. (UNIT AND INTEGRATION TEST- WIP).
 */

 import {ERC1155Supply, ERC1155} from "../../lib/openzeppelin-contracts/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
 import {Ownable} from "../../lib/openzeppelin-contracts/contracts/access/Ownable.sol";
 import {IDACreateAbleAsset1155} from "../interface/IDACreateAbleAsset1155.sol";
 import {DALibrary} from "../Library/DALibrary.sol";
//import {AccessControlUpgradeable} from "../../lib/openzeppelin-contracts-upgradeable/contracts/access/AccessControlUpgradeable.sol";

contract DACreateAbleAsset1155 is ERC1155Supply, IDACreateAbleAsset1155 {

    ///////////////////////
    /// State Variables ///
    ///////////////////////
  address private RWA_Manager;
   mapping (uint id => mapping (string uri => bool)) public TokenURI;
   mapping (address _manager=> uint _ids) managerIDs;
   uint8 public MAX_MINTS = 10;
   uint256 private constant MAX_Precision = 10_000;
   uint256 private immutable precision = 9_000;
   
    ///////////////////
    /// Constructor ///
    ///////////////////
  constructor (
    uint256[] memory _id,
    uint256[] memory _amount,
    bytes memory _data,
    string[] memory _uri, 
    address _rwaMananger, 
    address _engine
    // note- sort out a good way to input the right ERC1155 uri into the instance below.
  ) ERC1155(""){

    if (_id.length != _amount.length || _uri.length != _id.length) {
      revert DALibrary.RWAInvalidArrayLength(_id.length, _amount.length, _uri.length);
    }
    uint256 IDLength = _id.length;
    if ( IDLength > MAX_MINTS) {
      revert DALibrary.RWAExceedMaxMint(_id.length, MAX_MINTS);
    }
      _rwaMananger = RWA_Manager; //
      uint256[] memory engineAmt;
      uint256[] memory managerAmt;
    for (uint i = 0; i < IDLength; ++i) {
      uint256 assetID = _id[i];
      string memory assetURI = _uri[i];
      if (TokenURI[assetID][assetURI] == true) revert DALibrary.RWAAssetAlreadyExists(assetID, assetURI);
      managerIDs[_rwaMananger] = assetID;
      engineAmt[i] = (precision * _amount[i]) / MAX_Precision;
      managerAmt[i] = _amount[i] - engineAmt[i];
      _setURI(_id[i], _uri[i]);
    }
    // note send 20% of the total RWA asset to the RWA manager. 
    // send the rest to the engine contract
    batchMint(_engine, _id, engineAmt, _data);
    batchMint(_rwaMananger, _id, managerAmt, _data);
    emit DALibrary.BatchMinted(_rwaMananger, _id, _amount);
   }
    function mint(
      address _to,
      uint256 _id,
      uint256 _amount, 
      bytes memory _data
    ) external { 
      // if address ()
      // if (msg.sender != RWA_Manager) {
      //   revert DALibrary.InvalidManager(msg.sender, RWA_Manager);
      // }
        _mint(_to, _id, _amount, _data);
        emit DALibrary.SingleMinted(_to, _id, _amount);
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
        revert DALibrary.InvalidManager(msg.sender, RWA_Manager);
      }
      _setURI(_id,_uri);
      emit DALibrary.TokenURISet(_id, _uri);
    }

    function burn(
      address _manager,
      uint256 _id,
      uint256 _amount
    ) external {
      // if (msg.sender != RWA_Manager ) {
      //   revert DALibrary.InvalidManager(msg.sender, RWA_Manager);
      // }
      _burn(_manager, _id, _amount);
      emit DALibrary.SingleBurned(_manager, _id, _amount);
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
          revert DALibrary.RWAInvalidBurnAsset(_id[i], _uri[i]);
        }
      }
      if (msg.sender != RWA_Manager ) {
        revert DALibrary.InvalidManager(msg.sender, RWA_Manager);
      } 
      _burnBatch(_manager, _id, _amount);
      emit DALibrary.BatchBurned(_manager, _id, _amount);
    }

    function SetRWAManager(
      address _newManager
    ) external {
      address oldManager = RWA_Manager;
      if (msg.sender != RWA_Manager) {
        revert DALibrary.InvalidManager(msg.sender, RWA_Manager);
      }
      RWA_Manager = _newManager;
      emit DALibrary.RWAManagerUpdated(oldManager, _newManager);
    }
 }