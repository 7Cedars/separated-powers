// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import "lib/forge-std/src/Script.sol";
import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";

// core protocol
import { SeparatedPowers } from "../src/SeparatedPowers.sol";
import { Law } from "../src/Law.sol";
import { ILaw } from "../src/interfaces/ILaw.sol";
import { SeparatedPowersTypes } from "../src/interfaces/SeparatedPowersTypes.sol";

// config
import { HelperConfig } from "./HelperConfig.s.sol";

// laws
import { NominateMe } from "../src/laws/state/NominateMe.sol"; 
import { DelegateSelect } from "../src/laws/electoral/DelegateSelect.sol";
import { DirectSelect } from "../src/laws/electoral/DirectSelect.sol";
import { PeerSelect } from "../src/laws/electoral/PeerSelect.sol";
import { ProposalOnly } from "../src/laws/executive/ProposalOnly.sol";
import { OpenAction } from "../src/laws/executive/OpenAction.sol";
import { BespokeAction } from "../src/laws/executive/BespokeAction.sol";
import { PresetAction } from "../src/laws/executive/PresetAction.sol";
import { StringsArray } from "../src/laws/state/StringsArray.sol";
import { RevokeMembership } from "../src/laws/bespoke/alignedDao/RevokeMembership.sol";
import { ReinstateRole } from "../src/laws/bespoke/alignedDao/ReinstateRole.sol";
import { RequestPayment } from "../src/laws/bespoke/alignedDao/RequestPayment.sol";
import { NftSelfSelect } from "../src/laws/bespoke/alignedDao/NftSelfSelect.sol";

import { SelfDestructPresetAction } from "../src/laws/bespoke/diversifiedGrants/SelfDestructPresetAction.sol"; 

// mocks 
import { Erc20VotesMock } from "../test/mocks/Erc20VotesMock.sol";
import { Erc721Mock } from "../test/mocks/Erc721Mock.sol";
import { Erc1155Mock } from "../test/mocks/Erc1155Mock.sol";

contract DeployAlignedDao is Script {
    address[] laws;

    function run()
        external
        returns (
            address payable dao, 
            address[] memory constituentLaws, 
            HelperConfig.NetworkConfig memory config, 
            address payable mock20_, 
            address payable mock721_, 
            address payable mock1155_
            )
    {
        HelperConfig helperConfig = new HelperConfig();
        config = helperConfig.getConfigByChainId(block.chainid);

        // deploying token contracts that will be managed by the Dao. 
        vm.startBroadcast();
        // initiating Dao
        SeparatedPowers separatedPowers = new SeparatedPowers(
            "Aligned Dao", 
            "https://aqua-famous-sailfish-288.mypinata.cloud/ipfs/bafkreihwvloi4rmzeertaclrz4pom4a42fn6asbcxex2iw3kggmdmsexee"
            );
        // Deploying token contracts that will be controlled by the Dao
        Erc20VotesMock erc20VotesMock = new Erc20VotesMock(); 
        Erc721Mock erc721Mock = new Erc721Mock();
        Erc1155Mock erc1155Mock = new Erc1155Mock(); 
        vm.stopBroadcast();

        dao = payable(address(separatedPowers));
        mock20_ = payable(address(erc20VotesMock)); 
        mock721_ = payable(address(erc721Mock));
        mock1155_ = payable(address(erc1155Mock));

        // initiating constitution: creates the Daos laws. 
        initiateConstitution(dao, mock20_, mock721_, mock1155_);

        vm.startBroadcast();
        // constitute dao.
        separatedPowers.constitute(laws);
        // & transferring ownership of Erc721 token to the Dao. 
        erc721Mock.transferOwnership(address(separatedPowers));
        vm.stopBroadcast();
 
        return (dao, laws, config, mock20_, mock721_, mock1155_);
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
        string[] memory inputParams = new string[](2);
        inputParams[0] = "string Value";
        inputParams[1] = "bool Add";
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
        inputParams[0] = "uint256 TokenId";
        inputParams[1] = "address Account";
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
            0,
            5000, // number of tokens
            2000 // number of blocks = 30 days
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
            string.concat("Anyone who knows how to mint an NFT at ", Strings.toHexString(uint256(addressToInt(mock721_)), 20), " can (de)select themselves for role 1. Mint an NFT and claim the role!"),
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

        // laws[12]: selfDestructPresetAction: assign initial accounts to role 3.
        address[] memory targets = new address[](3);
        uint256[] memory values = new uint256[](3);
        bytes[] memory calldatas = new bytes[](3);
        for (uint256 i = 0; i < targets.length; i++) {
            targets[i] = dao_;
        }
        calldatas[0] = abi.encodeWithSelector(
          SeparatedPowers.assignRole.selector, 
          3, 
          0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266
        );
        calldatas[1] = abi.encodeWithSelector(
          SeparatedPowers.assignRole.selector, 
          3, 
          0x70997970C51812dc3A010C7d01b50e0d17dc79C8
        );
        calldatas[2] = abi.encodeWithSelector(
          SeparatedPowers.assignRole.selector, 
          3, 
          0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC
        );
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
    }

    ///////////////////////////////////////////////////////
    //                  Helper functions                //
    //////////////////////////////////////////////////////
    function addressToInt(address a) internal pure returns (uint256) {
        return uint256(uint160(a));
    }
}
