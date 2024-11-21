// SPDX-License-Identifier: MIT

/// @title Law.sol v.0.2
/// @notice Base implementation of a Law in the SeparatedPowers protocol. Meant to be inherited by law implementations.
///
/// @dev Laws are role restricted contracts that are executed by the core SeparatedPowers protocol. The provide the following functionality:
/// 1 - Role restricting DAO actions
/// 2 - Transforming a {lawCalldata) input into an output of targets[], values[], calldatas[] to be executed by the core protocol.
/// 3 - Adding conditions to execution of the law, such as a proposal vote, a completed parent law or a delay. Any logic can be added.  
/// 
/// A number of law settings are set through the {setLaw} function in the core protocol:
/// - what role restriction applies to the law. 
/// - quorum needed to execute the law. (optional)
/// - vote threshold. (optional)
/// - voting period. (optional)
///
/// {Law.sol} provides five modifiers that law implementations can use.
/// - {needsProposalVote}: requires a proposal vote to be successful before the law can be executed.
/// - {needsParentCompleted}: requires a parent law to be completed before the law can be executed. It can be used to create a balance of power between two roles. 
/// - {parentCanBlock}: requires a parent law to not be completed before the law can be executed. It can be used to give a role an effective veto to a governance process.
/// - {delayProposalExecution}: requires a delay to pass before the law can be executed. Can be used to create cool off periods.  
/// - {limitExecutions}: allows a law to only execute a number of times or requires a delay between executions.
/// If needed, more modifiers can be added. 
///
/// Note This protocol is a work in progress. A number of features are planned to be added to this contract in the future.
/// - Add an enum for data types. 
/// - Add an array with data types at each contract, so that front ends know what data types are requested by the law. 
///
/// @author 7Cedars, Oct-Nov 2024, RnDAO CollabTech Hackathon
pragma solidity 0.8.26;

import { SeparatedPowers } from "./SeparatedPowers.sol";
import { SeparatedPowersTypes } from "./interfaces/SeparatedPowersTypes.sol";
import { ILaw } from "./interfaces/ILaw.sol";
import { ERC165 } from "lib/openzeppelin-contracts/contracts/utils/introspection/ERC165.sol";
import { IERC165 } from "lib/openzeppelin-contracts/contracts/utils/introspection/IERC165.sol";
import "@openzeppelin/contracts/utils/ShortStrings.sol";

