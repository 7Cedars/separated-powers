// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {SeparatedPowers} from "../SeparatedPowers.sol";
import "../../lib/openzeppelin-contracts/contracts/utils/ShortStrings.sol";

// ONLY FOR TESTING PURPOSES // DO NOT USE IN PRODUCTION
import {console2} from "lib/forge-std/src/Test.sol";

/**
 * @notice Example DAO contract based on the SeparatedPowers protocol.
 */
contract AgDao is SeparatedPowers {
  using ShortStrings for *;

  // naming uint64 roles at initiation. Optional.  
  uint64 public constant SENIOR_ROLE = 1; 
  uint64 public constant WHALE_ROLE = 2; 
  uint64 public constant MEMBER_ROLE = 3; 

  ShortString[] public coreRequirements; // description of short strings. have to be shorter than 31 characters.
  mapping(address => bool) public blacklistedAccounts; // description of short strings. have to be shorter than 31 characters.

  event AgDao_RequirementAdded(ShortString requirement);
  event AgDao_RequirementRemoved(uint256 index);
  event AgDao_AccountBlacklisted(address account, bool isBlackListed);

  constructor( ) SeparatedPowers('agDao') // name of the DAO. 
    { // an example core value of agDao.  
      coreRequirements.push("All accounts must be human.".toShortString());
    } 

  // a few functions that are specific to the AgDao.
  function addRequirement(ShortString requirement) public onlySeparatedPowers {
    coreRequirements.push(requirement);

    emit AgDao_RequirementAdded(requirement); 
  }

  function removeRequirement(uint256 index) public onlySeparatedPowers {
    coreRequirements[index] = coreRequirements[coreRequirements.length - 1]; 
    coreRequirements.pop();

    emit AgDao_RequirementRemoved(index);
  }

  function setBlacklistAccount(address account, bool isBlackListed) public onlySeparatedPowers {
    blacklistedAccounts[account] = isBlackListed;

    emit AgDao_AccountBlacklisted(account, isBlackListed);
  }

  /* getter function */ 
  function getCoreValues() public returns (ShortString[] memory coreValues)  {
    return coreRequirements;
  }
}
