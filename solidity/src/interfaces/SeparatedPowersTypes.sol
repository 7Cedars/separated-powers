// SPDX-License-Identifier: MIT
/**
 * @notice Interface for the SeparatedPowers protocol.
 * Code derived from OpenZeppelin's Governor.sol contract and Haberdasher Labs Hats protocol.
 *
 * @author 7Cedars, Oct 2024, RnDAO CollabTech Hackathon
 */
pragma solidity 0.8.26;

interface SeparatedPowersTypes {
    /// @dev struct for a proposal.
    ///
    /// note A proposal includes a reference to the law that it is aimed at.
    /// This enables the role restriction of governance processes in {SeparatedPowers}.
    struct Proposal {
        // slot 1. 
        address targetLaw; //   20
        uint48 voteStart; //   6
        uint32 voteDuration; // 4
        bool cancelled; //    1
        bool completed; //    1

        // slot 2
        uint32 againstVotes; // 4 as votes are not weighted, uint32 is sufficient to count number of votes.  -- this is a big gas saver. As such, combining the proposalCore and ProposalVote is (I think) okay
        uint32 forVotes; // 4
        uint32 abstainVotes; // 4 
        
        // slot 2 or 3 ? have to check this out. 
        mapping(address voter => bool) hasVoted; // ? 
    }

    /// @dev enum for the state of a proposal.
    ///
    /// note that a proposal cannot be set as 'executed' as in Governor.sol. It can only be set as 'completed'.
    /// Execution logic in {SeparatedPowers} is separated from the proposal logic.
    enum ProposalState {
        Active,
        Cancelled,
        Defeated,
        Succeeded,
        Completed
    }

    /// @dev Supported vote types. Matches Governor Bravo ordering.
    enum VoteType {
        Against,
        For,
        Abstain
    }

    /// @dev struct keeping track of settings for a law.
    struct LawConfig {
        // 1 memory slot 
        address lawAddress; // 20
        uint32 allowedRole; // 4
        uint8 quorum; // 1
        uint8 succeedAt; // 1
        uint32 votingPeriod; // 4 
        bool active; // 1
    }

    /// @dev struct keeping track of 1) account acceess to role and 2) total amount of members of role.
    struct Role {
        // Members of the role.
        mapping(address account => uint48 since) members;
        uint256 amountMembers;
    }

    /// this is a struct for just one function. Let's see if we can drop it. 
    /// @dev struct keeping track of 1) account acceess to role and 2) total amount of members of role.
    // struct ConstituentRole {
    //     // Members of the role.
    //     address account;
    //     uint48 roleId;
    // }
}
