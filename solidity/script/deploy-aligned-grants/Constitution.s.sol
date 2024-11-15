// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import { Script, console2 } from "lib/forge-std/src/Script.sol";

// electoral laws
import { Law } from "../../src/Law.sol";
import { AlignedGrants } from "../../src/implementations/daos/AlignedGrants.sol";
import { Tokens } from "../../src/implementations/laws/electoral/Tokens.sol";
import { Direct } from "../../src/implementations/laws/electoral/Direct.sol";
// administrative laws
import { NeedsVote } from "../../src/implementations/laws/administrative/NeedsVote.sol";
import { ChallengeExecution } from "../../src/implementations/laws/administrative/ChallengeExecution.sol";
// bespoke laws
import { AdoptValue } from "../../src/implementations/laws/bespoke/AdoptValue.sol";
import { RevokeRole } from "../../src/implementations/laws/bespoke/RevokeRole.sol";
import { RevertRevokeRole } from "../../src/implementations/laws/bespoke/RevertRevokeRole.sol";

contract Constitution is Script {
    uint32 constant NUMBER_OF_LAWS = 8;

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

        //////////////////////////////////////////////////////////////
        //              CHAPTER 1: ELECT ROLES                      //
        //////////////////////////////////////////////////////////////

        ///////////////////////////////////////
        // Law 0: anyone can become a member //
        ///////////////////////////////////////
        // initiate law
        laws[0] = address(
                new Direct(
                    "Public -> MEMBER_ROLE", // max 31 chars
                    "Anyone can apply for a member role in the Aligned Grants Dao",
                    dao_,
                    3 // = member role // somehow MEMBER_ROLE not recognized.
                )
            ); 
        // add necessary configurations
        allowedRoles[0] = type(uint32).max;

        //////////////////////////////////////////////////////
        // Law 1: members can call election for Whale roles //
        //////////////////////////////////////////////////////
        // step 1: initiate law //
        laws[1] = address(
            new Tokens(
                "Members select WHALE_ROLE", // max 31 chars
                "Members can call (and pay for) a whale election at any time. They can also nominate themselves. No vote needed",
                dao_,
                mock1155_,
                15,
                2 // AlignedGrants.WHALE_ROLE()
            )
        );

        // step 3: add configuration law
        // note that voting quorum etc does not have to be set in this case.
        allowedRoles[1] = 3; // AlignedGrants.MEMBER_ROLE();

        ////////////////////////////////////////////////////////////////////
        // Law 2 + 3: seniors can propose and vote to (de)select seniors  //
        ////////////////////////////////////////////////////////////////////
        // initiate law. Note: this law is NOT set as an active laws in the protocol.
        // It will never be called directly, by anyone, from the protocol.
        address electSeniorsLaw = address(
            new Direct(
                "Seniors elect seniors", // max 31 chars
                "Seniors can propose and vote to (de)select seniors.",
                dao_,
                1 // AlignedGrants.SENIOR_ROLE()
            )
        );

        // {NeedsVote} makes its parent law subject to a vote.
        laws[2] = address(
            new NeedsVote(
                electSeniorsLaw, // parent contract
                true // should it execute its parent contract if vote passes?
            )
        );
        allowedRoles[2] = 1; // AlignedGrants.SENIOR_ROLE();
        quorums[2] = 30; // = 30% quorum needed
        succeedAts[2] = 51; // = 51% simple majority needed for assigning and revoking members.
        votingPeriods[2] = 1200; // = number of blocks

        //////////////////////////////////////////////////////////////
        //              CHAPTER 2: EXECUTIVE ACTIONS                //
        //////////////////////////////////////////////////////////////

        //////////////////////////////////////////////////////////////////////
        //       Law 4, 5, 6: members propose value, whales accept value    //
        //////////////////////////////////////////////////////////////////////
        // initiate law - the actual executive law is set at admin.
        // no-one should be allowed to access this law directly. ADMIN_ROLE is meant for these cases.
        address adoptValueLaw = address(
            new AdoptValue(
                "Member -> whale -> new value", // max 31 chars
                "Members vote to propose a new value to be selected. Whales can accept a proposed value and add it to the core values of the Dao",
                dao_
            )
        );

        // {NeedsVote} makes its parent law subject to a vote.
        // in this case Members can vote on a proposal to execute law[4]. But they cannot execute it.
        laws[3] = address(
            new NeedsVote(
                adoptValueLaw, // parent contract
                false // this vote can accept the proposal, but cannot execute the law
            )
        );
        allowedRoles[3] = 3; // AlignedGrants.MEMBER_ROLE();
        quorums[3] = 60; // = 60% quorum needed
        succeedAts[3] = 30; // = 51% simple majority needed for assigning and revoking members.
        votingPeriods[3] = 1200; // = number of blocks to vote

        // {NeedsVote} makes its parent law subject to a vote.
        // in this case Whales can vote on a proposal to execute law[4]. But they cannot execute it.
        laws[4] = address(
            new NeedsVote(
                laws[3], // parent contract
                true // this vote should make execution possible.
            )
        );
        allowedRoles[4] = 2; // AlignedGrants.WHALE_ROLE();
        quorums[4] = 30; // = 30% quorum needed
        succeedAts[4] = 66; // =  two/thirds majority needed for
        votingPeriods[4] = 1200; // = number of blocks to vote

        //////////////////////////////////////////////////////////////////////
        //        Law 7 + 8 Whales can vote to revoke a member's role       //
        //////////////////////////////////////////////////////////////////////
        // initiate law - the actual executive law is set at admin.
        // no-one should be allowed to access this law directly. ADMIN_ROLE is meant for these cases.
        address revokeRoleLaw = address(
            new RevokeRole(
                "Whales -> revoke member", // max 31 chars
                "Subject to a vote, whales can revoke a member's role",
                dao_
            )
        );

        // {NeedsVote} makes its parent law subject to a vote.
        // in this case Whales can vote on a proposal to execute law[7]. If votes passes, it can be executed.
        laws[5] = address(
            new NeedsVote(
                revokeRoleLaw, // parent contract
                true // this vote makes execution possible.
            )
        );
        allowedRoles[5] = 2; // AlignedGrants.WHALE_ROLE();
        quorums[5] = 80; // = 30% quorum needed
        succeedAts[5] = 66; // =  two/thirds majority needed for
        votingPeriods[5] = 1200; // = number of blocks to vote

        /////////////////////////////////////////////////////////////////////////////////////
        //                    Law 9, 10: Members can challenge a revoke                    //
        /////////////////////////////////////////////////////////////////////////////////////
        // initiate law - the actual executive law is automatically to admin role Id (0).
        address challengeExecutionLaw = address(new ChallengeExecution(revokeRoleLaw));

        // {NeedsVote} makes its parent law subject to a vote.
        // In this case the only thing that is needed is to create a proposal.
        // Hence the proposal passes with 0 votes (and can be proposed and passed by any account that holds a member roleId.)
        laws[6] = address(
            new NeedsVote(
                challengeExecutionLaw, // parent contract
                true // this vote makes execution possible.
            )
        );
        allowedRoles[6] = 3; // AlignedGrants.MEMBER_ROLE();
        quorums[6] = 0; // = 0% quorum needed
        succeedAts[6] = 0; // =  no threshold
        votingPeriods[6] = 1200; // = time to pass the proposal. -- it also acts as a delay mechanism.

        //////////////////////////////////////////////////////////////////////
        //       Law 11, 12 Members can vote to revoke a member's role      //
        //////////////////////////////////////////////////////////////////////
        // initiate law - the actual executive law is automatically to admin role Id (0).
        address reinstateMemberLaw = address(
            new RevertRevokeRole(
                "Seniors reinstate member", // max 31 chars
                "Seniors can accept a Member revoke challenge and reinstate the role.",
                dao_
            )
        );

        // {NeedsVote} makes its parent law subject to a vote.
        // In this case the only thing that is needed is to create a proposal.
        // Hence the proposal passes with 0 votes (and can be proposed and passed by any account that holds a member roleId.)
        laws[7] = address(
            new NeedsVote(
                reinstateMemberLaw, // parent contract
                true // this vote makes execution possible.
            )
        );
        allowedRoles[7] = 1; // AlignedGrants.SENIOR_ROLE();
        quorums[7] = 20; // = 20% quorum needed
        succeedAts[7] = 67; // =  two thitrds majority needed
        votingPeriods[7] = 1200; // = time to pass the proposal.

        //////////////////////////////////////////////////////////////////////
        //       Law 13,... adding new laws and revoking existing ones      //
        //////////////////////////////////////////////////////////////////////
        // tbi.

        //////////////////////////////////////////////////////////////
        //                  RETURN CONSTITUTION                     //
        //////////////////////////////////////////////////////////////
        return (laws, allowedRoles, quorums, succeedAts, votingPeriods);
    }
}
