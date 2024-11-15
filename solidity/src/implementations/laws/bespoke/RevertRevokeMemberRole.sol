// SPDX-License-Identifier: MIT

/// Note natspecs are still WIP.
///
/// @notice A modifier that sets a function to be conditioned by a proposal vote.
/// This modifier ensures that the function is only callable if a proposal has passed a vote.
pragma solidity 0.8.26;

import { Law } from "../../../Law.sol";
import { SeparatedPowers } from "../../../SeparatedPowers.sol";
import { RevokeRole } from "./RevokeRole.sol";
import "@openzeppelin/contracts/utils/ShortStrings.sol";

contract RevertRevokeMemberRole is Law {
    using ShortStrings for *;

    bool private immutable _execute;
    uint32 immutable MEMBER_ROLE = 3;

    constructor(address parentLaw_) // = ChallengeExecution
         Law(Law(parentLaw_).name().toString(), Law(parentLaw_).description(), Law(parentLaw_).separatedPowers())
    { }

    function executeLaw(address proposer, bytes memory lawCalldata, bytes32 descriptionHash)
        external
        override
        returns (address[] memory tar, uint256[] memory val, bytes[] memory cal)
    { 
        address originalRevokeLaw = Law(parentLaw).parentLaw();
        
        tar = new address[](2);
        val = new uint256[](2);
        cal = new bytes[](2);

        uint256 proposalId = _hashProposal(proposer, originalRevokeLaw, lawCalldata, descriptionHash);
        if (SeparatedPowers(payable(separatedPowers)).state(proposalId) != SeparatedPowersTypes.ProposalState.Completed)
        {
            cal[0] = abi.encode("parent proposal not completed".toShortString());
            return (tar, val, cal);
        }

        // retrieve the account that was revoked
        address revokedAccount = abi.decode(lawCalldata, address);

        // send data to reinstate account to the member role and deblacklist.. 
        tar[0] = separatedPowers;
        cal[0] = abi.encodeWithSignature(SeparatedPowers.setRole, MEMBER_ROLE, revokedAccount, true);

        tar[1] = separatedPowers;
        cal[1] = abi.encodeWithSignature(AlignedGrantsDao.setBlacklistAccount, revokedAccount, false);
        return (tar, val, cal);
    }
}
