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

// note that natspecs are wip.

/// @notice This contract ...
///
pragma solidity 0.8.26;

import { Law } from "../../Law.sol";
import { SeparatedPowers } from "../../SeparatedPowers.sol";

contract BlacklistAccount is Law {
    error BlacklistAccount__AlreadyBlacklisted();
    error BlacklistAccount__NotBlacklisted();

    // the state vars that this law manages: blacklisted accounts.
    mapping(address => bool) public blacklistedAccounts; // description of short strings. have to be shorter than 31 characters.

    event BlacklistAccount__Added(address account);
    event BlacklistAccount__Removed(address account);

    constructor(
        string memory name_,
        string memory description_,
        address separatedPowers_,
        uint32 allowedRole_,
        LawConfig memory config_
    ) Law(name_, description_, separatedPowers_, allowedRole_, config_) {
        inputParams[0] = dataType("address");
        inputParams[1] = dataType("bool");
        stateVars[0] = dataType("address");
        stateVars[1] = dataType("bool");
    }

    function simulateLaw(address, /*initiator */ bytes memory lawCalldata, bytes32 descriptionHash)
        public view
        override
        returns (address[] memory tar, uint256[] memory val, bytes[] memory cal, bytes memory stateChange)
    {
        // retrieve the account that was revoked
        (address account, bool blacklist) = abi.decode(lawCalldata, (address, bool));  

        if (blacklist && blacklistedAccounts[account]) {
            revert BlacklistAccount__AlreadyBlacklisted();
        } else if (!blacklist && !blacklistedAccounts[account]) {
            revert BlacklistAccount__NotBlacklisted();
        }

        // step 2: return data
        tar = new address[](1);
        val = new uint256[](1);
        cal = new bytes[](1);

        tar[0] = address(1); // signals that separatedPowers should not execute anything else.
        return (tar, val, cal, lawCalldata);
    }

    function _changeStateVariables(bytes memory stateChange) internal override {
        (address account, bool blacklist) = abi.decode(stateChange, (address, bool));

        if (blacklist) {
            blacklistedAccounts[account] = true;
            emit BlacklistAccount__Added(account);
        } else {
            blacklistedAccounts[account] = false;
            emit BlacklistAccount__Removed(account);
        }
    }
}
