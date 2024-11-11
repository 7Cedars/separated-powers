// SPDX-License-Identifier: MIT

/// @notice Modifiers to create checks and balance to powers in DAOs that implement the SeparatedPowers protocol. 
/// @author 7Cedars, Oct-Nov 2024, RnDAO CollabTech Hackathon

pragma solidity 0.8.26;

library PowerModifiers {
  error PowerModifiers__ProposalVoteNotSucceeded(uint256 proposalId);
  error PowerModifiers__ProposalIdNotRecognised(uint256 proposalId);
  error PowerModifiers__DeadlineNotPassed(uint256 deadline);
  error PowerModifiers__NoZeroAddress();
  error PowerModifiers__RoleIdsNotDifferent();
  error PowerModifiers__ParentProposalVoteNotSucceeded(uint256 proposalId);
  error PowerModifiers__ParentProposalVoteNotCompleted(uint256 proposalId);

  /// @notice A modifier that sets a function to be conditioned by a proposal vote.
  /// This modifier ensures that the function is only callable if a proposal has passed a vote.
  modifier needsVote() { 
      uint256 proposalId = _hashProposal(proposer, address(this), lawCalldata, descriptionHash);
      if (SeparatedPowers(payable(separatedPowers)).state(proposalId) != SeparatedPowersTypes.ProposalState.Succeeded) {
          revert PowerModifiers__ProposalVoteNotSucceeded(proposalId);
      }

      _;
  }

  /// @notice A modifier that removes execute data from a law. 
  /// The law can only be used as initiator for a proposal as a result. 
  /// Execution needs to be implemented by another law. 
  /// It allows for a governance flow where 
  /// - roleId A only has the power to propose a law and 
  /// - roleId B only has the power to execute a proposed law. 
  modifier proposeOnly() { 

    _;

    address[] memory tar = new address[](0);
    uint256[] memory val = new uint256[](0);
    bytes[] memory cal = new bytes[](0);

    return (tar, val, cal);
  }

  /// @notice A modifier that makes the execution of a law conditional on a deadline having passed.
  /// @param blocks the number of blocks to wait before executing the law.
  /// 
  /// @dev the delay is calculated from the moment the vote related to the law is closed.
  /// Note that this means that {DelayDxecutions} only works in combination with the {Vote} modifier. 
  modifier delayExecution(uint256 blocks) {
      uint256 proposalId = _hashProposal(proposer, address(this), lawCalldata, descriptionHash);
      uint256 currentBlock = block.number;
      uint256 deadline = SeparatedPowers(payable(separatedPowers)).proposalDeadline(proposalId);
      
      if (deadline == 0) {
          revert PowerModifiers__ProposalIdNotRecognised(proposalId);
      }

      if (deadline < currentBlock) {
          revert PowerModifiers__DeadlineNotPassed(deadline);
      }

      _;
  }  

  /// @notice A modifier that limits the number of executions of a law,
  /// either by absolute numbers or by a time gap (measured in blocks) between executions. 
  /// @param maxExecution the maximum number of executions allowed.
  /// @param gapExecutions the minimum number of blocks between executions.
  modifier limitExecutions(uint256 maxExecution, uint256 gapExecutions) { 
    uint256 numberOfExecutions = executions.length; 
    
    if (numberOfExecutions >= maxExecution) {
        revert PowerModifiers__ExecutionLimitReached();
    }

    if (block.number - executions[numberOfExecutions - 1] < gapExecutions) {
        revert PowerModifiers__ExecutionGapTooSmall();
    }  
    
    _; 
  }

  /// @notice A modifier that conditions a law's execution on a proposal vote of a parent law having passed.
  /// @param parentLaw the address of the parent law.
  /// 
  /// @dev This modifier allows for a governance flow where 
  /// - roleId A has to have passed a proposal, before 
  /// - roleId B can execute the proposal.
  /// It creates a balance of power between roleId B and roleId A: they need to _both_ pass a proposal for an action to be executed.
  /// @dev It works well in combination with the {proposeOnly} modifier.
  modifier balancePower(address parentLaw) {
    if (parentLaw == address(0)) {
        revert PowerModifiers__NoZeroAddress();
    } 

    if (
      SeparatedPowers(payable(separatedPowers)).laws[parentLaw].allowedRole == 
      SeparatedPowers(payable(separatedPowers)).laws[address(this)].allowedRole
      ) { 
        revert PowerModifiers__RoleIdsNotDifferent();
      }
    
    uint256 proposalId = hashProposal(parentLaw, lawCalldata, descriptionHash);
    if (SeparatedPowers(payable(separatedPowers)).state(proposalId) != SeparatedPowersTypes.ProposalState.Succeeded) {
        revert PowerModifiers__ParentProposalVoteNotSucceeded(proposalId);
    }
    
    _;
  }

  /// @notice A modifier that conditions a law's execution on a proposal vote of a parent law having completed.
  /// @param parentLaw the address of the parent law.
  /// 
  /// @dev This modifier allows for a governance flow where 
  /// - roleId A executes a law. 
  /// - roleId B can challenge its execution after it has been executed. 
  /// It creates a situation where roleId B can check the power of roleId A. 
  modifier checkPower(address parentLaw) {
    if (parentLaw == address(0)) {
        revert PowerModifiers__NoZeroAddress();
    } 
    
    uint256 proposalId = hashProposal(parentLaw, lawCalldata, descriptionHash);
    if (SeparatedPowers(payable(separatedPowers)).state(proposalId) != SeparatedPowersTypes.ProposalState.Completed) {
        revert PowerModifiers__ParentProposalVoteNotCompleted(proposalId);
    }
    
    _;
  }

  /// @notice an internal helper function for hashing proposals. 
  function _hashProposal(address proposer, address proposer, address targetLaw, bytes memory lawCalldata, bytes32 descriptionHash)
      internal
      pure
      virtual
      returns (uint256)
  {
      return uint256(keccak256(abi.encode(proposer, targetLaw, lawCalldata, descriptionHash)));
  }
}