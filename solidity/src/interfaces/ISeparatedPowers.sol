// SPDX-License-Identifier: MIT
/// @notice Interface for the SeparatedPowers protocol.
///Code derived from OpenZeppelin's Governor.sol contract.
///
/// @dev the interface also includes type declarations, but errors and events are placed in {SeparatedPowers}.
///
/// @author 7Cedars, Oct 2024, RnDAO CollabTech Hackathon

pragma solidity 0.8.26;

import { SeparatedPowersErrors } from "./SeparatedPowersErrors.sol";
import { SeparatedPowersEvents } from "./SeparatedPowersEvents.sol";
import { SeparatedPowersTypes } from "./SeparatedPowersTypes.sol";

interface ISeparatedPowers is SeparatedPowersErrors, SeparatedPowersEvents, SeparatedPowersTypes {
    //////////////////////////////////////////////////////////////
    //                  GOVERNANCE FUNCTIONS                    //
    //////////////////////////////////////////////////////////////
    /// @dev the external function to call when a new proposal is created.
    ///
    /// @param targetLaw : the address of the law to be executed. Can only be one address.
    /// @param lawCalldata : the calldata to be passed to the law
    /// @param description : the description of the proposal
    ///
    /// emits a {ProposalCreated} event.
    function propose(address targetLaw, bytes memory lawCalldata, string memory description)
        external
        returns (uint256);

    /// @dev external function to call when a proposal is executed.
    /// Note The function can only be called from a whitelisted Law contract.
    ///
    /// @param targetLaw : the address of the law to be executed. Can only be one address.
    /// @param lawCalldata : the calldata to be passed to the law
    /// @param descriptionHash : the descriptionHash of the proposal
    ///
    /// @dev note: the arrays of targets, values and calldatas must have the same length.
    function execute(address targetLaw, bytes memory lawCalldata, bytes32 descriptionHash) external payable;

    /// @dev external function to call to set a proposal to completed. It should be called when execution logic of a law is about to be executed.
    /// Note The function can only be called from a whitelisted Law contract.
    ///
    /// @param lawCalldata : the calldata that was passed to the law, and is part of the proposal.
    /// @param descriptionHash : the descriptionHash of the proposal
    function complete(bytes memory lawCalldata, bytes32 descriptionHash) external;

    /// @dev external function to call to cancel a proposal.
    /// Note The function can only be called by the account that proposed the proposal.
    ///
    /// @param targetLaw : the address of the law to be executed. Can only be one address.
    /// @param lawCalldata : the calldata to be passed to the law
    /// @param descriptionHash : the descriptionHash of the proposal
    function cancel(address targetLaw, bytes memory lawCalldata, bytes32 descriptionHash) external returns (uint256);

    /// @dev external function to call to cast a vote.
    ///
    /// @param proposalId : the id of the proposal
    /// @param support : the support of the vote
    ///
    /// @dev Note: the function will throw a revert if the value for the support param is not 0 (against), 1 (for) or 2 (abstain).
    function castVote(uint256 proposalId, uint8 support) external;

    /// @dev external function to call to cast a vote with a reason.
    ///Has the exact same functionality as {castVote}, except that it adds a reason to the vote.
    ///
    /// @param proposalId : the id of the proposal
    /// @param support : the support of the vote
    /// @param reason : the reason for the vote
    ///
    /// @dev Note: the function will throw a revert if the value for the support param is not 0 (against), 1 (for) or 2 (abstain).
    function castVoteWithReason(uint256 proposalId, uint8 support, string calldata reason) external;

    //////////////////////////////////////////////////////////////
    //                  ROLE AND LAW ADMIN                      //
    //////////////////////////////////////////////////////////////
    /// @dev  external function to batch activate laws and roles in a DAO. Can only be called once, and only by Admin.
    ///
    /// @param laws : the addresses of the laws to be activated.
    /// @param allowedRoles : the allowed roles of the laws.
    /// @param quorums : the quorums of the laws.
    /// @param succeedAts : the succeedAts of the laws.
    /// @param votingPeriods : the votingPeriods of the laws.
    /// @param constituentRoles : the constituent roles of the roles.
    /// @param constituentAccounts : the constituent accounts of the roles.
    ///
    /// emits a {ProposalCreated} event.
    function constitute(
        address[] memory laws,
        uint32[] memory allowedRoles,
        uint8[] memory quorums,
        uint8[] memory succeedAts, 
        uint32[] memory votingPeriods,
        // roles data 
        uint48[] memory constituentRoles, 
        address[] memory constituentAccounts
        ) external;

