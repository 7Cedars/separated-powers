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

// note that natspecs are wip.

/// @notice This contract ...
///
pragma solidity 0.8.26;

import { Law } from "../../Law.sol";
import { NominateMe } from "./NominateMe.sol";

contract PeerVote is Law {
    error PeerVote__NotNominee();
    error PeerVote__AlreadyVoted();
    error PeerVote__ElectionNotOpen();

    // the state vars that this law manages: community strings.
    mapping (address => bool) public hasVoted;
    mapping (address => uint256) public votes;
    uint48 public immutable startVote;
    uint48 public immutable endVote;
    address public immutable NOMINEES; 
    address public immutable TALLY;

    event PeerVote__VoteCast(address voter);

    constructor(
        string memory name_,
        string memory description_,
        address payable separatedPowers_,
        uint32 allowedRole_,
        LawConfig memory config_, 
        address nominateMe, // the nominateMe contract linked to this contract. 
        address tallyVote, // the tallyVote contract linked to this contract. 
        uint48 startVote_,
        uint48 endVote_
    ) Law(name_, description_, separatedPowers_, allowedRole_, config_) {
        NOMINEES = nominateMe;
        startVote = startVote_;
        endVote = endVote_;

        inputParams[0] = _dataType("address");
        stateVars[0] = _dataType("address"); // address that is voted on 
        stateVars[1] = _dataType("address"); // address that has voted
    }

    function simulateLaw(address initiator,  bytes memory lawCalldata, bytes32 descriptionHash)
        public
        view
        override
        returns (address[] memory tar, uint256[] memory val, bytes[] memory cal, bytes memory stateChange)
    {
        // step 0: run additional checks
        if (block.timestamp < startVote || block.timestamp > endVote) {
            revert PeerVote__ElectionNotOpen();
        }
        if (hasVoted[initiator]) {
            revert PeerVote__AlreadyVoted();
        }

        // step 1: decode law calldata
        (address vote) = abi.decode(lawCalldata, (address));

        // step 2: return data
        tar = new address[](1);
        val = new uint256[](1);
        cal = new bytes[](1);
        tar[0] = address(1); // signals that separatedPowers should not execute anything else.

        stateChange = abi.encode(vote, initiator);
        return (tar, val, cal, lawCalldata);
    }

    function _changeStateVariables(bytes memory stateChange) internal override {
        (address nominee, address initiator) = abi.decode(stateChange, (address, address));
        uint48 since = NominateMe(NOMINEES).nominees(nominee);

        // step 3: save vote
        if (since == 0) {
            revert PeerVote__NotNominee();
        }

        hasVoted[initiator] = true;
        votes[nominee] = votes[nominee]++;
        emit PeerVote__VoteCast(initiator);
    }
}
