// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import { Law } from "../../../Law.sol";

/**
 * @notice This contract allows the execution of a present action. 
 * - At construction time, it sets:
 * - address[] memory targets
 * - uint256[] memory values 
 * - bytes[] memory calldatas
 *
 * - The contract allows for a specific action to be executed directly, and be role restricted, but without a vote. 
 *    - if this law is restricted by PUBLIC_ROLE, it means that anyone has access to it. Which means that anyone is given the right to do execute the given action through the DAO.
 *
 * - The logic: 
 *    - anythe lawCalldata includes a single bool. If the bool is set to true, it will aend the present calldatas to the execute function of the SeparatedPowers protocol.  
 *
 * @dev The contract is a key example of giving specific executive powers to a particular role.
 */
contract PresetExecution is Law {
    address[] private _targets; 
    uint256[] private _values;
    bytes[] private _calldatas;

    event PresetExecution__Initialized(address[] targets, uint256[] values, bytes[] calldatas);
    
    constructor(string memory name_, string memory description_, address[] memory targets_, uint256[] memory values_, bytes[] memory calldatas_) 
        Law(name_, description_, targets_)
    { 
        _targets = targets_;
        _values = values_;
        _calldatas = calldatas_; 

        emit PresetExecution__Initialized(_targets, _values, _calldatas);
    }

    function executeLaw(address executioner, bytes memory lawCalldata, bytes32 descriptionHash)
        external
        override
        returns (address[] memory targets, uint256[] memory values, bytes[] memory calldatas)
    {
        // decode the calldata.
        // note: no check on decoded call data. If needed, this can be added.
        (bool execute) = abi.decode(lawCalldata, (bool));

        // send calldata straight to the SeparatedPowers protocol. 
        if (execute) {
          return (targets, values, calldatas);
        }
    }
}
