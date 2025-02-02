// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import "lib/forge-std/src/Script.sol";

// core protocol
import { SeparatedPowers } from "../src/SeparatedPowers.sol";
import { Law } from "../src/Law.sol";
import { ILaw } from "../src/interfaces/ILaw.sol";
import { SeparatedPowersTypes } from "../src/interfaces/SeparatedPowersTypes.sol";

// laws
import { NominateMe } from "../src/laws/state/NominateMe.sol";
import { DelegateSelect } from "../src/laws/electoral/DelegateSelect.sol";
import { DirectSelect } from "../src/laws/electoral/DirectSelect.sol";
import { PeerSelect } from "../src/laws/electoral/PeerSelect.sol";
import { ProposalOnly } from "../src/laws/executive/ProposalOnly.sol";
import { BespokeAction } from "../src/laws/executive/BespokeAction.sol";
import { PresetAction } from "../src/laws/executive/PresetAction.sol";
import { Erc721Mock } from "../test/mocks/Erc721Mock.sol";

import { Grant } from "../src/laws/bespoke/diversifiedGrants/Grant.sol";
import { StartGrant } from "../src/laws/bespoke/diversifiedGrants/StartGrant.sol";
import { StopGrant } from "../src/laws/bespoke/diversifiedGrants/StopGrant.sol";
import { SelfDestructPresetAction } from "../src/laws/bespoke/diversifiedGrants/SelfDestructPresetAction.sol";
// borrowing one law from another bespoke folder. Not ideal, but ok for now.
import { NftSelfSelect } from "../src/laws/bespoke/alignedDao/NftSelfSelect.sol";

// config
import { HelperConfig } from "./HelperConfig.s.sol";

