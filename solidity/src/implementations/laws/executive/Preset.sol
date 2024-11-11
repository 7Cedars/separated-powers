// SPDX-License-Identifier: MIT

/// @notice A base contract that executes a preset action. 
/// 
/// The logic: 
/// - anythe lawCalldata includes a single bool. If the bool is set to true, it will aend the present calldatas to the execute function of the SeparatedPowers protocol.  
///
/// @author 7Cedars, Oct-Nov 2024, RnDAO CollabTech Hackathon

pragma solidity 0.8.26;

import { Law } from "../../../Law.sol";

contract Preset is Law {
    /// the targets, values and calldatas to be used in the calls: set at construction.
    address[] private _targets;
    uint256[] private _values;
    bytes[] private _calldatas; 

    /// emitted when the law is initialised.
    event Preset__Initialized(address[] targets, uint256[] values, bytes[] calldatas);
    
    /// @notice constructor of the law
    /// @param name_ the name of the law.
    /// @param description_ the description of the law.
    /// @param values_ the values to use in the calls.
    /// @param calldatas_ the calldatas to use in the calls.
    constructor(string memory name_, string memory description_, address[] memory targets_, uint256[] memory values_, bytes[] memory calldatas_) 
        Law(name_, description_)
    { 
        _targets = targets_;
        _values = values_;
        _calldatas = calldatas_; 

        emit Preset__Initialized(_targets, _values, _calldatas);
    }

    /// @notice execute the law.
    /// @param proposer the proposer of the law.
    /// @param lawCalldata the calldata of the law.
    /// @param descriptionHash the description hash of the law.
    function executeLaw(address proposer, bytes memory lawCalldata, bytes32 descriptionHash)
        external
        override
        returns (address[] memory targets, uint256[] memory values, bytes[] memory calldatas)
    {
        // decode the calldata.
        // note: no check on decoded call data. If needed, this can be added through a bespoke modifier.
        (bool execute) = abi.decode(lawCalldata, (bool));
        
        // log execution block 
        // and send calldata straight to the SeparatedPowers protocol. 
        if (execute) {
            executions.push(uint48(block.number)); 
            return (targets, values, calldatas);
        }
    }
}
