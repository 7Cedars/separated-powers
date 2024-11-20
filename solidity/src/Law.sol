// SPDX-License-Identifier: MIT

/// @notice Base implementation of a Law in the SeparatedPowers protocol. Meant to be inherited by law implementations.
/// See ./laws/Readme.md for more details.
///
/// @dev Law contracts only encode the base logic of the law:
/// - how an input is transformed into an output.
/// - under what conditions the law can be executed.
///
/// They take an input from the {SeparatedPowers::execute} in the form of calldata.
/// They return an output to the same {SeparatedPowers::execute} function in the form of targets[], values[], calldatas[].
///
/// There are four modifiers for laws to use.
/// - {needsProposalVote}: sets law to need a proposal vote to be executed.
/// - {needsParentCompleted}: checks if a parent law has been completed.
/// - {delayProposalExecution}: sets a deadline for when the law can be executed.
/// - {limitExecutions}: limits the number of times the law can be executed.
/// If needed, more modifiers can be added.
///
/// Laws do NOT revert. They always return data. There are some standards for laws to communicate to the protocol.
/// - targets[0] == address(0): general error message. Checks did not pass.
/// - targets[0] == address(1): the protocol should not take any further executive action.
///
/// Configuration of the law is handled in the core SeparatedPowers contract.
/// - what role restriction applies to the law
/// - quorum (in case law is restricted by the needsProposalVote modifier)
/// - vote threshold
/// - voting period
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
    uint48[] public executions = [0]; // optional log of block numbers at which a law was executed.

    ShortString public immutable name; // name of the law
    address public separatedPowers; // the address of the core governance protocol
    string public description; // description of the law

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
}
