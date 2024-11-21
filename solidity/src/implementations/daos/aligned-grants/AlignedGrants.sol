// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import { SeparatedPowers } from "../../../SeparatedPowers.sol";
import "lib/openzeppelin-contracts/contracts/utils/ShortStrings.sol";

/// @notice Example DAO contract based on the SeparatedPowers protocol.
contract AlignedGrants is SeparatedPowers {
    using ShortStrings for *;

    // Optional naming uint48 roles at initiation.
    uint32 public constant SENIOR_ROLE = 1;
    uint32 public constant WHALE_ROLE = 2;
    uint32 public constant MEMBER_ROLE = 3;

    ShortString[] public coreValue; // description of short strings. have to be shorter than 31 characters.
    mapping(address => bool) public blacklistedAccounts; // description of short strings. have to be shorter than 31 characters.

    event AlignedGrants__RequirementAdded(ShortString requirement);
    event AlignedGrants__RequirementRemoved(uint256 index);
    event AlignedGrants__AccountBlacklisted(address account, bool isBlackListed);

    constructor()
        SeparatedPowers("AlignedGrants") // name of the DAO.
    {
        // an example core value of agDao.
        coreValue.push("All accounts must be human.".toShortString());
    }

    // a few functions that are specific to the AgDao.
    function addCoreValue(ShortString requirement) public onlySeparatedPowers {
        coreValue.push(requirement);

        emit AlignedGrants__RequirementAdded(requirement);
    }

    function removeCoreValue(uint256 index) public onlySeparatedPowers {
        coreValue[index] = coreValue[coreValue.length - 1];
        coreValue.pop();

        emit AlignedGrants__RequirementRemoved(index);
    }

    function setBlacklistAccount(address account, bool isBlackListed) public onlySeparatedPowers {
        blacklistedAccounts[account] = isBlackListed;

        emit AlignedGrants__AccountBlacklisted(account, isBlackListed);
    }

    /* getter function */
    function getCoreValues() public view returns (string[] memory coreValues) {
        coreValues = new string[](coreValue.length);
        for (uint256 i = 0; i < coreValue.length; i++) {
            coreValues[i] = coreValue[i].toString();
        }
        return coreValues;
    }
}
