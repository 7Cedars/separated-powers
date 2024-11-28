// SPDX-License-Identifier: MIT
/// @notice Example DAO contract based on the SeparatedPowers protocol.
/// 
/// Note It provides a basic starting point for a DAO. Any action can be executed, but a simple balance and check system provide security against hostile take overs. 
/// See {Constitution.sol} for details about the roles and laws that make up this DAO. 
///
/// Note. IMPORTANT: This is a work in progress. Do not use in production. It does not come with any guarantees, warranties of any kind. 
/// 
/// @author 7Cedars, Oct-Nov 2024, RnDAO CollabTech Hackathon
pragma solidity 0.8.26;

import { SeparatedPowers } from "../../../SeparatedPowers.sol";
import "lib/openzeppelin-contracts/contracts/utils/ShortStrings.sol";

contract BasicDao is SeparatedPowers {
    using ShortStrings for *;

    // Optional naming uint48 roles at initiation.
    uint32 public constant SENIOR_ROLE = 1; // selected by peers on subjective assessment criteria
    uint32 public constant DELEGATE_ROLE = 2; // selected on basis of delegated voting among token holders. 
    
    constructor()
        SeparatedPowers("BasicDao") // name of the DAO.
    { }

}
