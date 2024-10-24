// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Law} from "../../Law.sol";
import {SeparatedPowers} from "../../SeparatedPowers.sol";
import {ISeparatedPowers} from "../../interfaces/ISeparatedPowers.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @notice This law allows a senior to revoke a senior role. This can be their own or another senior. 
 * 
 * @dev The contract is an example of a law 
 * - that has access control and needs a proposal to be voted through.
 * - that has an additional conditional check. In this case the account needs to have be a senior role holder.  
 *  
 */
contract Senior_revokeRole is Law {
    error Senior_revokeRole__NotASenior();
    error Senior_revokeRole__ProposalVoteNotSucceeded(uint256 proposalId);

    address public agCoins; 
    address public agDao;
    uint256 agCoinsReward = 60_000;
    
    constructor(address payable agDao_, address agCoins_) // can take a address parentLaw param. 
      Law(
        "Senior_revokeRole", // = name
        "Senior role can be revoked by large majority vote. If passed the proposer receives a reward in agCoins", // = description
        1, // = access senior
        agDao_, // = SeparatedPower.sol derived contract. Core of protocol.   
        80, // = quorum in percent
        80, // = succeedAt in percent
        75,// votingPeriod_ in blocks,  Note: these are L1 ethereum blocks! 
        address(0) // = parent Law 
    ) {
      agDao = agDao_;
      agCoins = agCoins_; 
    } 

    function executeLaw(
      address executioner,
      bytes memory lawCalldata,
      bytes32 descriptionHash
      ) external override returns (
          address[] memory targets,
          uint256[] memory values,
          bytes[] memory calldatas
      ){    

      // step 0: check if caller is the SeparatedPowers protocol.
      if (msg.sender != daoCore) { 
        revert Law__AccessNotAuthorized(msg.sender);  
      }

      // step 1: decode the calldata. Note: lawCalldata can have any format. 
      (address seniorToRevoke) = abi.decode(lawCalldata, (address));

      // step 2: check if newSenior is already a member and if the maximum amount of seniors has already been met.  
      if (SeparatedPowers(payable(agDao)).hasRoleSince(seniorToRevoke, accessRole) == 0) {
        revert Senior_revokeRole__NotASenior();
      }

      // step 3: check if proposal passed vote.
      uint256 proposalId = hashProposal(address(this), lawCalldata, descriptionHash);
      if (SeparatedPowers(payable(agDao)).state(proposalId) != ISeparatedPowers.ProposalState.Succeeded) {
        revert Senior_revokeRole__ProposalVoteNotSucceeded(proposalId);
      }

      // step 4: complete the proposal. 
      SeparatedPowers(payable(agDao)).complete(lawCalldata, descriptionHash);

      // step 5: creating data to send to the execute function of agDAO's SepearatedPowers contract.
      address[] memory tar = new address[](2);
      uint256[] memory val = new uint256[](2);
      bytes[] memory cal = new bytes[](2);

      // action 1: add membership role to applicant. 
      tar[0] = agDao;
      val[0] = 0;
      cal[0] = abi.encodeWithSelector(0xd2ab9970, 1, seniorToRevoke, false); // = setRole(uint64 roleId, address account, bool access); 
      
      // action 2: give proposer reward. 
      tar[1] = agCoins;
      val[1] = 0;
      cal[1] = abi.encodeWithSelector(IERC20.transfer.selector, msg.sender, agCoinsReward);
      
      // step 6: return data
      return (tar, val, cal);
    }
}