contract Law is ERC165, ILaw {
    using ShortStrings for *;

    //////////////////////////////////////////////////
    //                 variables                    //
    //////////////////////////////////////////////////
    address public parentLaw; // optional slot to save a parentLaw.
    uint48[] public executions = [0]; // optional log of block numbers at which the law was executed.

    ShortString public immutable name; // name of the law
    address public separatedPowers; // the address of the core governance protocol
    string public description; // description of the law
    bytes4[] public params; // hashes of data types needed for the lawCalldata. Saved as bytes4, encoded through the {DataType} function 

    //////////////////////////////////////////////////
    //                 MODIFIERS                    //
    //////////////////////////////////////////////////
    /// @notice makes law conditional on a proposal succeeding.
    ///
    /// @param lawCalldata the calldata of the law
    /// @param descriptionHash the description hash of the law
    modifier needsProposalVote(bytes memory lawCalldata, bytes32 descriptionHash) {
        uint256 proposalId = _hashProposal(address(this), lawCalldata, descriptionHash);
        if (SeparatedPowers(payable(separatedPowers)).state(proposalId) != SeparatedPowersTypes.ActionState.Succeeded) {
            revert Law__ProposalNotSucceeded();
        }
        _;
    }

    /// @notice makes law conditional on a parent law being completed.
    ///
    /// @param lawCalldata the calldata of the law
    /// @param descriptionHash the description hash of the law
    modifier needsParentCompleted(bytes memory lawCalldata, bytes32 descriptionHash) {
        if (parentLaw == address(0)) {
            revert Law__ParentLawNotSet();
        }
        uint256 parentProposalId = _hashProposal(parentLaw, lawCalldata, descriptionHash);
        if (
            SeparatedPowers(payable(separatedPowers)).state(parentProposalId)
                != SeparatedPowersTypes.ActionState.Completed
        ) {
            revert Law__ParentNotCompleted();
        }
        _;
    }

    /// @notice makes law conditional on a parent law NOT being completed.
    /// @dev this means a roleId can be given an effective veto to a legal process. If the RoleId does nothing, the law will pass. If they actively oppose, it will fail.
    ///
    /// @param lawCalldata the calldata of the law
    /// @param descriptionHash the description hash of the law
    modifier parentCanBlock(bytes memory lawCalldata, bytes32 descriptionHash) {
        if (parentLaw == address(0)) {
            revert Law__ParentLawNotSet();
        }
        uint256 parentProposalId = _hashProposal(parentLaw, lawCalldata, descriptionHash);
        if (
            SeparatedPowers(payable(separatedPowers)).state(parentProposalId)
                == SeparatedPowersTypes.ActionState.Completed
        ) {
            revert Law__ParentBlocksCompletion();
        }
        _;
    }

    /// @notice sets a deadline for when the law can be executed.
    ///
    /// @param blocksDelay the number of blocks until the law can be executed
    /// @param lawCalldata the calldata of the law
    /// @param descriptionHash the description hash of the law
    modifier delayProposalExecution(uint256 blocksDelay, bytes memory lawCalldata, bytes32 descriptionHash) {
        uint256 proposalId = _hashProposal(address(this), lawCalldata, descriptionHash);
        uint256 currentBlock = block.number;
        uint256 deadline = SeparatedPowers(payable(separatedPowers)).proposalDeadline(proposalId);

        if (deadline == 0) {
            revert Law__NoDeadlineSet();
        }
        if (deadline + blocksDelay > currentBlock) {
            revert Law__DeadlineNotPassed();
        }
        _;
    }

    /// @notice limits the number of times the law can be executed.
    ///
    /// @param maxExecution the maximum number of times the law can be executed
    /// @param gapExecutions the minimum number of blocks between executions
    modifier limitExecutions(uint256 maxExecution, uint256 gapExecutions) {
        uint256 numberOfExecutions = executions.length - 1;

        if (numberOfExecutions >= maxExecution) {
            revert Law__ExecutionLimitReached();
        }
        if (block.number - executions[numberOfExecutions] < gapExecutions) {
            revert Law__ExecutionGapTooSmall();
        }

        executions.push(uint48(block.number));
        _;
    }

    //////////////////////////////////////////////////
    //                 FUNCTIONS                    //
    //////////////////////////////////////////////////
    /// @dev Constructor function for Law contract.
    constructor(string memory name_, string memory description_, address separatedPowers_) {
        separatedPowers = separatedPowers_;
        name = name_.toShortString();
        description = description_;

        emit Law__Initialized(address(this));
    }

    /// @inheritdoc ILaw
    function executeLaw(address, /* initiator */ bytes memory, /* lawCalldata */ bytes32 /* descriptionHash */ )
        public
        virtual
        returns (address[] memory targets, uint256[] memory values, bytes[] memory calldatas)
    {
        address[] memory tar = new address[](1);
        uint256[] memory val = new uint256[](1);
        bytes[] memory cal = new bytes[](1);
        return (tar, val, cal);
    }

    /// @notice implements ERC165
    function supportsInterface(bytes4 interfaceId) public view override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(ILaw).interfaceId || super.supportsInterface(interfaceId);
    }

    /// @notice an internal helper function for hashing proposals.
    function _hashProposal(address targetLaw, bytes memory lawCalldata, bytes32 descriptionHash)
        internal
        pure
        returns (uint256)
    {
        return uint256(keccak256(abi.encode(targetLaw, lawCalldata, descriptionHash)));
    }

    /// @notice an internal helper function for hashing data types
    function dataType(string memory dataType)
        internal
        pure
        returns (bytes4)
    {
        return bytes4(keccak256(bytes(dataType)));
    }
}
