// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Law} from "../../Law.sol";
import {SeparatedPowers} from "../../SeparatedPowers.sol";
import {AgDao} from "../AgDao.sol";

/**
 * @notice A law that allows anyone to apply and get a Member role in the Dao. 
 * 
 * @dev The law is an example of 
 * - a law that has no access control
 * - a law that can be directly executed, without creating a proposal or having a vote. 
 * - adding an additional check to a law: in this case if the account has been blacklisted. See {Whale_RevokeRole} for how this can happen. 
 *  
 * @dev When executed, it simply assigns the member role to the account. 
 */
contract Public_assignRole is Law {
    error Public_assignRole__IncorrectRequiredStatement(); 
    error Public_assignRole__AccountBlacklisted(); 

    string private requiredStatement = "I request membership to agDAO.";
    address public agDao;  
    
    constructor(address payable agDao_) // can take a address parentLaw param. 
      Law(
        "Public_assignRole", // = name
        "Any account can become member of the agDAO by sending keccak256(bytes('I request membership to agDAO.') to the agDAO. Blacklisted accounts cannot become members.", // = description
        type(uint64).max, // = access PUBLIC_ROLE
        agDao_, // = SeparatedPower.sol derived contract. Core of protocol.   
        0, // = no quorum, means no vote. 
        0, // = succeedAt in percent
        0, // votingPeriod_ in blocks  Note: these are L1 ethereum blocks! 
        address(0) // = parent Law 
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
      ){  

      // step 0: check if caller is the SeparatedPowers protocol.
      if (msg.sender != daoCore) { 
        revert Law__AccessNotAuthorized(msg.sender);  
      }

      // step 1: decode the calldata. 
      bytes32 requiredDescriptionHash = keccak256(bytes(requiredStatement)); 
      if (requiredDescriptionHash != descriptionHash) {
        revert Public_assignRole__IncorrectRequiredStatement();
      }

      // check if account is blacklisted. 
      if (AgDao(payable(agDao)).blacklistedAccounts(executioner) == true) {
        revert Public_assignRole__AccountBlacklisted();
      }

      // NB: note, no check if a proposal has succeeded. This law can be called directly. 

      // step 3 : creating data to send to the execute function of agDAO's SepearatedPowers contract.
      address[] memory tar = new address[](1);
      uint256[] memory val = new uint256[](1);
      bytes[] memory cal = new bytes[](1);

      // action: add membership role to applicant. 
      tar[0] = agDao;
      val[0] = 0;
      cal[0] = abi.encodeWithSelector(0xd2ab9970, 3, executioner, true); // = setRole(uint64 roleId, address account, bool access); 

      // step 4: return data
      return (tar, val, cal);
  }
}
