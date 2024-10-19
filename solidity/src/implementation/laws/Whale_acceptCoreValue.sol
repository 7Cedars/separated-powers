// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Law} from "../../Law.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ISeparatedPowers} from "../../interfaces/ISeparatedPowers.sol";
import {SeparatedPowers} from "../../SeparatedPowers.sol";
import "@openzeppelin/contracts/utils/ShortStrings.sol";

// ONLY FOR TESTING PURPOSES // DO NOT USE IN PRODUCTION
import {console2} from "lib/forge-std/src/Test.sol";

/**
 * @notice This law allows a whale role holder to accept a new requirement for accounts to be funded with agCoins.
 * 
 * @dev The contract is an exmaple of a law  
 * - that needs a prior proposal to have passed. In this case from the {Member_proposeCoreValue} contract.
 * - it also needs the proposal to have passed by whales.     
 * 
 * If the contract passes the proposer can execute the law: 
 * 1 - proposer will get a reward.
 * 2 - requirement will be included in the agDAO.  
 *  
 */
contract Whale_acceptCoreValue is Law {
    using ShortStrings for *;

    error Whale_acceptCoreValue__ParentLawNotSet(); 
    error Whale_acceptCoreValue__ParentProposalnotSucceededOrExecuted(uint256 parentProposalId);
    error Whale_acceptCoreValue__ProposalVoteNotSucceeded(uint256 proposalId); 

    address public agCoins; 
    address public agDao;
    uint256 agCoinsReward = 50_000; 
    
    constructor(address payable agDao_, address agCoins_, address member_proposeCoreValue) // can take a address parentLaw param. 
      Law(
        "Whale_acceptCoreValue", // = name
        "A whale role holder ar agDAO can accept a new requirement and add it to the core values of the DAO. The whale will receive an AgCoin reward in return.", // = description
        2, // = access roleId = whale.  
        agDao_, // = SeparatedPower.sol derived contract. Core of protocol.   
        30, // = quorum
        51, // = succeedAt in percent
        3_600, // votingPeriod_ in blocks, On arbitrum each block is about .5 (half) a second. This is about half an hour. 
        member_proposeCoreValue // = parent Law 
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

      // step 1: decode the calldata. Note: lawCalldata can have any format. 
      (ShortString requirement, bytes32 parentDescriptionHash, bytes32 descriptionHash) =
            abi.decode(lawCalldata, (ShortString, bytes32, bytes32));

      // Note step 2: check if the parentLaw has succeeded or has executed.
      // Note It doubles as a check on the calldata. 
      uint256 parentProposalId = hashProposal(parentLaw, abi.encode(requirement, parentDescriptionHash), parentDescriptionHash); 
      ISeparatedPowers.ProposalState parentState = SeparatedPowers(payable(agDao)).state(parentProposalId);

      if (parentState != ISeparatedPowers.ProposalState.Completed ) {
        revert Whale_acceptCoreValue__ParentProposalnotSucceededOrExecuted(parentProposalId);
      }
    
      // step 3: check if the proposal has passed. 
      uint256 proposalId = hashProposal(address(this), lawCalldata, descriptionHash);
      ISeparatedPowers.ProposalState proposalState = SeparatedPowers(payable(agDao)).state(proposalId);
      if ( proposalState != ISeparatedPowers.ProposalState.Succeeded) {
        revert Whale_acceptCoreValue__ProposalVoteNotSucceeded(proposalId);
      }

      // step 4: complete the proposal. 
      SeparatedPowers(payable(agDao)).complete(lawCalldata, descriptionHash);

      // step 5 : creating data to send to the execute function of agDAO's SepearatedPowers contract.
      // action 1: give reward to proposer of proposal. 
      targets[0] = agCoins;
      values[0] = 0;
      calldatas[0] = abi.encodeWithSelector(IERC20.transfer.selector, msg.sender, agCoinsReward);

      // action 2: add requirement to agDAO. 
      targets[1] = agDao;
      values[1] = 0;
      calldatas[1] = abi.encodeWithSelector(0x7be05842, requirement);

      // step 6: return data
      return (targets, values, calldatas);
  }
}
