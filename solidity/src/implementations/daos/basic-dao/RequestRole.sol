// SPDX-License-Identifier: MIT

/// @notice A bespoke law that allows someone to request a member role.
/// The request can be granted by any existing member after a delay: see law # in constitution. 
pragma solidity 0.8.26;

import { Law } from "../../../Law.sol";
import { DirectSelect } from "../../laws/electoral/DirectSelect.sol";
import { ProposalOnly } from "../../laws/executive/ProposalOnly.sol";
import "@openzeppelin/contracts/utils/ShortStrings.sol";

contract RequestRole is ProposalOnly {
    using ShortStrings for *;

    error DirectSelect__IncorrectParameters();

    uint32 private immutable _roleId;

    constructor(
      string memory name_, 
      string memory description_, 
      address separatedPowers_,
      uint32 roleId_, 
      bytes4[] memory params_
      )
        ProposalOnly(name_, description_, separatedPowers_, params_)
    {
        _roleId = roleId_; 
    }

    function executeLaw(address initiator, bytes memory lawCalldata, bytes32 descriptionHash)
        public
        override
        returns (address[] memory tar, uint256[] memory val, bytes[] memory cal)
    {
        // step 0: check if initiator is the account holder. 
        ( uint32 roleId,
          address requestedMemberAccount
          ) = abi.decode(lawCalldata, (uint32, address));

        if (
          initiator != requestedMemberAccount || 
          roleId != _roleId 
          ) {
          revert DirectSelect__IncorrectParameters();
        }
        
        // step 1: do necessary optional checks & return data. 
        (tar, val, cal) = super.executeLaw(address(0), lawCalldata, descriptionHash);
    }
}