    /// @notice set a law to active or inactive.
    ///
    /// @dev
    /// @param law address of the law.
    /// @param allowedRole : the allowed role of the law.
    /// @param quorum : the quorum of the law.
    /// @param succeedAt : the succeedAt of the law.
    /// @param votingPeriod : the votingPeriod of the law.
    ///
    /// @dev this function can only be called from the execute function of SeperatedPowers.sol.
    function setLaw(address law, uint32 allowedRole, uint8 quorum, uint8 succeedAt, uint32 votingPeriod) external;

    /// @notice set a law to active or inactive.
    ///
    /// @dev
    /// @param law address of the law.
    ///
    /// @dev this function can only be called from the execute function of SeperatedPowers.sol.
    function revokeLaw(address law) external;

    /// @notice set role access.
    ///
    /// @param roleId role identifier
    /// @param account account address
    ///
    /// @dev this function can only be called from within {SeperatedPowers}.
    function assignRole(uint48 roleId, address account) external;

    /// @notice set role access.
    ///
    /// @param roleId role identifier
    /// @param account account address
    ///
    /// @dev this function can only be called from within {SeperatedPowers}.
    function revokeRole(uint48 roleId, address account) external;

    //////////////////////////////////////////////////////////////
    //                      VIEW FUNCTIONS                      //
    //////////////////////////////////////////////////////////////
    /// @dev returns the State of a proposal.
    ///
    /// @param proposalId : the id of the proposal
    ///
    /// @dev returns the State of a proposal
    function state(uint256 proposalId) external returns (ProposalState);

    /// @notice Checks if account has voted for a proposal.
    ///
    /// @dev Returns true if the role has been voted for a proposal.
    ///
    /// @param proposalId id of the proposal.
    /// @param account address of the account to check.
    function hasVoted(uint256 proposalId, address account) external returns (bool);

    /// @notice Returns the number of against, for, and abstain votes for a proposal.
    ///
    /// @param proposalId id of the proposal.
    function proposalVotes(uint256 proposalId)
        external
        returns (uint256 againstVotes, uint256 forVotes, uint256 abstainVotes);

    /// @dev Retreives the deadline of a proposal.
    ///
    /// @param proposalId : the id of the proposal
    ///
    /// @dev returns the deadline of a proposal.
    function proposalDeadline(uint256 proposalId) external returns (uint256);

    /// @notice returns the block number since the account has held the role. Returns 0 if account does not currently hold the role.
    ///
    /// @param account account address
    /// @param roleId role identifier
    function hasRoleSince(address account, uint48 roleId) external returns (uint48 since);

    /// @notice returns bool if law is set as active or not. (true = active, false = inactive).
    /// @param law address of the law.
    function getActiveLaw(address law) external returns (bool active);

    /// @dev checks if an account can call a law.
    ///
    /// @param caller caller address
    /// @param targetLaw law address to check.
    ///
    /// returns true if the caller can call the law.
    function canCallLaw(address caller, address targetLaw) external returns (bool);

    /// @dev returns the name of the protocol. This is the name of the Dao that inherits the {SeparatedPowers} contract.
    function name() external returns (string memory);

    /// @dev returns the version of the protocol.
    /// Set at 1 for the current version. Cannot be changed in inherited contracts.
    function version() external returns (string memory);

    //////////////////////////////////////////////////////////////
    //                      HELPER FUNCTIONS                    //
    //////////////////////////////////////////////////////////////
    /// @dev Helper function to create a ProposalId on the basis of targetLaw, lawCalldata and descriptionHash.
    ///
    /// @param targetLaw : the address of the law to be executed. Can only be one address.
    /// @param lawCalldata : the calldata to be passed to the law
    /// @param descriptionHash : the descriptionHash of the proposal
    ///
    /// Note the difference with the original at Governor.sol
    /// In SeparatedPowers proposals are always aimed at a single Laws, with a single slot of calldata.
    /// This callData can have any kind of data.
    ///
    /// The call that is executed at the Law has the traditional layout of targets[], values[], calldatas[].
    function hashProposal(address targetLaw, bytes memory lawCalldata, bytes32 descriptionHash)
        external
        returns (uint256);
}
