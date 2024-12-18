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
    /// @param initiator the address of the initiator
    /// @param targetLaw the address of the target law
    /// @param signature the signature of the proposal
    /// @param ececuteCalldata the calldata to be passed to the law
    /// @param voteStart the start of the voting period
    /// @param voteEnd the end of the voting period
    /// @param description the description of the proposal
    event ProposalCreated(
        uint256 proposalId,
        address initiator,
        address targetLaw,
        string signature,
        bytes ececuteCalldata,
        uint256 voteStart,
        uint256 voteEnd,
        string description
    );

    /// @notice Emitted when executive action is completed.
    /// @param initiator the address of the initiator
    /// @param targetLaw the address of the target law
    /// @param lawCalldata the calldata of the law
    /// @param descriptionHash the description hash of the law
    event ProposalCompleted(address initiator, address targetLaw, bytes lawCalldata, bytes32 descriptionHash);

    /// @notice Emitted when a proposal for an executive action is cancelled.
    /// @param proposalId the id of the proposal
    event ProposalCancelled(uint256 indexed proposalId);

    // @notice Emitted when an executive action has been executed.
    /// @param targets the targets of the action
    /// @param values the values of the action
    /// @param calldatas the calldatas of the action
    event ProposalExecuted(address[] targets, uint256[] values, bytes[] calldatas);

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
    event LawAdopted(address indexed law);

    /// @notice Emitted when a law is revoked.
    /// @param law the address of the law
    event LawRevoked(address indexed law);
}
