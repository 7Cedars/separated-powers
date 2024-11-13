// SPDX-License-Identifier: MIT

/// Note natspecs are still WIP. 
///
/// @notice A modifier that sets a function to be conditioned by a proposal vote.
/// This modifier ensures that the function is only callable if a proposal has passed a vote.

pragma solidity 0.8.26;

import { Law } from "../../../Law.sol";
import { SeparatedPowers } from "../../../SeparatedPowers.sol";

contract NeedsVote is Law {
  error NeedsVote__NoZeroAddress();

  bool private immutable _execute;

  ShortString public immutable name; // name of the law
  address public separatedPowers; // the address of the core governance protocol
  string public description;
  uint48[] public executions; // log of bl

  constructor(address parentLaw_, bool execute_)
        Law(
          Law(parentLaw_).name(), 
          Law(parentLaw_).description(), 
          Law(parentLaw_).separatedPowers()          
          )
    {
      if (parentLaw_ == address(0)) {
        revert NeedsVote__NoZeroAddress();
      }
      _parentLaw = parentLaw_;
      _execute = execute_;
      }

  function executeLaw(address proposer, bytes memory lawCalldata, bytes32 descriptionHash) {
    // check if vote on this law has succeeded.
    uint256 proposalId = _hashProposal(proposer, address(this), lawCalldata, descriptionHash);
    if (SeparatedPowers(payable(separatedPowers)).state(proposalId) != SeparatedPowersTypes.ProposalState.Succeeded) {
        revert PowerModifiers__ProposalVoteNotSucceeded(proposalId);
    }

    // check if  conditions of the parent law have passed. 
    Law(parentLaw).executeLaw(proposer, lawCalldata, descriptionHash)

    // if all this passes. 
    // If no execute: return empty arrays. 
    if (!_execute) { 
      address[] tar = new address[](0);
      uint256[] val = new uint256[](0);
      bytes[] cal = new bytes[](0); 

      return (tar, val, cal);
    // if execute: return arrays of original law. 
    } else {
      // retrieve the original executive law. - and execute. 
      address executiveLaw = Law(_parentLaw).parentLaw();
      return (
        Law(executiveLaw).executeLaw(proposer, lawCalldata, descriptionHash)
      );
    }
  }
}

