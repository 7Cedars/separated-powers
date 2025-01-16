// SPDX-License-Identifier: MIT

///////////////////////////////////////////////////////////////////////////////
/// This program is free software: you can redistribute it and/or modify    ///
/// it under the terms of the MIT Public License.                           ///
///                                                                         ///
/// This is a Proof Of Concept and is not intended for production use.      ///
/// Tests are incomplete and it contracts have not been audited.            ///
///                                                                         ///
/// It is distributed in the hope that it will be useful and insightful,    ///
/// but WITHOUT ANY WARRANTY; without even the implied warranty of          ///
/// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.                    ///
///////////////////////////////////////////////////////////////////////////////

/// @title Law.sol v.0.2
/// @notice Base implementation of a Law in the SeparatedPowers protocol. Meant to be inherited by law implementations.
///
/// @dev Laws are role restricted contracts that are executed by the core SeparatedPowers protocol. The provide the following functionality:
/// 1 - Role restricting DAO actions
/// 2 - Transforming a {lawCalldata) input into an output of targets[], values[], calldatas[] to be executed by the core protocol.
/// 3 - Adding conditions to execution of the law, such as a proposal vote, a completed parent law or a delay. Any logic can be added.
///
/// A number of law settings are set through the {setLawConfig} function:
/// - a required role restriction.
/// - optional configurations of the law, such as
///     - a vote quorum needed to execute the law.
///     - a vote threshold.
///     - a vote period.
///     - a parent law that needs to be completed before the law can be executed.
///     - a parent law that needs to NOT be completed before the law can be executed.
///     - a vote delay: an amount of time in blocks that needs to have passed since the proposal vote ended before the law can be executed.
///     - a minimum amount of blocks that need to have passed since the previous execution before the law can be executed again.
/// It is possible to add additional checks if needed.
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
    // required parameters
    uint32 public allowedRole;
    ShortString public immutable name; // name of the law
    address public separatedPowers; // the address of the core governance protocol
    string public description; // description of the law
    bytes4[8] public inputParams; // hashes of data types needed for the lawCalldata. Saved as bytes4, encoded through the {DataType} function
    bytes4[8] public stateVars; // hashes of data types needed for setting state variables. Saved as bytes4, encoded through the {DataType} function

    // optional parameters
    LawConfig public config;

    // optional storage
    uint48[] public executions = [0]; // optional log of when the law was executed in block.number.

    //////////////////////////////////////////////////
    //                 FUNCTIONS                    //
    //////////////////////////////////////////////////
    /// @dev Constructor function for Law contract.
    constructor(
        string memory name_,
        string memory description_,
        address separatedPowers_,
        uint32 allowedRole_,
        LawConfig memory config_
    ) {
        separatedPowers = separatedPowers_;
        name = name_.toShortString();
        description = description_;
        allowedRole = allowedRole_;
        config = config_;

        emit Law__Initialized(address(this), separatedPowers, name_, description, allowedRole, config);
    }

    /// note this is the function that is called by the SeparatedPowers protocol. It always runs checks before execution of law logic.
    /// @inheritdoc ILaw
    function executeLaw(address initiator, bytes memory lawCalldata, bytes32 descriptionHash)
        public
        returns (address[] memory targets, uint256[] memory values, bytes[] memory calldatas)
    {
        if (msg.sender != separatedPowers) {
            revert Law__OnlySeparatedPowers();
        }
        _executeChecks(initiator, lawCalldata, descriptionHash);
        bytes memory stateChange;
        (targets, values, calldatas, stateChange) = simulateLaw(initiator, lawCalldata, descriptionHash);
        _changeStateVariables(stateChange);
    }

    /// note NB! this function needs to be overwritten by law implementations to include law specific logics. 
    /// @inheritdoc ILaw
    function simulateLaw(address initiator, bytes memory lawCalldata, bytes32 descriptionHash) // NB. £bug: simulateLaw can change state of law _without_ checks having been run! 
        public
        view // CANNOT change state of law. 
        virtual
        returns (address[] memory targets, uint256[] memory values, bytes[] memory calldatas, bytes memory stateChange) {
            // Empty law logic. Needs to be overridden by law implementations   
    }

    //////////////////////////////////////////////////
    //                 INTERNALS                    //
    //////////////////////////////////////////////////

    function _changeStateVariables(bytes memory stateChange) internal virtual {
        // Empty function. Needs to be overridden by law implementations
    }

    /// @notice an internal function to check that the law is valid before execution.
    /// @dev Optional checks can be added by overriding this function.
    ///
    /// @param lawCalldata the calldata for the law.
    /// @param descriptionHash the hash of the description of the law.
    function _executeChecks(address initiator, bytes memory lawCalldata, bytes32 descriptionHash) internal virtual {
        // Optional check 1: make law conditional on a proposal succeeding.
        if (config.quorum != 0) {
            uint256 proposalId = _hashProposal(address(this), lawCalldata, descriptionHash);
            if (
                SeparatedPowers(payable(separatedPowers)).state(proposalId)
                    != SeparatedPowersTypes.ProposalState.Succeeded
            ) {
                revert Law__ProposalNotSucceeded();
            }
        }

        /// Optional check 2: make law conditional on a parent law being completed.
        if (config.needCompleted != address(0)) {
            uint256 parentProposalId = _hashProposal(config.needCompleted, lawCalldata, descriptionHash);
            if (
                SeparatedPowers(payable(separatedPowers)).state(parentProposalId)
                    != SeparatedPowersTypes.ProposalState.Completed
            ) {
                revert Law__ParentNotCompleted();
            }
        }

        /// Optional check 3: make law conditional on a parent law NOT being completed.
        /// Note this means a roleId can be given an effective veto to a legal process. If the RoleId does nothing, the law will pass. If they actively oppose, it will fail.
        if (config.needNotCompleted != address(0)) {
            uint256 parentProposalId = _hashProposal(config.needNotCompleted, lawCalldata, descriptionHash);
            if (
                SeparatedPowers(payable(separatedPowers)).state(parentProposalId)
                    == SeparatedPowersTypes.ProposalState.Completed
            ) {
                revert Law__ParentBlocksCompletion();
            }
        }

        /// Optional check 4: set a deadline for when the law can be executed.
        if (config.delayExecution != 0) {
            uint256 proposalId = _hashProposal(address(this), lawCalldata, descriptionHash);
            uint256 currentBlock = block.number;
            uint256 deadline = SeparatedPowers(payable(separatedPowers)).proposalDeadline(proposalId);

            if (deadline + config.delayExecution > currentBlock) {
                revert Law__DeadlineNotPassed();
            }
        }

        /// Optional check 5: throttle how often the law can be executed.
        if (config.throttleExecution != 0) {
            uint256 numberOfExecutions = executions.length - 1;
            if (
                executions[numberOfExecutions] != 0
                    && block.number - executions[numberOfExecutions] < config.throttleExecution
            ) {
                revert Law__ExecutionGapTooSmall();
            }
            executions.push(uint48(block.number));
        }
    }

    //////////////////////////////////////////////////
    //           HELPER & VIEW FUNCTIONS            //
    //////////////////////////////////////////////////
    function getInputParams() public view returns (
        bytes4 param0, bytes4 param1, bytes4 param2, bytes4 param3, 
        bytes4 param4, bytes4 param5, bytes4 param6, bytes4 param7
        ) {
            return (
                inputParams[0], inputParams[1], inputParams[2], inputParams[3],
                inputParams[4], inputParams[5], inputParams[6], inputParams[7]
       );
    }

    function getStateVars() public view returns (
        bytes4 var0, bytes4 var1, bytes4 var2, bytes4 var3, 
        bytes4 var4, bytes4 var5, bytes4 var6, bytes4 var7
        ) {
            return (
                stateVars[0], stateVars[1], stateVars[2], stateVars[3],
                stateVars[4], stateVars[5], stateVars[6], stateVars[7]
       );
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
    function dataType(string memory param) internal pure returns (bytes4) {
        return bytes4(keccak256(bytes(param)));
    }
}
