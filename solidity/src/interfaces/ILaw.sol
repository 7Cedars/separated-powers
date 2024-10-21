// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

/**
 * @notice interface for law contracts.  
 *
 * @dev law contracts must implement this interface. 
 * 
 * They can only have one external function: executeLaw. 
 */
interface ILaw {
    
  /**
  * @param lawCallData call data to be executed. 
  */ 
  function executeLaw (
    address executioner,
    bytes memory lawCallData, 
    bytes32 descriptionHash
    ) external returns (
      address[] memory targets,
      uint256[] memory values,
      bytes[] memory calldatas
      ); 
}
