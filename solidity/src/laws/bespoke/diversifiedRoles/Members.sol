// SPDX-License-Identifier: MIT

///////////////////////////////////////////////////////////////////////////////
/// This program is free software: you can redistribute it and/or modify    ///
/// it under the terms of the MIT Public License.                           ///
///                                                                         ///
/// This is a Proof Of Concept and is not intended for production use.      ///
/// Tests are incomplete and it contracts have not been audited.            ///
///                                                                         ///
/// It is distributed in the hope that it will be useful and insightful,    ///
/// but WITHOUT ANY WARRANTY; without even the implied warranty of          ///
/// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.                    ///
///////////////////////////////////////////////////////////////////////////////

// note that natspecs are wip.

pragma solidity 0.8.26;

// protocol
import { Law } from "../../Law.sol";
import { SeparatedPowers } from "../../SeparatedPowers.sol";

// mocks 
import { Erc721Mock } from "../../../test/mocks/Erc721Mock.sol";
import { Erc1155Mock } from "../../../test/mocks/Erc1155Mock.sol";

// laws 
import { PresetAction } from "../executive/PresetAction.sol";
import { BespokeAction } from "../executive/BespokeAction.sol";
import { SelfDestruct } from "../modules/SelfDestruct.sol";
import { ThrottlePerAccount } from "../modules/ThrottlePerAccount.sol";
import { NftCheck } from "../modules/NftCheck.sol";
import { SelfSelect } from "../electoral/SelfSelect.sol";

// open zeppelin contracts
import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { ERC1155 } from "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import { Create2 } from "@openzeppelin/contracts/utils/Create2.sol";

// possible to add more types later on. 
 
// NB: no checks on what kind of Erc20 token is used. This is just an example. 
contract Members is Law {
    error Members__MemberAlreadyExists(address account);
    error Members__MemberNonExistent(address account);

    // see for country codes IBAN: https://www.iban.com/country-codes
    struct Member {
        uint16 nationality;
        uint16 countryOfResidence;
        int64  dateOfBirth; // NB: can also go into minus for before 1970.  https://en.wikipedia.org/wiki/Unix_time#:~:text=A%20signed%2032%2Dbit%20value,Tuesday%202038%2D01%2D19.
    }
    mapping(address => Member) public members; 

    event Members__Added(address indexed account);
    event Members__Removed(address indexed account);

    constructor(
        string memory name_,
        string memory description_,
        address payable separatedPowers_,
        uint32 allowedRole_,
        LawConfig memory config_
    ) Law(name_, description_, separatedPowers_, allowedRole_, config_) {
        inputParams[0] = _dataType("address"); // account
        inputParams[1] = _dataType("uint16");  // nationality
        inputParams[2] = _dataType("uint16");  // country of residence 
        inputParams[3] = _dataType("int64"); // DoB
        inputParams[4] = _dataType("bool"); // add ? (if false: remove)  
      }
   
    /// @notice execute the law.
    /// @param lawCalldata the calldata _without function signature_ to send to the function.
    function simulateLaw(address, /*initiator*/ bytes memory lawCalldata, bytes32 descriptionHash)
        public
        view 
        virtual
        override
        returns (address[] memory targets, uint256[] memory values, bytes[] memory calldatas, bytes memory stateChange)
    {   
        // step 0: decode law calldata
        (address account, , , , bool add) = abi.decode(lawCalldata, (address, uint16, uint16, int64, bool));
        
        // step 1: run additional checks 
        if (add && members[account].nationality != 0) {
            revert Members__MemberAlreadyExists(account);            
        } 
        if (!add && members[account].nationality == 0) {
            revert Members__MemberNonExistent(account);
        } 

        // step 2: create arrays 
        targets = new address[](1);
        values = new uint256[](1);
        calldatas = new bytes[](1);
        stateChange = abi.encode("");

        // step 3: fill out arrays with data - no action should be taken by protocol. 
        targets[0] = address(1);
        stateChange = lawCalldata; 

        // step 4: return data 
        return (targets, values, calldatas, stateChange);
    }

    // add or remove member from state mapping in law. 
    function _changeStateVariables(bytes memory stateChange) internal override {
        (address account, uint16 nationality, uint16 countryOfResidence, int64 DoB, bool add) = abi.decode(stateChange, (address, uint16, uint16, int64, bool));

        if (add) {
            members[account] = Member(nationality, countryOfResidence, DoB); 
            emit Members__Added(account);            
        } else {
            members[account] = Member(0, 0, 0);
            emit Members__Removed(account);
        }
    }
}