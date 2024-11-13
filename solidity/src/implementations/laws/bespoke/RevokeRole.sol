// SPDX-License-Identifier: MIT

/// Note natspecs are still WIP. 
///
/// @notice A modifier that sets a function to be conditioned by a proposal vote.
/// This modifier ensures that the function is only callable if a proposal has passed a vote.
pragma solidity 0.8.26;

import { Law } from "../../../Law.sol";
import { SeparatedPowers } from "../../../SeparatedPowers.sol";
import "@openzeppelin/contracts/utils/ShortStrings.sol";

contract RevokeRole is Law {
  using ShortStrings for *;

  bool private immutable _execute;

  constructor(string memory name_, string memory description_, address separatedPowers_ ) 
        Law(name_, description_, separatedPowers_)
    { }

  function executeLaw(      
    address proposer, 
    bytes memory lawCalldata, 
    bytes32 descriptionHash
    ) external override returns (address[] memory tar, uint256[] memory val, bytes[] memory cal) {

  }
}