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

contract Direct is Law {
    error Direct__AccountAlreadyHasRole();
    error Direct__AccountDoesNotHaveRole();

    uint32 private immutable ROLE_ID;

    event Direct__AccountAssigned(uint32 indexed roleId, address indexed account);
    event Direct__AccountRevoked(uint32 indexed roleId, address indexed account);

    constructor(string memory name_, string memory description_, uint32 roleId_) Law(name_, description_) {
        ROLE_ID = roleId_;
    }

    function executeLaw(address executioner, bytes memory lawCalldata, bytes32 descriptionHash)
        external
        override
        returns (address[] memory targets, uint256[] memory values, bytes[] memory calldatas)
    {
        // step 1: decode the calldata.
        (bool revoke) = abi.decode(lawCalldata, (bool));

        // step 2: create & send return calldata conditional if it is an assign or revoke action.
        address[] memory tar = new address[](1);
        uint256[] memory val = new uint256[](1);
        bytes[] memory cal = new bytes[](1);

        // £ to do: I combined the laws into one. Simplifying flow. 
        if (revoke) {
            if (SeparatedPowers(payable(separatedPowers)).hasRoleSince(executioner, ROLE_ID) == 0) {
                revert Direct__AccountDoesNotHaveRole();
            }

            tar[0] = separatedPowers;
            val[0] = 0;
            cal[0] = abi.encodeWithSelector(0x22ec1861, ROLE_ID, executioner); // selector = revokeRole
            return (tar, val, cal);
        } else {
            if (SeparatedPowers(payable(separatedPowers)).hasRoleSince(executioner, ROLE_ID) != 0) {
                revert Direct__AccountAlreadyHasRole();
            }
            tar[0] = separatedPowers;
            val[0] = 0;
            cal[0] = abi.encodeWithSelector(0x446b340f, ROLE_ID, executioner); // selector = assignRole
            return (tar, val, cal);
        }
    }
}
