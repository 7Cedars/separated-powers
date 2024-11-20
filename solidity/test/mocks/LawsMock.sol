// SPDX-License-Identifier: MIT

/// @notice Mock law contracts for testing.
/// @dev Each law inherits the same {PresetAction} contract, but adds another modifier at {executeLaw} function.
///
/// @author 7Cedars, Oct-Nov 2024, RnDAO CollabTech Hackathon

pragma solidity 0.8.26;

import { PresetAction } from "../../src/implementations/laws/executive/PresetAction.sol";

contract NeedsProposalVote is PresetAction {
    constructor(
        string memory name_,
        string memory description_,
        address separatedPowers_,
        address[] memory targets_,
        uint256[] memory values_,
        bytes[] memory calldatas_
    ) PresetAction(name_, description_, separatedPowers_, targets_, values_, calldatas_) { }

    function executeLaw(address, /*initiator*/ bytes memory lawCalldata, bytes32 descriptionHash)
        public
        override
        needsProposalVote(lawCalldata, descriptionHash)
        returns (address[] memory targets, uint256[] memory values, bytes[] memory calldatas)
    {
        (targets, values, calldatas) = super.executeLaw(address(0), lawCalldata, "");
    }
}

contract NeedsParentCompleted is PresetAction {
    constructor(
        string memory name_,
        string memory description_,
        address separatedPowers_,
        address[] memory targets_,
        uint256[] memory values_,
        bytes[] memory calldatas_,
        address parentLaw_
    ) PresetAction(name_, description_, separatedPowers_, targets_, values_, calldatas_) {
        parentLaw = parentLaw_;
    }

    function executeLaw(address, /*initiator*/ bytes memory lawCalldata, bytes32 descriptionHash)
        public
        override
        needsParentCompleted(lawCalldata, descriptionHash)
        returns (address[] memory targets, uint256[] memory values, bytes[] memory calldatas)
    {
        (targets, values, calldatas) = super.executeLaw(address(0), lawCalldata, "");
    }
}

contract ParentCanBlock is PresetAction {
    constructor(
        string memory name_,
        string memory description_,
        address separatedPowers_,
        address[] memory targets_,
        uint256[] memory values_,
        bytes[] memory calldatas_,
        address parentLaw_
    ) PresetAction(name_, description_, separatedPowers_, targets_, values_, calldatas_) {
        parentLaw = parentLaw_;
    }

    function executeLaw(address, /*initiator*/ bytes memory lawCalldata, bytes32 descriptionHash)
        public
        override
        parentCanBlock(lawCalldata, descriptionHash)
        returns (address[] memory targets, uint256[] memory values, bytes[] memory calldatas)
    {
        (targets, values, calldatas) = super.executeLaw(address(0), lawCalldata, "");
    }
}

contract DelayProposalExecution is PresetAction {
    uint256 private immutable DELAY;

    constructor(
        string memory name_,
        string memory description_,
        address separatedPowers_,
        address[] memory targets_,
        uint256[] memory values_,
        bytes[] memory calldatas_,
        uint256 delay_
    ) PresetAction(name_, description_, separatedPowers_, targets_, values_, calldatas_) {
        DELAY = delay_;
    }

    function executeLaw(address, /*initiator*/ bytes memory lawCalldata, bytes32 descriptionHash)
        public
        override
        delayProposalExecution(DELAY, lawCalldata, descriptionHash)
        returns (address[] memory targets, uint256[] memory values, bytes[] memory calldatas)
    {
        (targets, values, calldatas) = super.executeLaw(address(0), lawCalldata, "");
    }
}

contract LimitExecutions is PresetAction {
    uint256 private immutable MAX_EXECUTIONS;
    uint256 private immutable GAP_EXECUTIONS;

    constructor(
        string memory name_,
        string memory description_,
        address separatedPowers_,
        address[] memory targets_,
        uint256[] memory values_,
        bytes[] memory calldatas_,
        uint256 maxExecutions_,
        uint256 gapExecutions_
    ) PresetAction(name_, description_, separatedPowers_, targets_, values_, calldatas_) {
        MAX_EXECUTIONS = maxExecutions_;
        GAP_EXECUTIONS = gapExecutions_;
    }

    function executeLaw(address, /*initiator*/ bytes memory lawCalldata, bytes32 descriptionHash)
        public
        override
        limitExecutions(MAX_EXECUTIONS, GAP_EXECUTIONS)
        returns (address[] memory targets, uint256[] memory values, bytes[] memory calldatas)
    {
        (targets, values, calldatas) = super.executeLaw(address(0), lawCalldata, "");
    }
}
