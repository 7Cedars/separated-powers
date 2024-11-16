// SPDX-License-Identifier: MIT

// note that natspecs are wip.

/// 
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

contract VoteSelect is Law {
    using ShortStrings for *;

    uint32 private immutable ROLE_ID;

    constructor(string memory name_, string memory description_, address separatedPowers_, uint32 roleId_)
        Law(name_, description_, separatedPowers_)
    {
        ROLE_ID = roleId_;
    }

    function executeLaw(bytes memory lawCalldata, bytes32 descriptionHash)
        external
        needsProposalVote(lawCalldata, descriptionHash)
        override
        returns (address[] memory targets, uint256[] memory values, bytes[] memory calldatas)
    {
        // step 1: decode the calldata.
        (bool revoke, address account) = abi.decode(lawCalldata, (bool, address));

        // step 2: create & send return calldata conditional if it is an assign or revoke action.
        address[] memory tar = new address[](1);
        uint256[] memory val = new uint256[](1);
        bytes[] memory cal = new bytes[](1);

        if (revoke) {
            if (SeparatedPowers(payable(separatedPowers)).hasRoleSince(account, ROLE_ID) == 0) {
                cal[0] = abi.encode("account does not have role".toShortString());
                return (tar, val, cal);
            }
            tar[0] = separatedPowers;
            val[0] = 0;
            cal[0] = abi.encodeWithSelector(SeparatedPowers.setRole.selector, ROLE_ID, account, false); // selector = revokeRole
            return (tar, val, cal);
        } else {
            if (SeparatedPowers(payable(separatedPowers)).hasRoleSince(account, ROLE_ID) != 0) {
                cal[0] = abi.encode("account already has role".toShortString());
                return (tar, val, cal);
            }
            tar[0] = separatedPowers;
            val[0] = 0;
            cal[0] = abi.encodeWithSelector(SeparatedPowers.setRole.selector, ROLE_ID, account, true); // selector = assignRole
            return (tar, val, cal);
        }
    }
}
