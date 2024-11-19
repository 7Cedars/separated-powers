// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.26;

import "forge-std/Test.sol";
import "@openzeppelin/contracts/utils/ShortStrings.sol";
import { SeparatedPowers } from "../../src/SeparatedPowers.sol";
import { TestSetupLaw } from "../TestSetup.t.sol";
import { OpenAction } from "../../src/implementations/laws/executive/OpenAction.sol";
import { Law } from "../../src/Law.sol";
import { NeedsParentCompleted, ParentCanBlock, DelayProposalExecution } from "../mocks/LawsMock.sol";

//////////////////////////////////////////////////
//                  DEPLOY                      //
//////////////////////////////////////////////////
contract DeployTest is TestSetupLaw {
    using ShortStrings for *;

    function testDeploy() public {
        Law lawMock = new OpenAction("OpenAction Mock", "This is a mock of the open action law contract", address(123));

        string memory lawMockName = lawMock.name().toString();
        string memory lawMockDescription = lawMock.description();

        assertEq(lawMockName, "OpenAction Mock");
        assertEq(lawMockDescription, "This is a mock of the open action law contract");
        assertEq(lawMock.separatedPowers(), address(123));
    }

    function testDeployEmitsEvent() public {
        vm.expectEmit(false, false, false, false);
        emit Law__Initialized(address(0));
        Law lawMock = new OpenAction("OpenAction Mock", "This is a mock of the open action law contract", address(123));
    }
}

//////////////////////////////////////////////////
//                 MODIFIERS                    //
//////////////////////////////////////////////////
contract NeedsProposalVoteTest is TestSetupLaw {
    function testExecuteLawSucceedsWithSuccessfulVote() public {
        // prep: create a proposal
        uint32 lawNumber = 0;
        string memory description = "Executing a proposal vote";
        bytes memory lawCalldata = abi.encode(true);
        vm.prank(alice);
        uint256 actionId = daoMock.propose(laws[lawNumber], lawCalldata, description);

        // Loop through users, they vote for the proposal
        for (uint256 i = 0; i < users.length; i++) {
            if (daoMock.hasRoleSince(users[i], allowedRoles[lawNumber]) != 0) {
                vm.prank(users[i]);
                daoMock.castVote(actionId, FOR);
            }
        }
        vm.roll(4000); // forward in time

        // act
        vm.prank(alice);
        daoMock.execute(laws[lawNumber], lawCalldata, keccak256(bytes(description)));

        // assert
        uint256 balance = erc1155Mock.balanceOf(address(daoMock), 0);
        assertEq(balance, 123);
    }

    function testLawRevertsWithUnsuccessfulVote() public {
        // prep: create a proposal
        uint32 lawNumber = 0;
        string memory description = "Executing a proposal vote";
        bytes memory lawCalldata = abi.encode(true);
        vm.prank(alice);
        uint256 actionId = daoMock.propose(laws[lawNumber], lawCalldata, description);

        // Loop through users, they vote against the proposal
        for (uint256 i = 0; i < users.length; i++) {
            if (daoMock.hasRoleSince(users[i], allowedRoles[lawNumber]) != 0) {
                vm.prank(users[i]);
                daoMock.castVote(actionId, AGAINST);
            }
        }
        vm.roll(4000); // forward in time

        // act & assert
        vm.expectRevert(Law__ProposalNotSucceeded.selector);
        vm.prank(alice);
        daoMock.execute(laws[lawNumber], lawCalldata, keccak256(bytes(description)));
    }

    function testLawRevertsIfVoteStillActive() public {
        // prep: create a proposal
        uint32 lawNumber = 0;
        string memory description = "Executing a proposal vote";
        bytes memory lawCalldata = abi.encode(true);
        vm.prank(alice);
        uint256 actionId = daoMock.propose(laws[lawNumber], lawCalldata, description);

        // act & assert
        vm.expectRevert(Law__ProposalNotSucceeded.selector);
        vm.prank(alice);
        daoMock.execute(laws[lawNumber], lawCalldata, keccak256(bytes(description)));
    }
}

