// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import { SeparatedPowers } from "../../../SeparatedPowers.sol";

// electoral laws
import { Law } from "../../../Law.sol";
import { ILaw } from "../../../interfaces/ILaw.sol";
import { TokensSelect } from "../../laws/electoral/TokensSelect.sol";
import { DirectSelect } from "../../laws/electoral/DirectSelect.sol";
import { DelegateSelect } from "../../laws/electoral/DelegateSelect.sol";

// executive laws
import { ProposalOnly } from "../../laws/executive/ProposalOnly.sol";
import { BespokeAction } from "../../laws/executive/BespokeAction.sol";
import { RequestMemberRole } from "./RequestMemberRole.sol";

// dao and its bespoke laws
import { BasicDao } from "./BasicDao.sol";

contract Constitution {
    uint32 constant NUMBER_OF_LAWS = 11;

    function initiate(address payable dao_, address payable mockErc20Votes_)
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

    bytes4[] memory paramsAddMember = new bytes4[](3);
    paramsAddMember[0] = bytes4(keccak256("uint32")); // roleId
    paramsAddMember[1] = bytes4(keccak256("address")); // account
    paramsAddMember[2] = bytes4(keccak256("bool")); // access 

    // Note this law constrains input parameters. Hence laws[1] and laws[2] do not need to do this. 
    laws[0] = address(
        new RequestMemberRole(
            "Request to become member", // max 31 chars
            "Anyone can request a member role.",
            dao_,
            BasicDao(dao_).MEMBER_ROLE(),
            paramsAddMember
        )
    );
    allowedRoles[0] = type(uint32).max;

    laws[1] = address(
        new ProposalOnly(
            "Any Senior can veto member Appointment", // max 31 chars
            "Any Senior can veto assigning MEMBER_ROLE to an account. No vote needed.",
            dao_,
            paramsAddMember
        )
    );
    allowedRoles[1] = BasicDao(dao_).SENIOR_ROLE();

    laws[2] = address(
        new BespokeAction(
            "Members accept members request", 
            "Members can accept a request to become a member. Law is subject to vote, and can be vetoed by Senior",
            dao_, // separated powers
            dao_, // target contract
            SeparatedPowers.setRole.selector, // function selector
            paramsAddMember
        )
    );
    allowedRoles[2] = BasicDao(dao_).MEMBER_ROLE();
    lawConfigs[2].quorum = 1; // = 1% quorum needed
    lawConfigs[2].succeedAt = 51; // = 51% simple majority needed. 
    lawConfigs[2].votingPeriod = 1200; // = number of blocks for vote. = 4 hours
    lawConfigs[2].delayExecution = 7200; // = one day. -- gives time for senior to veto. 
    lawConfigs[2].needNotCompleted = laws[1];

    // how are MEMBERS revoked? 

    // should nominate be a separated law? Is it possible to build this?   

    laws[3] = address(
        new DelegateSelect(
            "Members elect Delegates", // max 31 chars
            "Any members can call (and pay for) a delegate election at any time.. The nominated accounts with most delegated vote tokens will be assigned the DELEGATE_ROLE.",
            dao_,
            mockErc20Votes_,
            address(0), // nominateMe 
            15,
            BasicDao(dao_).DELEGATE_ROLE()
        )
    );
    allowedRoles[1] = BasicDao(dao_).MEMBER_ROLE();

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
    
    // bytes4[] memory paramsAddValue = new bytes4[](0);
    // paramsAddValue[0] = bytes4(keccak256("ShortString"));

    // laws[3] = address(
    //     new ProposalOnly(
    //         "Members propose value", 
    //         "Members can propose a new value to be selected. They cannot implement it.", 
    //         dao_, 
    //         paramsAddValue
    //     )
    // );
    // allowedRoles[3] = 3; // AlignedGrants.MEMBER_ROLE();
    // lawConfigs[3].quorum = 60; // = 60% quorum needed to pass the proposal
    // lawConfigs[3].succeedAt = 30; // = 51% simple majority needed for assigning and revoking members.
    // lawConfigs[3].votingPeriod = 1200; // = number of blocks to vote

    // laws[4] = address(
    //     new BespokeAction(
    //         "Whales accept value",
    //         "Whales can accept and implement a new value that was proposed by members.",
    //         dao_, // separated powers
    //         dao_, // target contract
    //         AlignedGrants.addCoreValue.selector, // function selector
    //         paramsAddValue
    //     )
    // );
    // allowedRoles[4] = AlignedGrants(dao_).WHALE_ROLE(); // 2; // AlignedGrants.WHALE_ROLE();
    // lawConfigs[4].quorum = 30; // = 30% quorum needed
    // lawConfigs[4].succeedAt = 66; // =  two/thirds majority needed for
    // lawConfigs[4].votingPeriod = 1200; // = number of blocks to vote
    // lawConfigs[4].needCompleted = laws[3];

    // laws[5] = address(
    //     new RevokeRole(
    //         "Whales -> revoke member", // max 31 chars
    //         "Subject to a vote, whales can revoke a member's role",
    //         dao_,
    //         AlignedGrants(dao_).MEMBER_ROLE() // 3 // AlignedGrants.MEMBER_ROLE(): the roleId to be revoked.
    //     )
    // );
    // allowedRoles[5] = AlignedGrants(dao_).WHALE_ROLE(); // 2; // AlignedGrants.WHALE_ROLE();
    // lawConfigs[5].quorum = 80; // = 80% quorum needed
    // lawConfigs[5].succeedAt = 66; // =  two/thirds majority needed to vote 'For' for veto to succeed.
    // lawConfigs[5].votingPeriod = 1200; // = time (in number of blocks) to vote

    // bytes4[] memory paramsChallengeRevoke = new bytes4[](0);
    // paramsChallengeRevoke[0] = bytes4(keccak256("address"));
    // laws[6] = address(
    //     new ProposalOnly(
    //         "Member challenge role revoke",
    //         "A members that had their role revoked can challenge this decision",
    //         dao_,
    //         paramsChallengeRevoke
    //     )
    // );
    // allowedRoles[6] = AlignedGrants(dao_).MEMBER_ROLE(); // 3; // AlignedGrants.MEMBER_ROLE();
    // lawConfigs[6].needCompleted = laws[5];

    // laws[7] = address(
    //     new ReinstateRole(
    //         "Reinstate member",
    //         "seniors can reinstated a member after it logged a challenge. This is done through a vote.",
    //         dao_,
    //         AlignedGrants(dao_).MEMBER_ROLE()
    //     )
    // );
    // allowedRoles[7] = AlignedGrants(dao_).SENIOR_ROLE(); // 1; // AlignedGrants.SENIOR_ROLE();
    // lawConfigs[7].quorum = 20; // = 20% quorum needed
    // lawConfigs[7].succeedAt = 67; // =  two thirds majority needed
    // lawConfigs[7].votingPeriod = 1200; // = time to pass the proposal.
    // lawConfigs[7].needCompleted = laws[6];

    //////////////////////////////////////////////////////////////////////
    //            Adding new laws and revoking existing ones            //
    //////////////////////////////////////////////////////////////////////
    // bytes4[] memory paramsAddLaw = new bytes4[](0);
    // paramsChallengeRevoke[0] = bytes4(keccak256("address"));
    // laws[8] = address(
    //     new ProposalOnly(
    //         "Whales propose laws",
    //         "Whales can propose new laws to be added to the Dao. Subject to a vote.",
    //         dao_,
    //         paramsAddLaw
    //     )
    // );
    // allowedRoles[8] = AlignedGrants(dao_).WHALE_ROLE();
    // lawConfigs[8].quorum = 40; // = 20% quorum needed
    // lawConfigs[8].succeedAt = 51; // =  two thirds majority needed
    // lawConfigs[8].votingPeriod = 1200; // = time to pass the proposal.

    // laws[9] = address(
    //     new ProposalOnly(
    //         "Seniors accept laws",
    //         "Seniors can accept laws proposed by whales. Subject to a vote.",
    //         dao_,
    //         paramsAddLaw
    //     )
    // );
    // allowedRoles[9] = AlignedGrants(dao_).SENIOR_ROLE(); 
    // lawConfigs[9].quorum = 30; // = 20% quorum needed
    // lawConfigs[9].succeedAt = 67; // =  two thirds majority needed
    // lawConfigs[9].votingPeriod = 1200; // = time to pass the proposal.
    // lawConfigs[9].needCompleted = laws[8];

    // laws[10] = address(
    //     new BespokeAction(
    //         "Admin implements laws",
    //         "The admin implements laws proposed by whales and accepted by seniors.",
    //         dao_,
    //         paramsAddLaw
    //     )
    // );
    // allowedRoles[10] = AlignedGrants(dao_).ADMIN_ROLE(); 
    // lawConfigs[10].needCompleted = laws[9];
    }
}
