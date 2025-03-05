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

import {OwnableUpgradeable} from "../../lib/openzeppelin-contracts-upgradeable/contracts/access/OwnableUpgradeable.sol";
import {DALibrary} from "../Library/DALibrary.sol";
import {DARWAFunctionSrc} from "../FunctionSources/DARWAFunctionSrc.sol";
import {DACreateAbleAsset1155} from "../core/DACreateAbleAsset1155.sol";
import {PausableUpgradeable} from "../../lib/openzeppelin-contracts-upgradeable/contracts/utils/PausableUpgradeable.sol";
import {ReentrancyGuard} from "../../lib/openzeppelin-contracts/contracts/utils/ReentrancyGuard.sol";
import {Initializable} from "../../lib/openzeppelin-contracts-upgradeable/contracts/proxy/utils/Initializable.sol";
import {UUPSUpgradeable} from "../../lib/openzeppelin-contracts-upgradeable/contracts/proxy/utils/UUPSUpgradeable.sol";
import {IERC1155} from "../../lib/openzeppelin-contracts/contracts/token/ERC1155/IERC1155.sol";
import {IERC20} from "../../lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

abstract contract DAEngine is OwnableUpgradeable, PausableUpgradeable, UUPSUpgradeable {

    DACreateAbleAsset1155 public s_DAAsset1155;
    DARWAFunctionSrc public s_DARWAFunctionSrc;
    IERC20 public s_collateralToken;
    //DARWAFunctionSrc public DARWAFunctionSrc;
    constructor () {
        _disableInitializers();
    }

    // this should be used to kick start the engine contracts, what are the var you think it should have?
    //  AssetCreationParams struct, Asset struct, 
    function Initialize(
        address _DAAsset1155,
        address _FunctionSrc,
        address _collateralToken
    ) external onlyOwner {
        s_DAAsset1155 = DACreateAbleAsset1155(_DAAsset1155);
        s_DARWAFunctionSrc = DARWAFunctionSrc(_FunctionSrc);
        s_collateralToken = IERC20(_collateralToken);
        



    }

    // request unlock/buy
    // check collateral
        // if over 80% buy if not revert
    // buy token with ETH~ You pay eth you earn the token out
        // calls the function sorrce to buy asset
        

    // request lock/sell
        // sell asset from function source
        // // sell token for ETH
        // user take eth

    // 

    // add liquidity to dex earn reward 
    // the more your liquidity stays the more you earn~ staking 
        // add vesting as an option

    // remove liquidity from dex

    function _checkNoZeroAddress(address _address) internal pure {
        if (_address == address(0)) revert DALibrary.DARWA_ZeroAddress();
    }

    function _checkZeroAmount(uint256 _amount) internal pure {
        if (_amount == 0) revert DALibrary.DARWA_ZEROAmount();
    }

}

