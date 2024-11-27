// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import { SeparatedPowers } from "../../../SeparatedPowers.sol";
import "lib/openzeppelin-contracts/contracts/utils/ShortStrings.sol";

/// @notice Example DAO contract based on the SeparatedPowers protocol.
contract BasicDao is SeparatedPowers {
    using ShortStrings for *;

    // Optional naming uint48 roles at initiation.
    uint32 public constant SENIOR_ROLE = 1; // selected by peers on subjective assessment criteria
    uint32 public constant DELEGATE_ROLE = 2; // selected on basis of delegated voting among token holders. 
    uint32 public constant SECURITY_ROLE = 3; // Nominated by seniors. Elected by delegates.
    uint32 public constant MEMBER_ROLE = 4; // self selected role, but subject to delay. 
    // Needs to have a minimum amount of tokens. Can be selection can vetoed and role revoked by seniors.
    
    constructor()
        SeparatedPowers("BasicDao") // name of the DAO.
    { }

}
