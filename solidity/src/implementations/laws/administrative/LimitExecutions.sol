// // SPDX-License-Identifier: MIT

/// Note natspecs are still WIP. 
///
/// @notice A modifier that limits the number of executions of a law,
/// either by absolute numbers or by a time gap (measured in blocks) between executions. 
/// @param maxExecution the maximum number of executions allowed.
/// @param gapExecutions the minimum number of blocks between executions.

pragma solidity 0.8.26;

import { Law } from "../../../Law.sol";
import { SeparatedPowers } from "../../../SeparatedPowers.sol";
import "@openzeppelin/contracts/utils/ShortStrings.sol";

contract LimitExecutions is Law {
  using ShortStrings for *;

  address private immutable _parentLaw;
  uint256 private immutable _maxExecution;
  uint256 private immutable _gapExecutions;

  constructor(address parentLaw_, uint256 maxExecution_, uint256 gapExecutions_)
        Law(
          Law(parentLaw_).name().toString(), 
          Law(parentLaw_).description(), 
          Law(parentLaw_).separatedPowers()
          )
    {
      if (parentLaw_ == address(0)) {
        revert Law__NoZeroAddress(); 
      } 
      _parentLaw = parentLaw_;
      _maxExecution = maxExecution_;
      _gapExecutions = gapExecutions_;
      }

  function executeLaw(      
    address proposer, 
    bytes memory lawCalldata, 
    bytes32 descriptionHash
    ) external override returns (address[] memory tar, uint256[] memory val, bytes[] memory cal) {
      uint48[] memory executions = Law(_parentLaw).getExecutions(); 
      uint256 numberOfExecutions = executions.length;
      tar = new address[](1);
      val = new uint256[](1);
      cal = new bytes[](1);
      
      // check if the limit has been reached
      if (numberOfExecutions >= _maxExecution) {
        cal[0] = abi.encode("execution limit reached".toShortString());
        return (tar, val, cal);
      }
      // check if the gap to the previous execution is large enough
      if (block.number - executions[numberOfExecutions - 1] < _gapExecutions) {
        cal[0] = abi.encode("execution gap too small".toShortString());
        return (tar, val, cal);
      }

      // if check passed: run execute on the original executive law. 
      (tar, val, cal) = Law(_parentLaw).executeLaw(proposer, lawCalldata, descriptionHash);
      return (tar, val, cal);
  }
}
