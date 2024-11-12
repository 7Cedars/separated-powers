// SPDX-License-Identifier: MIT

/// @notice A base contract that executes an action with one single input.
/// The example here deactivates an active law.
/// NOTE this is example is still work in progress.
///  
/// Note As the contract allows for any action to be executed, it severely limits the functionality of the SeparatedPowers protocol. 
/// - any role that has access to this law, can execute any function. It has full power of the DAO. 
/// - if this law is restricted by PUBLIC_ROLE, it means that anyone has access to it. Which means that anyone is given the right to do anything through the DAO. 
/// - The contract should always be used in combination with modifiers from {PowerModiifiers}. 
/// 
/// The logic: 
/// - any the lawCalldata includes targets[], values[], calldatas[] - that are send straight to the SeparatedPowers protocol. without any checks.  
/// 
/// @author 7Cedars, Oct-Nov 2024, RnDAO CollabTech Hackathon

pragma solidity 0.8.26;

import { Law } from "../../../Law.sol";

contract Bespoke is Law {
    /// @notice Constructor function for Open contract.
    /// @param name_ name of the law
    /// @param description_ description of the law    
    constructor(string memory name_, string memory description_)
        Law(name_, description_)
    { }

    /// @notice Execute the open action.
    /// @param proposer the address of the proposer
    /// @param lawCalldata the calldata of the law
    /// @param descriptionHash the description hash of the law
    function executeLaw(address proposer, bytes memory lawCalldata, bytes32 descriptionHash)
        external
        override
        returns (address[] memory targets, uint256[] memory values, bytes[] memory calldatas)
    {
        // £todo WIP 
        
        // decode the calldata.
        // note: no check on decoded call data. If needed, this can be added.
        (targetLaw) = abi.decode(lawCalldata, (address));

        // send calldata straight to the SeparatedPowers protocol.
        executions.push(uint48(block.number)); 
        return (targets, values, calldatas);
    }
}
