// SPDX-License-Identifier: MIT

// note that natspecs are wip.

/// @notice This contract assigns accounts to roles by the tokens that have been delegated to them.
/// - At construction time, the following is set:
///    - the amount of role holders {N}
///    - the roleId {R} to be assigned
///    - the ERC20 token {T} address to be assessed.
///
/// - The contract is meant to be open (using PUBLIC_ROLE at SeperatedPowers protocol), but can also be role restricted.
///    - anyone can nominate themselves for the role.
///    - anyone can call the law to have it (re)assign accounts to the law.
///
/// - The logic:
///    - If fewer than N accounts are nominated, all will be assigne roleId R.
///    - If more than N accounts are nominated, the accounts that hold most ERC20 T will be assigned roleId R.
///
/// @dev The contract is an example of a law that
/// - has does not need a proposal to be voted through. It can be called directly.
/// - has two internal mechanisms: nominate or elect. Which one is run depends on calldata input.
/// - doess not have to role restricted.
/// - translates a simple token based voting system to separated powers.
/// - Note this logic can also be applied with a delegation logic added. Not only taking simple token holdings into account, but also delegated tokens.

pragma solidity 0.8.26;

import { Law } from "../../../Law.sol";
import { SeparatedPowers } from "../../../SeparatedPowers.sol";
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

    mapping(address => uint48) private _elected;
    address[] private _electedSorted;
    uint48 private _lastElection;

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
        params = new bytes4[](0); 
    }

    function executeLaw(address /*initiator*/, bytes memory lawCalldata, bytes32 descriptionHash)
        public
        override
        returns (address[] memory targets, uint256[] memory values, bytes[] memory calldatas)
    {
        // do optional checks. 
        super.executeLaw(address(0), lawCalldata, descriptionHash);

        // step 1: setting up array for revoking & assigning roles. 
        console.log("waypoint 1"); 
        uint256 numberNominees = NominateMe(NOMINEES).nomineesCount();
        uint256 numberElected = _electedSorted.length;
        uint256 arrayLength = numberNominees < MAX_ROLE_HOLDERS ? 
            numberElected + numberNominees 
            : 
            numberElected + MAX_ROLE_HOLDERS; 

        targets = new address[](arrayLength);
        values = new uint256[](arrayLength);
        calldatas = new bytes[](arrayLength);
        
        console.log("waypoint 2"); 
        for (uint256 i; i < arrayLength; i++) { targets[i] = separatedPowers; } 

        console.log("waypoint 3"); 
        // step 2: calls to revoke roles of previously elected accounts & delete array that stores elected accounts. 
        for (uint256 i; i < numberElected; i++) {
            uint256 index = (numberElected - i) - 1; // we work backwards through the list. 
            calldatas[i] = abi.encodeWithSelector(SeparatedPowers.revokeRole.selector, ROLE_ID, _electedSorted[index]);
            _elected[_electedSorted[index]] = uint48(0);
            _electedSorted.pop();
        }
        
        console.log("waypoint 4"); 
        // step 3a: calls to add nominees if fewer than MAX_ROLE_HOLDERS
        if (numberNominees < MAX_ROLE_HOLDERS) {
            for (uint256 i; i < numberNominees; i++) {
                address accountElect = NominateMe(NOMINEES).nomineesSorted(i);   
                calldatas[i + numberElected] = abi.encodeWithSelector(SeparatedPowers.assignRole.selector, ROLE_ID, accountElect);
                _elected[accountElect] = uint48(block.timestamp);
                _electedSorted.push(accountElect);
            }
        // step 3b: calls to add nominees if more than MAX_ROLE_HOLDERS
        } else {
            console.log("waypoint 5"); 
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
            console.log("waypoint 6"); 
            for (uint256 i; i < numberNominees; i++) {
                uint256 rank; 
                // a: loop to assess ranking. 
                for (uint256 j; j < numberNominees; j++) {
                    if (_votes[j] > _votes[i]) {
                        rank++;
                        if (rank > MAX_ROLE_HOLDERS) { break; } // b: do not need to know rank beyond MAX_ROLE_HOLDERS threshold. 
                    } 
                } 
                console.log("waypoint 7"); 
                // c: assigning role if rank is less than MAX_ROLE_HOLDERS.
                if (rank < MAX_ROLE_HOLDERS && index < arrayLength - numberElected) {
                    console.log("waypoint 7a"); 
                    calldatas[index + numberElected] = abi.encodeWithSelector(SeparatedPowers.assignRole.selector, ROLE_ID, _nominees[i]); 
                    console.log("waypoint 7b");
                    _elected[_nominees[i]] = uint48(block.timestamp);
                    console.log("waypoint 7c");
                    _electedSorted.push(_nominees[i]);
                    index++;
                }
            }
        }
    }
}


