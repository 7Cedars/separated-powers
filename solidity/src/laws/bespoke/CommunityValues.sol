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

contract CommunityValues is Law {
  using ShortStrings for *;

  error CommunityValues__ValueNotFound(); 
  
  // the state vars that this law manages: community values. 
  string[] public communityValue; // description of short strings. have to be shorter than 31 characters.
  uint256 public numberOfCommunityValues;

  event CommunityValues__Added(string value);
  event CommunityValues__Removed(string value);

  constructor(
      string memory name_, 
      string memory description_, 
      address separatedPowers_,
      uint32 allowedRole_, 
      LawConfig memory config_
    )
      Law(name_, description_, separatedPowers_, allowedRole_, config_)
  {
      params = [dataType("ShortString"), dataType("bool")];
  }

  function executeLaw(address, /*initiator */ bytes memory lawCalldata, bytes32 descriptionHash)
        public
        override
        returns (address[] memory tar, uint256[] memory val, bytes[] memory cal) {
        // step 0: do necessary optional checks. 
        super.executeLaw(address(0), lawCalldata, descriptionHash);

        // retrieve the account that was revoked
        (string memory value, bool addValue) = abi.decode(lawCalldata, (string, bool)); // don't know if this is going to work...

        if (addValue) {
            _addCommunityValue(value);
        } else {
            _removeCommunityValue(value);
        }

        // step 2: return data
        tar[0] = address(1); // signals that separatedPowers should not execute anything else. 
        return (tar, val, cal);
  }

  // add value 
  function _addCommunityValue(string memory value) internal {
      communityValue.push(value);
      numberOfCommunityValues++;

      emit CommunityValues__Added(value);
  }

  // remove value 
  // note: it works by searching for value. Not by index. 
  // because this way executeLaw always needs the short string + low chance on accidentally removing wrong value. 
  function _removeCommunityValue(string memory value) internal {
    for (uint256 index; index <= numberOfCommunityValues; index++) {
      if (keccak256(bytes(communityValue[index])) == keccak256(bytes(value))) { 
        communityValue[index] = communityValue[numberOfCommunityValues - 1];
        communityValue.pop();
        numberOfCommunityValues--;
        break; 
       }

      if (index == numberOfCommunityValues) {
        revert CommunityValues__ValueNotFound();
      }
    }
    
    emit CommunityValues__Removed(value);
  }
}
