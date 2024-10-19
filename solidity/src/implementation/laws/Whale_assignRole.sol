// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Law} from "../../Law.sol";
import {SeparatedPowers} from "../../SeparatedPowers.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/**
 * @notice This contract allows whales to assign or revoke whale roles, on the basis of the agCoins an account holds.
 * If an account holds fewer than 1_000_000 agCoins, it will be deselected. If it owns 1_000_000 or more tokens, it will be selected.   
 * 
 * @dev The contract is an example of a law that 
 * - has does not need a proposal to be voted through. It can be called directly. 
 * - is role restricted. 
 * - links token holdings to role selection. There are many ways to do this. This law is but one example. 
 */
contract Whale_assignRole is Law {
    error Whale_assignRole__Error();
    error Senior_assignRole__TooManySeniors();

    address public agCoins; 
    address public agDao;
    uint256 amountTokensForWhaleRole = 1_000_000;
    uint256 agCoinsReward = 75_000;
    uint64 constant WHALE_ROLE = 2;
    
    constructor(address payable agDao_, address agCoins_) // can take a address parentLaw param. 
      Law(
        "Whale_assignRole", // = name
        "Whales can assign or revoke whale roles, according to the agCoins an account hold. If a change has been applied, the executioner will receive a reward.", // = description
        2, // = access Whale
        agDao_, // = SeparatedPower.sol derived contract. Core of protocol.   
        0, // = no quorum, means no vote. 
        0, // = succeedAt in percent
        0, // votingPeriod_ in blocks 
        address(0) // = parent Law 
    ) {
      agDao = agDao_;
      agCoins = agCoins_; 
    } 

    function executeLaw(
      bytes memory lawCalldata
      ) external override returns (
          address[] memory targets,
          uint256[] memory values,
          bytes[] memory calldatas
      ){  

      // step 0: check if caller has correct access control.
      if (SeparatedPowers(payable(agDao)).hasRoleSince(msg.sender, accessRole) == 0) {
        revert Law__AccessNotAuthorized(msg.sender);
      }

      // step 1: decode the calldata. Note: lawCalldata can have any format. 
      (address accountToAssess, ) = abi.decode(lawCalldata, (address, bytes32));

      // step 2: retrieve necessary data.  
      uint256 balanceAccount = ERC20(agCoins).balanceOf(accountToAssess);
      uint48 since = SeparatedPowers(payable(agDao)).hasRoleSince(accountToAssess, accessRole);

      // step 3: Note that check for proposal to have passed & setting proposal as completed is missing. This action can be executed without setting a proposal or passing a vote.  

      // step 4: set data structure for call to execute function.
      // action 1: conditional assign or revoke role. 
      targets[0] = agDao;
      values[0] = 0;

      // action 2: give reward to proposer of proposal. 
      targets[1] = agCoins;
      values[1] = 0;
      calldatas[1] = abi.encodeWithSelector(IERC20.transfer.selector, msg.sender, agCoinsReward);

      //step 5: conditionally set data. 
      // 5a: option 1: if accountToCheck is a whale but has fewer tokens than the minimum. Role is revoked. 
      if (balanceAccount < amountTokensForWhaleRole && since != 0) {
        calldatas[0] = abi.encodeWithSelector(0xd2ab9970, WHALE_ROLE, accountToAssess, false); // = setRole(uint64 roleId, address account, bool access); 
      } 
      // 5b: option 2: if accountToCheck is not a whale but has more tokens than the minimum. Role is assigned. 
      else if (balanceAccount >= amountTokensForWhaleRole && since == 0) {
        calldatas[0] = abi.encodeWithSelector(0xd2ab9970, WHALE_ROLE, accountToAssess, true); // = setRole(uint64 roleId, address account, bool access); 
      } else {
        revert Whale_assignRole__Error();
      }
      
      // step 6: return data
      return (targets, values, calldatas);
  }
}
