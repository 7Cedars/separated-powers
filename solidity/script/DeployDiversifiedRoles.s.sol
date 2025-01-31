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
import { BespokeAction } from "../src/laws/executive/BespokeAction.sol";
import { PresetAction } from "../src/laws/executive/PresetAction.sol";
import { Erc721Mock } from "../test/mocks/Erc721Mock.sol";

import { Members } from "../src/laws/bespoke/diversifiedRoles/Members.sol";
import { RoleByKyc } from "../src/laws/bespoke/diversifiedRoles/RoleByKyc.sol";
import { RoleByKycFactory } from "../src/laws/bespoke/diversifiedRoles/RoleByKycFactory.sol";
import { AiAgents } from "../src/laws/bespoke/diversifiedRoles/AiAgents.sol";
import { BespokeActionFactory } from "../src/laws/bespoke/diversifiedRoles/BespokeActionFactory.sol";

// config
import { HelperConfig } from "./HelperConfig.s.sol";

contract DeployDiverseRoles is Script {
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
            payable(address(separatedPowers)),
            payable(config.erc1155Mock),
            payable(config.erc20VotesMock),
            payable(address(erc721Mock))
        );

        // constitute dao.
        vm.startBroadcast();
        separatedPowers.constitute(laws);
        vm.stopBroadcast();

        return (payable(address(separatedPowers)), laws, config);
    }

    function initiateConstitution(
        address payable dao_,
        address payable mock20_,
        address payable mock721_,
        address payable mock1155_
    ) public {
        Law law;
        ILaw.LawConfig memory lawConfig;

        //////////////////////////////////////////////////////////////
        //              CHAPTER 1: EXECUTIVE ACTIONS                //
        //////////////////////////////////////////////////////////////
        // laws[0]
        // add or remove KYC data to address. (public in this case, just for testing purposes.
        // initiating law.
        vm.startBroadcast();
        law = new Members(
            "Add KYC data to an account.",
            "Add Know Your Customer (KYC) data to an account. This law is accessible for any one, for testing purposes only.",
            dao_,
            type(uint32).max, // access role = public.
            lawConfig
        );
        vm.stopBroadcast();
        laws.push(address(law));

        // laws[1]
        // propose new role filter. (Role 2)
        lawConfig.quorum = 70; // = 60% quorum needed
        lawConfig.succeedAt = 60; // = Simple majority vote needed.
        lawConfig.votingPeriod = 1200; // = number of blocks
        // setting up params
        string[] memory inputParams = new string[](6); // same as DeployRoleByKyc inputParams
        inputParams[0] = "string"; // name
        inputParams[1] = "string"; // description
        inputParams[2] = "uint16[]"; // nationalities
        inputParams[3] = "uint16[]"; // countries of residence
        inputParams[4] = "int64"; // olderThan
        inputParams[5] = "int64"; // youngerThan
        // initiating law.
        vm.startBroadcast();
        law = new ProposalOnly(
            "Propose to create role filter.",
            "Make a proposal to create a role filter based on Know Your Customer (KYC) data to assign a specific role to a subsection of community members. Input [0] = grantee address to transfer to. Inputs: 0 = name; 1: description; 2: nationalities to select (IBAN code); 3: Country of Residence to select (IBAN code); 4: older than (in seconds); 5: younger than (in seconds);     ",
            dao_,
            2, // access role
            lawConfig,
            inputParams // input parameters
        );
        vm.stopBroadcast();
        laws.push(address(law));
        delete lawConfig;

        // laws[2]
        // ok & implement new role self Select filter (Role 1)
        lawConfig.quorum = 5; // = 5% quorum needed
        lawConfig.succeedAt = 51; // = Simple majority vote needed.
        lawConfig.votingPeriod = 1200; // = number of blocks
        vm.startBroadcast();
        law = new RoleByKycFactory(
            "Accept role filter.",
            "Accept and implement a role filter based on Know Your Customer (KYC) data to assign a specific role to a subsection of community members. Input [0] = grantee address to transfer to. Inputs: 0 = name; 1: description; 2: nationalities to select (IBAN code); 3: Country of Residence to select (IBAN code); 4: older than (in seconds); 5: younger than (in seconds);     ",
            dao_,
            1, // access role
            lawConfig,
            laws[0]
        );
        vm.stopBroadcast();
        laws.push(address(law));
        delete lawConfig;

        // laws[3]
        // propose new AiAgent (Role 2)
        lawConfig.quorum = 60; // = 60% quorum needed
        lawConfig.succeedAt = 51; // = Simple majority vote needed.
        lawConfig.votingPeriod = 1200; // = number of blocks
        // setting up params
        inputParams = new string[](4); // same as AiAgents inputParams
        inputParams[0] = "string"; // name
        inputParams[1] = "address"; // account
        inputParams[2] = "string"; // uri
        inputParams[3] = "bool"; // add
        // initiating law.
        vm.startBroadcast();
        law = new ProposalOnly(
            "Propose to add AI Agent.",
            "Make a proposal to add an AI agent to the DAO. Inputs: 0 = name agent; 1: account of AI agent; 2: uri; 3: add? (false = remove entry)",
            dao_,
            2, // access role
            lawConfig,
            inputParams // input parameters
        );
        vm.stopBroadcast();
        laws.push(address(law));
        delete lawConfig;

        // laws[4]
        // ok & implement new AiAgent (Role 1)
        lawConfig.quorum = 5; // = 5% quorum needed
        lawConfig.succeedAt = 51; // = Simple majority vote needed.
        lawConfig.votingPeriod = 1200; // = number of blocks
        vm.startBroadcast();
        law = new AiAgents(
            "Accept and add AI Agent.",
            "Accept and add an AI agent to the DAO.",
            dao_,
            1, // access role
            lawConfig
        );
        vm.stopBroadcast();
        laws.push(address(law));
        delete lawConfig;

        // laws[5]
        // propose new bespoke action (Role 2)
        lawConfig.quorum = 60; // = 60% quorum needed
        lawConfig.succeedAt = 51; // = Simple majority vote needed.
        lawConfig.votingPeriod = 1200; // = number of blocks
        // setting up params
        inputParams = new string[](6); // same as AiAgents inputParams
        inputParams[0] = "string"; // name
        inputParams[1] = "string"; // description
        inputParams[2] = "uint32"; // allowedRole
        inputParams[3] = "address"; // target contract
        inputParams[4] = "bytes4"; // target function
        inputParams[5] = "string[]"; // params
        // initiating law.
        vm.startBroadcast();
        law = new ProposalOnly(
            "Propose new Bespoke Action.",
            "Propose to deploy a new, role restricted, bespoke action. Inputs: 0 = name; 1: description; 2: allowed Role; 3: target contract; 4: target function; 5: input parameters.",
            dao_,
            2, // access role
            lawConfig,
            inputParams // input parameters
        );
        vm.stopBroadcast();
        laws.push(address(law));
        delete lawConfig;

        // laws [6]
        // ok & implement new role restricted bespoke action (Admin)
        vm.startBroadcast();
        law = new BespokeActionFactory(
            "Deploy bespoke action.",
            "Accept and deploy bespoke action.",
            dao_,
            0, // access role = Admin.
            lawConfig
        );
        vm.stopBroadcast();
        laws.push(address(law));

        //////////////////////////////////////////////////////////////
        //              CHAPTER 2: ELECT ROLES                      //
        //////////////////////////////////////////////////////////////

        // laws[7]
        // self select Role 1 (checks if age has been filled out, but accepts everyone.)
        vm.startBroadcast();
        law = new RoleByKyc(
            "Claim community role.",
            "Claim community role.",
            dao_,
            type(uint32).max, // access role = public.
            lawConfig,
            //// self select
            1, // uint32 roleId_
            //// filter
            new uint16[](0), // memory nationalities,
            new uint16[](0), // uint16[] memory countryOfResidences,
            1, // int64 olderThan, // in seconds, set to minimum
            type(int64).max, // int64 youngerThan // in seconds, set to maximum.
            laws[0] // address members
        );
        vm.stopBroadcast();
        laws.push(address(law));

        // laws[8]
        // NominateMe for Role 2 (allowedRole = Role 1)
        vm.startBroadcast();
        law = new NominateMe(
            "Nominate self for role 2", // max 31 chars
            "Community members can nominate themselves for role 2.",
            dao_,
            type(uint32).max, // access role = public access
            lawConfig
        );
        vm.stopBroadcast();
        laws.push(address(law));

        // laws[9]
        // peer select Role 2 (allowedRole = Role 1)
        vm.startBroadcast();
        law = new PeerSelect(
            "Claim community role.",
            "Claim community role.",
            dao_,
            type(uint32).max, // access role = public.
            lawConfig,
            //
            15,
            // uint256 maxRoleHolders_,
            laws[8], // address nominees_,
            2 // uint32 roleId_
        );
        vm.stopBroadcast();
        laws.push(address(law));

        // ... all other roles through dynamic self select.
    }
}
