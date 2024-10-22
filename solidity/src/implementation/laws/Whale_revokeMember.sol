// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Law} from "../../Law.sol";
import {SeparatedPowers} from "../../SeparatedPowers.sol";
import {ISeparatedPowers} from "../../interfaces/ISeparatedPowers.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @notice This law allows whales to revoke a member. 
 * 
 * @dev This contract is an example of a law that
 * - has access control and needs a proposal to be voted through.
 * - calls several functions, among which {setRole} and {blacklistAccount}. 
 * - at the same time it can also - optionally - be the start of a proposal chain. This happens when the revoked member challenges the decision. See {Public_challengeRevoke}. 
 */
contract Whale_revokeMember is Law {
    error Whale_revokeMember__AccountIsNotMember();
    error Whale_revokeMember__ProposalVoteNotSucceeded(uint256 proposalId);

    address public agCoins; 
    address public agDao;
    uint256 agCoinsReward = 75_000;
    
    constructor(address payable agDao_, address agCoins_) // can take a address parentLaw param. 
      Law(
        "Whale_revokeMember", // = name
        "Whales can revoke membership of members when they think the Member has the broken core DAO requirements for funding accounts.", // = description
        2, // = access whale
        agDao_, // = SeparatedPower.sol derived contract. Core of protocol.   
        50, // = quorum in percent
        66, // = succeedAt in percent
        3_600, // votingPeriod_ in blocks, On arbitrum each block is about .5 (half) a second. This is about half an hour. 
        address(0) // = parent Law 
    ) {
      agDao = agDao_;
      agCoins = agCoins_; 
    } 

    function executeLaw(
      address executioner,
      bytes memory lawCalldata,
      bytes32 descriptionHash
      ) external override returns (
          address[] memory targets,
          uint256[] memory values,
          bytes[] memory calldatas
      ){  

      // step 0: check if caller is the SeparatedPowers protocol.
      if (msg.sender != daoCore) { 
        revert Law__AccessNotAuthorized(msg.sender);  
      }

      // step 1: decode the calldata. Note: lawCalldata can have any format. 
      (address memberToRevoke) = abi.decode(lawCalldata, (address));

      // step 2: retrieve necessary data.  
      uint48 since = SeparatedPowers(payable(agDao)).hasRoleSince(memberToRevoke, 3); // = member role. 
      if (since == 0) {
        revert Whale_revokeMember__AccountIsNotMember();
      }

      // step 3: check if proposal passed vote.
      uint256 proposalId = hashProposal(address(this), lawCalldata, descriptionHash);
      if (SeparatedPowers(payable(agDao)).state(proposalId) != ISeparatedPowers.ProposalState.Succeeded) {
        revert Whale_revokeMember__ProposalVoteNotSucceeded(proposalId);
      }

      // step 4: set proposal to completed. 
      SeparatedPowers(payable(agDao)).complete(lawCalldata, descriptionHash);

      // step 5: creating data to send to the execute function of agDAO's SepearatedPowers contract.
      address[] memory tar = new address[](3);
      uint256[] memory val = new uint256[](3);
      bytes[] memory cal = new bytes[](3);

      // action 1: revoke membership role to applicant. 
      tar[0] = agDao;
      val[0] = 0;
      cal[0] = abi.encodeWithSelector(0xd2ab9970, 3, memberToRevoke, false); // = setRole(uint64 roleId, address account, bool access); 

      // action 2: add account to blacklist 
      tar[1] = agDao;
      val[1] = 0;
      cal[1] = abi.encodeWithSelector(0xe594707e, memberToRevoke, true); // = blacklistAccount(address account, bool isBlacklisted);

      // action 3: give proposer reward.  
      tar[2] = agCoins;
      val[2] = 0;
      cal[2] = abi.encodeWithSelector(IERC20.transfer.selector, msg.sender, agCoinsReward);

      // step 6: return data
      return (tar, val, cal);
    }
}
