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

////// NB ONLY FOR TESTING ////// 
import "lib/forge-std/src/Script.sol";
////// NB ONLY FOR TESTING //////

import { Law } from "../../Law.sol";
import { SeparatedPowers } from "../../SeparatedPowers.sol";

abstract contract ThrottlePerAccount is Law {
    error ThrottlePerAccount__DelayNotPassed();

    address private initiatorSaved;
    mapping(address initiator => uint48 blockNumber) public lastTransaction;

    function simulateLaw(
        address initiator, 
        bytes memory lawCalldata, 
        bytes32 descriptionHash
        ) public view override virtual returns (
            address[] memory targets, 
            uint256[] memory values, 
            bytes[] memory calldatas, 
            bytes memory stateChange
        ) {
            console.log("waypoint 1");
            if (uint48(block.number) - lastTransaction[initiator] < _delay()) {
                revert ThrottlePerAccount__DelayNotPassed();
            }

            console.log("waypoint 2");
            (targets, values, calldatas, stateChange) = super.simulateLaw(initiator, lawCalldata, descriptionHash);
            
            console.log("waypoint 3");
            bytes memory newStateChange = abi.encode(stateChange, initiator); // adding initiator to stateChange
            
            console.log("waypoint 4");
            return (targets, values, calldatas, newStateChange);
    }

    function _changeStateVariables(bytes memory stateChange) internal override {
        console.log("waypoint 5");
        console.logBytes(stateChange);
        (bytes memory oldStateChange, address initiator) =  abi.decode(stateChange, (bytes, address));
        console.log("waypoint 6");
        lastTransaction[initiator] = uint48(block.number);
        console.log("waypoint 7");
        super._changeStateVariables(oldStateChange); // continue with normal logic and stateChange
    }

    function _delay() internal view virtual returns (uint48) {
        return 0;
    }
}
