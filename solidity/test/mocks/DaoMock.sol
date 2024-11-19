// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import { SeparatedPowers } from "../../src/SeparatedPowers.sol";
import "lib/openzeppelin-contracts/contracts/utils/ShortStrings.sol";

/// @notice Example DAO contract based on the SeparatedPowers protocol.
contract DaoMock is SeparatedPowers {
    using ShortStrings for *;

    // Optional naming uint48 roles at initiation.
    uint32 public constant ROLE_ONE = 1;
    uint32 public constant ROLE_TWO = 2;
    uint32 public constant ROLE_THREE = 3;

    constructor()
        SeparatedPowers("DaoMock") // name of the DAO.
    { }
}
