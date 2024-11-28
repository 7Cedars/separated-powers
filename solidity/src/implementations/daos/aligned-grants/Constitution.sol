// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import { SeparatedPowers } from "../../../SeparatedPowers.sol";

// electoral laws
import { Law } from "../../../Law.sol";
import { ILaw } from "../../../interfaces/ILaw.sol";
import { TokensSelect } from "../../laws/electoral/TokensSelect.sol";
import { DirectSelect } from "../../laws/electoral/DirectSelect.sol";
import "lib/openzeppelin-contracts/contracts/utils/ShortStrings.sol";

// executive laws
import { ProposalOnly } from "../../laws/executive/ProposalOnly.sol";
import { PresetAction } from "../../laws/executive/ProposalOnly.sol";
import { BespokeAction } from "../../laws/executive/BespokeAction.sol";
import { RevokeRole } from "./RevokeRole.sol";
import { ReinstateRole } from "./ReinstateRole.sol";

// dao and its bespoke laws
import { AlignedGrants } from "./AlignedGrants.sol";

contract Constitution {
    uint32 constant NUMBER_OF_LAWS = 11;

    function initiate(address payable dao_, address payable mock1155_)
        external
        returns (
            address[] memory laws,
            uint32[] memory allowedRoles,
            ILaw.LawConfig[] memory lawConfigs
        )
    {
        laws = new address[](NUMBER_OF_LAWS);
        allowedRoles = new uint32[](NUMBER_OF_LAWS);
        lawConfigs = new ILaw.LawConfig[](NUMBER_OF_LAWS);
    

    //////////////////////////////////////////////////////////////
    //              CHAPTER 1: ELECT ROLES                      //
    //////////////////////////////////////////////////////////////
    laws[0] = address(
        new DirectSelect(
            "Anyone can become member", // max 31 chars
            "Anyone can apply for a member role in the Aligned Grants Dao",
            dao_,
            AlignedGrants(dao_).MEMBER_ROLE()
        )
    );
    allowedRoles[0] = type(uint32).max;

    laws[1] = address(
        new TokensSelect(
            "Members select WHALE_ROLE", // max 31 chars
            "Members can call (and pay for) a whale election at any time. They can also nominate themselves. The nominated accounts with most tokens will be assigned the WHALE_ROLE.  No vote needed",
            dao_,
            mock1155_,
            address(0), 
            15,
            AlignedGrants(dao_).WHALE_ROLE() // 2 // AlignedGrants.WHALE_ROLE()
        )
    );
    allowedRoles[1] = AlignedGrants(dao_).MEMBER_ROLE(); // 3; // AlignedGrants.MEMBER_ROLE();

    // laws[2] = DirectSelect(
    //     new VoteSelect(
    //         "Seniors elect seniors", // max 31 chars
    //         "Seniors can propose and vote to (de)select an account for the SENIOR_ROLE.",
    //         dao_,
    //         AlignedGrants(dao_).SENIOR_ROLE() // 1 // AlignedGrants.SENIOR_ROLE()
    //     )
    // );
    // allowedRoles[2] = AlignedGrants(dao_).SENIOR_ROLE(); // 1; // AlignedGrants.SENIOR_ROLE();
    // lawConfigs[2].quorum = 30; // = 30% quorum needed
    // lawConfigs[2].succeedAt = 51; // = 51% simple majority needed for assigning and revoking members.
    // lawConfigs[2].votingPeriod = 1200; // = number of blocks

    //////////////////////////////////////////////////////////////
    //              CHAPTER 2: EXECUTIVE ACTIONS                //
    //////////////////////////////////////////////////////////////
    
    bytes4[] memory paramsAddValue = new bytes4[](0);
    paramsAddValue[0] = bytes4(keccak256("ShortString"));

    laws[3] = address(
        new ProposalOnly(
            "Members propose value", 
            "Members can propose a new value to be selected. They cannot implement it.", 
            dao_, 
            paramsAddValue
        )
    );
    allowedRoles[3] = 3; // AlignedGrants.MEMBER_ROLE();
    lawConfigs[3].quorum = 60; // = 60% quorum needed to pass the proposal
    lawConfigs[3].succeedAt = 30; // = 51% simple majority needed for assigning and revoking members.
    lawConfigs[3].votingPeriod = 1200; // = number of blocks to vote

    laws[4] = address(
        new BespokeAction(
            "Whales accept value",
            "Whales can accept and implement a new value that was proposed by members.",
            dao_, // separated powers
            dao_, // target contract
            AlignedGrants.addCoreValue.selector, // function selector
            paramsAddValue
        )
    );
    allowedRoles[4] = AlignedGrants(dao_).WHALE_ROLE(); // 2; // AlignedGrants.WHALE_ROLE();
    lawConfigs[4].quorum = 30; // = 30% quorum needed
    lawConfigs[4].succeedAt = 66; // =  two/thirds majority needed for
    lawConfigs[4].votingPeriod = 1200; // = number of blocks to vote
    lawConfigs[4].needCompleted = laws[3];

    laws[5] = address(
        new RevokeRole(
            "Whales -> revoke member", // max 31 chars
            "Subject to a vote, whales can revoke a member's role",
            dao_,
            AlignedGrants(dao_).MEMBER_ROLE() // 3 // AlignedGrants.MEMBER_ROLE(): the roleId to be revoked.
        )
    );
    allowedRoles[5] = AlignedGrants(dao_).WHALE_ROLE(); // 2; // AlignedGrants.WHALE_ROLE();
    lawConfigs[5].quorum = 80; // = 80% quorum needed
    lawConfigs[5].succeedAt = 66; // =  two/thirds majority needed to vote 'For' for voet to succeed.
    lawConfigs[5].votingPeriod = 1200; // = time (in number of blocks) to vote

    bytes4[] memory paramsChallengeRevoke = new bytes4[](0);
    paramsChallengeRevoke[0] = bytes4(keccak256("address"));
    laws[6] = address(
        new ProposalOnly(
            "Member challenge role revoke",
            "A members that had their role revoked can challenge this decision",
            dao_,
            paramsChallengeRevoke
        )
    );
    allowedRoles[6] = AlignedGrants(dao_).MEMBER_ROLE(); // 3; // AlignedGrants.MEMBER_ROLE();
    lawConfigs[6].needCompleted = laws[5];

    laws[7] = address(
        new ReinstateRole(
            "Reinstate member",
            "seniors can reinstated a member after it logged a challange. This is done through a vote.",
            dao_,
            AlignedGrants(dao_).MEMBER_ROLE()
        )
    );
    allowedRoles[7] = AlignedGrants(dao_).SENIOR_ROLE(); // 1; // AlignedGrants.SENIOR_ROLE();
    lawConfigs[7].quorum = 20; // = 20% quorum needed
    lawConfigs[7].succeedAt = 67; // =  two thirds majority needed
    lawConfigs[7].votingPeriod = 1200; // = time to pass the proposal.
    lawConfigs[7].needCompleted = laws[6];

    //////////////////////////////////////////////////////////////////////
    //            Adding new laws and revoking existing ones            //
    //////////////////////////////////////////////////////////////////////
    bytes4[] memory paramsAddLaw = new bytes4[](0);
    paramsChallengeRevoke[0] = bytes4(keccak256("address"));
    laws[8] = address(
        new ProposalOnly(
            "Whales propose laws",
            "Whales can propose new laws to be added to the Dao. Subject to a vote.",
            dao_,
            paramsAddLaw
        )
    );
    allowedRoles[8] = AlignedGrants(dao_).WHALE_ROLE();
    lawConfigs[8].quorum = 40; // = 20% quorum needed
    lawConfigs[8].succeedAt = 51; // =  two thirds majority needed
    lawConfigs[8].votingPeriod = 1200; // = time to pass the proposal.

    laws[9] = address(
        new ProposalOnly(
            "Seniors accept laws",
            "Seniors can accept laws proposed by whales. Subject to a vote.",
            dao_,
            paramsAddLaw
        )
    );
    allowedRoles[9] = AlignedGrants(dao_).SENIOR_ROLE(); 
    lawConfigs[9].quorum = 30; // = 20% quorum needed
    lawConfigs[9].succeedAt = 67; // =  two thirds majority needed
    lawConfigs[9].votingPeriod = 1200; // = time to pass the proposal.
    lawConfigs[9].needCompleted = laws[8];

    laws[10] = address(
        new BespokeAction(
            "Admin implements laws",
            "The admin implements laws proposed by whales and accepted by seniors.",
            dao_,
            dao_,
            SeparatedPowers.setLaw.selector,
            paramsAddLaw
        )
    );
    allowedRoles[10] = AlignedGrants(dao_).ADMIN_ROLE(); 
    lawConfigs[10].needCompleted = laws[9];
    }
}
