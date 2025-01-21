// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import "forge-std/Test.sol";
import { ISeparatedPowers } from "../../src/interfaces/ISeparatedPowers.sol";
import { Law } from "../../src/Law.sol";
import { ILaw } from "../../src/interfaces/ILaw.sol";
import { Erc1155Mock } from "./Erc1155Mock.sol";
import { DaoMock } from "./DaoMock.sol";
import { BaseSetup } from "../TestSetup.t.sol";

// electoral laws
import { TokensSelect } from "../../src/laws/electoral/TokensSelect.sol";
import { DirectSelect } from "../../src/laws/electoral/DirectSelect.sol";
import { DelegateSelect } from "../../src/laws/electoral/DelegateSelect.sol";
import { RandomlySelect } from "../../src/laws/electoral/RandomlySelect.sol";
import { NominateMe } from "../../src/laws/electoral/NominateMe.sol";
// executive laws.
import { ProposalOnly } from "../../src/laws/executive/ProposalOnly.sol";
import { OpenAction } from "../../src/laws/executive/OpenAction.sol";
import { PresetAction } from "../../src/laws/executive/PresetAction.sol";
import { BespokeAction } from "../../src/laws/executive/BespokeAction.sol";
 
contract ConstitutionsMock is Test {
    //////////////////////////////////////////////////////////////
    //                  FIRST CONSTITUTION                      //
    //////////////////////////////////////////////////////////////
    function initiateSeparatedPowersConstitution(address payable dao_, address payable mock1155_)
        external
        returns (address[] memory laws)
    {
        Law law;
        ILaw.LawConfig memory lawConfig;
        laws = new address[](7);

        // dummy call.
        address[] memory targets = new address[](1);
        uint256[] memory values = new uint256[](1);
        bytes[] memory calldatas = new bytes[](1);
        targets[0] = address(123);
        calldatas[0] = abi.encode("mockCall");

        law = new DirectSelect(
            "1 = open", // max 31 chars
            "Anyone can apply for 1",
            dao_,
            type(uint32).max, // access role
            lawConfig, // empty config file.
            1
        );
        laws[0] = address(law);

        law = new NominateMe(
            "2 nominees", // max 31 chars
            "Anyone can nominate themselves for 2",
            dao_,
            type(uint32).max, // access role
            lawConfig // empty config file.
        );
        laws[1] = address(law);

        law = new TokensSelect(
            "1 elects 2", // max 31 chars
            "1 holders can call (and pay for) a whale election at any time. They can also nominate themselves.",
            dao_,
            1,
            lawConfig, // empty config file.
            // bespoke configs for this law:
            mock1155_,
            laws[1],
            15,
            2
        );
        laws[2] = address(law);

        // Note this proposalOnly law has no internal data, as such it cannot actually do anyting.
        // This law is only for example and testing purposes.
        string[] memory params = new string[](0);
        law = new ProposalOnly(
            "3 makes proposals", // max 31 chars
            "3 holders can make any proposal, without vote.",
            dao_,
            3,
            lawConfig, // empty config file.
            // bespoke configs for this law:
            params
        );
        laws[3] = address(law);

        // setting up config file
        lawConfig.quorum = 20; // = 30% quorum needed
        lawConfig.succeedAt = 66; // = 51% simple majority needed for assigning and revoking members.
        lawConfig.votingPeriod = 1200; // = number of blocks
        lawConfig.needCompleted = laws[2];
        // initiating law.
        law = new OpenAction(
            "2 accepts proposal", // max 31 chars
            "2 holders can vote on and accept proposal proposed by 3.",
            dao_,
            2, // access role
            lawConfig
        );
        // bespoke configs for this law:
        laws[4] = address(law);
        delete lawConfig;

        // setting up config file
        lawConfig.quorum = 30; // = 30% quorum needed
        lawConfig.succeedAt = 51; // = 51% simple majority needed for assigning and revoking members.
        lawConfig.votingPeriod = 1200; // = number of blocks
        // initiating law.
        law = new PresetAction(
            "1 votes on preset action", // max 31 chars
            "1 can vote on executing preset actions",
            dao_,
            1, // access role
            lawConfig, // config file.
            // bespoke configs for this law:
            targets,
            values,
            calldatas
        );
        laws[5] = address(law);
        delete lawConfig;

        // get calldata
        (address[] memory targetsRoles, uint256[] memory valuesRoles, bytes[] memory calldatasRoles) = _getRoles(dao_);
        // set config
        // setting the throttle to max means the law can only be called once.
        lawConfig.throttleExecution = type(uint48).max - uint48(block.number);
        // initiate law
        vm.startBroadcast();
        law = new PresetAction(
            "Admin assigns initial roles",
            "The admin assigns initial roles. This law can only be used once.",
            dao_, // separated powers
            0, // access role = ADMIN
            lawConfig,
            targetsRoles,
            valuesRoles,
            calldatasRoles
        );
        vm.stopBroadcast();
        laws[6] = address(law);
        delete lawConfig;
    }

    //////////////////////////////////////////////////////////////
    //                  SECOND CONSTITUTION                     //
    //////////////////////////////////////////////////////////////
    function initiateBasic(address payable dao_, address payable /* mock1155_ */ )
        external
        returns (address[] memory laws)
    {
        laws = new address[](1);

        Law law;
        ILaw.LawConfig memory lawConfig;
        law = new OpenAction(
            "Admin can do anything", // max 31 chars
            "The admin has the power to execute any internal or external action.",
            dao_,
            0, // access role
            lawConfig // empty config file.
                // bespoke configs for this law:
        );
        laws[0] = address(law);
    }

    //////////////////////////////////////////////////////////////
    //                  THIRD CONSTITUTION                     //
    //////////////////////////////////////////////////////////////
    function initiateLawTestConstitution(address payable dao_, address payable mock1155_)
        external
        returns (address[] memory laws)
    {
        Law law;
        laws = new address[](6);

        // dummy call: mint coins at mock1155 contract.
        address[] memory targets = new address[](1);
        uint256[] memory values = new uint256[](1);
        bytes[] memory calldatas = new bytes[](1);
        targets[0] = mock1155_;
        values[0] = 0;
        calldatas[0] = abi.encodeWithSelector(Erc1155Mock.mintCoins.selector, 123);

        // setting up config file
        ILaw.LawConfig memory lawConfig;
        lawConfig.quorum = 20; // = 30% quorum needed
        lawConfig.succeedAt = 66; // = 51% simple majority needed for assigning and revoking members.
        lawConfig.votingPeriod = 1200; // = number of blocks
        // initiating law.
        law = new PresetAction(
            "Needs Proposal Vote", // max 31 chars
            "Needs Proposal Vote to pass",
            dao_,
            1, // access role
            lawConfig, // empty config file.
            // bespoke configs for this law:
            targets,
            values,
            calldatas
        );
        laws[0] = address(law);

        // setting up config file
        delete lawConfig;
        lawConfig.needCompleted = laws[0];
        // initiating law.
        law = new PresetAction(
            "Needs Parent Completed", // max 31 chars
            "Needs Parent Completed to pass",
            dao_,
            1, // access role
            lawConfig, // empty config file.
            // bespoke configs for this law:
            targets,
            values,
            calldatas
        );
        laws[1] = address(law);

        // setting up config file
        delete lawConfig;
        lawConfig.needNotCompleted = laws[0];
        // initiating law.
        law = new PresetAction(
            "Parent Can Block", // max 31 chars
            "Parent can block a law, making it impossible to pass",
            dao_,
            1, // access role
            lawConfig, // empty config file.
            // bespoke configs for this law:
            targets,
            values,
            calldatas
        );
        laws[2] = address(law);

        // setting up config file
        delete lawConfig;
        lawConfig.quorum = 30; // = 30% quorum needed
        lawConfig.succeedAt = 51; // = 51% simple majority needed for assigning and revoking members.
        lawConfig.votingPeriod = 1200; // = number of blocks
        lawConfig.delayExecution = 5000;
        // initiating law.
        law = new PresetAction(
            "Delay Execution", // max 31 chars
            "Delay execution of a law, by a preset number of blocks . ",
            dao_,
            1, // access role
            lawConfig, // empty config file.
            // bespoke configs for this law:
            targets,
            values,
            calldatas
        );
        laws[3] = address(law);

        // setting up config file
        delete lawConfig;
        lawConfig.throttleExecution = 10;
        // initiating law.
        law = new PresetAction(
            "Throttle Executions", // max 31 chars
            "Throttle the number of executions of a by setting minimum time that should have passed since last execution.",
            dao_,
            1, // access role
            lawConfig, // empty config file.
            // bespoke configs for this law:
            targets,
            values,
            calldatas
        );
        laws[4] = address(law);

        // get calldata
        (address[] memory targetsRoles, uint256[] memory valuesRoles, bytes[] memory calldatasRoles) = _getRoles(dao_);
        // set config
        // setting the throttle to max means the law can only be called once.
        lawConfig.throttleExecution = type(uint48).max - uint48(block.number);
        // initiate law
        vm.startBroadcast();
        law = new PresetAction(
            "Admin assigns initial roles",
            "The admin assigns initial roles. This law can only be used once.",
            dao_, // separated powers
            0, // access role = ADMIN
            lawConfig,
            targetsRoles,
            valuesRoles,
            calldatasRoles
        );
        vm.stopBroadcast();
        laws[5] = address(law);
        delete lawConfig;
    }

    //////////////////////////////////////////////////////////////
    //                  FOURTH CONSTITUTION                     //
    //////////////////////////////////////////////////////////////
    function initiateLawsTestConstitution(address payable dao_, address payable mock1155_, address payable mock20_)
        external
        returns (address[] memory laws)
    {
        Law law;
        laws = new address[](14);
        ILaw.LawConfig memory lawConfig;

        // dummy call: mint coins at mock1155 contract.
        address[] memory targets = new address[](1);
        uint256[] memory values = new uint256[](1);
        bytes[] memory calldatas = new bytes[](1);
        targets[0] = mock1155_;
        values[0] = 0;
        calldatas[0] = abi.encodeWithSelector(Erc1155Mock.mintCoins.selector, 123);

        // dummy params
        string[] memory params = new string[](0);

        // setting up config file
        lawConfig.quorum = 30; // = 30% quorum needed
        lawConfig.succeedAt = 51; // = 51% simple majority needed for assigning and revoking members.
        lawConfig.votingPeriod = 1200; // = number of blocks
        // initiating law.
        law = new ProposalOnly(
            "Proposal Only With Vote", // max 31 chars
            "Proposal Only With Vote to pass.",
            dao_,
            1, // access role
            lawConfig, // empty config file.
            // bespoke configs for this law:
            params
        );
        laws[0] = address(law);
        delete lawConfig; // reset lawConfig.

        law = new OpenAction(
            "Open Action", // max 31 chars
            "Execute an action, any action.",
            dao_,
            1, // access role
            lawConfig // empty config file.
                // bespoke configs for this law:
        );
        laws[1] = address(law);

        // need to setup a memory array of bytes4 for setting bespoke params
        string[] memory bespokeParams = new string[](1); 
        bespokeParams[0] = "uint256";
        law = new BespokeAction(
            "Bespoke Action", // max 31 chars
            "Execute any action, but confined by a contract and function selector.",
            dao_,
            1, // access role
            lawConfig, // empty config file.
            // bespoke configs for this law:
            mock1155_, // target contract that can be called.
            Erc1155Mock.mintCoins.selector, // the function selector that can be called.
            bespokeParams
        );
        laws[2] = address(law);

        law = new NominateMe(
            "Nominate for any role", // max 31 chars
            "This is a placeholder nomination law.",
            dao_,
            1, // access role
            lawConfig // empty config file.
                // bespoke configs for this law:
        );
        laws[3] = address(law);

        // electoral laws //
        law = new DirectSelect(
            "Direct select role", // max 31 chars
            "Directly select a role.",
            dao_,
            1, // access role
            lawConfig, // empty config file.
            // bespoke configs for this law:
            3
        );
        laws[4] = address(law);

        law = new RandomlySelect(
            "Randomly select role", // max 31 chars
            "Randomly select a role.",
            dao_,
            1, // access role
            lawConfig, // empty config file.
            // bespoke configs for this law:
            laws[3],
            3, // max role holders
            3 // role id.
        );
        laws[5] = address(law);

        law = new TokensSelect(
            "1 can do anything", // max 31 chars
            "1 holders have the power to execute any internal or external action.",
            dao_,
            1, // access role
            lawConfig, // empty config file.
            // bespoke configs for this law:
            mock1155_,
            laws[3],
            3, // max role holders
            3 // role id.
        );
        laws[6] = address(law);

        law = new DelegateSelect(
            "Delegate Select", // max 31 chars
            "Select a role by delegated votes.",
            dao_,
            1, // access role
            lawConfig, // empty config file.
            // bespoke configs for this law:
            mock20_,
            laws[3], // NominateMe contract.
            3, // max role holders
            3 // role id.
        );
        laws[7] = address(law);

        law = new ProposalOnly(
            "Proposal Only", // max 31 chars
            "Proposal Only without vote or other checks.",
            dao_,
            1, // access role
            lawConfig, // empty config file.
            // bespoke configs for this law:
            params
        );
        laws[8] = address(law);

        // get calldata
        (address[] memory targetsRoles, uint256[] memory valuesRoles, bytes[] memory calldatasRoles) = _getRoles(dao_);
        // set config
        delete lawConfig; // reset lawConfig
        // config
        // setting the throttle to max means the law can only be called once.
        lawConfig.throttleExecution = type(uint48).max - uint48(block.number);
        // initiate law
        vm.startBroadcast();
        law = new PresetAction(
            "Admin assigns initial roles",
            "The admin assigns initial roles. This law can only be used once.",
            dao_, // separated powers
            0, // access role = ADMIN
            lawConfig,
            targetsRoles,
            valuesRoles,
            calldatasRoles
        );
        vm.stopBroadcast();
        laws[9] = address(law);
        delete lawConfig; // reset lawConfig
    }

    function _getRoles(address payable dao_)
        internal
        returns (address[] memory targets, uint256[] memory values, bytes[] memory calldatas)
    {
        // create addresses.
        address alice = makeAddr("alice");
        address bob = makeAddr("bob");
        address charlotte = makeAddr("charlotte");
        address david = makeAddr("david");
        address eve = makeAddr("eve");
        address frank = makeAddr("frank");
        address gary = makeAddr("gary");
        address helen = makeAddr("helen");

        // call to set initial roles. Also used as dummy call data.
        targets = new address[](13);
        values = new uint256[](13);
        calldatas = new bytes[](13);
        for (uint256 i = 0; i < targets.length; i++) {
            targets[i] = dao_;
        }

        calldatas[0] = abi.encodeWithSelector(ISeparatedPowers.assignRole.selector, 1, alice);
        calldatas[1] = abi.encodeWithSelector(ISeparatedPowers.assignRole.selector, 1, bob);
        calldatas[2] = abi.encodeWithSelector(ISeparatedPowers.assignRole.selector, 1, charlotte);
        calldatas[3] = abi.encodeWithSelector(ISeparatedPowers.assignRole.selector, 1, david);
        calldatas[4] = abi.encodeWithSelector(ISeparatedPowers.assignRole.selector, 1, eve);
        calldatas[5] = abi.encodeWithSelector(ISeparatedPowers.assignRole.selector, 1, frank);
        calldatas[6] = abi.encodeWithSelector(ISeparatedPowers.assignRole.selector, 1, gary);
        calldatas[7] = abi.encodeWithSelector(ISeparatedPowers.assignRole.selector, 1, helen);
        calldatas[8] = abi.encodeWithSelector(ISeparatedPowers.assignRole.selector, 2, alice);
        calldatas[9] = abi.encodeWithSelector(ISeparatedPowers.assignRole.selector, 2, bob);
        calldatas[10] = abi.encodeWithSelector(ISeparatedPowers.assignRole.selector, 2, charlotte);
        calldatas[11] = abi.encodeWithSelector(ISeparatedPowers.assignRole.selector, 3, alice);
        calldatas[12] = abi.encodeWithSelector(ISeparatedPowers.assignRole.selector, 3, bob);

        return (targets, values, calldatas);
    }
}
