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

/// @notice Natspecs WIP 
/// 
pragma solidity 0.8.26;

import { Law } from "../../Law.sol";
import { SeparatedPowers } from "../../SeparatedPowers.sol";
import { Addresses } from "../state/Addresses.sol";

abstract contract ThrottlePerAccount is Law {
    error ThrottlePerAccount__DelayNotPassed(); 

    uint48 public delay;
    mapping(address initiator => uint48 blockNumber) public lastTransaction;

    function _executeChecks(address initiator, bytes memory lawCalldata, bytes32 descriptionHash) internal override {
        if (uint48(block.number) - lastPayment[initiator] < delay) {
            revert ThrottlePerAccount__DelayNotPassed();
        }
        
        super._executeChecks(initiator, lawCalldata, descriptionHash);
    }

    function _changeStateVariables(bytes memory stateChange) internal override {
        lastTransaction[initiator] = block.number;

        super._changeStateVariables(stateChange);
    }
}
