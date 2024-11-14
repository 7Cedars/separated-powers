// SPDX-License-Identifier: MIT
///
/// @notice Events used in the SeparatedPowers protocol.
/// Code derived from OpenZeppelin's Governor.sol contract and Haberdasher Labs Hats protocol.
///
/// @author 7Cedars, Oct-Nov 2024, RnDAO CollabTech Hackathon
pragma solidity 0.8.26;

interface SeparatedPowersEvents {
    /// @notice Emitted when protocol is initialized.
    /// @param contractAddress the address of the contract
    event SeparatedPowers__Initialized(address contractAddress);

    /// @notice Emitted when protocol receives funds/
    /// @param value the amount of funds received
    event FundsReceived(uint256 value);

    /// @notice Emitted when a proposal is created.
    /// @param proposalId the id of the proposal
    /// @param proposer the address of the proposer
    /// @param targetLaw the address of the target law
    /// @param signature the signature of the proposal
    /// @param ececuteCalldata the calldata to be passed to the law
    /// @param voteStart the start of the voting period
    /// @param voteEnd the end of the voting period
    /// @param description the description of the proposal
    event ProposalCreated(
        uint256 proposalId,
        address proposer,
        address targetLaw,
        string signature,
        bytes ececuteCalldata,
        uint256 voteStart,
        uint256 voteEnd,
        string description
    );

    /// @notice Emitted when proposal is completed.
    /// @param proposalId the id of the proposal
    event ProposalCompleted(uint256 indexed proposalId);

    /// @notice Emitted when proposal is cancelled.
    /// @param proposalId the id of the proposal
    event ProposalCancelled(uint256 indexed proposalId);

    /// @notice Emitted when a vote is cast.
    /// @param account the address of the account that cast the vote
    /// @param proposalId the id of the proposal
    /// @param support support of the vote: Against, For or Abstain.
    /// @param reason the reason for the vote
    event VoteCast(address indexed account, uint256 indexed proposalId, uint8 indexed support, string reason);

    /// @notice Emitted when a role is set.
    /// @param roleId the id of the role
    /// @param account the address of the account that has the role
    event RoleSet(uint48 indexed roleId, address indexed account);

    /// @notice Emitted when a law is set.
    /// @param law the address of the law
    /// @param allowedRole the role that has access to the law
    /// @param existingLaw whether the law is new or existing (if it is existing, its configuration is updated)
    /// @param quorum the quorum needed for a vote to succeed
    /// @param succeedAt the vote threshold: percentage of 'For' votes needed for a vote to succeed
    /// @param votingPeriod the period voting is open
    event LawSet(
        address indexed law,
        uint32 indexed allowedRole,
        bool indexed existingLaw,
        uint8 quorum,
        uint8 succeedAt,
        uint32 votingPeriod
    );

    /// @notice Emitted when a law is revoked.
    /// @param law the address of the law
    event LawRevoked(address indexed law);
}
