// SPDX-License-Identifier: MIT

// note that natspecs are wip.

/// @notice This contract ...
///
pragma solidity 0.8.26;

import { Law } from "../../Law.sol";
import { SeparatedPowers } from "../../SeparatedPowers.sol";
import { ERC1155 } from "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/utils/ShortStrings.sol";

// ONLY FOR TESTING
import { console } from "lib/forge-std/src/console.sol";

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
        params = [dataType("address"), dataType("bool")];
    }

    function simulateLaw(address, /*initiator */ bytes memory lawCalldata, bytes32 descriptionHash)
        public
        override
        returns (address[] memory tar, uint256[] memory val, bytes[] memory cal)
    {
        // retrieve the account that was revoked
        (address account, bool blacklist) = abi.decode(lawCalldata, (address, bool)); // don't know if this is going to work...

        if (blacklist) {
            if (blacklistedAccounts[account]) {
                revert BlacklistAccount__AlreadyBlacklisted();
            }
            blacklistedAccounts[account] = true;
            emit BlacklistAccount__Added(account);
        } else {
            if (!blacklistedAccounts[account]) {
                revert BlacklistAccount__NotBlacklisted();
            }
            blacklistedAccounts[account] = false;
            emit BlacklistAccount__Removed(account);
        }

        // step 2: return data
        address[] memory tar = new address[](1);
        uint256[] memory val = new uint256[](1);
        bytes[] memory cal = new bytes[](1);

        tar[0] = address(1); // signals that separatedPowers should not execute anything else.
        return (tar, val, cal);
    }
}
