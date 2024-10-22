// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Law} from "../../Law.sol";
import {SeparatedPowers} from "../../SeparatedPowers.sol";
import {ISeparatedPowers} from "../../interfaces/ISeparatedPowers.sol";

/**
 * @notice This law allows the admin of the governance protocol to set a new law, after it has been checked by seniors through {Senior_acceptProposedLaw}.
 * 
 * @dev This law 
 * - is only available to the admin of the governance protocol.
 * - does not need a proposal or vote. It can be executed directly by the admin. 
 *  
 * - the parent law must have been executed.
 * - as this contract does not need a proposal, it can be called multiple times on the same parentProposalId. 
 *   In this case this is fine. In cases where it needs to be avoided, consider forcing the creation of a proposal that can be completed without a vote. 
 *   See {Public_challengeRevoke} for an example of such a law. 
 */
 contract Admin_setLaw is Law {
    error Senior_acceptProposedLaw__ParentProposalNotCompleted(uint256 parentProposalId); 
    error Senior_acceptProposedLaw__ProposalNotCompleted(uint256 proposalId); 

    address public agDao;  
    
    constructor(address payable agDao_, address Senior_acceptProposedLaw) // can take a address parentLaw param. 
      Law(
        "Senior_acceptProposedLaw", // = name
        "Seniors can accept to activate or deactive laws as propised by whales.", // = description
        0, // = access roleId = ADMIN 
        agDao_, // = SeparatedPower.sol derived contract. Core of protocol.   
        0, // = quorum
        0, // = succeedAt in percent
        0, // votingPeriod_ in blocks 
        Senior_acceptProposedLaw // = parent Law 
    ) {
      agDao = agDao_;
    } 

    function executeLaw(
      address executioner, 
      bytes memory lawCalldata, 
      bytes32 descriptionHash
      ) external override returns (
          address[] memory targets,
          uint256[] memory values,
          bytes[] memory calldatas
      ) {  

      // step 0: check if caller is the SeparatedPowers protocol.
      if (msg.sender != daoCore) { 
        revert Law__AccessNotAuthorized(msg.sender);  
      }

      // step 1: decode the calldata. Note: calldata is identical to the calldata of the parent law and the grandParentLaw.
      (address law, bool toInclude) =
            abi.decode(lawCalldata, (address, bool));

      // step 2: check if parent proposal has been executed. 
      uint256 parentProposalId = hashProposal(parentLaw, lawCalldata, descriptionHash);
      if (SeparatedPowers(payable(agDao)).state(parentProposalId) != ISeparatedPowers.ProposalState.Completed) {
        revert Senior_acceptProposedLaw__ParentProposalNotCompleted(parentProposalId);
      }

      // step 3: Note : check if proposal succeeded is absent. This law does not require a proposal to be set or a vote to pass - it can be executed directly by the Admin. 
      
      // step 4: creating data to send to the execute function of agDAO's SepearatedPowers contract.
      address[] memory tar = new address[](1);
      uint256[] memory val = new uint256[](1);
      bytes[] memory cal = new bytes[](1);

      tar[0] = agDao; 
      val[0] = 0;
      cal[0] = abi.encodeWithSelector(0xd55a5cc6, law, toInclude); // = setLaw(address law, bool toInclude);

      // step 6: return data
      return (tar, val, cal);
  }
}
