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
    /// @param params_ the parameters of the function
    constructor(
        string memory name_, 
        string memory description_, 
        address separatedPowers_,
        bytes4[] memory params_
        )
        Law(name_, description_, separatedPowers_)
    {  
        params = params_;
     }

    /// @notice Execute the open action.
    function executeLaw(address /*initiator*/, bytes memory lawCalldata, bytes32 descriptionHash)
        public
        override
        virtual
        // return an empty array.
        returns (address[] memory tar, uint256[] memory val, bytes[] memory cal)
        {
            // execute all necessary checks. 
            super.executeLaw(address(0), lawCalldata, descriptionHash); 

            // at execution, send empty calldata to protocol. -- nothing gets done.
            tar = new address[](1);
            val = new uint256[](1);
            cal = new bytes[](1);
            
            tar[0] = address(1); // targets[0] = address(1) is a signal to the protocol that it should not try and execute anything. 
        }
}
