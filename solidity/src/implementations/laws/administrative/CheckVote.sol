// SPDX-License-Identifier: MIT

/// Note natspecs are still WIP. 
///
/// @notice A modifier that sets a function to be conditioned by a proposal vote.
/// This modifier ensures that the function is only callable if a proposal has passed a vote.

pragma solidity 0.8.26;

import { Law } from "../../../Law.sol";
import { SeparatedPowers } from "../../../SeparatedPowers.sol";

contract CheckVote is Law {
  error CheckVote__NoZeroAddress();

  address private immutable _parentLaw;

  ShortString public immutable name; // name of the law
  address public separatedPowers; // the address of the core governance protocol
  string public description;
  uint48[] public executions; // log of bl

  constructor(address parentLaw_)
        Law(
          Law(parentLaw_).name(), 
          Law(parentLaw_).description(), 
          Law(parentLaw_).separatedPowers()
          )
    {
      if (parentLaw_ == address(0)) {
        revert CheckVote__NoZeroAddress();
      } 
      _parentLaw = parentLaw_;
      }

  function executeLaw(address proposer, bytes memory lawCalldata, bytes32 descriptionHash) {
    // check if vote has succeeded.
    uint256 proposalId = _hashProposal(proposer, address(this), lawCalldata, descriptionHash);
    if (SeparatedPowers(payable(separatedPowers)).state(proposalId) != SeparatedPowersTypes.ProposalState.Succeeded) {
        revert PowerModifiers__ProposalVoteNotSucceeded(proposalId);
    }
    
    // if check passed: run execute on the original executive law. 
    return (
      Law(_parentLaw).executeLaw(proposer, lawCalldata, descriptionHash)
    );
  }
}

