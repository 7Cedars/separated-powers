// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

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

// dao and its bespoke laws
import { AlignedGrants } from "./AlignedGrants.sol";

contract Constitution {
    uint32 constant NUMBER_OF_LAWS = 0;

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
    }

    //////////////////////////////////////////////////////////////
    //              CHAPTER 1: ELECT ROLES                      //
    //////////////////////////////////////////////////////////////
    // Law 0: {DirectSelect}
    laws[0] = address(
        new DirectSelect(
            "Anyone can get MEMBER_ROLE", // max 31 chars
            "Anyone can apply for a member role in the Aligned Grants Dao",
            dao_,
            AlignedGrants(dao_).MEMBER_ROLE()
        )
    );
    allowedRoles[0] = AlignedGrants(dao_).PUBLIC_ROLE(); 

    // Law 1: {TokensSelect}
    // deploy law
    laws[1] = address(
        new TokensSelect(
            "Members elect WHALE_ROLE", // max 31 chars
            "Members can call (and pay for) a whale election at any time. They can also nominate themselves. The nominated accounts with the most tokens will be elected. No vote needed",
            dao_,
            mock1155_,
            15, // max number of whales to be elected. 
            AlignedGrants(dao_).WHALE_ROLE();
        )
    );
    allowedRoles[1] = AlignedGrants(dao_).MEMBER_ROLE(); // ;

    // Law 2: {VoteSelect}
    laws[2] = address(
        new VoteSelect(
            "Seniors elect seniors", // max 31 chars
            "Seniors can propose and vote to (de)select seniors.",
            dao_,
            AlignedGrants(dao_).SENIOR_ROLE();
        )
    );
    allowedRoles[2] = AlignedGrants(dao_).SENIOR_ROLE();
    lawConfigs[2].quorum = 30; // = 30% quorum needed
    lawConfigs[2].succeedAt = 51; // = 51% simple majority needed for assigning and revoking members.
    lawConfigs[2].votingPeriod = 1200; // = number of blocks that the vote lasts for. 

    //////////////////////////////////////////////////////////////
    //              CHAPTER 2: EXECUTIVE ACTIONS                //
    //////////////////////////////////////////////////////////////
    // Law 3: {ProposeOnly}
    // setting input params. 
    bytes4[] memory params = new bytes4[](1);
    params[0] = bytes4(keccak256("ShortString"));
    // initiating law
    laws[3] = address(
        new ProposalOnly(
            "Members propose value", 
            "Members can propose a new value to be selected. They cannot execute it.", 
            dao_,
            params
        )
    );
    // setting config. 
    allowedRoles[3] = AlignedGrants(dao_).MEMBER_ROLE();
    lawConfigs[3].quorum = 60; // = 60% quorum needed to pass the proposal
    lawConfigs[3].succeedAt = 30; // = 51% simple majority needed for assigning and revoking members.
    lawConfigs[3].votingPeriod = 1200; // = number of blocks to vote

    // Law 4: {AdoptValue}
    // setting input params. 
    bytes4[] memory params = new bytes4[](1);
    params[0] = bytes4(keccak256("ShortString"));
    // initiating law
    laws[4] = address(
        new BespokeAction(
            "Whales accept value",
            "Whales can accept and implement a new value that was proposed by members.",
            dao_, // separated powers
            dao_, // target contract
            "addCoreValue(ShortString)", // target function
            params // parameters. 
        )
    );
    // law config 
    allowedRoles[4] = AlignedGrants(dao_).WHALE_ROLE();
    lawConfigs[4].quorum = 30; // = 30% quorum needed
    lawConfigs[4].succeedAt = 66; // =  two/thirds majority needed for
    lawConfigs[4].votingPeriod = 1200; // = number of blocks to vote
    lawConfigs[4].needCompleted = laws[3]; 

    // Law 5: Revoking a role 
    laws[5] = address(
        new RevokeRole(
            "Whales can revoke a member", // max 31 chars
            "Subject to a vote, whales can revoke a member's role",
            dao_,
            AlignedGrants(dao_).MEMBER_ROLE(); 
        )
    );
    allowedRoles[5] = AlignedGrants(dao_).WHALE_ROLE(); 
    lawConfigs[5].quorum = 80; // = 80% quorum needed
    lawConfigs[5.]succeedAt = 66; // =  two/thirds majority needed to vote 'For' for voet to succeed.
    lawConfigs[5].votingPeriod = 1200; // = time (in number of blocks) to vote

    // Law 6: Challenge revoke membership from an account. 
    bytes4[] memory params = new bytes4[](1);
    params[0] = bytes4(keccak256("address"));
    laws[6] = address(
        new ProposalOnly(
            "Member challenge role revoke",
            "Any member can challenge the decision to revoke membership of a member. ",
            dao_
        )
    );
    allowedRoles[6] = AlignedGrants(dao_).MEMBER_ROLE();
    lawConfigs[6].needCompleted = laws[5]; // note that anyone can challenge a revoke in this case. 

    // Law 7: {ReinstateMember}
    laws[7] = address(
        new ReinstateRole(
            "Reinstate member",
            "seniors can reinstated a member after it logged a challange. This is done through a vote.",
            dao_,
            AlignedGrants(dao_).MEMBER_ROLE(); 
        )
    );
    allowedRoles[7] = AlignedGrants(dao_).SENIOR_ROLE(); //
    lawConfigs.quorum[7] = 20; // = 20% quorum needed
    lawConfigs.succeedAt[7] = 67; // =  two thirds majority needed
    lawConfigs.votingPeriod[7] = 1200; // = voting time to pass the proposal.

    //     //////////////////////////////////////////////////////////////////////
    //     //       Law 13,... adding new laws and revoking existing ones      //
    //     //////////////////////////////////////////////////////////////////////
    //     // tbi.
}