contract DeployDiversifiedGrants is Script {
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
        lawConfig.quorum = 60; // = 60% quorum needed
        lawConfig.succeedAt = 50; // = Simple majority vote needed.
        lawConfig.votingPeriod = 1200; // = number of blocks
        // setting up params
        string[] memory inputParams = new string[](3);
        inputParams[0] = "address"; // grantee
        inputParams[1] = "address"; // grant Law address
        inputParams[2] = "uint256"; // amount
        // initiating law.
        vm.startBroadcast();
        // Note: the grant has its token pre specified.
        law = new ProposalOnly(
            "Make a proposal to a grant.",
            "Make a grant proposal that will be voted on by community members. It has to specify the grant address in the proposal. Input [0] = grantee address to transfer to. input[1] = grant address to transfer from.  input[2] =  quantity to transfer of token.",
            dao_,
            1, // access role
            lawConfig,
            inputParams // input parameters
        );
        vm.stopBroadcast();
        laws.push(address(law));
        delete lawConfig;

        // laws[1]
        lawConfig.quorum = 80; // = 80% quorum needed
        lawConfig.succeedAt = 66; // =  two/thirds majority needed for
        lawConfig.votingPeriod = 1200; // = number of blocks
        // initiating law
        vm.startBroadcast();
        law = new StartGrant(
            "Create a grant", // max 31 chars
            "Subject to a vote, a grant can be created. The token, budget and duration are pre-specified, as well as the role Id that will govern the grant.",
            dao_, // separated powers
            2, // access role
            lawConfig, // bespoke configs for this law.
            laws[0] // law from where proposals need to be made.
        );
        vm.stopBroadcast();
        laws.push(address(law));
        delete lawConfig;

        // laws[2]
        lawConfig.quorum = 40; // = 40% quorum needed
        lawConfig.succeedAt = 80; // =  80 majority needed
        lawConfig.votingPeriod = 120; // = number of blocks for vote.
        // input params
        inputParams = new string[](1);
        inputParams[0] = "address";
        // initiating law.
        vm.startBroadcast();
        law = new BespokeAction(
            "Stop law",
            "The security Council can stop any law.",
            dao_, // separated powers
            3, // access role
            lawConfig, // bespoke configs for this law
            dao_,
            SeparatedPowers.revokeLaw.selector,
            inputParams
        );
        vm.stopBroadcast();
        laws.push(address(law));
        delete lawConfig;

        // laws[3]
        lawConfig.quorum = 50; // = 50% quorum needed
        lawConfig.succeedAt = 66; // =  two/thirds majority needed for
        lawConfig.votingPeriod = 1200; // = number of blocks
        lawConfig.needCompleted = laws[2]; // NB! first a law needs to be stopped before it can be restarted!
        // This does mean that the reason given needs to be the same as when the law was stopped.
        // initiating law.
        vm.startBroadcast();
        law = new BespokeAction(
            "Restart law",
            "The security Council can restart a law.",
            dao_, // separated powers
            3, // access role
            lawConfig, // bespoke configs for this law
            dao_,
            SeparatedPowers.adoptLaw.selector,
            inputParams // note: same inputParams as laws [2]
        );
        vm.stopBroadcast();
        laws.push(address(law));
        delete lawConfig;

        //////////////////////////////////////////////////////////////
        //              CHAPTER 2: ELECT ROLES                      //
        //////////////////////////////////////////////////////////////
        // laws[4]
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

        // laws[5]
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

        // laws[6]
        vm.startBroadcast();
        law = new DelegateSelect(
            "Call role 2 election", // max 31 chars
            "An election is called by an oracle, as set by the admin. The nominated accounts with most delegated vote tokens are then assigned to role 2.",
            dao_, // separated powers protocol.
            9, // oracle role id designation.
            lawConfig, //  config file.
            mock20_, // the tokens that will be used as votes in the election.
            laws[7], // nominateMe //
            10, // maximum amount of delegates
            2 // role id to be assigned
        );
        vm.stopBroadcast();
        laws.push(address(law));

        // laws[7]
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

        // laws[8]: security council: peer select. - role 3
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
            3, // maximum elected to role
            laws[7], // nominateMe
            3 // role id to be assigned
        );
        vm.stopBroadcast();
        laws.push(address(law));
        delete lawConfig;

        // laws[9]: selfDestructPresetAction: assign initial accounts to security council.
        address[] memory targets = new address[](3);
        uint256[] memory values = new uint256[](3);
        bytes[] memory calldatas = new bytes[](3);
        for (uint256 i = 0; i < targets.length; i++) {
            targets[i] = dao_;
        }
        calldatas[0] =
            abi.encodeWithSelector(SeparatedPowers.assignRole.selector, 3, 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266);
        calldatas[1] =
            abi.encodeWithSelector(SeparatedPowers.assignRole.selector, 3, 0x70997970C51812dc3A010C7d01b50e0d17dc79C8);
        calldatas[2] =
            abi.encodeWithSelector(SeparatedPowers.assignRole.selector, 3, 0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC);
        vm.startBroadcast();
        law = new SelfDestructPresetAction(
            "Set initial roles 3", // max 31 chars
            "The admin selects initial accounts for role 3. The law self destructs when executed.",
            dao_, // separated powers protocol.
            0, // admin.
            lawConfig, //  config file.
            targets,
            values,
            calldatas
        );
        vm.stopBroadcast();
        laws.push(address(law));
        delete lawConfig;

        // laws[10]: elect and revoke members to grant council A -- governance council votes.
        lawConfig.quorum = 70; // = 70% quorum needed
        lawConfig.succeedAt = 51; // =  simple majority sufficient
        lawConfig.votingPeriod = 1200; // = number of blocks
        vm.startBroadcast();
        law = new DirectSelect(
            "Elect and revoke role 4", // max 31 chars
            "Elect and revoke members for role 4 (Grant council A)",
            dao_, // separated powers protocol.
            2, // governors.
            lawConfig, //  config file.
            4 // role id to be assigned
        );
        vm.stopBroadcast();

        // laws[11]: elect and revoke members to grant council B -- governance council votes.
        vm.startBroadcast();
        law = new DirectSelect(
            "Elect and revoke role 5", // max 31 chars
            "Elect and revoke members for role 5 (Grant council B)",
            dao_, // separated powers protocol.
            2, // governors.
            lawConfig, //  config file. // same as law[9]
            5 // role id to be assigned
        );
        vm.stopBroadcast();

        // laws[12]: elect and revoke members to grant council C -- governance council votes.
        vm.startBroadcast();
        law = new DirectSelect(
            "Elect and revoke role 6", // max 31 chars
            "Elect and revoke members for role 6 (Grant council C)",
            dao_, // separated powers protocol.
            2, // governors.
            lawConfig, //  config file. // same as law[9]
            6 // role id to be assigned
        );
        vm.stopBroadcast();
        delete lawConfig; // here we delete the law config

        // note at the moment not possible to resign form these roles. In reality there should be a law that allows for resignations.

        // laws[13]
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
