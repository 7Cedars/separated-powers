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

contract ProposalOnly is Law {
    /// @notice Constructor function for Open contract.
    /// @param name_ name of the law
    /// @param description_ description of the law
    /// @param separatedPowers_ the address of the core governance protocol
    constructor(string memory name_, string memory description_, address separatedPowers_)
        Law(name_, description_, separatedPowers_)
    { }

    /// @notice Execute the open action.
    function executeLaw(address /*initiator*/, bytes memory /*lawCalldata*/, bytes32 /*descriptionHash*/)
        external
        override
        // needVote() //  needs vote to pass
        // needsParentCompleted() // needs parent Law to be completed. 
        returns (address[] memory tar, uint256[] memory val, bytes[] memory cal)
    {
        // at execution, send empty calldata to protocol. -- nothing gets done. 
        tar[0] = address(1); // protocol should not revert. 
        return (tar, val, cal);
    }
}
