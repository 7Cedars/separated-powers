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

    /* errors */
    error Law__AccessNotAuthorized(address caller);
    error Law__CallNotImplemented();
    error Law__InvalidLengths(uint256 lengthTargets, uint256 lengthCalldatas);
    error Law__TargetLawNotPassed(address targetLaw);
    error Law__InvalidProposalId(uint256 proposalId);
    error Law__ProposalAlreadyExecuted(uint256 proposalId);
    error Law__ProposalCancelled(uint256 proposalId);

    /**
     * @param lawCallData call data to be executed.
     */
    function executeLaw(address executioner, bytes memory lawCallData, bytes32 descriptionHash)
        external
        returns (address[] memory targets, uint256[] memory values, bytes[] memory calldatas);
    
    /**
     * @param lawCallData call data to be executed.
     */
    function checkLaw(address executioner, bytes memory lawCallData, bytes32 descriptionHash)
        external
        returns (bool passed);
}
