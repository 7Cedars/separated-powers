// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import "lib/forge-std/src/Script.sol";

// core protocol
import { SeparatedPowers } from "../src/SeparatedPowers.sol";
import { Law } from "../src/Law.sol";
import { ILaw } from "../src/interfaces/ILaw.sol";
import { SeparatedPowersTypes } from "../src/interfaces/SeparatedPowersTypes.sol";

// laws
import { NominateMe } from "../src/laws/electoral/NominateMe.sol";
import { DelegateSelect } from "../src/laws/electoral/DelegateSelect.sol";
import { DirectSelect } from "../src/laws/electoral/DirectSelect.sol";
import { PeerSelect } from "../src/laws/electoral/PeerSelect.sol";
import { ProposalOnly } from "../src/laws/executive/ProposalOnly.sol";
import { OpenAction } from "../src/laws/executive/OpenAction.sol";
import { BespokeAction } from "../src/laws/executive/BespokeAction.sol";
import { PresetAction } from "../src/laws/executive/PresetAction.sol";
import { StringsArray } from "../src/laws/state/StringsArray.sol";
import { Erc721Mock } from "../test/mocks/Erc721Mock.sol";

import { 
    RevokeMembership,
    ReinstateRole, 
    RequestPayment, 
    NftSelfSelect 
    } from "../src/laws/bespoke/AlignedDao.sol";

// config
import { HelperConfig } from "./HelperConfig.s.sol";

