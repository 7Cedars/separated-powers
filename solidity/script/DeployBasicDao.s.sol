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
import { OpenAction } from "../src/laws/executive/OpenAction.sol";
import { PresetAction } from "../src/laws/executive/PresetAction.sol";

// config
import { HelperConfig } from "./HelperConfig.s.sol";

/// @notice core script to deploy a dao
/// Note the {run} function for deploying the dao can be used without changes.
/// Note  the {initiateConstitution} function for creating bespoke constitution for the DAO.
/// Note the {getFounders} function for setting founders' roles.
contract DeployBasicDao is Script {
    address[] laws;

    function run()
        external
        returns (address payable dao, address[] memory constituentLaws, HelperConfig.NetworkConfig memory config)
    {
        HelperConfig helperConfig = new HelperConfig();
        config = helperConfig.getConfigByChainId(block.chainid);

        // Initiating Dao.
        vm.startBroadcast();
        SeparatedPowers separatedPowers = new SeparatedPowers(
            "Basic Dao",
            "https://aqua-famous-sailfish-288.mypinata.cloud/ipfs/bafkreicipqz46fivyta6mnizu3ly7hrulnlp6skzyrd7dddgnakwl5ulre"
        );
        vm.stopBroadcast();

        initiateConstitution(
            payable(address(separatedPowers)), payable(config.erc1155Mock), payable(config.erc20VotesMock)
        );

        // constitute dao.
        vm.startBroadcast();
        separatedPowers.constitute(laws);
        vm.stopBroadcast();

        return (payable(address(separatedPowers)), laws, config);
    }

    function initiateConstitution(address payable dao_, address payable mock1155_, address payable mock20_) public {
        Law law;
        ILaw.LawConfig memory lawConfig;

        //////////////////////////////////////////////////////////////
        //              CHAPTER 1: EXECUTIVE ACTIONS                //
        //////////////////////////////////////////////////////////////

        // law[0]
        string[] memory paramsAction = new string[](3);
        paramsAction[0] = "address[]"; // targets
        paramsAction[1] = "uint256[]"; // values
        paramsAction[2] = "bytes[]"; // calldatas
        // setting config.
        lawConfig.quorum = 66; // = Two thirds quorum needed to pass the proposal
        lawConfig.succeedAt = 51; // = 51% simple majority needed for assigning and revoking members.
        lawConfig.votingPeriod = 50_400; // = duration in number of blocks to vote, about one week.
        // initiating law
        vm.startBroadcast();
        law = new ProposalOnly(
            "Propose an action",
            "Accounts with role 2 can propose new actions to be executed. They cannot implement them.",
            dao_,
            2, // access role
            lawConfig,
            paramsAction
        );
        vm.stopBroadcast();
        laws.push(address(law));
        delete lawConfig;

        // law[1]
        vm.startBroadcast();
        law = new ProposalOnly(
            "Veto an action",
            "The admin can veto any proposed action.",
            dao_,
            0, // access role
            lawConfig,
            paramsAction
        );
        vm.stopBroadcast();
        laws.push(address(law));

        // law[2]
        // setting config.
        lawConfig.quorum = 51; // = 51 majority of seniors need to vote.
        lawConfig.succeedAt = 66; // =  two/thirds majority FOR vote needed to pass.
        lawConfig.votingPeriod = 50_400; // = duration in number of blocks to vote, about one week.
        lawConfig.needCompleted = laws[0]; // needs the proposal by Delegates to be completed.
        lawConfig.needNotCompleted = laws[1]; // needs the admin NOT to have cast a veto.
        lawConfig.delayExecution = 25_200; // = duration in number of blocks (= half a week).
       
        // initiate law
        vm.startBroadcast();
        law = new OpenAction(
            "Execute an action",
            "Accounts with role 1 can execute actions that accounts with role 2 proposed and passed the proposal vote. They can only be execute if Admin did not cast a veto.",
            dao_, // separated powers
            1, // access role
            lawConfig
        );
        vm.stopBroadcast();
        laws.push(address(law));
        delete lawConfig;

        // law[3]
        address[] memory targets = new address[](3);
        uint256[] memory values = new uint256[](3);
        bytes[] memory calldatas = new bytes[](3);
        for (uint256 i = 0; i < targets.length; i++) {
            targets[i] = dao_;
        }
        calldatas[0] =
            abi.encodeWithSelector(SeparatedPowers.assignRole.selector, 1, 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266);
        calldatas[1] =
            abi.encodeWithSelector(SeparatedPowers.assignRole.selector, 1, 0x70997970C51812dc3A010C7d01b50e0d17dc79C8);
        calldatas[2] =
            abi.encodeWithSelector(SeparatedPowers.assignRole.selector, 1, 0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC);
        // set config
        lawConfig.throttleExecution = type(uint48).max - uint48(block.number); // setting the throttle to max means the law can only be called once.
        // initiate law
        vm.startBroadcast();
        law = new PresetAction(
            "Assign accounts to role 1",
            "The admin can assign the initial group of role 1 holders. This law can only be executed once.",
            dao_, // separated powers
            0, // access role = ADMIN
            lawConfig,
            targets,
            values,
            calldatas
        );
        vm.stopBroadcast();
        laws.push(address(law));
        delete lawConfig;

        //////////////////////////////////////////////////////////////
        //              CHAPTER 2: ELECT ROLES                      //
        //////////////////////////////////////////////////////////////

        // law[4]
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

        // law[5]
        vm.startBroadcast();
        lawConfig.throttleExecution = 500;
        law = new DelegateSelect(
            "Call role 2 election", // max 31 chars
            "Anyone can call (and pay for) an election to assign accounts to role 2. Address can be added to revoke roles. The nominated accounts with most delegated vote tokens will be assigned to role 2. The law can only be called once every 500 blocks.",
            dao_, // separated powers protocol.
            type(uint32).max, // public access
            lawConfig, //  config file.
            mock20_, // the tokens that will be used as votes in the election.
            laws[4], // nominateMe
            3, // maximum amount of delegates
            2 // role id to be assigned
        );
        vm.stopBroadcast();
        laws.push(address(law));
        delete lawConfig;

        // law[6]
        vm.startBroadcast();
        law = new NominateMe(
            "Nominate self for role 1", // max 31 chars
            "Anyone can nominate themselves for role 1.",
            dao_,
            type(uint32).max, // access role = public access
            lawConfig
        );
        vm.stopBroadcast();
        laws.push(address(law));

        // law[7]
        lawConfig.quorum = 20; // = Only 20% quorum needed
        lawConfig.succeedAt = 66; // = but at least 2/3 majority needed for assigning and revoking members.
        lawConfig.votingPeriod = 1200; // = number of blocks
        // initiate law
        vm.startBroadcast();
        law = new PeerSelect(
            "(De)select account for role 1", // max 31 chars
            "Propose to (de)select an account for role 1.",
            dao_,
            1, // access role
            lawConfig,
            15, // max amount of seniors
            laws[6], // nominateMe
            2 // role id to be assigned
        );
        vm.stopBroadcast();
        laws.push(address(law)); // log address
        delete lawConfig; // reset lawConfig before next usage.
    }
}
