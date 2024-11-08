// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import { Law } from "../../../Law.sol";
import { SeparatedPowers } from "../../../SeparatedPowers.sol";
import { SeparatedPowersTypes } from "../../../interfaces/SeparatedPowersTypes.sol";

/**
 * @notice This contract allows the execution of any action conditional to a vote. 
 * - At construction time, no data is set
 *
 * - As the contract allows for any action to be executed, it severely limits the functionality of the SeparatedPowers protocol. 
 *    - only the vote limits powers of role holders. But if quorum and vote threshold is set to 0, it will mean anyone can execute any function by proposing and passing a proposal.  
 *    - Use this law with great caution.  
 *
 * - The logic: 
 *    - the lawCalldata includes targets[], values[], calldatas[] 
 *    - if a vote regarding the given proposal passes,
 *    - any targets[], values[], calldatas[] included in the lawCalldata is send to the SeparatedPowers protocol.   
 *
 * @dev The contract is an example of the power the SeparatedPowers protocol can give to a specific group.
 * - If any group is given this much power, the governance protocol will become highly centralised. 
 */
contract VoteOnOpenExecution is Law { 
    error VoteOnOpenExecution__ProposalVoteNotSucceeded(uint256 proposalId);

    address[] private targets_; 
    
    constructor(string memory name_, string memory description_)
        Law(name_, description_, targets_)
    { }

    function executeLaw(address executioner, bytes memory lawCalldata, bytes32 descriptionHash)
        external
        override
        returns (address[] memory targets, uint256[] memory values, bytes[] memory calldatas)
    {
        // step 1: decode the calldata.
        // note: no check on decoded call data. If needed, this can be added.
        (targets, values, calldatas) = abi.decode(lawCalldata, (address[] , uint256[], bytes[]));

        // step 2: check if proposal passed vote.
        uint256 proposalId = _hashProposal(address(this), lawCalldata, descriptionHash);
        if (SeparatedPowers(payable(separatedPowers)).state(proposalId) != SeparatedPowersTypes.ProposalState.Succeeded) {
            revert VoteOnOpenExecution__ProposalVoteNotSucceeded(proposalId);
        }

        // step 3: if checks pass, send calldata straight to the SeparatedPowers protocol. 
        return (targets, values, calldatas);
    }
}