contract NeedsParentCompletedTest is TestSetupLaw {
    function testLawSucceedsIfParentCompleted() public {
        // prep: create a parent proposal, vote & execute.
        uint32 lawNumber = 1;
        uint32 parentLawNumber = 0;
        string memory description = "Executing a proposal vote";
        bytes memory lawCalldata = abi.encode(true);
        vm.prank(alice);
        uint256 actionId = daoMock.propose(laws[parentLawNumber], lawCalldata, description);

        // Loop through users, they vote for the proposal
        for (uint256 i = 0; i < users.length; i++) {
            if (daoMock.hasRoleSince(users[i], allowedRoles[parentLawNumber]) != 0) {
                vm.prank(users[i]);
                daoMock.castVote(actionId, FOR);
            }
        }
        vm.roll(4000); // forward in time
        vm.prank(alice);
        daoMock.execute(laws[parentLawNumber], lawCalldata, keccak256(bytes(description)));
        // check if law has been set as completed.

        ActionState proposalState = daoMock.state(actionId);
        assertEq(uint8(proposalState), uint8(ActionState.Completed));

        uint256 balanceBefore = erc1155Mock.balanceOf(address(daoMock), 0);

        // act
        vm.prank(alice);
        daoMock.execute(laws[lawNumber], lawCalldata, keccak256(bytes(description)));

        // assert
        uint256 balanceAfter = erc1155Mock.balanceOf(address(daoMock), 0);
        assertEq(balanceBefore, balanceAfter - 123);
    }

    function testLawRevertsIfParentNotCompleted() public {
        // prep: create a parent proposal and have it be defeated.
        uint32 lawNumber = 1;
        uint32 parentLawNumber = 0;
        string memory description = "Executing a proposal vote";
        bytes memory lawCalldata = abi.encode(true);
        vm.prank(alice);
        uint256 actionId = daoMock.propose(laws[parentLawNumber], lawCalldata, description);

        // Loop through users, they vote against the proposal
        for (uint256 i = 0; i < users.length; i++) {
            if (daoMock.hasRoleSince(users[i], allowedRoles[parentLawNumber]) != 0) {
                vm.prank(users[i]);
                daoMock.castVote(actionId, AGAINST);
            }
        }
        vm.roll(4000); // forward in time
        ActionState proposalState = daoMock.state(actionId);
        assertEq(uint8(proposalState), uint8(ActionState.Defeated));

        // act & assert
        vm.expectRevert(Law__ParentNotCompleted.selector);
        vm.prank(alice);
        daoMock.execute(laws[lawNumber], lawCalldata, keccak256(bytes(description)));
    }

    function testLawRevertsIfParentAddressZero() public {
        // prep: create a mock data
        address[] memory targets = new address[](1);
        uint256[] memory values = new uint256[](1);
        bytes[] memory calldatas = new bytes[](1);
        targets[0] = address(erc1155Mock);
        values[0] = 0;
        calldatas[0] = abi.encodeWithSignature("mintCoins(uint256)", 123);

        // prep: create a mock law
        string memory description = "Executing a proposal vote";
        bytes memory lawCalldata = abi.encode(true);
        address mockLaw = address(
            new NeedsParentCompleted(
                "Needs Parent Completed", // max 31 chars
                "Needs Parent Completed to pass",
                address(daoMock),
                targets,
                values,
                calldatas,
                address(0) // address zero as parent Law
            )
        );
        // set the law in mockDao
        vm.prank(address(daoMock));
        daoMock.setLaw(mockLaw, ROLE_ONE, 0, 0, 0);

        // act & assert
        vm.expectRevert(Law__ParentLawNotSet.selector);
        vm.prank(alice);
        daoMock.execute(mockLaw, lawCalldata, keccak256(bytes(description)));
    }
}

