// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Law} from "../../Law.sol";
import {SeparatedPowers} from "../../SeparatedPowers.sol";
import {ISeparatedPowers} from "../../interfaces/ISeparatedPowers.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/ShortStrings.sol";

/**
 * @notice Any Member can propose a new 'Core value' to agDao. These core values act as requirement for the type of accounts that are allowed to be funded with agCoins. 
 * 
 * @dev The contract is an example of 
 * - a law that has access control and passes with a small quorum (20%) but high yes vote (70%).
 * - a law that is the start of a proposal chain: members can only propose new requirements. The proposal needs to be check and implemented by Whales through {Whales_acceptCoreValue}.  
 * - Having said this, the contract DOES execute a call: it gives agCoins to the member that executes the proposal. 
 */
contract Member_proposeCoreValue is Law {
    error Member_proposeCoreValue__ProposalVoteNotSucceeded(uint256 proposalId);
    
    string private _name = "Member_proposeCoreValue"; 
    address public agCoins;
    address public agDao;  
    uint256 agCoinsReward = 100_000;  

    event Member_coreValueProposed(
      uint256 proposalId,
      ShortString indexed coreValue
    );
    
    constructor(address payable agDao_, address agCoins_) // can take a address parentLaw param. 
      Law(
        "Member_proposeCoreValue", // = name
        "A member of agDAO can propose new values to be added to the core values of the DAO.", // = description
        3, // = access roleId 
        agDao_, // = SeparatedPower.sol derived contract. Core of protocol.   
        20, // = quorum
        70, // = succeedAt in percent
        3_600, // votingPeriod_ in blocks, On arbitrum each block is about .5 (half) a second. This is about half an hour. 
        address(0) // = parent Law 
    ) {
      agDao = agDao_;
      agCoins = agCoins_;
    } 

    function executeLaw(
      bytes memory lawCalldata
      ) external override returns (
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas
      ){  

      // step 0: check if caller has correct access control.
      if (SeparatedPowers(payable(agDao)).hasRoleSince(msg.sender, accessRole) == 0) {
        revert Law__AccessNotAuthorized(msg.sender);
      }

      // step 1: decode the calldata. 
      (ShortString coreValue, bytes32 descriptionHash) =
            abi.decode(lawCalldata, (ShortString, bytes32));

      // step 2: check if proposal passed vote.
      uint256 proposalId = hashProposal(address(this), lawCalldata, descriptionHash);
      if (SeparatedPowers(payable(agDao)).state(proposalId) != ISeparatedPowers.ProposalState.Succeeded) {
        revert Member_proposeCoreValue__ProposalVoteNotSucceeded(proposalId);
      }

      // step 3: set Proposal to completed
      SeparatedPowers(payable(agDao)).complete(lawCalldata, descriptionHash);
      // step3a: emit an additional event stating the proposed value. 
      emit Member_coreValueProposed(proposalId, coreValue); 

      // step 4 : creating data to send to the execute function of agDAO's SepearatedPowers contract.
      targets[0] = agCoins;
      values[0] = 0;
      calldatas[0] = abi.encodeWithSelector(IERC20.transfer.selector, msg.sender, agCoinsReward);

      // step 5: return data
      return (targets, values, calldatas);
  }
}
