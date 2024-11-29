// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import { SeparatedPowers } from "../../../SeparatedPowers.sol";

// electoral laws
import { Law } from "../../../Law.sol";
import { ILaw } from "../../../interfaces/ILaw.sol";
import { NominateMe } from "../../laws/electoral/NominateMe.sol";
import { TokensSelect } from "../../laws/electoral/TokensSelect.sol";
import { DirectSelect } from "../../laws/electoral/DirectSelect.sol";
import "lib/openzeppelin-contracts/contracts/utils/ShortStrings.sol";

// executive laws
import { ProposalOnly } from "../../laws/executive/ProposalOnly.sol";
import { BespokeAction } from "../../laws/executive/BespokeAction.sol";
import { RevokeRole } from "./RevokeRole.sol";
import { ReinstateRole } from "./ReinstateRole.sol";
import { RequestPayment } from "./RequestPayment.sol";

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
        new NominateMe(
            "Nominees for WHALE_ROLE", // max 31 chars
            "Anyone can nominate themselves for a role WHALE_ROLE",
            dao_
        )
    );
    allowedRoles[1] = type(uint32).max;

    laws[2] = address(
        new TokensSelect(
            "Members select WHALE_ROLE", // max 31 chars
            "Members can call (and pay for) a whale election at any time. The nominated accounts with most tokens will be assigned the role.",
            dao_,
            mock1155_,
            laws[1],
            15,
            AlignedGrants(dao_).WHALE_ROLE() // 2 // AlignedGrants.WHALE_ROLE()
        )
    );
    allowedRoles[2] = AlignedGrants(dao_).MEMBER_ROLE(); // 3; // AlignedGrants.MEMBER_ROLE();

    laws[3] = address(
        new DirectSelect(
            "Seniors elect seniors", // max 31 chars
            "Seniors can propose and vote to (de)select an account for the SENIOR_ROLE.",
            dao_,
            AlignedGrants(dao_).SENIOR_ROLE() // 1 // AlignedGrants.SENIOR_ROLE()
        )
    );
    allowedRoles[3] = AlignedGrants(dao_).SENIOR_ROLE(); // 1; // AlignedGrants.SENIOR_ROLE();
    lawConfigs[3].quorum = 30; // = 30% quorum needed
    lawConfigs[3].succeedAt = 51; // = 51% simple majority needed for assigning and revoking members.
    lawConfigs[3].votingPeriod = 1200; // = number of blocks

    //////////////////////////////////////////////////////////////
    //              CHAPTER 2: EXECUTIVE ACTIONS                //
    //////////////////////////////////////////////////////////////
    
    bytes4[] memory paramsAddValue = new bytes4[](0);
    paramsAddValue[0] = bytes4(keccak256("ShortString"));

    laws[4] = address(
        new ProposalOnly(
            "Members propose value", 
            "Members can propose a new value to be selected. They cannot implement it.", 
            dao_, 
            paramsAddValue
        )
    );
    allowedRoles[4] = 3; // AlignedGrants.MEMBER_ROLE();
    lawConfigs[4].quorum = 60; // = 60% quorum needed to pass the proposal
    lawConfigs[4].succeedAt = 30; // = 51% simple majority needed for assigning and revoking members.
    lawConfigs[4].votingPeriod = 1200; // = number of blocks to vote

    laws[5] = address(
        new BespokeAction(
            "Whales accept value",
            "Whales can accept and implement a new value that was proposed by members.",
            dao_, // separated powers
            dao_, // target contract
            AlignedGrants.addCoreValue.selector, // function selector
            paramsAddValue
        )
    );
    allowedRoles[5] = AlignedGrants(dao_).WHALE_ROLE(); // 2; // AlignedGrants.WHALE_ROLE();
    lawConfigs[5].quorum = 30; // = 30% quorum needed
    lawConfigs[5].succeedAt = 66; // =  two/thirds majority needed for
    lawConfigs[5].votingPeriod = 1200; // = number of blocks to vote
    lawConfigs[5].needCompleted = laws[4];

    laws[6] = address(
        new RevokeRole(
            "Whales -> revoke member", // max 31 chars
            "Subject to a vote, whales can revoke a member's role",
            dao_,
            AlignedGrants(dao_).MEMBER_ROLE() // 3 // AlignedGrants.MEMBER_ROLE(): the roleId to be revoked.
        )
    );
    allowedRoles[6] = AlignedGrants(dao_).WHALE_ROLE(); // 2; // AlignedGrants.WHALE_ROLE();
    lawConfigs[6].quorum = 80; // = 80% quorum needed
    lawConfigs[6].succeedAt = 66; // =  two/thirds majority needed to vote 'For' for voet to succeed.
    lawConfigs[6].votingPeriod = 1200; // = time (in number of blocks) to vote

    bytes4[] memory paramsChallengeRevoke = new bytes4[](0);
    paramsChallengeRevoke[0] = bytes4(keccak256("address"));
    laws[7] = address(
        new ProposalOnly(
            "Member challenge role revoke",
            "A members that had their role revoked can challenge this decision",
            dao_,
            paramsChallengeRevoke
        )
    );
    allowedRoles[7] = AlignedGrants(dao_).MEMBER_ROLE(); // 3; // AlignedGrants.MEMBER_ROLE();
    lawConfigs[7].needCompleted = laws[6];

    laws[8] = address(
        new ReinstateRole(
            "Reinstate member",
            "seniors can reinstated a member after it logged a challange. This is done through a vote.",
            dao_,
            AlignedGrants(dao_).MEMBER_ROLE()
        )
    );
    allowedRoles[8] = AlignedGrants(dao_).SENIOR_ROLE(); // 1; // AlignedGrants.SENIOR_ROLE();
    lawConfigs[8].quorum = 20; // = 20% quorum needed
    lawConfigs[8].succeedAt = 67; // =  two thirds majority needed
    lawConfigs[8].votingPeriod = 1200; // = time to pass the proposal.
    lawConfigs[8].needCompleted = laws[7];

    laws[9] = address(
        new RequestPayment(
            "Members request payment",
            "Members can request a payment of 5_000 tokens every 30 days.",
            dao_,
            mock1155_, // token address. 
            0, // token id
            5_000, // number of tokens
            216_000 // number of blocks = 30 days
        )
    );
    allowedRoles[9] = AlignedGrants(dao_).MEMBER_ROLE(); // 1; // AlignedGrants.SENIOR_ROLE();

    //////////////////////////////////////////////////////////////////////
    //            Adding new laws and revoking existing ones            //
    //////////////////////////////////////////////////////////////////////
    bytes4[] memory paramsAddLaw = new bytes4[](0);
    paramsChallengeRevoke[0] = bytes4(keccak256("address"));
    laws[10] = address(
        new ProposalOnly(
            "Whales propose laws",
            "Whales can propose new laws to be added to the Dao. Subject to a vote.",
            dao_,
            paramsAddLaw
        )
    );
    allowedRoles[10] = AlignedGrants(dao_).WHALE_ROLE();
    lawConfigs[10].quorum = 40; // = 20% quorum needed
    lawConfigs[10].succeedAt = 51; // =  two thirds majority needed
    lawConfigs[10].votingPeriod = 1200; // = time to pass the proposal.

    laws[11] = address(
        new ProposalOnly(
            "Seniors accept laws",
            "Seniors can accept laws proposed by whales. Subject to a vote.",
            dao_,
            paramsAddLaw
        )
    );
    allowedRoles[11] = AlignedGrants(dao_).SENIOR_ROLE(); 
    lawConfigs[11].quorum = 30; // = 20% quorum needed
    lawConfigs[11].succeedAt = 67; // =  two thirds majority needed
    lawConfigs[11].votingPeriod = 1200; // = time to pass the proposal.
    lawConfigs[11].needCompleted = laws[10];

    laws[12] = address(
        new BespokeAction(
            "Admin implements laws",
            "The admin implements laws proposed by whales and accepted by seniors.",
            dao_,
            dao_,
            SeparatedPowers.setLaw.selector,
            paramsAddLaw
        )
    );
    allowedRoles[12] = AlignedGrants(dao_).ADMIN_ROLE(); 
    lawConfigs[12].needCompleted = laws[11];
    }
}
