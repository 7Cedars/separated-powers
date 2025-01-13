// SPDX-License-Identifier: MIT

// note that natspecs are wip.

/// @notice This contract assigns accounts to roles by the tokens that have been delegated to them.
/// - At construction time, the following is set:
///    - the maximum amount of accounts that can be assigned the role 
///    - the roleId to be assigned
///    - the ERC20 token address to be assessed.
///    - the address from which to retrieve nominees.
///
/// - The logic:
///    - The calldata holds the accounts that need to be _revoked_ from the role prior to the election. 
///    - If fewer than N accounts are nominated, all will be assigne roleId R.
///    - If more than N accounts are nominated, the accounts that hold most ERC20 T will be assigned roleId R.
/// 
/// 
///
/// @dev The contract is an example of a law that
/// - has does not need a proposal to be voted through. It can be called directly.
/// - has two internal mechanisms: nominate or elect. Which one is run depends on calldata input.
/// - doess not have to role restricted.
/// - translates a simple token based voting system to separated powers.
/// - Note this logic can also be applied with a delegation logic added. Not only taking simple token holdings into account, but also delegated tokens.

pragma solidity 0.8.26;

import { Law } from "../../Law.sol";
import { SeparatedPowers } from "../../SeparatedPowers.sol";
import { ERC20Votes } from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol";
import { NominateMe } from "./NominateMe.sol";
import "@openzeppelin/contracts/utils/ShortStrings.sol";

/// ONLY FOR TESTING PURPOSES
import "forge-std/Test.sol";

contract DelegateSelect is Law {
    using ShortStrings for *;

    address public immutable ERC_20_VOTE_TOKEN;
    uint256 public immutable MAX_ROLE_HOLDERS;
    uint32 public immutable ROLE_ID;
    address public immutable NOMINEES;

    constructor(
        string memory name_,
        string memory description_,
        address payable separatedPowers_,
        uint32 allowedRole_,
        LawConfig memory config_,
        address payable erc20Token_,
        address nominees_,
        uint256 maxRoleHolders_,
        uint32 roleId_
    ) Law(name_, description_, separatedPowers_, allowedRole_, config_) {
        ERC_20_VOTE_TOKEN = erc20Token_; // £todo interface should be checked here.
        MAX_ROLE_HOLDERS = maxRoleHolders_;
        ROLE_ID = roleId_;
        NOMINEES = nominees_;
        inputParams[0] = dataType("address[]");
    }

    function simulateLaw(address, /*initiator*/ bytes memory lawCalldata, bytes32 descriptionHash)
        public view
        override
        returns (address[] memory targets, uint256[] memory values, bytes[] memory calldatas, bytes memory stateChange)
    {
        
        // step 0: retrieve accounts from calldata that need to be revoked from role prior to election. 
        (address[] memory revokees) = abi.decode(lawCalldata, (address[]));
        
        // step 1: setting up array for revoking & assigning roles.
        uint256 numberNominees = NominateMe(NOMINEES).nomineesCount();
        uint256 numberRevokees = revokees.length;
        uint256 arrayLength =
            numberNominees < MAX_ROLE_HOLDERS ? numberRevokees + numberNominees : numberRevokees + MAX_ROLE_HOLDERS;

        targets = new address[](arrayLength);
        values = new uint256[](arrayLength);
        calldatas = new bytes[](arrayLength);

        for (uint256 i; i < arrayLength; i++) {
            targets[i] = separatedPowers;
        }

        // step 2: calls to revoke roles of previously elected accounts & delete array that stores elected accounts.
        for (uint256 i; i < numberRevokees; i++) {
            calldatas[i] = abi.encodeWithSelector(SeparatedPowers.revokeRole.selector, ROLE_ID, revokees[i]);
        }

        // step 3a: calls to add nominees if fewer than MAX_ROLE_HOLDERS
        if (numberNominees < MAX_ROLE_HOLDERS) {
            for (uint256 i; i < numberNominees; i++) {
                address accountElect = NominateMe(NOMINEES).nomineesSorted(i);
                calldatas[i + numberRevokees] =
                    abi.encodeWithSelector(SeparatedPowers.assignRole.selector, ROLE_ID, accountElect);
            }
            // step 3b: calls to add nominees if more than MAX_ROLE_HOLDERS
        } else {
            // retrieve balances of delegated votes of nominees.
            uint256[] memory _votes = new uint256[](numberNominees);
            address[] memory _nominees = new address[](numberNominees);
            for (uint256 i; i < numberNominees; i++) {
                _nominees[i] = NominateMe(NOMINEES).nomineesSorted(i);
                _votes[i] = ERC20Votes(ERC_20_VOTE_TOKEN).getVotes(_nominees[i]);
            }
            // £todo: check what will happen if people have the same amount of delegated votes.
            // note how the following mechanism works:
            // a. we add 1 to each nominee's position, if we found a account that holds more tokens.
            // b. if the position is greater than MAX_ROLE_HOLDERS, we break. (it means there are more accounts that have more tokens than MAX_ROLE_HOLDERS)
            // c. if the position is less than MAX_ROLE_HOLDERS, we assign the roles.
            uint256 index;
            for (uint256 i; i < numberNominees; i++) {
                uint256 rank;
                // a: loop to assess ranking.
                for (uint256 j; j < numberNominees; j++) {
                    if (_votes[j] > _votes[i]) {
                        rank++;
                        if (rank > MAX_ROLE_HOLDERS) break; // b: do not need to know rank beyond MAX_ROLE_HOLDERS threshold.
                    }
                }
                // c: assigning role if rank is less than MAX_ROLE_HOLDERS.
                if (rank < MAX_ROLE_HOLDERS && index < arrayLength - numberRevokees) {
                    calldatas[index + numberRevokees] =
                        abi.encodeWithSelector(SeparatedPowers.assignRole.selector, ROLE_ID, _nominees[i]);
                    index++;
                }
            }
        }
    }
}