contract ParentCanBlockTest is TestSetupLaw {
    function testLawRevertsIfParentHasCompleted() public {
        // prep: create a parent proposal and have it be defeated.
        uint32 lawNumber = 2;
        uint32 parentLawNumber = 0;
        string memory description = "Executing a proposal vote";
        bytes memory lawCalldata = abi.encode(true);
        vm.prank(alice);
        uint256 actionId = daoMock.propose(laws[parentLawNumber], lawCalldata, description);

        // Loop through users, they vote for the proposal
        for (uint256 i = 0; i < users.length; i++) {
            if (daoMock.hasRoleSince(users[i], allowedRoles[parentLawNumber]) != 0) {
                vm.prank(users[i]);
                daoMock.castVote(actionId, FOR);
            }
        }
        vm.roll(4000); // forward in time
        vm.prank(alice);
        daoMock.execute(laws[parentLawNumber], lawCalldata, keccak256(bytes(description)));
        // check if law has been set as completed.
        ActionState proposalState = daoMock.state(actionId);
        assertEq(uint8(proposalState), uint8(ActionState.Completed));

        // act & assert
        vm.expectRevert(Law__ParentBlocksCompletion.selector);
        vm.prank(alice);
        daoMock.execute(laws[lawNumber], lawCalldata, keccak256(bytes(description)));
    }

    function testLawSucceedsIfParentHasNotCompleted() public {
        // prep: create a parent proposal and have it be defeated.
        uint32 lawNumber = 2;
        uint32 parentLawNumber = 0;
        string memory description = "Executing a proposal vote";
        bytes memory lawCalldata = abi.encode(true);
        vm.prank(alice);
        uint256 actionId = daoMock.propose(laws[parentLawNumber], lawCalldata, description);

        // Loop through users, they vote against the proposal
        for (uint256 i = 0; i < users.length; i++) {
            if (daoMock.hasRoleSince(users[i], allowedRoles[parentLawNumber]) != 0) {
                vm.prank(users[i]);
                daoMock.castVote(actionId, AGAINST);
            }
        }
        vm.roll(4000); // forward in time
        vm.prank(alice);
        // check if law has been set as defeated.
        ActionState proposalState = daoMock.state(actionId);
        assertEq(uint8(proposalState), uint8(ActionState.Defeated));

        // act
        uint256 balanceBefore = erc1155Mock.balanceOf(address(daoMock), 0);
        vm.prank(alice);
        daoMock.execute(laws[lawNumber], lawCalldata, keccak256(bytes(description)));

        // assert
        uint256 balanceAfter = erc1155Mock.balanceOf(address(daoMock), 0);
        assertEq(balanceBefore, balanceAfter - 123);
    }

    function testLawRevertsIfParentAddressZero() public {
        // prep: create a mock data
        address[] memory targets = new address[](1);
        uint256[] memory values = new uint256[](1);
        bytes[] memory calldatas = new bytes[](1);
        targets[0] = address(erc1155Mock);
        values[0] = 0;
        calldatas[0] = abi.encodeWithSignature("mintCoins(uint256)", 123);

        // prep: create a mock law
        string memory description = "Executing a proposal vote";
        bytes memory lawCalldata = abi.encode(true);
        address mockLaw = address(
            new ParentCanBlock(
                "Needs Parent Completed", // max 31 chars
                "Needs Parent Completed to pass",
                address(daoMock),
                targets,
                values,
                calldatas,
                address(0) // address zero as parent Law
            )
        );
        // set the law in mockDao
        vm.prank(address(daoMock));
        daoMock.setLaw(mockLaw, ROLE_ONE, 0, 0, 0);

        // act & assert
        vm.expectRevert(Law__ParentLawNotSet.selector);
        vm.prank(alice);
        daoMock.execute(mockLaw, lawCalldata, keccak256(bytes(description)));
    }
}

contract DelayProposalExecutionTest is TestSetupLaw {
    function testExecuteLawSucceedsAfterDelay() public {
        // prep: create a proposal
        uint32 lawNumber = 3;
        string memory description = "Executing a delayed proposal vote";
        bytes memory lawCalldata = abi.encode(true);
        vm.prank(alice);
        uint256 actionId = daoMock.propose(laws[lawNumber], lawCalldata, description);

        // Loop through users, they vote for the proposal
        for (uint256 i = 0; i < users.length; i++) {
            if (daoMock.hasRoleSince(users[i], allowedRoles[lawNumber]) != 0) {
                vm.prank(users[i]);
                daoMock.castVote(actionId, FOR);
            }
        }
        vm.roll(10_000); // forward in time, past the delay.
        // act
        vm.prank(alice);
        daoMock.execute(laws[lawNumber], lawCalldata, keccak256(bytes(description)));

        // assert
        uint256 balance = erc1155Mock.balanceOf(address(daoMock), 0);
        assertEq(balance, 123);
    }

    function testExecuteLawRevertsBeforeDelay() public {
        // prep: create a proposal
        uint32 lawNumber = 3;
        string memory description = "Executing a delayed proposal vote";
        bytes memory lawCalldata = abi.encode(true);
        vm.prank(alice);
        uint256 actionId = daoMock.propose(laws[lawNumber], lawCalldata, description);

        // Loop through users, they vote for the proposal
        for (uint256 i = 0; i < users.length; i++) {
            if (daoMock.hasRoleSince(users[i], allowedRoles[lawNumber]) != 0) {
                vm.prank(users[i]);
                daoMock.castVote(actionId, FOR);
            }
        }
        vm.roll(4000); // forward in time, but NOT past the delay.
        // act & assert
        vm.expectRevert(Law__DeadlineNotPassed.selector);
        vm.prank(alice);
        daoMock.execute(laws[lawNumber], lawCalldata, keccak256(bytes(description)));
    }

    function testLawRevertsIfDelaySetToZero() public {
        // prep: create a mock data
        address[] memory targets = new address[](1);
        uint256[] memory values = new uint256[](1);
        bytes[] memory calldatas = new bytes[](1);
        targets[0] = address(erc1155Mock);
        values[0] = 0;
        calldatas[0] = abi.encodeWithSignature("mintCoins(uint256)", 123);

        // prep: create a mock law
        string memory description = "Executing a proposal vote";
        bytes memory lawCalldata = abi.encode(true);
        address mockLaw = address(
            new DelayProposalExecution(
                "Needs Parent Completed", // max 31 chars
                "Needs Parent Completed to pass",
                address(daoMock),
                targets,
                values,
                calldatas,
                0 // delay set at 0.
            )
        );
        // set the law in mockDao
        vm.prank(address(daoMock));
        daoMock.setLaw(mockLaw, ROLE_ONE, 20, 66, 1200);

        // act & assert
        vm.expectRevert(Law__NoDeadlineSet.selector);
        vm.prank(alice);
        daoMock.execute(mockLaw, lawCalldata, keccak256(bytes(description)));
    }
}

