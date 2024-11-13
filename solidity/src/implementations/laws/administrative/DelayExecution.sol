// SPDX-License-Identifier: MIT

/// @notice A modifier that makes the execution of a law conditional on a deadline having passed.
/// @param blocks the number of blocks to wait before executing the law.
/// 
/// @dev the delay is calculated from the moment the vote related to the law is closed.
/// Note that this means that {DelayDxecutions} only works in combination with the {Vote} modifier. 

pragma solidity 0.8.26;

import { Law } from "../../../Law.sol";
import { SeparatedPowers } from "../../../SeparatedPowers.sol";

contract NeedsVote is Law {
  error NeedsVote__NoZeroAddress();

  uint256 private immutable _blocksDelay;

  ShortString public immutable name; // name of the law
  address public separatedPowers; // the address of the core governance protocol
  string public description;
  uint48[] public executions; // log of bl

  constructor(address parentLaw_, uint256 blocksDelay_)
        Law(
          Law(parentLaw_).name(), 
          Law(parentLaw_).description(), 
          Law(parentLaw_).separatedPowers()          
          )
    {
      if (parentLaw_ == address(0)) {
        revert NeedsVote__NoZeroAddress();
      }
      _parentLaw = parentLaw_;
      _blocksDelay = blocksDelay_;
      }

    function executeLaw(address proposer, bytes memory lawCalldata, bytes32 descriptionHash) {
        uint256 proposalId = _hashProposal(proposer, address(this), lawCalldata, descriptionHash);
        uint256 currentBlock = block.number;
        uint256 deadline = SeparatedPowers(payable(separatedPowers)).proposalDeadline(proposalId);

        address[] tar = new address[](1);
        uint256[] val = new uint256[](1);
        bytes[] cal = new bytes[](1);
        
        if (deadline == 0) {
            cal[0] = abi.encode("no deadline set".toShortString()); 
            return (tar, val, cal);
        }

        if (deadline < currentBlock) {
            cal[0] = abi.encode("deadline not passed".toShortString());
            return (tar, val, cal);        
        }

        // if checks pass, give execute data. 
        address executiveLaw = Law(_parentLaw).parentLaw();
        (address[] tar, uint256[] val, bytes[] cal) = Law(executiveLaw).executeLaw(proposer, lawCalldata, descriptionHash); 
        return (tar, val, cal);
    }
}