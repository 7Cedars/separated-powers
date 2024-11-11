// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

library PowerModifiers {

  error PowerModifiers__NoZeroAddress();
  error PowerModifiers__RoleIdsNotDifferent();
  error PowerModifiers__ParentProposalVoteNotSucceeded(uint256 proposalId);
  error PowerModifiers__ParentProposalVoteNotCompleted(uint256 proposalId);
  error PowerModifiers__ProposalVoteNotSucceeded(uint256 proposalId);
  error PowerModifiers__ProposalIdNotRecognised(uint256 proposalId);
  error PowerModifiers__DeadlineNotPassed(uint256 deadline);

  /// @notice A modifier that sets a function to be conditioned by a proposal vote.
  modifier Vote() { 
      uint256 proposalId = _hashProposal(address(this), lawCalldata, descriptionHash);
      if (SeparatedPowers(payable(separatedPowers)).state(proposalId) != SeparatedPowersTypes.ProposalState.Succeeded) {
          revert PowerModifiers__ProposalVoteNotSucceeded(proposalId);
      }

      _;

  }

  /// 
  modifier Delay(uint256 blocks) {
      uint256 proposalId = _hashProposal(address(this), lawCalldata, descriptionHash);
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

  /// 
  modifier Limit(uint256 maxExecution, uint256 gapExecutions) { 
    uint256 numberOfExecutions = executions.length; 
    
    if (numberOfExecutions >= maxExecution) {
        revert PowerModifiers__ExecutionLimitReached();
    }

    if (block.number - executions[numberOfExecutions - 1] < gapExecutions) {
        revert PowerModifiers__ExecutionGapTooSmall();
    }  
    
    _; 

  }

  modifier BalancePower(address parentLaw) {
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

  modifier CheckPower(address parentLaw) {
    if (parentLaw == address(0)) {
        revert PowerModifiers__NoZeroAddress();
    } 
    
    uint256 proposalId = hashProposal(parentLaw, lawCalldata, descriptionHash);
    if (SeparatedPowers(payable(separatedPowers)).state(proposalId) != SeparatedPowersTypes.ProposalState.Completed) {
        revert PowerModifiers__ParentProposalVoteNotCompleted(proposalId);
    }
    
    _;
  }

  modifier ProposeOnly() { 

    _;

    address[] memory tar = new address[](0);
    uint256[] memory val = new uint256[](0);
    bytes[] memory cal = new bytes[](0);

    return (tar, val, cal);
  }

}