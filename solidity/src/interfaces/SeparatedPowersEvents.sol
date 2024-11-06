// SPDX-License-Identifier: MIT
/**
 * @notice Interface for the SeparatedPowers protocol.
 * Code derived from OpenZeppelin's Governor.sol contract and Haberdasher Labs Hats protocol.
 *
 * @author 7Cedars, Oct 2024, RnDAO CollabTech Hackathon
 */
pragma solidity 0.8.26;

interface SeparatedPowersEvents {
    /// @notice Emitted when...
    /// £todo param...
    /// etc.
    event FundsReceived(uint256 value);

    /// @notice Emitted when...
    /// £todo param...
    /// etc.
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

    /// @notice Emitted when...
    /// £todo param...
    /// etc.
    event ProposalCompleted(uint256 indexed proposalId);

    /// @notice Emitted when...
    /// £todo param...
    /// etc.
    event ProposalCancelled(uint256 indexed proposalId);

    /// @notice Emitted when...
    /// £todo param...
    /// etc.
    event VoteCast(address indexed account, uint256 indexed proposalId, uint8 indexed support, string reason);

    /// @notice Emitted when...
    /// £todo param...
    /// etc.
    event SeparatedPowers__Initialized(address contractAddress);

    /// @notice Emitted when a role is set.
    /// £todo param...
    /// etc.
    event RoleSet(uint48 indexed roleId, address indexed account, bool indexed accessChanged);

    /// @notice Emitted when...
    /// £todo param...
    /// etc.

    event LawSet(
        address indexed law, 
        uint32 indexed allowedRole, 
        bool indexed existingLaw,
        uint8 quorum, 
        uint8 succeedAt, 
        uint32 votingPeriod
        );

    /// @notice Emitted when...
    /// £todo param...
    /// etc.
    event LawRevoked(address indexed law); 
}
