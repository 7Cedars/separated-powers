// SPDX-License-Identifier: MIT

// note that natspecs are wip.

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

import { Law } from "../../../Law.sol";
import { SeparatedPowers } from "../../../SeparatedPowers.sol";
import { ERC1155 } from "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/utils/ShortStrings.sol";

// ONLY FOR TESTING
import { console } from "lib/forge-std/src/console.sol";

contract DirectSelect is Law {
    using ShortStrings for *;

    error DirectSelect__AccountDoesNotHaveRole();
    error DirectSelect__AccountAlreadyHasRole();

    uint32 private immutable ROLE_ID;

    constructor(
        string memory name_, 
        string memory description_, 
        address separatedPowers_, 
        uint32 roleId_
        ) Law(name_, description_, separatedPowers_) {
            ROLE_ID = roleId_;
            params = [dataType("bool")]; 
    }

    function executeLaw(address initiator, bytes memory lawCalldata, bytes32 descriptionHash)
        public
        override
        returns (address[] memory targets, uint256[] memory values, bytes[] memory calldatas)
    {
        // step 0: do necessary optional checks. 
        super.executeLaw(address(0), lawCalldata, descriptionHash);

        // step 1: decode the calldata.
        (bool revoke) = abi.decode(lawCalldata, (bool));

        // step 2: create & send return calldata conditional if it is an assign or revoke action.
        targets = new address[](1);
        values = new uint256[](1);
        calldatas = new bytes[](1);

        targets[0] = separatedPowers;
        if (revoke) {
            if (SeparatedPowers(payable(separatedPowers)).hasRoleSince(initiator, ROLE_ID) == 0) {
                revert DirectSelect__AccountDoesNotHaveRole();
            }
            calldatas[0] = abi.encodeWithSelector(SeparatedPowers.revokeRole.selector, ROLE_ID, initiator); // selector = revokeRole
        } else {
            if (SeparatedPowers(payable(separatedPowers)).hasRoleSince(initiator, ROLE_ID) != 0) {
                revert DirectSelect__AccountAlreadyHasRole();
            }
            calldatas[0] = abi.encodeWithSelector(SeparatedPowers.assignRole.selector, ROLE_ID, initiator); // selector = assignRole
        }
    }
}
