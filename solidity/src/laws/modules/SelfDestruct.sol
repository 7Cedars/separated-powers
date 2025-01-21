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

abstract contract SelfDestruct is Law {
    /// @notice execute the law.
    /// @param lawCalldata the calldata _without function signature_ to send to the function.
    function simulateLaw(address, initiator bytes memory lawCalldata, bytes32 descriptionHash)
        public
        view
        virtual
        override
        returns (address[] memory targets, uint256[] memory values, bytes[] memory calldatas, bytes memory stateChange)
    {
      (address[] memory targets, uint256[] memory values, bytes[] memory calldatas, bytes memory stateChange) = super.simulateLaw(initiator, lawCalldata, descriptionHash);

      // creating new arrays 
      targetsNew = new address[](targets.length + 1);
      valuesNew = new uint256[](values.length + 1);
      calldatasNew = new bytes[](calldatas.length + 1);
      
      // pasting in old arrays -- don't know if this works. We'll see through tests. 
      targetsNew = targets;
      valuesNew = values;
      calldatasNew = calldatas;

      // adding self destruct data to array
      targetsNew[targets.length] = separatedPowers;
      valuesNew[values.length] = 0;
      calldatasNew[calldatas.length] = abi.encodeWithSelector(SeparatedPowers.revokeLaw.selector, address(this));

      // return new arrays
      return (targetsNew, valuesNew, calldatasNew, stateChange);
    }

}
