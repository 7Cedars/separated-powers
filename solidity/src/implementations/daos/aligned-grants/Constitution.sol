// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

// electoral laws
import { Law } from "../../src/Law.sol";
import { AlignedGrants } from "../../src/implementations/daos/AlignedGrants.sol";
import { TokensSelect } from "../../src/implementations/laws/electoral/TokensSelect.sol";
import { DirectSelect } from "../../src/implementations/laws/electoral/DirectSelect.sol";
// executive laws

// bespoke laws
import { AdoptValue } from "../../src/implementations/laws/bespoke/AdoptValue.sol";
import { RevokeRole } from "../../src/implementations/laws/bespoke/RevokeRole.sol";
import { RevertRevokeMemberRole } from "../../src/implementations/laws/bespoke/RevertRevokeMemberRole.sol";

contract Constitution {
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
        // Law 1: {DirectSelect}
        // initiate law
        laws[0] = address(
                new DirectSelect(
                    "Public -> MEMBER_ROLE", // max 31 chars
                    "Anyone can apply for a member role in the Aligned Grants Dao",
                    dao_,
                    3 // = member role // somehow MEMBER_ROLE not recognized.
                )
            ); 
        // add necessary configurations
        allowedRoles[0] = type(uint32).max;

        // Law 1: {TokensSelect}
        // deploy law 
        laws[1] = address(
            new TokensSelect(
                "Members select WHALE_ROLE", // max 31 chars
                "Members can call (and pay for) a whale election at any time. They can also nominate themselves. No vote needed",
                dao_,
                mock1155_,
                15,
                2 // AlignedGrants.WHALE_ROLE()
            )
        );
        // configuration law 
        allowedRoles[1] = 3; // AlignedGrants.MEMBER_ROLE();

        // Law 2: {VoteSelect}
        laws[2] = address(
            new VoteSelect(
                "Seniors elect seniors", // max 31 chars
                "Seniors can propose and vote to (de)select seniors.",
                dao_,
                1 // AlignedGrants.SENIOR_ROLE()
            )
        );
        allowedRoles[2] = 1; // AlignedGrants.SENIOR_ROLE();
        quorums[2] = 30; // = 30% quorum needed
        succeedAts[2] = 51; // = 51% simple majority needed for assigning and revoking members.
        votingPeriods[2] = 1200; // = number of blocks

        //////////////////////////////////////////////////////////////
        //              CHAPTER 2: EXECUTIVE ACTIONS                //
        //////////////////////////////////////////////////////////////
        // Law 3: {ProposeOnly}
        laws[3] = address(
            new ProposeOnly(
                "Members propose value",
                "Members can propose a new value to be selected. They cannot execute it.",
                dao_ 
            )
        );
        allowedRoles[3] = 3; // AlignedGrants.MEMBER_ROLE();
        quorums[3] = 60; // = 60% quorum needed to pass the proposal 
        succeedAts[3] = 30; // = 51% simple majority needed for assigning and revoking members.
        votingPeriods[3] = 1200; // = number of blocks to vote

        // Law 4: {AdoptValue}
        laws[4] = address(
            new AdoptValue(
                "Whales accept value",
                "Whales can accept and implement a new value that was proposed by members.",
                dao_ 
            )
        );
        allowedRoles[4] = 2; // AlignedGrants.WHALE_ROLE();
        quorums[4] = 30; // = 30% quorum needed
        succeedAts[4] = 66; // =  two/thirds majority needed for
        votingPeriods[4] = 1200; // = number of blocks to vote

        // Law 5: {RevokeRole}
        laws[5] = address(
            new RevokeRole(
                "Whales -> revoke member", // max 31 chars
                "Subject to a vote, whales can revoke a member's role",
                dao_,
                3 // AlignedGrants.MEMBER_ROLE(): the roleId to be revoked.  
            )
        );
        allowedRoles[5] = 2; // AlignedGrants.WHALE_ROLE();
        quorums[5] = 80; // = 80% quorum needed
        succeedAts[5] = 66; // =  two/thirds majority needed to vote 'For' for voet to succeed. 
        votingPeriods[5] = 1200; // = time (in number of blocks) to vote

        // Law 6: {ChallengeRevoke}
        laws[6] = address(
            new ChallengeRevoke(
                "Member challenge role revoke",
                "A members that had their role revoked can challenge this decision",
                dao_,
                laws[5] // parent law
            )
        );
        allowedRoles[6] = 3; // AlignedGrants.MEMBER_ROLE();

        // Law 7: {ReinstateMember}
        laws[7] = address(
            new ReinstateMember(
                "Reinstate member",
                "seniors can reinstated a member after it logged a challange. This is done through a vote.",
                dao_,
                laws[6]
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
