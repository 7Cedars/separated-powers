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
import "@openzeppelin/contracts/utils/ShortStrings.sol";

/// ONLY FOR TESTING PURPOSES 
import "forge-std/Test.sol";

contract DelegateSelect is Law {
    using ShortStrings for *;

    error DelegateSelect__NomineeAlreadyNominated();
    error DelegateSelect__NomineeNotNominated();

    address private immutable ERC_20_VOTE_TOKEN;
    uint256 private immutable MAX_ROLE_HOLDERS;
    uint32 private immutable ROLE_ID;

    mapping(address => uint48) private _nominees;
    address[] private _nomineesSorted;
    mapping(address => uint48) private _elected;
    address[] private _electedSorted;
    uint48 private _lastElection;

    event DelegateSelect__NominationReceived(address indexed nominee);
    event DelegateSelect__NominationRevoked(address indexed nominee);

    constructor(
        string memory name_,
        string memory description_,
        address payable separatedPowers_,
        address payable erc20Token_,
        uint256 maxRoleHolders_,
        uint32 roleId_
    ) Law(name_, description_, separatedPowers_) {
        ERC_20_VOTE_TOKEN = erc20Token_; // £todo interface should be checked here. 
        MAX_ROLE_HOLDERS = maxRoleHolders_;
        ROLE_ID = roleId_;
        params = [dataType("bool"), dataType("bool")]; 
    }

    function executeLaw(address initiator, bytes memory lawCalldata, bytes32 /* descriptionHash */ )
        public
        override
        returns (address[] memory targets, uint256[] memory values, bytes[] memory calldatas)
    {
        // decode the calldata.
        (bool nominateMe, bool assignRoles) = abi.decode(lawCalldata, (bool, bool));

        // nominating // 
        if (nominateMe && !assignRoles) {
            if (_nominees[initiator] != 0) {
                revert DelegateSelect__NomineeAlreadyNominated();
            }
            _nominees[initiator] = uint48(block.timestamp);
            _nomineesSorted.push(initiator);

            emit DelegateSelect__NominationReceived(initiator);
        }

        // revoke nomination // 
        if (!nominateMe && !assignRoles) {
            if (_nominees[initiator] == 0) {
                revert DelegateSelect__NomineeNotNominated();
            }

            _nominees[initiator] = 0;
            for (uint256 i; i < _nomineesSorted.length; i++) {
                if (_nomineesSorted[i] == initiator) {
                    _nomineesSorted[i] = _nomineesSorted[_nomineesSorted.length - 1];
                    _nomineesSorted.pop();
                    break;
                }
            }
            emit DelegateSelect__NominationRevoked(initiator);
        }

        // electing roles // 
        if (assignRoles) {
            // step 1: setting up array for revoking & assigning roles. 
            uint256 numberNominees = _nomineesSorted.length;
            uint256 numberElected = _electedSorted.length;
            uint256 arrayLength = numberNominees < MAX_ROLE_HOLDERS ? 
                numberElected + numberNominees 
                : 
                numberElected + MAX_ROLE_HOLDERS;

            address[] memory tar = new address[](arrayLength);
            uint256[] memory val = new uint256[](arrayLength);
            bytes[] memory cal = new bytes[](arrayLength);
            for (uint256 i; i < arrayLength; i++) { tar[i] = separatedPowers; } 

            // step 2: calls to revoke roles of previously elected accounts & delete array that stores elected accounts. 
            for (uint256 i = 0; i < numberElected; i++) {
                cal[i] = abi.encodeWithSelector(SeparatedPowers.setRole.selector, ROLE_ID, _nomineesSorted[i], false);
                _elected[_nomineesSorted[i]] = uint48(0);
                _electedSorted.pop();
            }

            // step 3a: calls to add nominees if fewer than MAX_ROLE_HOLDERS
            if (numberNominees < MAX_ROLE_HOLDERS) {
               for (uint256 i; i < numberNominees; i++) {
                    cal[i + numberElected] = abi.encodeWithSelector(SeparatedPowers.setRole.selector, ROLE_ID, _nomineesSorted[i], true);
                    _elected[_nomineesSorted[i]] = uint48(block.timestamp);
                    _electedSorted.push(_nomineesSorted[i]);
                }
                return (tar, val, cal);
            // step 3b: calls to add nominees if more than MAX_ROLE_HOLDERS
            } else {
                // retrieve balances of delegated votes of nominees. 
                uint256[] memory _votes = new uint256[](numberNominees);
                for (uint256 i; i < numberNominees; i++) {
                    _votes[i] = ERC20Votes(ERC_20_VOTE_TOKEN).getVotes(_nomineesSorted[i]);
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
                            if (rank > MAX_ROLE_HOLDERS) { break; } // b: do not need to know rank beyond MAX_ROLE_HOLDERS threshold. 
                        } 
                    } 
                    // c: assigning role if rank is less than MAX_ROLE_HOLDERS.
                    if (rank < MAX_ROLE_HOLDERS) {
                        cal[index + numberElected] = abi.encodeWithSelector(SeparatedPowers.setRole.selector, ROLE_ID, _nomineesSorted[i], true); 
                        _elected[_nomineesSorted[i]] = uint48(block.timestamp);
                        _electedSorted.push(_nomineesSorted[i]);
                        index++;
                    }
                }
                return (tar, val, cal);
            }
        }
    }
}


