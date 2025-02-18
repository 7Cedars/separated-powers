// TODO
// link to nominateMe + PeerVote.
//
// - start election: input: token, startDate + duration. tole to designated + allowedRole are preset. It creates a PeerVote contract + assigns to Dao.
// - end election: read from peerVote Law + nominateMe to assign roles. First deleting roles first assigned. (very close to delegateSelect logic) + delete peerVote law from Dao.
// - NB, gotcha: only assign roles for people that nominated themselves at time of call the PeerElect law!
//

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

pragma solidity 0.8.26;

// protocol
import { Law } from "../../Law.sol";
import { Powers} from "../../Powers.sol";

import { PeerVote } from "../state/PeerVote.sol";

// open zeppelin contracts
import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { ERC1155 } from "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import { Create2 } from "@openzeppelin/contracts/utils/Create2.sol";

contract ElectionCall is Law { 
    uint32 public immutable VOTER_ROLE_ID;
    address public immutable NOMINEES;
    address public immutable TALLY_VOTE;

    constructor(
        string memory name_,
        string memory description_,
        address payable powers_,
        uint32 allowedRole_,
        LawConfig memory config_,
        // bespoke params
        uint32 voterRoleId_,
        address nominees_,
        address tallyVote_
    ) Law(name_, description_, powers_, allowedRole_, config_) {
        inputParams = abi.encode(
            "string Description", // description = a description of the election.
            "uint48 StartVote", // startVote = the start date of the election.
            "uint48 EndVote" // endVote = the end date of the election.
        );
        stateVars = inputParams; // Note: stateVars == inputParams.

        VOTER_ROLE_ID = voterRoleId_;
        NOMINEES = nominees_;
        TALLY_VOTE = tallyVote_;
    }

    /// @notice execute the law.
    /// @param lawCalldata the calldata _without function signature_ to send to the function.
    function simulateLaw(address, /*initiator*/ bytes memory lawCalldata, bytes32 descriptionHash)
        public
        view
        virtual
        override
        returns (address[] memory targets, uint256[] memory values, bytes[] memory calldatas, bytes memory stateChange)
    {
        // step 0: decode the law calldata.
        (string memory description, uint48 startVote, uint48 endVote) =
            abi.decode(lawCalldata, (string, uint48, uint48));

        // step 1: run additional checks: £todo create ERC165 type checks for nominateMe and tallyVote.

        // step 2: calculate address at which grant will be created.
        address peerVoteAddress =
            _getPeerVoteAddress(VOTER_ROLE_ID, NOMINEES, TALLY_VOTE, startVote, endVote, description);

        // step 2: if address is already in use, revert.
        uint256 codeSize = peerVoteAddress.code.length;
        if (codeSize > 0) {
            revert ("Peer vote address already exists.");
        }

        // step 3: create arrays
        targets = new address[](1);
        values = new uint256[](1);
        calldatas = new bytes[](1);
        stateChange = abi.encode("");

        // step 4: fill out arrays with data
        targets[0] = powers;
        calldatas[0] = abi.encodeWithSelector(Powers.adoptLaw.selector, peerVoteAddress);
        stateChange = lawCalldata;

        // step 5: return data
        return (targets, values, calldatas, stateChange);
    }

    function _changeStateVariables(bytes memory stateChange) internal override {
        // step 0: decode data from stateChange
        (string memory description, uint48 startVote, uint48 endVote) =
            abi.decode(stateChange, (string, uint48, uint48));

        // stp 1: deploy new grant
        _deployPeerVote(VOTER_ROLE_ID, NOMINEES, TALLY_VOTE, startVote, endVote, description);
    }

    /**
     * calculate the counterfactual address of this account as it would be returned by createAccount()
     * exact copy from SimpleAccountFactory.sol, except it takes loyaltyProgram as param
     */
    function _getPeerVoteAddress(
        uint32 allowedRole,
        address nominateMe,
        address tallyVote,
        uint48 startVote,
        uint48 endVote,
        string memory description
    ) internal view returns (address) {
        LawConfig memory config;

        address peerReviewAddress = Create2.computeAddress(
            bytes32(keccak256(abi.encodePacked(description))),
            keccak256(
                abi.encodePacked(
                    type(PeerVote).creationCode,
                    abi.encode(
                        // standard params
                        "Election",
                        description,
                        powers,
                        allowedRole,
                        config,
                        // remaining params
                        nominateMe,
                        tallyVote,
                        startVote,
                        endVote
                    )
                )
            )
        );

        return peerReviewAddress;
    }

    function _deployPeerVote(
        uint32 allowedRole,
        address nominateMe,
        address tallyVote,
        uint48 startVote,
        uint48 endVote,
        string memory description
    ) internal {
        PeerVote newPeerVote = new PeerVote{ salt: bytes32(keccak256(abi.encodePacked(description))) }(
            // standard params
            "Election",
            description,
            powers,
            allowedRole,
            config,
            // remaining params
            nominateMe,
            tallyVote,
            startVote,
            endVote
        );
    }
}
