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
/// - {delayExecution}: sets a deadline for when the law can be executed.
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

import { ILaw } from "./interfaces/ILaw.sol";
import { PowerModifiers } from "./PowerModifiers.sol";
import { ERC165 } from "lib/openzeppelin-contracts/contracts/utils/introspection/ERC165.sol";
import { IERC165 } from "lib/openzeppelin-contracts/contracts/utils/introspection/IERC165.sol";
import "@openzeppelin/contracts/utils/ShortStrings.sol";

contract Law is ERC165, ILaw, PowerModifiers {
    using ShortStrings for *;

    //////////////////////////////////////////////////
    //                 variables                    //
    //////////////////////////////////////////////////
    ShortString public immutable name; // name of the law
    address public separatedPowers; // the address of the core governance protocol
    address public parentLaw; // optional slot to save a parentLaw.
    string public description;
    uint48[] public executions; // log of block numbers at which the law was executed.

    ////////////////////////////////////////////////// 
    //                 modifiers                    //
    //////////////////////////////////////////////////
    modifier needsProposalVote() {
        uint256 proposalId = _hashExecutiveAction(initiator, address(this), lawCalldata, descriptionHash);
        if (SeparatedPowers(payable(separatedPowers)).state(proposalId) != SeparatedPowersTypes.ActionState.Succeeded)
        {
            cal[0] = abi.encode("proposal not succeeded".toShortString());
            return (tar, val, cal);
        }
        _;
    }

    modifier needsParentCompleted() {
        if (parentLaw == address(0)) {
            cal[0] = abi.encode("parent law not set".toShortString());
            return (tar, val, cal);
        }
        uint256 proposalId = _hashExecutiveAction(initiator, parentLaw, lawCalldata, descriptionHash);
        if (SeparatedPowers(payable(separatedPowers)).state(proposalId) != SeparatedPowersTypes.ActionState.Completed)
        {
            cal[0] = abi.encode("parent proposal not completed".toShortString());
            return (tar, val, cal);
        }
        _;
    }

    modifier delayExecution(uint256 blocksDelay) {
        uint256 proposalId = _hashExecutiveAction(initiator, address(this), lawCalldata, descriptionHash);
        uint256 currentBlock = block.number;
        uint256 deadline = SeparatedPowers(payable(separatedPowers)).proposalDeadline(proposalId);

        tar = new address[](1);
        val = new uint256[](1);
        cal = new bytes[](1);

        if (deadline == 0) {
            cal[0] = abi.encode("no deadline set".toShortString());
            return (tar, val, cal);
        }
        if (deadline < currentBlock) {
            cal[0] = abi.encode("deadline not passed".toShortString());
            return (tar, val, cal);
        }
        _;     
    }

    modifier limitExecutions(uint256 maxExecution, uint256 gapExecutions) {
        uint256 numberOfExecutions = executions.length;
        tar = new address[](1);
        val = new uint256[](1);
        cal = new bytes[](1);

        // check if the limit has been reached
        if (numberOfExecutions >= _maxExecution) {
            cal[0] = abi.encode("execution limit reached".toShortString());
            return (tar, val, cal);
        }
        // check if the gap to the previous execution is large enough
        if (block.number - executions[numberOfExecutions - 1] < _gapExecutions) {
            cal[0] = abi.encode("execution gap too small".toShortString());
            return (tar, val, cal);
        }
        _; 
    }

    //////////////////////////////////////////////////
    //                 functions                    //
    //////////////////////////////////////////////////
    /// @dev Constructor function for Law contract.
    constructor(string memory name_, string memory description_, address separatedPowers_) {
        separatedPowers = separatedPowers_;
        name = name_.toShortString();
        description = description_;
    }

    /// @inheritdoc ILaw
    function executeLaw(address, /* initiator */ bytes memory, /* lawCalldata */ bytes32 /* descriptionHash */ )
        external
        virtual
        returns (address[] memory targets, uint256[] memory values, bytes[] memory calldatas)
    {
        address[] memory tar = new address[](1);
        uint256[] memory val = new uint256[](1);
        bytes[] memory cal = new bytes[](1);
        return (tar, val, cal);
    }

    /// @inheritdoc ILaw
    function getExecutions() public view returns (uint48[] memory) {
        return executions;
    }

    /// @notice implements ERC165
    function supportsInterface(bytes4 interfaceId) public view override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(ILaw).interfaceId || super.supportsInterface(interfaceId);
    }

    /// @notice an internal helper function for hashing proposals.
    function _hashExecutiveAction(address initiator, address targetLaw, bytes memory lawCalldata, bytes32 descriptionHash)
        internal
        pure
        returns (uint256)
    {
        return uint256(keccak256(abi.encode(initiator, targetLaw, lawCalldata, descriptionHash)));
    }
}
