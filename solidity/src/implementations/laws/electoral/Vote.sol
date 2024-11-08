// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import { Law } from "../../../Law.sol";
import { SeparatedPowers } from "../../../SeparatedPowers.sol";
import { SeparatedPowersTypes } from "../../../interfaces/SeparatedPowersTypes.sol";
import { ERC1155 } from "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";

/**
 * @notice This contract assigns or revokes one account to a role conditional on a vote being passed. 
 * - At construction time, the following is set: 
 *    - the role Id that the contract will be assigned or revoked.  
 *
 * - The contract is meant to be restricted by a specific role, allowing a council of roleId X to select accounts to a roleId X, Y or Z. 
 *    - note: no nominate logic.
 *
 * - The logic: 
 *    - If the vote passes, the account will be assigned the roleId.
 *
 * @dev The contract is an example of a law that
 * - can be used by a council of roleId X to select accounts to a roleId X, Y or Z. 
 */
contract Vote is Law {
    error Vote__AccountAlreadyHasRole();
    error Vote__AccountDoesNotHaveRole();
    error Vote__VoteNotSucceeded(uint256 proposalId);

    uint32 private immutable ROLE_ID;

    event Vote__AccountAssigned(uint32 indexed roleId, address indexed account);
    event Vote__AccountRevoked(uint32 indexed roleId, address indexed account);

    // address[] private dependencies_ = new address[](0);

    constructor(
        string memory name_, 
        string memory description_, 
        uint32 roleId_  
    )
        Law(name_, description_, new address[](0))
    {
        ROLE_ID = roleId_;
    }

    function executeLaw(address executioner, bytes memory lawCalldata, bytes32 descriptionHash)
        external
        override
        returns (address[] memory targets, uint256[] memory values, bytes[] memory calldatas)
    {
        // step 1: decode the calldata.
        (address account, bool revoke) = abi.decode(lawCalldata, (address, bool));

        // step 2: check if proposal passed vote.
        uint256 proposalId = _hashProposal(address(this), lawCalldata, descriptionHash);
        if (SeparatedPowers(payable(separatedPowers)).state(proposalId) != SeparatedPowersTypes.ProposalState.Succeeded) {
            revert Vote__VoteNotSucceeded(proposalId);
        }

        // step 3: create & send return calldata conditional if it is an assign or revoke action.
        address[] memory tar = new address[](1);
        uint256[] memory val = new uint256[](1);
        bytes[] memory cal = new bytes[](1);

        if (revoke) {
          if (SeparatedPowers(payable(separatedPowers)).hasRoleSince(account, ROLE_ID) == 0) {
            revert Vote__AccountDoesNotHaveRole(); 
          }

          tar[0] = separatedPowers;
          val[0] = 0;
          cal[0] = abi.encodeWithSelector(0x22ec1861, ROLE_ID, account); // selector = revokeRole
          return (tar, val, cal);

        } else {
          if (SeparatedPowers(payable(separatedPowers)).hasRoleSince(account, ROLE_ID) != 0) {
            revert Vote__AccountAlreadyHasRole(); 
          }
          tar[0] = separatedPowers;
          val[0] = 0;
          cal[0] = abi.encodeWithSelector(0x446b340f, ROLE_ID, account); // selector = assignRole
          return (tar, val, cal);

        }
        
    }
}
