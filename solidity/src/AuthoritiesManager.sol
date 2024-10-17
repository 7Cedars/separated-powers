// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {IAuthoritiesManager} from "./interfaces/IAuthoritiesManager.sol"; 

/**
 * @notice Interface for managing roles and vote access. Derived from OpenZeppelin's GovernorCountingSimple.sol. 
 *
 * Note: Derived from GovernorCountingSimple. 
 *
 */
contract AuthoritiesManager is IAuthoritiesManager { 
    /* errors */
    error AuthoritiesManager__NotAuthorized(address invalidAddress);
    error AuthoritiesManager__AlreadyCastVote(address account);
    error AuthoritiesManager__InvalidVoteType(); 
    
    /* State variables */
    mapping(uint256 proposalId => ProposalVote) public _proposalVotes;
    mapping(uint64 roleId => Role) public roles;   
    
    uint64 public constant ADMIN_ROLE = type(uint64).min; // == 0
    uint64 public constant PUBLIC_ROLE = type(uint64).max; // == a lot 
    uint256 constant DENOMINATOR = 100;

    /* Events */
    /**
     * @dev Emitted when a role is set.
     */
    event RoleSet(uint64 indexed roleId, address indexed account, bool indexed accessChanged); 

    //////////////////////////////
    //          FUNCTIONS       //
    //////////////////////////////
    /* external */

    /* public */
    /**
    * @dev see {IAuthoritiesManager.setRole}
    */
    function setRole(uint64 roleId, address account, bool access) public virtual {
      // this function can only be called from within SeperatedPowers. 
      if (msg.sender != address(this)) { 
        revert AuthoritiesManager__NotAuthorized(msg.sender);  
      }
        _setRole(roleId, account, access);
    }

    /* internal */
    /**
     * @notice Internal version of {setRole} without access control. Returns true if the role was newly granted.
     *
     * Emits a {RoleGranted} event.
     */
    function _setRole(
        uint64 roleId,
        address account,
        bool access
    ) internal virtual {
        bool newMember = roles[roleId].members[account] == 0;
        bool accessChanged;  

        if (access && newMember) {
            roles[roleId].members[account] = uint48(block.number); // 'since' is set at current block.number  
            roles[roleId].amountMembers++; 
            accessChanged = true; 
        } else if (!access && !newMember)  {
          roles[roleId].members[account] = 0;
          roles[roleId].amountMembers--; 
          accessChanged = true;
        }

        emit RoleSet(roleId, account, accessChanged);
    }

    /**
     * @notice internal function {countVote} that counts against, for, and abstain votes for a given proposal.
     * 
     * @dev In this module, the support follows the `VoteType` enum (from Governor Bravo).
     * @dev It does not check if account has roleId referenced in proposalId. This has to be done by {SeparatedPowers.castVote} function.  
     */
    function _countVote(
        uint256 proposalId,
        address account,
        uint8 support
    ) internal virtual {
        ProposalVote storage proposalVote = _proposalVotes[proposalId];

        if (proposalVote.hasVoted[account]) {
            revert AuthoritiesManager__AlreadyCastVote(account);
        }
        proposalVote.hasVoted[account] = true;

        if (support == uint8(VoteType.Against)) {
            proposalVote.againstVotes++;
        } else if (support == uint8(VoteType.For)) {
            proposalVote.forVotes++;
        } else if (support == uint8(VoteType.Abstain)) {
            proposalVote.abstainVotes++;
        } else {
            revert AuthoritiesManager__InvalidVoteType();
        }
    }

    /* external & public view & pure functions */
    /**
     * @dev see {IAuthoritiesManager.hasVoted}
     */
    function hasVoted(uint256 proposalId, address account) public view virtual returns (bool) {
        return _proposalVotes[proposalId].hasVoted[account];
    }

    /**
     * @dev see {IAuthoritiesManager.proposalVotes}
     */
    function proposalVotes(
        uint256 proposalId
    ) public view virtual returns (uint256 againstVotes, uint256 forVotes, uint256 abstainVotes) {
        ProposalVote storage proposalVote = _proposalVotes[proposalId];
        return (proposalVote.againstVotes, proposalVote.forVotes, proposalVote.abstainVotes);
    }

    /**
     * @dev see {IAuthoritiesManager.hasRoleSince}
     */
    function hasRoleSince(address account, uint64 roleId) public view returns (uint48 since) {
      return roles[roleId].members[account]; 
    }

    function getAmountRoleHolders(uint64 roleId) public view returns (uint256 amountMembers) {
      return roles[roleId].amountMembers; 
    }

} 

// Notes to self:
// Structure contract //
/* version */
/* imports */
/* errors */
/* interfaces, libraries, contracts */
/* Type declarations */
/* State variables */
/* Events */
/* Modifiers */

/* FUNCTIONS: */
/* constructor */
/* receive function (if exists) */
/* fallback function (if exists) */
/* external */
/* public */
/* internal */
/* private */
/* internal & private view & pure functions */
/* external & public view & pure functions */
