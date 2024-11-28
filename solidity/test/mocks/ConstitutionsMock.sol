// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import { DaoMock } from "./DaoMock.sol";
import { Law } from "../../src/Law.sol";
import { ILaw } from "../../src/interfaces/ILaw.sol";
import { Erc1155Mock } from "./Erc1155Mock.sol";
// electoral laws
import { TokensSelect } from "../../src/implementations/laws/electoral/TokensSelect.sol";
import { DirectSelect } from "../../src/implementations/laws/electoral/DirectSelect.sol";
import { DelegateSelect } from "../../src/implementations/laws/electoral/DelegateSelect.sol";
import { RandomlySelect } from "../../src/implementations/laws/electoral/RandomlySelect.sol";
import { NominateMe } from "../../src/implementations/laws/electoral/NominateMe.sol";
// executive laws. 
import { ProposalOnly } from "../../src/implementations/laws/executive/ProposalOnly.sol";
import { OpenAction } from "../../src/implementations/laws/executive/OpenAction.sol";
import { PresetAction } from "../../src/implementations/laws/executive/PresetAction.sol";
import { BespokeAction } from "../../src/implementations/laws/executive/BespokeAction.sol";

contract ConstitutionsMock {
    uint32 public numberOfLaws;

    //////////////////////////////////////////////////////////////
    //                  FIRST CONSTITUTION                      //
    //////////////////////////////////////////////////////////////
    function initiateSeparatedPowersConstitution(address payable dao_, address payable mock1155_)
        external
        returns (
            address[] memory laws,
            uint32[] memory allowedRoles,
            ILaw.LawConfig[] memory lawsConfig
        )
    {
        numberOfLaws = 6;
        laws = new address[](numberOfLaws);
        allowedRoles = new uint32[](numberOfLaws);
        lawsConfig = new ILaw.LawConfig[](numberOfLaws);

        // dummy data
        address[] memory targets = new address[](1);
        uint256[] memory values = new uint256[](1);
        bytes[] memory calldatas = new bytes[](1);
        targets[0] = address(333);
        values[0] = 333;
        calldatas[0] = "0x1111";

        laws[0] = address(
            new DirectSelect(
                "ROLE_ONE = open", // max 31 chars
                "Anyone can apply for ROLE_ONE",
                dao_,
                DaoMock(dao_).ROLE_ONE()
            )
        );
        // add necessary configurations
        allowedRoles[0] = type(uint32).max;

        laws[1] = address(
            new NominateMe(
                "ROLE_TWO nominees", // max 31 chars
                "Anyone can nominate themselves for ROLE_TWO",
                dao_
            )
        );

        laws[2] = address(
            new TokensSelect(
                "ROLE_ONE elects ROLE_TWO", // max 31 chars
                "ROLE_ONE holders can call (and pay for) a whale election at any time. They can also nominate themselves.",
                dao_,
                mock1155_,
                laws[1], 
                15,
                DaoMock(dao_).ROLE_TWO()
            )
        );
        // configuration law
        allowedRoles[2] = DaoMock(dao_).ROLE_ONE();

        // Note this proposalOnly law has no internal data, as such it cannot actually do anyting.
        // This law is only for example and testing purposes.
        bytes4[] memory params = new bytes4[](0);
        laws[3] = address(
            new ProposalOnly(
                "ROLE_THREE makes proposals", // max 31 chars
                "ROLE_THREE holders can make any proposal, without vote.",
                dao_, 
                params
            )
        );
        allowedRoles[3] = DaoMock(dao_).ROLE_THREE();

        laws[4] = address(
            new OpenAction(
                "ROLE_TWO accepts proposal", // max 31 chars
                "ROLE_TWO holders can vote on and accept proposal proposed by ROLE_THREE.",
                dao_
            )
        );
        allowedRoles[4] = DaoMock(dao_).ROLE_TWO();
        lawsConfig[4].quorum = 20;
        lawsConfig[4].succeedAt = 66;
        lawsConfig[4].votingPeriod = 1200;
        lawsConfig[4].needCompleted = laws[2];

        laws[5] = address(
            new PresetAction(
                "ROLE_ONE votes on preset action", // max 31 chars
                "ROLE_ONE can vote on executing preset actions",
                dao_,
                targets,
                values,
                calldatas
            )
        );
        allowedRoles[5] = DaoMock(dao_).ROLE_ONE();
        lawsConfig[5].quorum = 20;
        lawsConfig[5].succeedAt = 66;
        lawsConfig[5].votingPeriod = 1200;
    }

    //////////////////////////////////////////////////////////////
    //                  SECOND CONSTITUTION                     //
    //////////////////////////////////////////////////////////////
    function initiateBasic(address payable dao_, address payable mock1155_)
        external
        returns (
            address[] memory laws,
            uint32[] memory allowedRoles,
            ILaw.LawConfig[] memory lawsConfig
        )
    {
        numberOfLaws = 1;
        laws = new address[](numberOfLaws);
        allowedRoles = new uint32[](numberOfLaws);
        ILaw.LawConfig[] memory lawsConfig = new ILaw.LawConfig[](numberOfLaws);

        laws[0] = address(
            new OpenAction(
                "ROLE_ONE can do anything", // max 31 chars
                "ROLE_ONE holders have the power to execute any internal or external action.",
                dao_
            )
        );
        allowedRoles[0] = DaoMock(dao_).ROLE_ONE();
    }

    //////////////////////////////////////////////////////////////
    //                  THIRD CONSTITUTION                     //
    //////////////////////////////////////////////////////////////
    function initiateLawTestConstitution(address payable dao_, address payable mock1155_)
        external
        returns (
            address[] memory laws,
            uint32[] memory allowedRoles,
            ILaw.LawConfig[] memory lawsConfig
        )
    {
        numberOfLaws = 5;
        laws = new address[](numberOfLaws);
        allowedRoles = new uint32[](numberOfLaws);
        lawsConfig = new ILaw.LawConfig[](numberOfLaws);

        // dummy call: mint coins at mock1155 contract.
        address[] memory targets = new address[](1);
        uint256[] memory values = new uint256[](1);
        bytes[] memory calldatas = new bytes[](1);
        targets[0] = mock1155_;
        values[0] = 0;
        calldatas[0] = abi.encodeWithSelector(Erc1155Mock.mintCoins.selector, 123);

        laws[0] = address(
            new PresetAction(
                "Needs Proposal Vote", // max 31 chars
                "Needs Proposal Vote to pass",
                dao_,
                targets,
                values,
                calldatas
            )
        );
        allowedRoles[0] = DaoMock(dao_).ROLE_ONE();
        lawsConfig[0].quorum = 20;
        lawsConfig[0].succeedAt = 66;
        lawsConfig[0].votingPeriod = 1200;

        laws[1] = address(
            new PresetAction(
                "Needs Parent Completed", // max 31 chars
                "Needs Parent Completed to pass",
                dao_,
                targets,
                values,
                calldatas
            )
        );
        allowedRoles[1] = DaoMock(dao_).ROLE_ONE();
        lawsConfig[1].needCompleted = laws[0];

        laws[2] = address(
            new PresetAction(
                "Parent Can Block", // max 31 chars
                "Parent can block a law, making it impossible to pass",
                dao_,
                targets,
                values,
                calldatas
            )
        );
        allowedRoles[2] = DaoMock(dao_).ROLE_ONE();
        lawsConfig[2].needNotCompleted = laws[0];

        laws[3] = address(
            new PresetAction(
                "Delay Execution", // max 31 chars
                "Delay execution of a law, by a preset number of blocks. ",
                dao_,
                targets,
                values,
                calldatas
            )
        );
        allowedRoles[3] = DaoMock(dao_).ROLE_ONE();
        lawsConfig[3].quorum = 20;
        lawsConfig[3].succeedAt = 66;
        lawsConfig[3].votingPeriod = 1200;
        lawsConfig[3].delayExecution = 5000;

        laws[4] = address(
            new PresetAction(
                "Throttle Executions", // max 31 chars
                "Throttle the number of executions of a by setting minimum time that should have passed since last execution.",
                dao_,
                targets,
                values,
                calldatas
            )
        );
        allowedRoles[4] = DaoMock(dao_).ROLE_ONE();
        lawsConfig[4].throttleExecution = 10; 
    }

    //////////////////////////////////////////////////////////////
    //                  FOURTH CONSTITUTION                     //
    //////////////////////////////////////////////////////////////
    function initiateImplementationConstitution(address payable dao_, address payable mock1155_, address payable mock20_)
        external
        returns (
            address[] memory laws,
            uint32[] memory allowedRoles,
            ILaw.LawConfig[] memory lawsConfig
        )
    {
        numberOfLaws = 9;
        laws = new address[](numberOfLaws);
        allowedRoles = new uint32[](numberOfLaws);
        lawsConfig = new ILaw.LawConfig[](numberOfLaws);

        // dummy call: mint coins at mock1155 contract.
        address[] memory targets = new address[](1);
        uint256[] memory values = new uint256[](1);
        bytes[] memory calldatas = new bytes[](1);
        targets[0] = mock1155_;
        values[0] = 0;
        calldatas[0] = abi.encodeWithSelector(Erc1155Mock.mintCoins.selector, 123);

        // dummy params
        bytes4[] memory params = new bytes4[](1);

        // executive laws 
        laws[0] = address(
            new ProposalOnly(
                "Proposal Only With Vote", // max 31 chars
                "Proposal Only With Vote to pass.",
                dao_,
                params
            )
        );
        allowedRoles[0] = DaoMock(dao_).ROLE_ONE();
        lawsConfig[0].quorum = 20; 
        lawsConfig[0].succeedAt = 66;
        lawsConfig[0].votingPeriod = 1200;

        laws[1] = address(
            new OpenAction(
                "Open Action", // max 31 chars
                "Execute an action, any action.",
                dao_
            )
        );
        allowedRoles[1] = DaoMock(dao_).ROLE_ONE();
        
        // need to setup a memory array of bytes4 for setting bespoke params 
        bytes4[] memory bespokeParams = new bytes4[](1);
        bespokeParams[0] = bytes4(keccak256("uint256"));
        laws[2] = address(
            new BespokeAction(
                "Bespoke Action", // max 31 chars
                "Execute any action, but confined by a contract and function selector.",
                dao_, 
                mock1155_, // target contract that can be called. 
                Erc1155Mock.mintCoins.selector, // the function selector that can be called.
                bespokeParams
            )
        );
        allowedRoles[2] = DaoMock(dao_).ROLE_ONE();

        laws[3] = address(
            new NominateMe(
                "Nominate for any role", // max 31 chars
                "This is a placeholder nomination law.",
                dao_
            )
        );
        allowedRoles[3] = DaoMock(dao_).ROLE_ONE();

        // electoral laws // 
        laws[4] = address(
            new DirectSelect(
                "Direct select role", // max 31 chars
                "Directly select a role.",
                dao_,
                DaoMock(dao_).ROLE_THREE() 
            )
        );
        allowedRoles[4] = DaoMock(dao_).ROLE_ONE();

        laws[5] = address(
            new RandomlySelect(
                "Randomly select role", // max 31 chars
                "Randomly select a role.",
                dao_,
                laws[3], 
                3, // max role holders 
                DaoMock(dao_).ROLE_THREE() // role id. 
            )
        );
        allowedRoles[5] = DaoMock(dao_).ROLE_ONE();

        laws[6] = address(
            new TokensSelect(
                "ROLE_ONE can do anything", // max 31 chars
                "ROLE_ONE holders have the power to execute any internal or external action.",
                dao_,
                mock1155_,
                laws[3], 
                3, // max role holders 
                DaoMock(dao_).ROLE_THREE() // role id. 
            )
        );
        allowedRoles[6] = DaoMock(dao_).ROLE_ONE();

        laws[7] = address(
            new DelegateSelect(
                "Delegate Select", // max 31 chars
                "Select a role by delegated votes.",
                dao_,
                mock20_,
                laws[3], // NominateMe contract. 
                3, // max role holders 
                DaoMock(dao_).ROLE_THREE() // role id. 
            )
        );
        allowedRoles[7] = DaoMock(dao_).ROLE_ONE();

         laws[8] = address(
            new ProposalOnly(
                "Proposal Only", // max 31 chars
                "Proposal Only without vote or other checks.",
                dao_,
                params
            )
        );
        allowedRoles[8] = DaoMock(dao_).ROLE_ONE();0;

        // PresetAction sufficiently tested.

    }
}
