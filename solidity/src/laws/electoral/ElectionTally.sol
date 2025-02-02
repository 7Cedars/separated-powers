// SPDX-License-Identifier: MIT

///////////////////////////////////////////////////////////////////////////////
/// This program is free software: you can redistribute it and/or modify    ///
/// it under the terms of the MIT Public License.                           ///
///                                                                         ///
/// This is a Proof Of Concept and is not intended for production use.      ///
/// Tests are incomplete and it contracts have not been audited.            ///
///                                                                         ///
/// It is distributed in the hope that it will be useful and insightful,    ///
/// but WITHOUT ANY WARRANTY; without even the implied warranty of          ///
/// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.                    ///
///////////////////////////////////////////////////////////////////////////////

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
/// @dev The contract is an example of a law that
/// - has does not need a proposal to be voted through. It can be called directly.
/// - has two internal mechanisms: nominate or elect. Which one is run depends on calldata input.
/// - doess not have to role restricted.
/// - translates a simple token based voting system to separated powers.
/// - Note this logic can also be applied with a delegation logic added. Not only taking simple token holdings into account, but also delegated tokens.

pragma solidity 0.8.26;

import { Law } from "../../Law.sol";
import { SeparatedPowers } from "../../SeparatedPowers.sol";
import { PeerVote } from "../state/PeerVote.sol";
import { NominateMe } from "../state/NominateMe.sol";

contract ElectionTally is Law {
    error ElectionTally__PeerVoteContractNotActive(); 
    error ElectionTally__IncorrectNomineesContract();
    error ElectionTally__IncorrectTallyContract();
    error ElectionTally__NoNominees();
    error ElectionTally__ElectionHasNotEnded();
    
    address public immutable NOMINEES;
    uint256 public immutable MAX_ROLE_HOLDERS;
    uint32 public immutable ROLE_ID;
    address[] public electedAccounts;

    constructor(
        string memory name_,
        string memory description_,
        address payable separatedPowers_,
        uint32 allowedRole_,
        LawConfig memory config_,
        address peerVote_,
        address nominees_,
        uint256 maxRoleHolders_,
        uint32 roleId_
    ) Law(name_, description_, separatedPowers_, allowedRole_, config_) {
        MAX_ROLE_HOLDERS = maxRoleHolders_;
        ROLE_ID = roleId_;
        NOMINEES = nominees_;
        inputParams[0] = _dataType("address");
        stateVars[0] = _dataType("address[]");
    }

    function simulateLaw(address, /*initiator*/ bytes memory lawCalldata, bytes32 descriptionHash)
        public
        view
        virtual
        override
        returns (address[] memory targets, uint256[] memory values, bytes[] memory calldatas, bytes memory stateChange)
    {
        // step 0: unpacking calldata
        address peerVote = abi.decode(lawCalldata, (address));

        // step 1: run additional checks 
        if (!SeparatedPowers(separatedPowers).getActiveLaw(peerVote)) {
          revert ElectionTally__PeerVoteContractNotActive();
        }
        if (NominateMe(NOMINEES).nomineesCount() == 0) {
            revert ElectionTally__NoNominees();
        }
        if (PeerVote(peerVote).endVote() < block.timestamp) {
            revert ElectionTally__ElectionHasNotEnded();
        }
        if (PeerVote(peerVote).NOMINEES() != NOMINEES) {
            revert ElectionTally__IncorrectNomineesContract();
        } 
        if (PeerVote(peerVote).TALLY() != address(this)) {
            revert ElectionTally__IncorrectTallyContract();
        } 
 
        // step 2: setting up array for revoking & assigning roles.
        address[] memory accountElects;
        uint256 numberNominees = NominateMe(NOMINEES).nomineesCount();
        uint256 numberRevokees = electedAccounts.length;
        uint256 arrayLength =
            numberNominees < MAX_ROLE_HOLDERS ? numberRevokees + numberNominees : numberRevokees + MAX_ROLE_HOLDERS;

        targets = new address[](arrayLength);
        values = new uint256[](arrayLength);
        calldatas = new bytes[](arrayLength);
        accountElects = new address[](numberNominees < MAX_ROLE_HOLDERS ? numberNominees : MAX_ROLE_HOLDERS);

        for (uint256 i; i < arrayLength; i++) {
            targets[i] = separatedPowers;
        }

        // step 2: calls to revoke roles of previously elected accounts.
        for (uint256 i; i < numberRevokees; i++) {
            calldatas[i] = abi.encodeWithSelector(SeparatedPowers.revokeRole.selector, ROLE_ID, electedAccounts[i]);
        }

        // step 3a: calls to add nominees if fewer than MAX_ROLE_HOLDERS
        if (numberNominees < MAX_ROLE_HOLDERS) {
            for (uint256 i; i < numberNominees; i++) {
                address accountElect = NominateMe(NOMINEES).nomineesSorted(i);
                calldatas[i + numberRevokees] =
                    abi.encodeWithSelector(SeparatedPowers.assignRole.selector, ROLE_ID, accountElect);
                accountElects[i] = accountElect;
            }

        // step 3b: calls to add nominees if more than MAX_ROLE_HOLDERS
        } else {
            // retrieve votes for delegates from PeerVote contract.
            uint256[] memory _votes = new uint256[](numberNominees);
            address[] memory _nominees = new address[](numberNominees);
            for (uint256 i; i < numberNominees; i++) {
                _nominees[i] = NominateMe(NOMINEES).nomineesSorted(i);
                _votes[i] = PeerVote(peerVote).votes(_nominees[i]);
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
                    if (j != i && _votes[j] >= _votes[i]) {
                        rank++;
                        if (rank > MAX_ROLE_HOLDERS) break; // b: do not need to know rank beyond MAX_ROLE_HOLDERS threshold.
                    }
                }
                // c: assigning role if rank is less than MAX_ROLE_HOLDERS.
                if (rank < MAX_ROLE_HOLDERS && index < arrayLength - numberRevokees) {
                    calldatas[index + numberRevokees] =
                        abi.encodeWithSelector(SeparatedPowers.assignRole.selector, ROLE_ID, _nominees[i]);
                    accountElects[index] = _nominees[i];
                    index++;
                }
            }
        }
        stateChange = abi.encode(accountElects);
    }

    function _changeStateVariables(bytes memory stateChange) internal override {
      (address[] memory elected) = abi.decode(stateChange, (address[]));
      delete electedAccounts; 
      electedAccounts = elected;
    }
}
