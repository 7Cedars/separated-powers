// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Law} from "../../Law.sol";
import {SeparatedPowers} from "../../SeparatedPowers.sol";
import {ISeparatedPowers} from "../../interfaces/ISeparatedPowers.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @notice This law allows seniors to accept a law as proposed by whales through {Whale_proposeLaw}. 
 * 
 * @dev This law 
 * - Needs to have the same description as the parent law. Its proposalId is directly linked to the proposalId of the parent law.
 * - In other words, each whale proposal can only be voted on by seniors once.
 *
 * - It is an example of a standard linked law providing a check to the power of whales. 
 *   Proposed laws cannot be proceed further in the governance process without a check by seniors, but seniors cannot propose laws themselves. 
 */
contract Senior_acceptProposedLaw is Law {
  error Senior_acceptProposedLaw__ParentProposalNotCompleted(uint256 parentProposalId); 
  error Senior_acceptProposedLaw__ProposalNotSucceeded(uint256 proposalId); 

    address public agCoins;
    address public agDao;  
    uint256 agCoinsReward = 12_000;  
    
    constructor(address payable agDao_, address agCoins_, address Whale_proposeLaw) // can take a address parentLaw param. 
      Law(
        "Senior_acceptProposedLaw", // = name
        "Seniors can accept to activate or deactive laws as propised by whales.", // = description
        1, // = access roleId = senior 
        agDao_, // = SeparatedPower.sol derived contract. Core of protocol.   
        30, // = quorum
        100, // = succeedAt in percent
        3_600, // votingPeriod_ in blocks, On arbitrum each block is about .5 (half) a second. This is about half an hour. 
        Whale_proposeLaw // = parent Law 
    ) {
      agDao = agDao_;
      agCoins = agCoins_;
    } 

    function executeLaw(
      bytes memory lawCalldata
      ) external override {  

      // step 0: check if caller has correct access control.
      if (SeparatedPowers(payable(agDao)).hasRoleSince(msg.sender, accessRole) == 0) {
        revert Law__AccessNotAuthorized(msg.sender);
      }

      // step 1: decode the calldata. Note: lawCalldata can have any format. 
      (, , bytes32 descriptionHash) =
            abi.decode(lawCalldata, (address, bool, bytes32));

      // step 2: check if parent proposal has been executed. 
      uint256 parentProposalId = hashProposal(parentLaw, lawCalldata, descriptionHash);
      if (SeparatedPowers(payable(agDao)).state(parentProposalId) != ISeparatedPowers.ProposalState.Completed) {
        revert Senior_acceptProposedLaw__ParentProposalNotCompleted(parentProposalId);
      }

      // step 3: check if vote for this proposal has succeeded. 
      uint256 proposalId = hashProposal(address(this), lawCalldata, descriptionHash);
      if (SeparatedPowers(payable(agDao)).state(proposalId) != ISeparatedPowers.ProposalState.Succeeded) {
        revert Senior_acceptProposedLaw__ProposalNotSucceeded(proposalId);
      }

      // step 4: complete the proposal. 
      SeparatedPowers(payable(agDao)).complete(lawCalldata, descriptionHash);

      // step 5: creating data to send to the execute function of agDAO's SepearatedPowers contract.
      address[] memory targets = new address[](1);
      uint256[] memory values = new uint256[](1); 
      bytes[] memory calldatas = new bytes[](1);

      targets[0] = agCoins;
      values[0] = 0;
      calldatas[0] = abi.encodeWithSelector(IERC20.transfer.selector, msg.sender, agCoinsReward);

      // step 6: call {SeparatedPowers.execute}
      // note, call goes in following format: (address proposer, address[] memory targets, uint256[] memory values, bytes[] memory calldatas)
      SeparatedPowers(daoCore).execute(msg.sender, targets, values, calldatas);
  }
}
