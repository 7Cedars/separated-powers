// SPDX-License-Identifier: MIT
/**
 * @notice Interface for the SeparatedPowers protocol.
 * Code derived from OpenZeppelin's Governor.sol contract and Haberdasher Labs Hats protocol.
 *
 * @author 7Cedars, Oct 2024, RnDAO CollabTech Hackathon
 */
pragma solidity 0.8.26;

interface SeparatedPowersErrors {
    /// @notice £todo description.
    error SeparatedPowers__ConstitutionAlreadyExecuted();

    /// @notice £todo description.
    error SeparatedPowers__OnlySeparatedPowers();

    /// @notice £todo description.
    error SeparatedPowers__AccessDenied();

    /// @notice £todo description.
    error SeparatedPowers__UnexpectedProposalState();

    /// @notice £todo description.
    error SeparatedPowers__InvalidProposalId();

    /// @notice £todo description.
    error SeperatedPowers__NonExistentProposal(uint256 proposalId);

    /// @notice £todo description.
    error SeparatedPowers__ProposalAlreadyCompleted();

    /// @notice £todo description.
    error SeparatedPowers__ProposalCancelled();

    /// @notice £todo description.
    error SeparatedPowers__CancelCallNotFromActiveLaw(); 

    /// @notice £todo description.
    error SeparatedPowers__CompleteCallNotFromActiveLaw();

    /// @notice £todo description.
    error SeparatedPowers__OnlyProposer(address caller);

    /// @notice £todo description.
    error SeparatedPowers__ProposalNotActive();

    /// @notice £todo description.
    error SeparatedPowers__NoAccessToTargetLaw();

    /// @notice £todo description.
    error SeparatedPowers__InvalidCallData();

    /// @notice £todo description.
    error SeparatedPowers__NotAuthorized();

    /// @notice £todo description.
    error SeparatedPowers__IncorrectInterface(address law);

    /// @notice £todo description.
    error SeparatedPowers__AlreadyCastVote(address account);

    /// @notice £todo description.
    error SeparatedPowers__InvalidVoteType();
}
