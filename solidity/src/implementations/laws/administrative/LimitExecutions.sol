// // SPDX-License-Identifier: MIT

// /// Note natspecs are still WIP. 
// ///
// /// @notice A modifier that limits the number of executions of a law,
// /// either by absolute numbers or by a time gap (measured in blocks) between executions. 
// /// @param maxExecution the maximum number of executions allowed.
// /// @param gapExecutions the minimum number of blocks between executions.

// pragma solidity 0.8.26;

// import { Law } from "../../../Law.sol";
// import { SeparatedPowers } from "../../../SeparatedPowers.sol";

// contract LimitExecutions is Law {
//   error LimitExecutions__NoZeroAddress();

//   address private immutable _parentLaw;
//   uint256 private immutable _maxExecution;
//   uint256 private immutable _gapExecutions;

//   ShortString public immutable name; // name of the law
//   address public separatedPowers; // the address of the core governance protocol
//   string public description;
//   uint48[] public executions; // log of bl

//   constructor(address parentLaw_, uint256 maxExecution_, uint256 gapExecutions_)
//         Law(
//           Law(parentLaw_).name(), 
//           Law(parentLaw_).description(), 
//           Law(parentLaw_).separatedPowers()
//           )
//     {
//       if (parentLaw_ == address(0)) {
//         revert LimitExecutions__NoZeroAddress(); 
//       } 
//       _parentLaw = parentLaw_;
//       _maxExecution = maxExecution_;
//       _gapExecutions = gapExecutions_;
//       }

//   function executeLaw(address proposer, bytes memory lawCalldata, bytes32 descriptionHash) {
//     uint48[] memory executions = Law(_parentLaw).getExecutions(); 
//     uint256 numberOfExecutions = executions.length;
    
//     // check if the limit has been reached
//     if (numberOfExecutions >= maxExecution) {
//         revert LimitExecutions__ExecutionLimitReached();
//     }
//     // check if the gap to the previous execution is large enough
//     if (block.number - executions[numberOfExecutions - 1] < gapExecutions) {
//         revert LimitExecutions__ExecutionGapTooSmall();
//     }  

//     // if check passed: run execute on the original executive law. 
//     return (
//       Law(_parentLaw).executeLaw(proposer, lawCalldata, descriptionHash)
//     );
//   }
// }
