// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import { Law } from "../../../Law.sol";

/**
 * @notice This contract allows for the delayed execution of any action. 
 * - At construction time, a delay in blocks is set
 *
 * - As the contract allows for any action to be executed, it severely limits the functionality of the SeparatedPowers protocol. 
 *    - any role that has access to this law, can execute any function. It has full power of the DAO. 
 *    - if this law is restricted by PUBLIC_ROLE, it means that anyone has access to it. Which means that anyone is given the right to do anything through the DAO. 
 *    - Use this law with great caution.  
 *
 * - The logic: 
 *    - any the lawCalldata includes targets[], values[], calldatas[] - that are send straight to the SeparatedPowers protocol. without any checks.  
 *
 * @dev The contract is an example of the power of the SeparatedPowers protocol, by showing what happens if we disable it.  
 * - If anyone is given the right to do anything - there is no need for any governance. 
 * - It also means the DAO cannot function as it lacks any control over its funds. 
 */
contract DelayedExecution is Law {
    error DelayedExecution__DelayNotPassed();

    address[] private targets_; 
    uint256 private _delay;
    uint256 private _executeAtBlock; 
    bool private _delayInitialized;

    event SetDelay(uint256 indexed executeAtBlock);
    
    constructor(string memory name_, string memory description_, uint256 delay_)
        Law(name_, description_, targets_)
    { _delay = delay_; }

    function executeLaw(address executioner, bytes memory lawCalldata, bytes32 descriptionHash)
        external
        override
        returns (address[] memory targets, uint256[] memory values, bytes[] memory calldatas)
    {
        // decode the calldata.
        // note: no check on decoded call data. If needed, this can be added.
        (targets, values, calldatas) = abi.decode(lawCalldata, (address[] , uint256[], bytes[]));

        if (!_delayInitialized) {
          _delayInitialized = true;
          _executeAtBlock = block.number + _delay;
          
          emit SetDelay(_executeAtBlock);
        } else {
          if (block.number < _executeAtBlock) {
            revert DelayedExecution__DelayNotPassed();
          }
          // send calldata straight to the SeparatedPowers protocol. 
          return (targets, values, calldatas);
        }
    }
}
