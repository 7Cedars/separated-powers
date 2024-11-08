// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import { Law } from "../../../Law.sol";
import { SeparatedPowers } from "../../../SeparatedPowers.sol";
import { SeparatedPowersTypes } from "../../../interfaces/SeparatedPowersTypes.sol";

/**
 * @notice This contract allows the execution of a present action, conditional on a vote passing. 
 * - At construction time, it sets:
 * - address[] memory targets
 * - uint256[] memory values 
 * - bytes[] memory calldatas
 *
 * - The contract allows for a specific action to be executed after a vote among role holders has passed.
 *
 * - The logic: 
 *    - the lawCalldata includes a single bool. 
 *    - if a vote regarding the given proposal passes,
 *    - and if the bool is set to true, 
 *    - it will send the present calldatas to the execute function of the SeparatedPowers protocol.  
 *
 * @dev The contract is a key example of giving specific executive powers to a particular role conditional to a vote.
 */
contract VoteOnPresetExecution is Law {
    error VoteOnPresetExecution__ProposalVoteNotSucceeded(uint256 proposalId);
    
    address[] private _targets; 
    uint256[] private _values;
    bytes[] private _calldatas;

    event VoteOnPresetExecution__Initialized(address[] targets, uint256[] values, bytes[] calldatas);
    
    constructor(string memory name_, string memory description_, address[] memory targets_, uint256[] memory values_, bytes[] memory calldatas_)
        Law(name_, description_, targets_)
    { 
        _targets = targets_;
        _values = values_;
        _calldatas = calldatas_; 

        emit VoteOnPresetExecution__Initialized(_targets, _values, _calldatas);
    }

    function executeLaw(address executioner, bytes memory lawCalldata, bytes32 descriptionHash)
        external
        override
        returns (address[] memory targets, uint256[] memory values, bytes[] memory calldatas)
    {
        // step1: decode the calldata.
        (bool execute) = abi.decode(lawCalldata, (bool));

        // step 2: check if proposal passed vote.
        uint256 proposalId = _hashProposal(address(this), lawCalldata, descriptionHash);
        if (SeparatedPowers(payable(separatedPowers)).state(proposalId) != SeparatedPowersTypes.ProposalState.Succeeded) {
            revert VoteOnPresetExecution__ProposalVoteNotSucceeded(proposalId);
        }

        // step3: if checks pass, send calldata to the SeparatedPowers protocol. 
        if (execute) {
          return (targets, values, calldatas);
        }
    }
}
