// SPDX-License-Identifier: MIT

/// @notice A modifier that conditions a law's execution on a proposal vote of a parent law having completed.
/// @param parentLaw the address of the parent law.
///
/// @dev This modifier allows for a governance flow where
/// - roleId A executes a law.
/// - roleId B can challenge its execution after it has been executed.
/// It creates a situation where roleId B can check the power of roleId A.

pragma solidity 0.8.26;

import { Law } from "../../../Law.sol";
import { SeparatedPowers } from "../../../SeparatedPowers.sol";
import { SeparatedPowersTypes } from "../../../interfaces/SeparatedPowersTypes.sol";
import "@openzeppelin/contracts/utils/ShortStrings.sol";

contract ChallengeExecution is Law {
    using ShortStrings for *;

    event ExecutionChallenged(uint256 proposalId);

    constructor(address parentLaw_)
        Law(Law(parentLaw_).name().toString(), Law(parentLaw_).description(), Law(parentLaw_).separatedPowers())
    {
        if (parentLaw_ == address(0)) {
            revert Law__NoZeroAddress();
        }
        parentLaw = parentLaw_;
    }

    function executeLaw(address proposer, bytes memory lawCalldata, bytes32 descriptionHash)
        public
        override
        returns (address[] memory tar, uint256[] memory val, bytes[] memory cal)
    {
        tar = new address[](1);
        val = new uint256[](1);
        cal = new bytes[](1);

        uint256 proposalId = _hashProposal(proposer, parentLaw, lawCalldata, descriptionHash);
        if (SeparatedPowers(payable(separatedPowers)).state(proposalId) != SeparatedPowersTypes.ProposalState.Completed)
        {
            cal[0] = abi.encode("parent proposal not completed".toShortString());
            return (tar, val, cal);
        }

        emit ExecutionChallenged(proposalId);

        // if parent proposal is completed, return data to protocol.
        tar[0] = parentLaw;
        val[0] = proposalId;
        cal[0] = abi.encodeWithSelector(0x5e4c0d6a, proposalId); // selector = challengeExecution
        return (tar, val, cal);
    }
}
