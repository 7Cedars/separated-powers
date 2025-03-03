// todo.
// link to NominateMe
// save cast vote on address.
// log if address has voted.
// disallow repeated votes.

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

/// @notice Natspecs are tbi. 
///
/// @author 7Cedars

/// @notice This contract ...
///
pragma solidity 0.8.26;

import { Law } from "../../Law.sol";
import { NominateMe } from "./NominateMe.sol";

contract ElectionVotes is Law { 
    // the state vars that this law manages: community strings.
    mapping(address => bool) public hasVoted;
    mapping(address => uint256) public votes;
    uint48 public immutable startVote;
    uint48 public immutable endVote;

    event ElectionVotes__VoteCast(address voter);

    constructor(
        string memory name_,
        string memory description_,
        address payable powers_,
        uint32 allowedRole_,
        LawConfig memory config_,
        // bespoke params
        uint48 startVote_,
        uint48 endVote_
    ) Law(name_, description_, powers_, allowedRole_, config_) {
        startVote = startVote_;
        endVote = endVote_;

        inputParams = abi.encode(
            "address VoteFor"
            );
        stateVars = abi.encode(
            "address VoteFor", 
            "address VoteFrom"
            );
    }

    function simulateLaw(address initiator, bytes memory lawCalldata, bytes32 descriptionHash)
        public
        view
        override
        returns (address[] memory tar, uint256[] memory val, bytes[] memory cal, bytes memory stateChange)
    {
        // step 0: run additional checks
        if (block.number < startVote || block.number > endVote) {
            revert ("Election not open.");
        }
        if (hasVoted[initiator]) {
            revert ("Already voted.");
        }

        // step 1: decode law calldata
        (address vote) = abi.decode(lawCalldata, (address));

        // step 2: return data
        tar = new address[](1);
        val = new uint256[](1);
        cal = new bytes[](1);
        tar[0] = address(1); // signals that powers should not execute anything else.

        stateChange = abi.encode(vote, initiator);
        return (tar, val, cal, stateChange);
    }

    function _changeStateVariables(bytes memory stateChange) internal override {
        (address nominee, address initiator) = abi.decode(stateChange, (address, address));
        uint48 since = NominateMe(config.readStateFrom).nominees(nominee);

        // step 3: save vote
        if (since == 0) {
            revert ("Not a nominee.");
        }

        hasVoted[initiator] = true;
        votes[nominee]++;
        emit ElectionVotes__VoteCast(initiator);
    }

    
}
