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

/// @notice Natspecs are tbi. 
///
/// @author 7Cedars

/// @notice This contract that assigns or revokes a roleId to the person that called the law.
/// - At construction time, the following is set:
///    - the role Id that the contract will be assigned or revoked.
///
/// - The contract is meant to be restricted by a specific role, allowing an outsider to freely claim an (entry) role into a DAO.
///
/// - The logic:
///
/// @dev The contract is an example of a law that
/// - an open role elect law.

pragma solidity 0.8.26;

import { Law } from "../../Law.sol";
import { Powers} from "../../Powers.sol";

contract SelfSelect is Law { 
    uint32 private immutable ROLE_ID;

    constructor(
        string memory name_,
        string memory description_,
        address payable powers_,
        uint32 allowedRole_,
        LawConfig memory config_,
        uint32 roleId_
    ) Law(name_, description_, powers_, allowedRole_, config_) {
        ROLE_ID = roleId_;
        inputParams = abi.encode("bool Revoke");
    }

    function simulateLaw(address initiator, bytes memory lawCalldata, bytes32 descriptionHash)
        public
        view
        virtual
        override
        returns (address[] memory targets, uint256[] memory values, bytes[] memory calldatas, bytes memory stateChange)
    {
        // step 1: decode the calldata.
        (bool revoke) = abi.decode(lawCalldata, (bool));

        // step 2: create & send return calldata conditional if it is an assign or revoke action.
        targets = new address[](1);
        values = new uint256[](1);
        calldatas = new bytes[](1);

        targets[0] = powers;
        if (revoke) {
            if (Powers(payable(powers)).hasRoleSince(initiator, ROLE_ID) == 0) {
                revert ("Account does not have role.");
            }
            calldatas[0] = abi.encodeWithSelector(Powers.revokeRole.selector, ROLE_ID, initiator); // selector = revokeRole
        } else {
            if (Powers(payable(powers)).hasRoleSince(initiator, ROLE_ID) != 0) {
                revert ("Account already has role.");
            }
            calldatas[0] = abi.encodeWithSelector(Powers.assignRole.selector, ROLE_ID, initiator); // selector = assignRole
        }
    }
}
