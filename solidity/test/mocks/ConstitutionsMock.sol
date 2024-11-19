// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import { DaoMock } from "./DaoMock.sol";
import { Law } from "../../src/Law.sol";
import { TokensSelect } from "../../src/implementations/laws/electoral/TokensSelect.sol";
import { OpenAction } from "../../src/implementations/laws/executive/OpenAction.sol";
import { DirectSelect } from "../../src/implementations/laws/electoral/DirectSelect.sol";
import { ProposalOnly } from "../../src/implementations/laws/executive/ProposalOnly.sol";
import { VoteOnProposedAction } from "../../src/implementations/laws/bespoke/VoteOnProposedAction.sol";
import { VoteOnPresetAction } from "../../src/implementations/laws/bespoke/VoteOnPresetAction.sol";
import {
    NeedsProposalVote,
    NeedsParentCompleted,
    ParentCanBlock,
    DelayProposalExecution,
    LimitExecutions
} from "./LawsMock.sol";

contract ConstitutionsMock {
    uint32 public numberOfLaws;

    //////////////////////////////////////////////////////////////
    //                  FIRST CONSTITUTION                      //
    //////////////////////////////////////////////////////////////
    function initiateFirst(address payable dao_, address payable mock1155_)
        external
        returns (
            address[] memory laws,
            uint32[] memory allowedRoles,
            uint8[] memory quorums,
            uint8[] memory succeedAts,
            uint32[] memory votingPeriods
        )
    {
        numberOfLaws = 5;
        laws = new address[](numberOfLaws);
        allowedRoles = new uint32[](numberOfLaws);
        quorums = new uint8[](numberOfLaws);
        succeedAts = new uint8[](numberOfLaws);
        votingPeriods = new uint32[](numberOfLaws);

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
            new TokensSelect(
                "ROLE_ONE elects ROLE_TWO", // max 31 chars
                "ROLE_ONE holders can call (and pay for) a whale election at any time. They can also nominate themselves.",
                dao_,
                mock1155_,
                15,
                DaoMock(dao_).ROLE_TWO()
            )
        );
        // configuration law
        allowedRoles[1] = DaoMock(dao_).ROLE_ONE();

        // Note this proposalOnly law has no internal data, as such it cannot actually do anyting.
        // This law is only for example and testing purposes.
        laws[2] = address(
            new ProposalOnly(
                "ROLE_THREE makes proposals", // max 31 chars
                "ROLE_THREE holders can make any proposal, without vote.",
                dao_
            )
        );
        allowedRoles[2] = DaoMock(dao_).ROLE_THREE();

        laws[3] = address(
            new VoteOnProposedAction(
                "ROLE_TWO accepts proposal", // max 31 chars
                "ROLE_TWO holders can vote on and accept proposal proposed by ROLE_THREE.",
                dao_,
                laws[2]
            )
        );
        allowedRoles[3] = DaoMock(dao_).ROLE_TWO();
        quorums[3] = 20; // = 30% quorum needed
        succeedAts[3] = 66; // = 51% simple majority needed for assigning and revoking members.
        votingPeriods[3] = 1200; // = number of blocks

        laws[4] = address(
            new VoteOnPresetAction(
                "ROLE_ONE votes on preset action", // max 31 chars
                "ROLE_ONE can vote on executing preset actions",
                dao_,
                targets,
                values,
                calldatas
            )
        );
        allowedRoles[4] = DaoMock(dao_).ROLE_ONE();
        quorums[4] = 20; // = 30% quorum needed
        succeedAts[4] = 66; // = 51% simple majority needed for assigning and revoking members.
        votingPeriods[4] = 1200; // = number of blocks

        return (laws, allowedRoles, quorums, succeedAts, votingPeriods);
    }

    //////////////////////////////////////////////////////////////
    //                  SECOND CONSTITUTION                     //
    //////////////////////////////////////////////////////////////
    function initiateSecond(address payable dao_, address payable mock1155_)
        external
        returns (
            address[] memory laws,
            uint32[] memory allowedRoles,
            uint8[] memory quorums,
            uint8[] memory succeedAts,
            uint32[] memory votingPeriods
        )
    {
        numberOfLaws = 1;
        laws = new address[](numberOfLaws);
        allowedRoles = new uint32[](numberOfLaws);
        quorums = new uint8[](numberOfLaws);
        succeedAts = new uint8[](numberOfLaws);
        votingPeriods = new uint32[](numberOfLaws);

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
    function initiateThird(address payable dao_, address payable mock1155_)
        external
        returns (
            address[] memory laws,
            uint32[] memory allowedRoles,
            uint8[] memory quorums,
            uint8[] memory succeedAts,
            uint32[] memory votingPeriods
        )
    {
        numberOfLaws = 5;
        laws = new address[](numberOfLaws);
        allowedRoles = new uint32[](numberOfLaws);
        quorums = new uint8[](numberOfLaws);
        succeedAts = new uint8[](numberOfLaws);
        votingPeriods = new uint32[](numberOfLaws);

        // dummy call: mint coins at mock1155 contract.
        address[] memory targets = new address[](1);
        uint256[] memory values = new uint256[](1);
        bytes[] memory calldatas = new bytes[](1);
        targets[0] = mock1155_;
        values[0] = 0;
        calldatas[0] = abi.encodeWithSignature("mintCoins(uint256)", 123);

        laws[0] = address(
            new NeedsProposalVote(
                "Needs Proposal Vote", // max 31 chars
                "Needs Proposal Vote to pass",
                dao_,
                targets,
                values,
                calldatas
            )
        );
        allowedRoles[0] = DaoMock(dao_).ROLE_ONE();
        quorums[0] = 20;
        succeedAts[0] = 66;
        votingPeriods[0] = 1200;

        laws[1] = address(
            new NeedsParentCompleted(
                "Needs Parent Completed", // max 31 chars
                "Needs Parent Completed to pass",
                dao_,
                targets,
                values,
                calldatas,
                laws[0]
            )
        );
        allowedRoles[1] = DaoMock(dao_).ROLE_ONE();

        laws[2] = address(
            new ParentCanBlock(
                "Parent Can Block", // max 31 chars
                "Parent can block a law, making it impossible to pass",
                dao_,
                targets,
                values,
                calldatas,
                laws[0]
            )
        );
        allowedRoles[2] = DaoMock(dao_).ROLE_ONE();

        laws[3] = address(
            new DelayProposalExecution(
                "Delay Execution", // max 31 chars
                "Delay execution of a law, by a preset number of blocks. ",
                dao_,
                targets,
                values,
                calldatas,
                5000 // = delay in blocks
            )
        );
        allowedRoles[3] = DaoMock(dao_).ROLE_ONE();
        quorums[3] = 20;
        succeedAts[3] = 66;
        votingPeriods[3] = 1200;

        laws[4] = address(
            new LimitExecutions(
                "Limit Executions", // max 31 chars
                "Limit the number of executions of a law, either as absolute number or relative to previous execution.",
                dao_,
                targets,
                values,
                calldatas,
                10, // = absolute number of executions
                10 // = relative number of executions
            )
        );
        allowedRoles[4] = DaoMock(dao_).ROLE_ONE();

        //////////////////////////////////////////////////////////////
        //                  RETURN CONSTITUTION                     //
        //////////////////////////////////////////////////////////////
        return (laws, allowedRoles, quorums, succeedAts, votingPeriods);
    }
}
