// SPDX-License-Identifier: MIT

/// Note natspecs are still WIP.
///
/// @notice A modifier that sets a function to be conditioned by a proposal vote.
/// This modifier ensures that the function is only callable if a proposal has passed a vote.
pragma solidity 0.8.26;

import { Law } from "../../../Law.sol";
import { SeparatedPowers } from "../../../SeparatedPowers.sol";
import { SeparatedPowersTypes } from "../../../interfaces/SeparatedPowersTypes.sol";
import { AlignedGrants } from "../../../implementations/daos/aligned-grants/AlignedGrants.sol";
import { RevokeRole } from "./RevokeRole.sol";
import "@openzeppelin/contracts/utils/ShortStrings.sol";

contract ReinstateMember is Law {
    using ShortStrings for *;

    bool private immutable _execute;
    uint32 immutable MEMBER_ROLE = 3;

    constructor(
        string memory name_, 
        string memory description_, 
        address separatedPowers_,
        address parentLaw_
        ) Law(name_, description_, separatedPowers_) { 
            parentLaw = parentLaw_;
    }

    function executeLaw(bytes memory lawCalldata, bytes32 descriptionHash)
        external
        needsParentCompleted(lawCalldata, descriptionHash)
        needsProposalVote(lawCalldata, descriptionHash)
        override
        returns (address[] memory tar, uint256[] memory val, bytes[] memory cal)
    { 
        address originalRevokeLaw = Law(parentLaw).parentLaw();
        
        tar = new address[](2);
        val = new uint256[](2);
        cal = new bytes[](2);

        uint256 proposalId = _hashExecutiveAction(originalRevokeLaw, lawCalldata, descriptionHash);
        if (SeparatedPowers(payable(separatedPowers)).state(proposalId) != SeparatedPowersTypes.ActionState.Completed)
        {
            cal[0] = abi.encode("parent proposal not completed".toShortString());
            return (tar, val, cal);
        }

        // retrieve the account that was revoked
        address revokedAccount = abi.decode(lawCalldata, (address));

        // send data to reinstate account to the member role and deblacklist.. 
        tar[0] = separatedPowers;
        cal[0] = abi.encodeWithSignature("setRole(uint32,address,bool)", MEMBER_ROLE, revokedAccount, true);

        tar[1] = separatedPowers;
        cal[1] = abi.encodeWithSignature("setBlacklistAccount(address,bool)", revokedAccount, false);
        return (tar, val, cal);
    }
}
