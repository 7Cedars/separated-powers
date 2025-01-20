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

import { PresetAction } from "../executive/PresetAction.sol";

contract SelfDestructPresetAction is PresetAction {
    constructor(
        string memory name_,
        string memory description_,
        address separatedPowers_,
        uint32 allowedRole_,
        LawConfig memory config_,
        uint32 roleId_
        address erc721Address_
    ) SelfSelect(name_, description_, separatedPowers_, allowedRole_, config_, roleId_) {
        if (erc721Address_ == address(0)) {
            revert Erc721Check__NoZeroAddress();
        }
        erc721Address = erc721Address_;
    }

    /// @notice overrides the default simulateLaw function.
    /// adds a check for an nft
    // Any account that does not own the nft will not be able to execute any law that uses this additional check.
    function simulateLaw(address initiator, bytes memory lawCalldata, bytes32 descriptionHash) internal override {
        bool hasToken = ERC721(erc721Address).balanceOf(initiator) > 0;
        if (!hasToken) {
            revert Erc721Check__DoesNotOwnToken();
        }
        super.simulateLaw(initiator, lawCalldata, descriptionHash);

        calldatas.push(
          
        )

        return (targets, values, calldatas, '0x0');

    }
}
