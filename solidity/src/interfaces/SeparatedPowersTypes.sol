// SPDX-License-Identifier: MIT
/// 
/// @notice Types used in the SeparatedPowers protocol. Code derived from OpenZeppelin's Governor.sol contract. 
///
/// @author 7Cedars, Oct-Nov 2024, RnDAO CollabTech Hackathon
pragma solidity 0.8.26;

interface SeparatedPowersTypes {
    /// @notice struct to keep track of a proposal.
    ///
    /// @dev in contrast to other Governance protocols, a proposal in {SeparatedPowers} always includes a reference to a law.
    /// This enables the role restriction of governance processes in {SeparatedPowers}.
    /// 
    /// @dev in contrast to other Governance protocols, votes are not weighted and can hence be a uint32, not a uint256.
    /// @dev votes are logged at the proposal. In on struct. This is in contrast to other governance protocols where ProposalVote is a separate struct. 
    struct Proposal {
        // slot 1. 
        address targetLaw; // 20
        uint48 voteStart; // 6
        uint32 voteDuration; // 4
        bool cancelled; // 1
        bool completed; // 1

        // slot 2
        uint32 againstVotes; // 4 as votes are not weighted, uint32 is sufficient to count number of votes.  -- this is a big gas saver. As such, combining the proposalCore and ProposalVote is (I think) okay
        uint32 forVotes; // 4
        uint32 abstainVotes; // 4 
        
        // slot 2 or 3 ? £check: have to check this out. 
        mapping(address voter => bool) hasVoted; // 20 ?  
    }

    /// @notice enum for the state of a proposal.
    ///
    /// @dev that a proposal cannot be set as 'executed' as in Governor.sol. It can only be set as 'completed'.
    /// This is because execution logic in {SeparatedPowers} is separated from the proposal logic.
    enum ProposalState {
        Active,
        Cancelled,
        Defeated,
        Succeeded,
        Completed
    }

    /// @notice Supported vote types. Matches Governor Bravo ordering.
    enum VoteType {
        Against,
        For,
        Abstain
    }

    /// @notice struct to keep track of settings for a law.
    struct LawConfig {
        // 1 memory slot 
        address lawAddress; // address of the law
        uint32 allowedRole; // role restriction of law
        bool active; // Is the law active? Initiates as false. 
        // note: following 3 items are only used when law needs a proposal vote to be executed.
        uint8 quorum; // quorum needed for a vote to succeed. 
        uint8 succeedAt; // vote threshold: percentage of 'For' votes needed for a vote to succeed.
        uint32 votingPeriod; // period voting is open.
    }

    /// @notice struct keeping track of 
    /// - an account's access to roleId 
    /// - the total amount of members of role (this enables role based voting). 
    struct Role {
        mapping(address account => uint48 since) members;
        uint256 amountMembers;
    }
}
