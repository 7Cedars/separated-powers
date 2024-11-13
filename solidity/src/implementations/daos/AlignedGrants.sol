// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import { SeparatedPowers } from "../../SeparatedPowers.sol";
import "lib/openzeppelin-contracts/contracts/utils/ShortStrings.sol";

// ONLY FOR TESTING PURPOSES // DO NOT USE IN PRODUCTION
import { console2 } from "lib/forge-std/src/Test.sol";

/**
 * @notice Example DAO contract based on the SeparatedPowers protocol.
 */
contract AlignedGrants is SeparatedPowers {
    using ShortStrings for *;

    // Optional naming uint48 roles at initiation.
    uint32 public constant SENIOR_ROLE = 1;
    uint32 public constant WHALE_ROLE = 2;
    uint32 public constant MEMBER_ROLE = 3;

    ShortString[] public coreRequirements; // description of short strings. have to be shorter than 31 characters.
    mapping(address => bool) public blacklistedAccounts; // description of short strings. have to be shorter than 31 characters.

    event AlignedGrants__RequirementAdded(ShortString requirement);
    event AlignedGrants__RequirementRemoved(uint256 index);
    event AlignedGrants__AccountBlacklisted(address account, bool isBlackListed);

    constructor()
        SeparatedPowers("AlignedGrants") // name of the DAO.
    {
        // an example core value of agDao.
        coreRequirements.push("All accounts must be human.".toShortString());
    }

    // a few functions that are specific to the AgDao.
    function addRequirement(ShortString requirement) public onlySeparatedPowers {
        coreRequirements.push(requirement);

        emit AlignedGrants__RequirementAdded(requirement);
    }

    function removeRequirement(uint256 index) public onlySeparatedPowers {
        coreRequirements[index] = coreRequirements[coreRequirements.length - 1];
        coreRequirements.pop();

        emit AlignedGrants__RequirementRemoved(index);
    }

    function setBlacklistAccount(address account, bool isBlackListed) public onlySeparatedPowers {
        blacklistedAccounts[account] = isBlackListed;

        emit AlignedGrants__AccountBlacklisted(account, isBlackListed);
    }

    /* getter function */
    function getCoreValues() public view returns (string[] memory coreValues) {
        coreValues = new string[](coreRequirements.length);
        for (uint256 i = 0; i < coreRequirements.length; i++) {
            coreValues[i] = coreRequirements[i].toString();
        }
        return coreValues;
    }
}