contract LimitExecutionsTest is TestSetupLaw {
    function testExecuteSucceedsWithinLimits() public {
        // prep: create a proposal
        uint32 lawNumber = 4;
        uint256 numberOfExecutions = 5;
        uint256 numberOfBlockBetweenExecutions = 15;
        bytes memory lawCalldata = abi.encode(true);

        // act
        for (uint256 i = 0; i < numberOfExecutions; i++) {
            vm.roll(block.number + numberOfBlockBetweenExecutions);
            vm.prank(alice);
            daoMock.execute(laws[lawNumber], lawCalldata, keccak256(bytes(abi.encode(i))));
        }

        // assert
        uint256 balance = erc1155Mock.balanceOf(address(daoMock), 0);
        assertEq(balance, 123 * numberOfExecutions);
    }

    function testExecuteRevertsAfterTooManyExecutions() public {
        // prep: execute 10 times
        uint32 lawNumber = 4;
        uint256 numberOfExecutions = 10;
        uint256 numberOfBlockBetweenExecutions = 15;
        bytes memory lawCalldata = abi.encode(true);

        for (uint256 i = 0; i < numberOfExecutions; i++) {
            vm.roll(block.number + numberOfBlockBetweenExecutions);
            vm.prank(alice);
            daoMock.execute(laws[lawNumber], lawCalldata, keccak256(bytes(abi.encode(i))));
        }

        // act & assert
        vm.expectRevert(Law__ExecutionLimitReached.selector);
        vm.roll(block.number + numberOfBlockBetweenExecutions);
        vm.prank(alice);
        daoMock.execute(laws[lawNumber], lawCalldata, keccak256(bytes("one execution too many")));
    }

    function testExecuteRevertsIfGapTooSmall() public {
        // prep: execute 10 times
        uint32 lawNumber = 4;
        bytes memory lawCalldata = abi.encode(true);
        // prep: execute once...
        vm.prank(alice);
        daoMock.execute(laws[lawNumber], lawCalldata, keccak256(bytes("first execute")));

        // act & assert: execute twice, very soon after.
        vm.roll(block.number + 5);
        vm.expectRevert(Law__ExecutionGapTooSmall.selector);
        vm.prank(alice);
        daoMock.execute(laws[lawNumber], lawCalldata, keccak256(bytes("second execute")));
    }
}

//////////////////////////////////////////////////
//                 FUNCTIONS                    //
//////////////////////////////////////////////////
contract ExecutionLawTest is TestSetupLaw {
    function testBaseExecuteReturnsZeroArrays() public {
        bytes memory lawCalldata = abi.encode(true);

        Law law = new Law("mock law", "mock description", address(daoMock));

        (address[] memory targets, uint256[] memory values, bytes[] memory calldatas) =
            law.executeLaw(address(0), lawCalldata, keccak256(bytes("Mock execution description")));

        assertEq(targets.length, 1);
        assertEq(values.length, 1);
        assertEq(calldatas.length, 1);

        assertEq(targets[0], address(0));
        assertEq(values[0], 0);
    }
}
