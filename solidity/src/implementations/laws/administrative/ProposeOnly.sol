// SPDX-License-Identifier: MIT

/// Note natspecs are still WIP. 
///
/// @notice A modifier that removes execute data from a law. 
/// The law can only be used as initiator for a proposal as a result. 
/// Execution needs to be implemented by another law. 
/// It allows for a governance flow where 
/// - roleId A only has the power to propose a law and 
/// - roleId B only has the power to execute a proposed law. 

pragma solidity 0.8.26;

import { Law } from "../../../Law.sol";
import { SeparatedPowers } from "../../../SeparatedPowers.sol";

contract ProposeOnly is Law {
  error ProposeOnly__NoZeroAddress();

  ShortString public immutable name; // name of the law
  address public separatedPowers; // the address of the core governance protocol
  string public description;
  uint48[] public executions; // log of bl

  constructor(address parentLaw_)
        Law(
          Law(parentLaw_).name(), 
          Law(parentLaw_).description(), 
          Law(parentLaw_).separatedPowers()
          )
    {
      if (parentLaw_ == address(0)) {
        revert ProposeOnly__NoZeroAddress();
      } 
      parentLaw = parentLaw_;
      }

  function executeLaw(address proposer, bytes memory lawCalldata, bytes32 descriptionHash) {
    address[] tar = new address[](0);
    uint256[] val = new uint256[](0);
    bytes[] cal = new bytes[](0); 
    
    // run the original contract. 
    (address[] memory targets, uint256[] memory values, bytes[] memory calldatas) = Law(_parentLaw).executeLaw(proposer, lawCalldata, descriptionHash);

    // but return empty arrays - no action in taken. 
    return (tar, val, cal); 
  }
}

