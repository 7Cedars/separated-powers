// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Law} from "../../Law.sol";
import {SeparatedPowers} from "../../SeparatedPowers.sol";
import {ISeparatedPowers} from "../../interfaces/ISeparatedPowers.sol";
import "@openzeppelin/contracts/utils/ShortStrings.sol";

/**
 * @notice Example Law contract. In this contract aany account that previously held a member role can challenge having this role revoked.  
 * 
 * @dev This contract is an example of 
 * - a law that refers to a previously executed proposal of another law. 
 * - that takes a pre-set description ("I challenge the revoking of my membership to agDAO.") which makes it impossible to challenge a revoke twice. 
 *   If the challenge is not accepted by seniors (see {Senior_reinstateMember}) is the end of the line for the account.
 * - that takes the calldata of the parent law as part of its input. This is needed to restrict calling this law to those accounts that have been revoked.  
 */
contract Public_challengeRevoke is Law {
    error Public_challengeRevoke__IncorrectRequiredStatement(); 
    error Public_challengeRevoke__ProposalNotSucceeded(uint256 proposalId); 
    error Public_challengeRevoke__ParentProposalNotCompleted(uint256 parentProposalId); 
    error Public_challengeRevoke__RevokedMemberNoExecutioner(); 

    string private requiredStatement = "I challenge the revoking of my membership to agDAO.";
    address public agDao;  
    
    constructor(address payable agDao_, address whale_revokeMember) // can take a address parentLaw param. 
      Law(
        "Public_assignRole", // = name
        "Any account that has been revoked can challenge this decision by sending a message and the data of the revoke decision to the agDAO.", // = description
        type(uint64).max, // = access PUBLIC_ROLE
        agDao_, // = SeparatedPower.sol derived contract. Core of protocol.   
        0, // = no quorum, means no vote. 
        0, // = succeedAt in percent
        0, // votingPeriod_ in blocks
        whale_revokeMember // = no parent Law
    ) {
      agDao = agDao_;
    } 

    function executeLaw(
      address executioner,
      bytes memory lawCalldata,
      bytes32 descriptionHash
      ) external override returns (
          address[] memory /*targets*/,
          uint256[] memory /*values*/,
          bytes[] memory /*calldatas*/
      ){  

      // step 0: check if caller is the SeparatedPowers protocol.
      if (msg.sender != daoCore) { 
        revert Law__AccessNotAuthorized(msg.sender);  
      }
  
      // step 1: decode the calldata.
      (bytes32 revokeDescriptionHash, bytes memory revokeCalldata) = abi.decode(lawCalldata, (bytes32, bytes));
      
      // step 2: check if required statement is correct.
      bytes32 requiredDescriptionHash = keccak256(bytes(requiredStatement)); 
      if (requiredDescriptionHash != descriptionHash) {
        revert Public_challengeRevoke__IncorrectRequiredStatement();
      }

      // step 3: check if the proposal has succeeded.
      // Note: even though this law does not need a vote, it DOES need a proposal that has (automatically) succeeded. 
      // This is because the propotocol needs the (succeeded) proposal to start the governance process that can reinstate this member. See {Senior_reinstateMember}.
      uint256 proposalId = hashProposal(address(this), lawCalldata, descriptionHash);
      if (SeparatedPowers(payable(agDao)).state(proposalId) != ISeparatedPowers.ProposalState.Succeeded) {
        revert Public_challengeRevoke__ProposalNotSucceeded(proposalId);
      }

      // step 4: check if the parent proposal has been executed.
      uint256 parentProposalId = hashProposal(parentLaw, revokeCalldata, revokeDescriptionHash);
      if (SeparatedPowers(payable(agDao)).state(parentProposalId) != ISeparatedPowers.ProposalState.Completed) {
        revert Public_challengeRevoke__ParentProposalNotCompleted(proposalId);
      }

      // step 5: check if the parent proposal referred to the correct revokedMember. 
      // Only the account has has been revoked is allowed to challenge the revocation of the account.
      (address revokedMember) = abi.decode(revokeCalldata, (address));
      if (revokedMember != executioner) {
        revert Public_challengeRevoke__RevokedMemberNoExecutioner();
      }

      // step 6: set the proposal to executed.
      SeparatedPowers(payable(agDao)).complete(lawCalldata, descriptionHash);

      // Note this 'executeLaw' function does not have return values. 
    }
}
