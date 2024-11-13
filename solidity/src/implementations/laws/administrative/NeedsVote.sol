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
    address[] tar = new address[](1);
    uint256[] val = new uint256[](1);
    bytes[] cal = new bytes[](1);
    tar[0] = address(this);

    // check if  conditions of the parent law have passed. If not, return message from parent law to protocol.
    (address[] tar2, uint256[] val2, bytes[] cal2) = Law(_parentLaw).executeLaw(proposer, lawCalldata, descriptionHash)
    if (tar2[0] == _parentLaw || tar2[0] == address(0)) {     
      cal[0] = abi.encode("parentlaw check failed".toShortString()); 
      return (tar, val, cal);
    }
    
    // check if vote on this law has succeeded.
    // if not, return message to protocol.
    uint256 proposalId = _hashProposal(proposer, address(this), lawCalldata, descriptionHash);
    if (SeparatedPowers(payable(separatedPowers)).state(proposalId) != SeparatedPowersTypes.ProposalState.Succeeded) {
      cal[0] = abi.encode("proposal not succeeded".toShortString()); 
      return (tar, val, cal);
    } 

    // if all this passes. 
    // If no execute: return message to protocol.
    if (!_execute) { 
      cal[0] = abi.encode("execute disabled".toShortString()); 
      return (tar, val, cal);
    } else {
      // retrieve the original executive law. - and execute. 
      address executiveLaw = Law(_parentLaw).parentLaw();
      (address[] tar, uint256[] val, bytes[] cal) = Law(executiveLaw).executeLaw(proposer, lawCalldata, descriptionHash); 
      return (tar, val, cal);
    }
  }
}