contract DeployAlignedDao is Script {
  address[] laws;

    function run()
        external
        returns (address payable dao, address[] memory constituentLaws, HelperConfig.NetworkConfig memory config)
    {
        HelperConfig helperConfig = new HelperConfig();
        config = helperConfig.getConfigByChainId(block.chainid);

        // Initiating Dao.
        vm.startBroadcast();
        SeparatedPowers separatedPowers = new SeparatedPowers("Aligned Grants", "");
        vm.stopBroadcast();

        vm.startBroadcast(address(separatedPowers));
        Erc721Mock erc721Mock = new Erc721Mock();
        vm.stopBroadcast();

        initiateConstitution(
            payable(address(separatedPowers)), payable(config.erc1155Mock), payable(config.erc20VotesMock), payable(address(erc721Mock))
        );

        // constitute dao.
        vm.startBroadcast();
        separatedPowers.constitute(laws);
        vm.stopBroadcast();

        return (payable(address(separatedPowers)), laws, config);
    }

    function initiateConstitution(address payable dao_, address payable mock20_, address payable mock721_, address payable mock1155_) public {
        Law law;
        ILaw.LawConfig memory lawConfig;

        //////////////////////////////////////////////////////////////
        //              CHAPTER 1: EXECUTIVE ACTIONS                //
        //////////////////////////////////////////////////////////////
        // laws[0]
        lawConfig.quorum = 60; // = 60% quorum needed
        lawConfig.succeedAt = 50; // = Simple majority vote needed.
        lawConfig.votingPeriod = 1200; // = number of blocks
        // setting up params
        string[] memory inputParams = new string[](2);
        inputParams[0] = "string";
        inputParams[1] = "bool";
        // initiating law.
        vm.startBroadcast();
        law = new ProposalOnly(
                "Propose to add / remove value",
                "Propose to add a new core value to or remove an existing from the Dao. Subject to a vote and cannot be implemented.",
                dao_,
                1, // access role
                lawConfig,
                inputParams // input parameters
            );
        vm.stopBroadcast();
        laws.push(address(law));
        delete lawConfig;

        // laws[1]
        lawConfig.quorum = 30; // = 30% quorum needed
        lawConfig.succeedAt = 66; // =  two/thirds majority needed for
        lawConfig.votingPeriod = 1200; // = number of blocks
        lawConfig.needCompleted = laws[0];
        // initiating law.
        vm.startBroadcast();
        law = new StringsArray(
                "Add and Remove values",
                "Accept & implement a proposed decision to add or remove a value from the Dao.",
                dao_, // separated powers
                2, // access role
                lawConfig // bespoke configs for this law
            );
        vm.stopBroadcast();
        laws.push(address(law));
        delete lawConfig;

        // laws[2]
        lawConfig.quorum = 80; // = 80% quorum needed
        lawConfig.succeedAt = 66; // =  two/thirds majority needed for
        lawConfig.votingPeriod = 1200; // = number of blocks
        // initiating law
        vm.startBroadcast();
        law = new RevokeMembership(
                "Revoke membership", // max 31 chars
                "Subject to a vote, a member's role can be revoked and their access token burned.",
                dao_, // separated powers
                3, // access role
                lawConfig, // bespoke configs for this law. 
                mock721_ // the Erc721 token address. 
            );
        vm.stopBroadcast();
        laws.push(address(law));
        delete lawConfig;

        // laws[3]
        lawConfig.quorum = 1; // = 1% quorum needed
        lawConfig.succeedAt = 80; // = 80 percent of the quorum needs to vote fore reinstatement. 
        lawConfig.votingPeriod = 1200; // = number of blocks
        lawConfig.needCompleted = laws[2]; 
        // input params
        inputParams = new string[](2);
        inputParams[0] = "uint256";
        inputParams[1] = "address";
        // initiating law
        vm.startBroadcast();
        law = new ProposalOnly(
                "Challenge a member revoke",
                "Members can challenge revoking of another members role.", 
                dao_, // separated powers
                1, // access role
                lawConfig, // bespoke configs for this law.
                inputParams // input parameters
            );
        vm.stopBroadcast();
        laws.push(address(law));
        delete lawConfig;

        // laws[4]
        lawConfig.quorum = 20; // = 20% quorum needed
        lawConfig.succeedAt = 67; // =  two/thirds majority needed for
        lawConfig.votingPeriod = 1200; // = number of blocks
        lawConfig.needCompleted = laws[3]; // NB! £todo all the law references need to be changed!
        //initiating law
        vm.startBroadcast();
        law = new ReinstateRole(
                "Reinstate member",
                "Members can be reinstated after a challenge was made.",
                dao_,
                2, // access role
                lawConfig, 
                mock721_
            );
        vm.stopBroadcast();
        laws.push(address(law));
        delete lawConfig;

        // laws[5]
        vm.startBroadcast();
        law = new RequestPayment(
                "Members can request payment",
                "Members can request a payment of 5_000 tokens every 2000 blocks.",
                dao_,
                1,
                lawConfig, //  config
                // bespoke configs for this law:
                mock1155_, // token address.
                5_000, // number of tokens
                2_000 // number of blocks = 30 days
            );
        vm.stopBroadcast();
        laws.push(address(law));


        //////////////////////////////////////////////////////////////
        //              CHAPTER 2: ELECT ROLES                      //
        //////////////////////////////////////////////////////////////
        // laws[6]
        vm.startBroadcast();
        law = new NftSelfSelect(
            "Elect self for role 1", // max 31 chars
            "Anyone who has a mock Erc721 token can (de)select themselves for role 1. See the treasury page for the contract where to mint one.",
            dao_,
            type(uint32).max, // access role = public access
            lawConfig,
            1, // role id
            mock721_
        );
        vm.stopBroadcast();
        laws.push(address(law)); 

        // laws[7]
        vm.startBroadcast();
        law = new NominateMe(
            "Nominate self for role 2", // max 31 chars
            "Anyone can nominate themselves for role 2.",
            dao_,
            type(uint32).max, // access role = public access
            lawConfig
        );
        vm.stopBroadcast();
        laws.push(address(law));

        // laws[8]
        vm.startBroadcast();
        law = new DelegateSelect(
            "Call role 2 election", // max 31 chars
            "An election is called by an oracle, as set by the admin. The nominated accounts with most delegated vote tokens are then assigned to role 2.",
            dao_, // separated powers protocol.
            9, // oracle role id designation. 
            lawConfig, //  config file.
            mock20_, // the tokens that will be used as votes in the election.
            laws[7], // nominateMe // 
            5, // maximum amount of delegates
            2 // role id to be assigned
        );
        vm.stopBroadcast();
        laws.push(address(law));

        // laws[9]
        vm.startBroadcast();
        law = new NominateMe(
            "Nominate self for role 3", // max 31 chars
            "Anyone can nominate themselves for role 3.",
            dao_,
            type(uint32).max, // access role = public access
            lawConfig
        );
        vm.stopBroadcast();
        laws.push(address(law));

        // laws[10]
        lawConfig.quorum = 66; // = Two thirds quorum needed to pass the proposal
        lawConfig.succeedAt = 51; // = 51% simple majority needed for assigning and revoking members.
        lawConfig.votingPeriod = 7200; // = duration in number of blocks to vote, about one day.
        // 
        vm.startBroadcast();
        law = new PeerSelect(
            "Assign Role 3", // max 31 chars
            "Role 3 are assigned by their peers through a majority vote.",
            dao_, // separated powers protocol.
            3, // role 3 id designation. 
            lawConfig, //  config file.
            3, // maximum elected to role,
            laws[9], // nominateMe
            3 // role id to be assigned
        );
        vm.stopBroadcast();
        laws.push(address(law));
        delete lawConfig;

        // laws[11]
        vm.startBroadcast();
        law = new DirectSelect(
            "Set Oracle", // max 31 chars
            "The admin selects accounts for role 9, the oracle role.",
            dao_, // separated powers protocol.
            0, // admin. 
            lawConfig, //  config file.
            9 // role id to be assigned
        );
        vm.stopBroadcast();
        laws.push(address(law));
    }
}
