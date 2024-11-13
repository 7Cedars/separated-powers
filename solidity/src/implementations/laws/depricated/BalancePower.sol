// SPDX-License-Identifier: MIT

/// Note natspecs are still WIP. 
///
/// @notice A modifier that conditions a law's execution on a proposal vote of a parent law having passed.
/// @param parentLaw the address of the parent law.
/// 
/// @dev This modifier allows for a governance flow where 
/// - roleId A has to have passed a proposal, before 
/// - roleId B can execute the proposal.
/// It creates a balance of power between roleId B and roleId A: they need to _both_ pass a proposal for an action to be executed.
/// @dev It works well in combination with the {proposeOnly} modifier.

pragma solidity 0.8.26;

import { Law } from "../../../Law.sol";
import { SeparatedPowers } from "../../../SeparatedPowers.sol";

contract BalancePower is Law {
  error BalancePower__NoZeroAddress();
  error BalancePower__LawNotRecognised();
  error BalancePower__RoleIdsNotDifferent();
  error BalancePower__ParentProposalVoteNotSucceeded(uint256 proposalId);
  error BalancePower__ProposalVoteNotSucceeded(uint256 proposalId);

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
        revert BalancePower__NoZeroAddress();
      } 
      _parentLaw = parentLaw_;
      }

  function executeLaw(address proposer, bytes memory lawCalldata, bytes32 descriptionHash) {
    // retrieve data on addresses and role restrictions. 
    (address lawAddressA, uint32 allowedRoleA, , , , ) = SeparatedPowers(payable(separatedPowers)).laws(_parentLaw); 
    (address lawAddressB, uint32 allowedRoleB, , , , ) = SeparatedPowers(payable(separatedPowers)).laws(address(this));
    // check 1: no zero addresses
    if (lawAddressA == address(0) || lawAddressB == address(0)) {
      revert BalancePower__LawNotRecognised();
    }
    // check 2: role retsrictions between two laws differ? 
    if (allowedRoleA == allowedRoleB) {
      revert BalancePower__RoleIdsNotDifferent();
    }
    
    // check 3: did parent law proposal pass? 
    uint256 proposalIdParent = _hashProposal(proposer, _parentLaw, lawCalldata, descriptionHash);
    if (SeparatedPowers(payable(separatedPowers)).state(proposalIdParent) != SeparatedPowersTypes.ProposalState.Succeeded) {
        revert BalancePower__ParentProposalVoteNotSucceeded(proposalIdParent);
    }

    // check 4: did this law proposal pass?
    uint256 proposalId = _hashProposal(proposer, address(this), lawCalldata, descriptionHash);
    if (SeparatedPowers(payable(separatedPowers)).state(proposalId) != SeparatedPowersTypes.ProposalState.Succeeded) {
        revert BalancePower__ProposalVoteNotSucceeded(proposalId);
    }

    // if all checks pass: run execute on the original executive law. 
    return (
      Law(_parentLaw).executeLaw(proposer, lawCalldata, descriptionHash)
    );
  }
}

