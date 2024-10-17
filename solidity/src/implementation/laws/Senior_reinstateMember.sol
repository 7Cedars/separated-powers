// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Law} from "../../Law.sol";
import {ISeparatedPowers} from "../../interfaces/ISeparatedPowers.sol";
import {SeparatedPowers} from "../../SeparatedPowers.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/ShortStrings.sol";

/**
 * @notice A law that allows Seniors to vote on a former members challenge to having their member role revoked. 
 * 
 * @dev The contract is an example of 
 * - a law that has access control and passes with a simple majority vote.
 * - a linked law, that takes the exact same description as the parent law. It means that the proposalId of the parent law is directly linked to the proposalId of this law.
 * - In other words, seniors can only vote once on a challenge.  
 */
contract Senior_reinstateMember is Law {
 error Senior_reinstateMember__AccessNotAuthorized(address caller);
 error Senior_reinstateMember__TargetProposalNotCompleted(uint256 proposalId); 
 error Senior_reinstateMember__ProposalNotSucceeded(uint256 proposalId); 

    address public agCoins; 
    address public agDao;
    uint256 agCoinsReward = 250_000; 
    
    constructor(address payable agDao_, address agCoins_, address Member_challengeRevoke) // can take a address parentLaw param. 
      Law(
        "Senior_reinstateMember", // = name
        "Senior can reinstate a member, following a challenge by the member having been revoked.", // = description
        1, // = access roleId = senior.  
        agDao_, // = SeparatedPower.sol derived contract. Core of protocol.   
        51, // = quorum in percent
        51, // = succeedAt in percent
        3_600, // votingPeriod_ in blocks, On arbitrum each block is about .5 (half) a second. This is about half an hour. 
        Member_challengeRevoke // = parent Law 
    ) {
      agDao = agDao_;
      agCoins = agCoins_;
    } 

    function executeLaw(
      bytes memory lawCalldata
      ) external override {  

      // step 0: check if caller has correct access control.
      if (SeparatedPowers(payable(agDao)).hasRoleSince(msg.sender, accessRole) == 0) {
        revert Senior_reinstateMember__AccessNotAuthorized(msg.sender);
      }

      // step 1: decode the calldata. Note: the callData does include the address of the revoked member account as additional check. 
      (bytes32 descriptionChallengeHash, , bytes memory revokeCalldata) =
            abi.decode(lawCalldata, (bytes32, bytes32, bytes));

      // step 2: check if the parentProposalId has been executed.
      uint256 parentProposalId = hashProposal(parentLaw, lawCalldata, descriptionChallengeHash); 
      ISeparatedPowers.ProposalState stateChallenge = SeparatedPowers(payable(agDao)).state(parentProposalId);
      if (stateChallenge != ISeparatedPowers.ProposalState.Completed ) {
        revert Senior_reinstateMember__TargetProposalNotCompleted(parentProposalId);
      }
    
      // step 3: calculate proposalId and check if the proposal to reinstate member has passed.    
      uint256 proposalId = hashProposal(address(this), lawCalldata, descriptionChallengeHash); 
      ISeparatedPowers.ProposalState proposalState = SeparatedPowers(payable(agDao)).state(proposalId);
      if (proposalState != ISeparatedPowers.ProposalState.Succeeded) {
        revert Senior_reinstateMember__ProposalNotSucceeded(proposalId);
      }

      // step 4: retrieve the address of the revoked member from the original calldata to revoke membership.
      // any checks on correctness of this address (should)have already been executed at parent laws. 
      (address revokedMember, ) = abi.decode(revokeCalldata, (address, bytes32));

      // step 5: complete the proposal. 
      SeparatedPowers(payable(agDao)).complete(lawCalldata, descriptionChallengeHash);

      // step 6: creating data to send to the execute function of agDAO's SepearatedPowers contract.
      address[] memory targets = new address[](3);
      uint256[] memory values = new uint256[](3); 
      bytes[] memory calldatas = new bytes[](3);

      // 6a: action 1: give reward to proposer of proposal. 
      targets[0] = agCoins;
      values[0] = 0;
      calldatas[0] = abi.encodeWithSelector(IERC20.transfer.selector, msg.sender, agCoinsReward);

      // 6b: action 2: re-assign account to member role.
      targets[1] = agDao;
      values[1] = 0;
      calldatas[1] = abi.encodeWithSelector(0xd2ab9970, 3, revokedMember, true); // = setRole(uint64 roleId, address account, bool access); 

      // 6c: action 3: remove account from blacklist.
      targets[2] = agDao;
      values[2] = 0;
      calldatas[2] = abi.encodeWithSelector(0xe594707e, revokedMember, false); // = blacklistAccount(address account, bool isBlacklisted);

      // step 7: call {SeparatedPowers.execute}
      // note, call goes in following format: (address proposer, address[] memory targets, uint256[] memory values, bytes[] memory calldatas)
      SeparatedPowers(daoCore).execute(msg.sender, targets, values, calldatas);
  }
}
