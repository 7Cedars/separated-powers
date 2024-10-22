// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Law} from "../../Law.sol";
import {SeparatedPowers} from "../../SeparatedPowers.sol";
import {ISeparatedPowers} from "../../interfaces/ISeparatedPowers.sol";

/**
 * @notice This law allows a senior to assign accounts to a senior role, as long as maximum number of senior roles has not been reached.
 * 
 * @dev The contract is an example of a law that  
 * - has access control and needs a proposal to be voted through. 
 * - has an additional conditional check. In this case the number of accounts that hold a senior role cannot exceed 10.
 *  
 */
contract Senior_assignRole is Law {
    error Senior_assignRole__AlreadySenior();
    error Senior_assignRole__TooManySeniors();
    error Senior_assignRole__ProposalVoteNotSucceeded(uint256 proposalId);

    address public agCoins; 
    address public agDao;
    uint256 agCoinsReward = 150_000;
    uint256 maxNumberOfSeniors = 10;
    
    constructor(address payable agDao_, address agCoins_) // can take a address parentLaw param. 
      Law(
        "Senior_assignRole", // = name
        "Seniors can assign accounts to available senior role. A maximum of ten holders can be assigned. If passed the proposer receives a reward in agCoins", // = description
        1, // = access senior
        agDao_, // = SeparatedPower.sol derived contract. Core of protocol.   
        50, // = quorum in percent 
        66, // = succeedAt in percent 
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

      // step 1: decode the calldata.
      (address newSenior) = abi.decode(lawCalldata, (address));

      // step 2: check if newSenior is already a member and if the maximum amount of seniors has already been met.  
      if (SeparatedPowers(payable(agDao)).hasRoleSince(newSenior, accessRole) != 0) {
        revert Senior_assignRole__AlreadySenior();
      }
      uint256 amountSeniors = SeparatedPowers(payable(agDao)).getAmountRoleHolders(1);
      if (amountSeniors >= maxNumberOfSeniors) {
        revert Senior_assignRole__TooManySeniors();
      }

      // step 3: check if vote for this proposal has succeeded. 
      uint256 proposalId = hashProposal(address(this), lawCalldata, descriptionHash);
      if (SeparatedPowers(payable(agDao)).state(proposalId) != ISeparatedPowers.ProposalState.Succeeded) {
        revert Senior_assignRole__ProposalVoteNotSucceeded(proposalId);
      }

      // step 4: set proposal to completed.
      SeparatedPowers(payable(agDao)).complete(lawCalldata, descriptionHash);

      // step 5: creating data to send to the execute function of agDAO's SepearatedPowers contract.
      address[] memory tar = new address[](1);
      uint256[] memory val = new uint256[](1);
      bytes[] memory cal = new bytes[](1);

      // action: add membership role to applicant. 
      tar[0] = agDao;
      val[0] = 0;
      cal[0] = abi.encodeWithSelector(0xd2ab9970, 1, newSenior, true); // = setRole(uint64 roleId, address account, bool access); 

      // step 6: return data
      return (tar, val, cal);
  }
}
