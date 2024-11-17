// SPDX-License-Identifier: MIT
///
/// @notice Events used in the SeparatedPowers protocol.
/// Code derived from OpenActionZeppelin's Governor.sol contract and Haberdasher Labs Hats protocol.
///
/// @author 7Cedars, Oct-Nov 2024, RnDAO CollabTech Hackathon
import {IERC165} from "lib/openzeppelin-contracts/contracts/utils/introspection/IERC165.sol";
import {LawErrors} from "./LawErrors.sol";

pragma solidity 0.8.26;

interface ILaw is IERC165, LawErrors {
    error ILaw__AccessNotAuthorized(address caller);
    error Law__NoZeroAddress();

    /// @notice external function to execute a law.
    /// @param initiator the address of the account that proposed execution of the law.
    // this logic might still have to change. £check Maybe add initiator to lawCalldata?
    /// @param lawCallData call data to be executed.
    /// @param descriptionHash the descriptionHash of the proposal
    ///
    /// @dev the arrays of targets, values and calldatas must have the same length.
    /// @dev Note that this function should be overridden (without a super call) to add logic of the law.
    function executeLaw(bytes memory lawCallData, bytes32 descriptionHash)
        external
        returns (address[] memory targets, uint256[] memory values, bytes[] memory calldatas);

    /// @notice Returns the list of block numbers at which the law was executed.
    function getExecutions() external view returns (uint48[] memory executions);
}
