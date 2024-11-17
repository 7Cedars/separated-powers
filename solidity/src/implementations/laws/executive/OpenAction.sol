// SPDX-License-Identifier: MIT

/// @notice A base contract that executes a open action.
///
/// Note As the contract allows for any action to be executed, it severely limits the functionality of the SeparatedPowers protocol.
/// - any role that has access to this law, can execute any function. It has full power of the DAO.
/// - if this law is restricted by PUBLIC_ROLE, it means that anyone has access to it. Which means that anyone is given the right to do anything through the DAO.
/// - The contract should always be used in combination with modifiers from {PowerModiifiers}.
///
/// The logic:
/// - any the lawCalldata includes targets[], values[], calldatas[] - that are send straight to the SeparatedPowers protocol. without any checks.
///
/// @author 7Cedars, Oct-Nov 2024, RnDAO CollabTech Hackathon

pragma solidity 0.8.26;

import { Law } from "../../../Law.sol";

contract OpenAction is Law {
    /// @notice Constructor function for OpenAction contract.
    /// @param name_ name of the law
    /// @param description_ description of the law
    /// @param separatedPowers_ the address of the core governance protocol
    constructor(string memory name_, string memory description_, address separatedPowers_)
        Law(name_, description_, separatedPowers_)
    { }

    /// @notice Execute the open action.
    /// @param lawCalldata the calldata of the law
    function executeLaw(bytes memory lawCalldata, bytes32 /*descriptionHash*/ )
        external
        override
        returns (address[] memory targets, uint256[] memory values, bytes[] memory calldatas)
    {
        // decode the calldata.
        // note: no check on decoded call data. If needed, this can be added.
        (targets, values, calldatas) = abi.decode(lawCalldata, (address[], uint256[], bytes[]));

        // send calldata straight to the SeparatedPowers protocol.
        executions.push(uint48(block.number));
        return (targets, values, calldatas);
    }
}
