// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

/**
 * @notice Interface for the SeparatedPowers protocol. 
 * Code derived from OpenZeppelin's Governor.sol contract. 
 *
 * @dev the interface also includes type declarations, but errors and events are placed in {SeparatedPowers}.
 * 
 * @author 7Cedars, Oct 2024, RnDAO CollabTech Hackathon
 */
interface ISeparatedPowers { 
    
    /* Type declarations */
    /**
     * @dev enum for the state of a proposal.
     * 
     * note that a proposal cannot be set as 'executed' as in Governor.sol. It can only be set as 'completed'. 
     * Execution logic in {SeparatedPowers} is separated from the proposal logic.  
     */
    enum ProposalState {
        Active,
        Cancelled,
        Defeated,
        Succeeded,
        Completed
    }
    
    /**
     * @dev struct for a proposal.
     * 
     * note A proposal includes a reference to the law that it is aimed at. 
     * This enables the role restriction of governance processes in {SeparatedPowers}.
     */
    struct ProposalCore {
        address proposer;
        address targetLaw; 
        uint48 voteStart;
        uint32 voteDuration;
        bool cancelled;
        bool completed;
    }

    /* external function */ 
    /**
     * @dev the external function to call when a new proposal is created.
     *
     * @param targetLaw : the address of the law to be executed. Can only be one address. 
     * @param lawCalldata : the calldata to be passed to the law
     * @param description : the description of the proposal
     *
     * emits a {ProposalCreated} event.
     */
    function propose(
        address targetLaw,
        bytes memory lawCalldata,
        string memory description
        ) external returns (uint256);

    /**
     * @dev external function to call when a proposal is executed. 
     * Note The function can only be called from a whitelisted Law contract. 
     *
     * @param executioner : the address of the executioner: the address that called the law contract. 
     * @param targets : the targets of the execution. Can be multiple addresses. 
     * @param values : the values of the execution.
     * @param calldatas : the calldatas of the execution.
     *  
     * @dev note: the arrays of targets, values and calldatas must have the same length. 
     */
    function execute(
        address executioner, 
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas
        ) external payable; 

    /**
     * @dev external function to call to set a proposal to completed. It should be called when execution logic of a law is about to be executed.  
     * Note The function can only be called from a whitelisted Law contract.
     * 
     * @param lawCalldata : the calldata that was passed to the law, and is part of the proposal. 
     * @param descriptionHash : the descriptionHash of the proposal
     */
    function complete(
        bytes memory lawCalldata, 
        bytes32 descriptionHash
        ) external; 

    /**
     * @dev external function to call to cancel a proposal. 
     * Note The function can only be called by the account that proposed the proposal. 
     * 
     * @param targetLaw : the address of the law to be executed. Can only be one address. 
     * @param lawCalldata : the calldata to be passed to the law
     * @param descriptionHash : the descriptionHash of the proposal
     */
    function cancel(
        address targetLaw, 
        bytes memory lawCalldata,
        bytes32 descriptionHash
        ) external returns (uint256); 

    /**
     * @dev external function to call to cast a vote.
     *
     * @param proposalId : the id of the proposal
     * @param support : the support of the vote
     *
     * @dev Note: the function will throw a revert if the value for the support param is not 0 (against), 1 (for) or 2 (abstain).
     */
    function castVote(
        uint256 proposalId, 
        uint8 support
        ) external; 

    /**
     * @dev external function to call to cast a vote with a reason.
     * Has the exact same functionality as {castVote}, except that it adds a reason to the vote.
     *
     * @param proposalId : the id of the proposal
     * @param support : the support of the vote
     * @param reason : the reason for the vote
     *
     * @dev Note: the function will throw a revert if the value for the support param is not 0 (against), 1 (for) or 2 (abstain).
     */
    function castVoteWithReason(
        uint256 proposalId,
        uint8 support,
        string calldata reason
        ) external;

    /* public */ 
    /**
     * @dev returns the State of a proposal. 
     * 
     * @param proposalId : the id of the proposal
     *
     * @dev returns the State of a proposal
     */
    function state(uint256 proposalId) external returns (ProposalState);

    /* public pure & view functions */  
    /**
     * @dev returns the name of the protocol. This is the name of the Dao that inherits the {SeparatedPowers} contract. 
     */
    function name() external returns (string memory);

    /**
     * @dev returns the version of the protocol. 
     * Set at 1 for the current version. Cannot be changed in inherited contracts.
     */
    function version() external returns (string memory);

    /**
    * @dev checks if an account can call a law.
    *
    * @param caller caller address
    * @param targetLaw law address to check.
    *
    * returns true if the caller can call the law.
    */
    function canCallLaw(address caller, address targetLaw) external returns (bool); 

    /**
     * @dev Helper function to create a ProposalId on the basis of targetLaw, lawCalldata and descriptionHash. 
     *   
     * @param targetLaw : the address of the law to be executed. Can only be one address.
     * @param lawCalldata : the calldata to be passed to the law
     * @param descriptionHash : the descriptionHash of the proposal
     *
     * Note the difference with the original at Governor.sol
     * In SeparatedPowers proposals are always aimed at a single Laws, with a single slot of calldata. 
     * This callData can have any kind of data. 
     * 
     * The call that is executed at the Law has the traditional layout of targets[], values[], calldatas[].  
     */
    function hashProposal(
        address targetLaw, 
        bytes memory lawCalldata,
        bytes32 descriptionHash
    ) external returns (uint256);

    /**
     * @dev Retreives the deadline of a proposal. 
     * 
     * @param proposalId : the id of the proposal 
     * 
     * @dev returns the deadline of a proposal. 
     */
    function proposalDeadline(uint256 proposalId) external returns (uint256);

}