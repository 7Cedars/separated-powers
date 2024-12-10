// SPDX-License-Identifier: MIT

/// @notice Errors used in the SeparatedPowers protocol.
/// Code derived from OpenZeppelin's Governor.sol contract and Haberdasher Labs Hats protocol.
///
/// @author 7Cedars, Oct-Nov 2024, RnDAO CollabTech Hackathon

pragma solidity 0.8.26;

interface SeparatedPowersErrors {
    /// @notice Emitted when constitute is called more than once.
    error SeparatedPowers__ConstitutionAlreadyExecuted();

    /// @notice Emitted when a law is already active, when trying to set a new one.
    error SeparatedPowers__LawAlreadyActive();

    /// @notice Emitted when a law is not active.
    error SeparatedPowers__NotActiveLaw();

    /// @notice Emitted when a function is called from a contract that is not SeparatedPowers.
    error SeparatedPowers__OnlySeparatedPowers();

    /// @notice Emitted when a propose is called on a law that does not require a proposal vote. .
    error SeparatedPowers__NoVoteNeeded();

    /// @notice Emitted when a function is called by an account that lacks the correct roleId.
    error SeparatedPowers__AccessDenied();

    /// @notice Emmitted when a law does not need a proposal.
    error SeparatedPowers__LawDoesNotNeedProposalVote();

    // emitted when a role access is called, but role access is already set at requested access.
    error SeparatedPowers__RoleAccessNotChanged();

    /// @notice Emitted when a execution is attempted on a proposal that is not active.
    error SeparatedPowers__UnexpectedActionState();

    // @notice Emitted when a law does not pass checks.
    error SeparatedPowers__LawDidNotPassChecks();

    /// @notice Emitted when a proposal id is invalid.
    error SeparatedPowers__InvalidProposalId();

    /// @notice Emitted when a proposal is already completed.
    error SeparatedPowers__ProposalAlreadyCompleted();

    /// @notice Emitted when a proposal is has been cancelled.
    error SeparatedPowers__ProposalCancelled();

    /// @notice Emitted when cancelling a proposal that does not reference an active law.
    error SeparatedPowers__CancelCallNotFromActiveLaw();

    /// @notice Emitted when a proposal is not active.
    error SeparatedPowers__ProposalNotActive();

    /// @notice Emitted when a law is not active.
    error SeparatedPowers__LawNotActive();

    /// @notice Emitted when a callData is invalid.
    error SeparatedPowers__InvalidCallData();

    /// @notice Emitted when a law does not have the correct interface.
    error SeparatedPowers__IncorrectInterface();

    /// @notice Emitted when an account has already cast a vote for a proposal.
    error SeparatedPowers__AlreadyCastVote();

    /// @notice Emitted when a vote type is invalid.
    error SeparatedPowers__InvalidVoteType();
}
