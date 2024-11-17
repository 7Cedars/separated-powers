// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import { DaoMock } from "./DaoMock.sol";
import { Law } from "../../src/Law.sol";
import { TokensSelect } from "../../src/implementations/laws/electoral/TokensSelect.sol";
import { DirectSelect } from "../../src/implementations/laws/electoral/DirectSelect.sol";
import { ProposalOnly } from "../../src/implementations/laws/executive/ProposalOnly.sol";
import { VoteOnProposedAction } from "../../src/implementations/laws/bespoke/VoteOnProposedAction.sol";

contract ConstitutionMock {
    uint32 constant NUMBER_OF_LAWS = 4;

    function initiate(address payable dao_, address payable mock1155_)
        external
        returns (
            address[] memory laws,
            uint32[] memory allowedRoles,
            uint8[] memory quorums,
            uint8[] memory succeedAts,
            uint32[] memory votingPeriods
        )
    {
        laws = new address[](NUMBER_OF_LAWS);
        allowedRoles = new uint32[](NUMBER_OF_LAWS);
        quorums = new uint8[](NUMBER_OF_LAWS);
        succeedAts = new uint8[](NUMBER_OF_LAWS);
        votingPeriods = new uint32[](NUMBER_OF_LAWS);

        // Law 1: {DirectSelect}
        // initiate law
        laws[0] = address(
                new DirectSelect(
                    "ROLE_ONE = open", // max 31 chars
                    "Anyone can apply for ROLE_ONE",
                    dao_,
                    DaoMock(dao_).ROLE_ONE()
                )
            ); 
        // add necessary configurations
        allowedRoles[0] = type(uint32).max;

        // Law 1: {TokensSelect}
        // deploy law 
        laws[1] = address(
            new TokensSelect(
                "ROLE_ONE elects ROLE_TWO", // max 31 chars
                "ROLE_ONE holders can call (and pay for) a whale election at any time. They can also nominate themselves.",
                dao_,
                mock1155_,
                15,
                DaoMock(dao_).ROLE_TWO()
            )
        );
        // configuration law 
        allowedRoles[1] = DaoMock(dao_).ROLE_ONE();

        // Law 2: {VoteSelect}
        laws[2] = address(
            new ProposalOnly(
                "ROLE_THREE make proposals", // max 31 chars
                "ROLE_THREE holders can make any proposal, without vote.",
                dao_ 
            )
        );
        allowedRoles[2] = DaoMock(dao_).ROLE_THREE(); 

        // Law 2: {VoteSelect}
        laws[3] = address(
            new VoteOnProposedAction(
                "ROLE_TWO accepts proposal", // max 31 chars
                "ROLE_TWO holders can vote on and accept proposal proposed by ROLE_THREE.",
                dao_,
                laws[2]
            )
        );
        allowedRoles[3] = DaoMock(dao_).ROLE_TWO();
        quorums[3] = 20; // = 30% quorum needed
        succeedAts[3] = 66; // = 51% simple majority needed for assigning and revoking members.
        votingPeriods[3] = 1200; // = number of blocks

        //////////////////////////////////////////////////////////////
        //                  RETURN CONSTITUTION                     //
        //////////////////////////////////////////////////////////////
        return (laws, allowedRoles, quorums, succeedAts, votingPeriods);
    }
}
