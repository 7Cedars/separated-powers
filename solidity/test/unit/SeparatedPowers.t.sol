// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.26;

import "forge-std/Test.sol";
import { SeparatedPowers } from "../../src/SeparatedPowers.sol";
import { Law } from "../../src/Law.sol";
import { ILaw } from "../../src/interfaces/ILaw.sol";
import { TestSetupSeparatedPowers } from "../TestSetup.t.sol";
import { DaoMock } from "../mocks/DaoMock.sol";
import { OpenAction } from "../../src/implementations/laws/executive/OpenAction.sol";

/// @notice Unit tests for the core Separated Powers protocol.
/// @dev tests build on the Hats protocol example. See // https.... £todo

//////////////////////////////////////////////////////////////
//               CONSTRUCTOR & RECEIVE                      //
//////////////////////////////////////////////////////////////
contract DeployTest is TestSetupSeparatedPowers {
    function testDeployAlignedGrants() public {
        assertEq(daoMock.name(), daoNames[0]);
        assertEq(daoMock.version(), "1");

        assertNotEq(daoMock.hasRoleSince(alice, ROLE_ONE), 0);
    }

    function testReceive() public {
        vm.prank(alice);

        vm.expectEmit(true, false, false, false);
        emit FundsReceived(1 ether);
        address(daoMock).call{ value: 1 ether }("");

        assertEq(address(daoMock).balance, 1 ether);
    }

    function testDeployProtocolEmitsEvent() public {
        vm.expectEmit(true, false, false, false);
        emit SeparatedPowers__Initialized(address(daoMock));

        vm.prank(alice);
        daoMock = new DaoMock();
    }

    function testDeployProtocolSetsSenderToAdmin() public {
        vm.prank(alice);
        daoMock = new DaoMock();

        assertNotEq(daoMock.hasRoleSince(alice, ADMIN_ROLE), 0);
    }
}

//////////////////////////////////////////////////////////////
//                  GOVERNANCE LOGIC                        //
//////////////////////////////////////////////////////////////
contract ProposeTest is TestSetupSeparatedPowers {
    function testProposeRevertsWhenAccountLacksCredentials() public {
        uint32 lawNumber = 2;
        string memory description = "Creating a proposal";
        bytes memory lawCalldata = abi.encode(true);
        // check if helen does not have correct role
        address mockAddress = makeAddr("mock");
        assertEq(daoMock.hasRoleSince(mockAddress, Law(laws[lawNumber]).allowedRole()), 0);

        vm.expectRevert(SeparatedPowers__AccessDenied.selector);
        vm.prank(mockAddress);
        daoMock.propose(laws[4], lawCalldata, description);
    }

    function testProposeRevertsIfLawNotActive() public {
        uint32 lawNumber = 4;
        string memory description = "Creating a proposal";
        bytes memory lawCalldata = abi.encode(true);
        // check if charlotte has correct role
        assertNotEq(daoMock.hasRoleSince(charlotte, Law(laws[lawNumber]).allowedRole()), 0);

        vm.prank(address(daoMock));
        daoMock.revokeLaw(laws[lawNumber]);

        vm.expectRevert(SeparatedPowers__NotActiveLaw.selector);
        vm.prank(charlotte);
        uint256 actionId = daoMock.propose(laws[lawNumber], lawCalldata, description);
    }

    function testProposeRevertsIfLawDoesNotNeedVote() public {
        uint32 lawNumber = 2;
        string memory description = "Creating a proposal";
        bytes memory lawCalldata = abi.encode("this is dummy Data");
        address lawThatDoesNotNeedVote = laws[lawNumber];
        // check if david has correct role
        assertNotEq(daoMock.hasRoleSince(david, Law(laws[lawNumber]).allowedRole()), 0);

        vm.prank(david);
        vm.expectRevert(SeparatedPowers__NoVoteNeeded.selector);
        uint256 actionId = daoMock.propose(lawThatDoesNotNeedVote, lawCalldata, description);
    }

    function testProposePassesWithCorrectCredentials() public {
        uint32 lawNumber = 4;
        string memory description = "Creating a proposal";
        bytes memory lawCalldata = abi.encode(true);
        // check if charlotte has correct role
        assertNotEq(daoMock.hasRoleSince(charlotte, Law(laws[lawNumber]).allowedRole()), 0);

        vm.prank(charlotte);
        uint256 actionId = daoMock.propose(laws[lawNumber], lawCalldata, description);

        ActionState proposalState = daoMock.state(actionId);
        assertEq(uint8(proposalState), uint8(ActionState.Active));
    }

    function testProposeEmitsEvents() public {
        uint32 lawNumber = 4;
        string memory description = "Creating a proposal";
        bytes memory lawCalldata = abi.encode(true);
        address targetLaw = laws[lawNumber];
        // check if charlotte has correct role
        assertNotEq(daoMock.hasRoleSince(charlotte, Law(laws[lawNumber]).allowedRole()), 0);

        uint256 actionId = hashProposal(targetLaw, lawCalldata, keccak256(bytes(description)));
        ( , , uint32 duration, , , , ) = Law(laws[lawNumber]).config();

        vm.expectEmit(true, false, false, false);
        emit ProposalCreated(
            actionId, charlotte, targetLaw, "", lawCalldata, block.number, block.timestamp + duration, description
        );
        vm.prank(charlotte);
        daoMock.propose(targetLaw, lawCalldata, description);
    }
}

contract CancelTest is TestSetupSeparatedPowers {
    function testCancellingProposalsEmitsCorrectEvent() public {
        // prep: create a proposal
        address targetLaw = laws[4];
        string memory description = "Creating a proposal";
        bytes memory lawCalldata = abi.encode(true);
        vm.prank(charlotte);
        uint256 actionId = daoMock.propose(targetLaw, lawCalldata, description);

        // act: cancel the proposal
        vm.expectEmit(true, false, false, false);
        emit ProposalCancelled(actionId);
        vm.prank(charlotte);
        daoMock.cancel(targetLaw, lawCalldata, keccak256(bytes(description)));
    }

    function testCancellingProposalsSetsStateToCancelled() public {
        // prep: create a proposal
        address targetLaw = laws[4];
        string memory description = "Creating a proposal";
        bytes memory lawCalldata = abi.encode(true);
        vm.prank(charlotte);
        uint256 actionId = daoMock.propose(targetLaw, lawCalldata, description);

        // act: cancel the proposal
        vm.prank(charlotte);
        daoMock.cancel(targetLaw, lawCalldata, keccak256(bytes(description)));

        // check the state
        ActionState proposalState = daoMock.state(actionId);
        assertEq(uint8(proposalState), uint8(ActionState.Cancelled));
    }

    function testCancelRevertsWhenAccountDidNotCreateProposal() public {
        // prep: create a proposal
        address targetLaw = laws[4];
        string memory description = "Creating a proposal";
        bytes memory lawCalldata = abi.encode(true);
        vm.prank(charlotte);
        uint256 actionId = daoMock.propose(targetLaw, lawCalldata, description);

        // act: try to cancel the proposal
        vm.expectRevert(SeparatedPowers__AccessDenied.selector);
        vm.prank(david);
        daoMock.cancel(targetLaw, lawCalldata, keccak256(bytes(description)));
    }

    function testCancelledProposalsCannotBeExecuted() public {
        // prep: create a proposal
        address targetLaw = laws[4];
        string memory description = "Creating a proposal";
        bytes memory lawCalldata = abi.encode(true);
        vm.prank(charlotte);
        uint256 actionId = daoMock.propose(targetLaw, lawCalldata, description);

        // prep: cancel the proposal one time...
        vm.prank(charlotte);
        daoMock.cancel(targetLaw, lawCalldata, keccak256(bytes(description)));

        // act: try to cancel proposal a second time. Should revert
        vm.expectRevert(SeparatedPowers__UnexpectedActionState.selector);
        vm.prank(charlotte);
        daoMock.cancel(targetLaw, lawCalldata, keccak256(bytes(description)));
    }
}

contract VoteTest is TestSetupSeparatedPowers {
    function testVotingRevertsIfAccountNotAuthorised() public {
        // prep: create a proposal
        uint32 lawNumber = 4;
        string memory description = "Creating a proposal";
        bytes memory lawCalldata = abi.encode(true);
        vm.prank(charlotte);
        uint256 actionId = daoMock.propose(laws[lawNumber], lawCalldata, description);

        // create unauthorised account.
        address mockAddress = makeAddr("mock");
        assertEq(daoMock.hasRoleSince(mockAddress, Law(laws[lawNumber]).allowedRole()), 0);

        // act: try to vote, without credentials
        vm.expectRevert(SeparatedPowers__AccessDenied.selector);
        vm.prank(mockAddress);
        daoMock.castVote(actionId, FOR);
    }

    function testProposalDefeatedIfQuorumNotReachedInTime() public {
        // prep: create a proposal
        uint32 lawNumber = 4;
        string memory description = "Creating a proposal";
        bytes memory lawCalldata = abi.encode(true);
        vm.prank(charlotte);
        uint256 actionId = daoMock.propose(laws[lawNumber], lawCalldata, description);

        // act: go forward in time. -- no votes are cast.
        vm.roll(4000);

        // check state of proposal
        ActionState proposalState = daoMock.state(actionId);
        assertEq(uint8(proposalState), uint8(ActionState.Defeated));
    }

    function testVotingIsNotPossibleForDefeatedProposals() public {
        // prep: create a proposal
        uint32 lawNumber = 4;
        string memory description = "Creating a proposal";
        bytes memory lawCalldata = abi.encode(true);
        vm.prank(charlotte);
        uint256 actionId = daoMock.propose(laws[lawNumber], lawCalldata, description);

        // prep: defeat proposal: by going beyond voting period, quorum not reached. Proposal is defeated.
        vm.roll(4000);

        // act : try to vote
        vm.expectRevert(SeparatedPowers__ProposalNotActive.selector);
        vm.prank(charlotte);
        daoMock.castVote(actionId, FOR);
    }

    function testProposalSucceededIfQuorumReachedInTime() public {
        // prep: create a proposal
        uint32 lawNumber = 4;
        string memory description = "Creating a proposal";
        bytes memory lawCalldata = abi.encode(true);
        vm.prank(charlotte);
        uint256 actionId = daoMock.propose(laws[lawNumber], lawCalldata, description);

        // Loop through users,
        // each user that is authorised to vote, votes 'FOR'.
        for (uint256 i = 0; i < users.length; i++) {
            if (daoMock.hasRoleSince(users[i], Law(laws[lawNumber]).allowedRole()) != 0) {
                vm.prank(users[i]);
                daoMock.castVote(actionId, FOR);
            }
        }
        // go forward in time.
        vm.roll(4000); //

        // assert
        ActionState proposalState = daoMock.state(actionId);
        assertEq(uint8(proposalState), uint8(ActionState.Succeeded));
    }

    function testVotesWithReasonsWorks() public {
        // prep: create a proposal
        uint32 lawNumber = 4;
        string memory description = "Creating a proposal";
        bytes memory lawCalldata = abi.encode(true);
        vm.prank(charlotte);
        uint256 actionId = daoMock.propose(laws[lawNumber], lawCalldata, description);

        // Loop through users,
        // each user that is authorised to vote, votes 'FOR'.
        for (uint256 i = 0; i < users.length; i++) {
            if (daoMock.hasRoleSince(users[i], Law(laws[lawNumber]).allowedRole()) != 0) {
                vm.prank(users[i]);
                daoMock.castVoteWithReason(actionId, FOR, "This is a test");
            }
        }
        // go forward in time.
        vm.roll(4000);

        // assert
        ActionState proposalState = daoMock.state(actionId);
        assertEq(uint8(proposalState), uint8(ActionState.Succeeded));
    }

    function testProposalDefeatedIfQuorumReachedButNotEnoughForVotes() public {
        // prep: create a proposal
        uint32 lawNumber = 4;
        string memory description = "Creating a proposal";
        bytes memory lawCalldata = abi.encode(true);
        vm.prank(charlotte);
        uint256 actionId = daoMock.propose(laws[lawNumber], lawCalldata, description);

        // Loop through users,
        // each user that is authorised to vote, votes 'AGAINST'.
        for (uint256 i = 0; i < users.length; i++) {
            if (daoMock.hasRoleSince(users[i], Law(laws[lawNumber]).allowedRole()) != 0) {
                vm.prank(users[i]);
                daoMock.castVote(actionId, AGAINST);
            }
        }
        // go forward in time.
        vm.roll(4000); //

        // assert
        ActionState proposalState = daoMock.state(actionId);
        assertEq(uint8(proposalState), uint8(ActionState.Defeated));
    }

    function testAccountCannotVoteTwice() public {
        // prep: create a proposal
        uint32 lawNumber = 4;
        string memory description = "Creating a proposal";
        bytes memory lawCalldata = abi.encode(true);
        vm.prank(charlotte);
        uint256 actionId = daoMock.propose(laws[lawNumber], lawCalldata, description);

        // alice votes once..
        vm.prank(alice);
        daoMock.castVote(actionId, FOR);

        // alice tries to vote twice...
        vm.prank(alice);
        vm.expectRevert(SeparatedPowers__AlreadyCastVote.selector);
        daoMock.castVote(actionId, FOR);
    }

    function testAgainstVoteIsCorrectlyCounted() public {
        // prep: create a proposal
        uint256 numberAgainstVotes;
        uint32 lawNumber = 4;
        string memory description = "Creating a proposal";
        bytes memory lawCalldata = abi.encode(true);
        vm.prank(charlotte);
        uint256 actionId = daoMock.propose(laws[lawNumber], lawCalldata, description);

        // Loop through users,
        // each user that is authorised to vote, votes 'AGAINST'.
        for (uint256 i = 0; i < users.length; i++) {
            if (daoMock.hasRoleSince(users[i], Law(laws[lawNumber]).allowedRole()) != 0) {
                vm.prank(users[i]);
                daoMock.castVote(actionId, AGAINST);
                numberAgainstVotes++;
            }
        }

        // check
        (uint256 againstVotes,,) = daoMock.getProposalVotes(actionId);
        assertEq(againstVotes, numberAgainstVotes);
    }

    function testForVoteIsCorrectlyCounted() public {
        // prep: create a proposal
        uint256 numberForVotes;
        uint32 lawNumber = 4;
        string memory description = "Creating a proposal";
        bytes memory lawCalldata = abi.encode(true);
        vm.prank(charlotte);
        uint256 actionId = daoMock.propose(laws[lawNumber], lawCalldata, description);

        // Loop through users,
        // each user that is authorised to vote, votes 'FOR'.
        for (uint256 i = 0; i < users.length; i++) {
            if (daoMock.hasRoleSince(users[i], Law(laws[lawNumber]).allowedRole()) != 0) {
                vm.prank(users[i]);
                daoMock.castVote(actionId, FOR);
                numberForVotes++;
            }
        }

        // check
        (, uint256 forVotes,) = daoMock.getProposalVotes(actionId);
        assertEq(forVotes, numberForVotes);
    }

    function testAbstainVoteIsCorrectlyCounted() public {
        // prep: create a proposal
        uint256 numberAbstainVotes;
        uint32 lawNumber = 4;
        string memory description = "Creating a proposal";
        bytes memory lawCalldata = abi.encode(true);
        vm.prank(charlotte);
        uint256 actionId = daoMock.propose(laws[lawNumber], lawCalldata, description);

        // Loop through users,
        // each user that is authorised to vote, votes 'ABSTAIN'.
        for (uint256 i = 0; i < users.length; i++) {
            if (daoMock.hasRoleSince(users[i], Law(laws[lawNumber]).allowedRole()) != 0) {
                vm.prank(users[i]);
                daoMock.castVote(actionId, ABSTAIN);
                numberAbstainVotes++;
            }
        }

        // check
        (,, uint256 abstainVotes) = daoMock.getProposalVotes(actionId);
        assertEq(abstainVotes, numberAbstainVotes);
    }

    function testVoteRevertsWithInvalidVote() public {
        uint32 lawNumber = 4;
        string memory description = "Creating a proposal";
        bytes memory lawCalldata = abi.encode(true);
        vm.prank(charlotte);
        uint256 actionId = daoMock.propose(laws[lawNumber], lawCalldata, description);

        // act
        vm.prank(charlotte);
        vm.expectRevert(SeparatedPowers__InvalidVoteType.selector);
        daoMock.castVote(actionId, 4); // = incorrect vote type

        // check if indeed not stored as a vote
        (uint256 againstVotes, uint256 forVotes, uint256 abstainVotes) = daoMock.getProposalVotes(actionId);
        assertEq(againstVotes, 0);
        assertEq(forVotes, 0);
        assertEq(abstainVotes, 0);
    }

    function testHasVotedReturnCorrectData() public {
        uint32 lawNumber = 4;
        string memory description = "Creating a proposal";
        bytes memory lawCalldata = abi.encode(true);
        vm.prank(charlotte);
        uint256 actionId = daoMock.propose(laws[lawNumber], lawCalldata, description);

        // act
        vm.prank(charlotte);
        daoMock.castVote(actionId, ABSTAIN);

        // check
        assertTrue(daoMock.hasVoted(actionId, charlotte));
    }
}

contract ExecuteTest is TestSetupSeparatedPowers {
    function testExecuteCanChangeState() public {
        // prep
        uint32 lawNumber = 0;
        string memory description = "Assigning mockAddress ROLE_ONE";
        bytes memory lawCalldata = abi.encode(false); // revoke = false
        address mockAddress = makeAddr("mock");

        // check that mockAddress does NOT have ROLE_ONE
        assertEq(daoMock.hasRoleSince(mockAddress, ROLE_ONE), 0);

        // act
        vm.prank(mockAddress);
        daoMock.execute(laws[lawNumber], lawCalldata, keccak256(bytes(description)));

        // assert that mockAddress now has ROLE_ONE
        assertNotEq(daoMock.hasRoleSince(mockAddress, ROLE_ONE), 0);
    }

    function testExecuteSuccessSetsStateToComplete() public {
        // prep
        uint32 lawNumber = 0;
        string memory description = "Assigning mockAddress ROLE_ONE";
        bytes memory lawCalldata = abi.encode(false); // revoke = false
        address mockAddress = makeAddr("mock");

        // act
        vm.prank(mockAddress);
        daoMock.execute(laws[lawNumber], lawCalldata, keccak256(bytes(description)));

        // assert
        uint256 actionId = hashProposal(laws[lawNumber], lawCalldata, keccak256(bytes(description)));
        ActionState proposalState = daoMock.state(actionId);
        assertEq(uint8(proposalState), uint8(ActionState.Completed));
    }

    function testExecuteEmitEvent() public {
        // prep
        uint32 lawNumber = 0;
        string memory description = "Assigning mockAddress ROLE_ONE";
        bytes memory lawCalldata = abi.encode(false); // revoke = false
        address mockAddress = makeAddr("mock");

        // build return expected return data
        address[] memory tar = new address[](1);
        uint256[] memory val = new uint256[](1);
        bytes[] memory cal = new bytes[](1);
        tar[0] = address(daoMock);
        val[0] = 0;
        cal[0] = abi.encodeWithSelector(daoMock.assignRole.selector, ROLE_ONE, mockAddress); // selector = assignRole

        // act & assert
        vm.expectEmit(true, false, false, false);
        emit ProposalExecuted(tar, val, cal);
        vm.prank(mockAddress);
        daoMock.execute(laws[lawNumber], lawCalldata, keccak256(bytes(description)));
    }

    function testExecuteRevertsIfNotAuthorised() public {
        // prep
        uint32 lawNumber = 3;
        string memory description = "Unauthorised call to law 3";
        bytes memory lawCalldata = abi.encode(false, true); // (bool nominateMe, bool assignRoles)
        address mockAddress = makeAddr("mock");
        // check that mockAddress is not authorised
        assertEq(daoMock.hasRoleSince(mockAddress, Law(laws[lawNumber]).allowedRole()), 0);

        // act & assert
        vm.expectRevert(SeparatedPowers__AccessDenied.selector);
        vm.prank(mockAddress);
        daoMock.execute(laws[lawNumber], lawCalldata, keccak256(bytes(description)));
    }

    function testExecuteRevertsIfActionAlreadyExecuted() public {
        // prep
        uint32 lawNumber = 0;
        string memory description = "Assigning mockAddress ROLE_ONE";
        bytes memory lawCalldata = abi.encode(false); // revoke = false
        address mockAddress = makeAddr("mock");
        // execute action once...
        vm.prank(mockAddress);
        daoMock.execute(laws[lawNumber], lawCalldata, keccak256(bytes(description)));

        // act: try to execute action again.
        vm.expectRevert(SeparatedPowers__ProposalAlreadyCompleted.selector);
        vm.prank(mockAddress);
        daoMock.execute(laws[lawNumber], lawCalldata, keccak256(bytes(description)));
    }

    function testExecuteRevertsIfLawNotActive() public {
        uint32 lawNumber = 0;
        string memory description = "Assigning mockAddress ROLE_ONE";
        bytes memory lawCalldata = abi.encode(false); // revoke = false
        address mockAddress = makeAddr("mock");

        // revoke law
        vm.prank(address(daoMock));
        daoMock.revokeLaw(laws[lawNumber]);

        // act & assert
        vm.expectRevert(SeparatedPowers__NotActiveLaw.selector);
        vm.prank(mockAddress);
        daoMock.execute(laws[lawNumber], lawCalldata, keccak256(bytes(description)));
    }

    function testExecuteRevertsIfProposalNeeded() public {
        // prep: create a proposal
        uint32 lawNumber = 4;
        string memory description = "Creating a proposal";
        bytes memory lawCalldata = abi.encode(true);

        vm.expectRevert();
        vm.prank(charlotte);
        daoMock.execute(laws[lawNumber], lawCalldata, keccak256(bytes(description)));
    }

    function testExecuteRevertsIfProposalDefeated() public {
        // prep: create a proposal
        uint32 lawNumber = 4;
        string memory description = "Creating a proposal";
        bytes memory lawCalldata = abi.encode(true);
        vm.prank(charlotte);
        uint256 actionId = daoMock.propose(laws[lawNumber], lawCalldata, description);

        // Loop through users,
        // each user that is authorised to vote, votes 'AGAINST'.
        for (uint256 i = 0; i < users.length; i++) {
            if (daoMock.hasRoleSince(users[i], Law(laws[lawNumber]).allowedRole()) != 0) {
                vm.prank(users[i]);
                daoMock.castVote(actionId, AGAINST);
            }
        }
        // go forward in time.
        vm.roll(4000); //

        // check if proposal is defeated.
        ActionState proposalState = daoMock.state(actionId);
        assertEq(uint8(proposalState), uint8(ActionState.Defeated));

        // act & assert: try to execute proposal.
        vm.expectRevert(); // check selector
        vm.prank(charlotte);
        daoMock.execute(laws[lawNumber], lawCalldata, keccak256(bytes(description)));
    }

    function testExecuteRevertsIfProposalCancelled() public {
        // prep: create a proposal
        uint32 lawNumber = 4;
        string memory description = "Creating a proposal";
        bytes memory lawCalldata = abi.encode(true);
        vm.prank(charlotte);
        uint256 actionId = daoMock.propose(laws[lawNumber], lawCalldata, description);

        // cancel proposal
        vm.prank(charlotte);
        daoMock.cancel(laws[lawNumber], lawCalldata, keccak256(bytes(description)));

        // check if proposal is cancelled.
        ActionState proposalState = daoMock.state(actionId);
        assertEq(uint8(proposalState), uint8(ActionState.Cancelled));

        // act & assert: try to execute proposal.
        vm.expectRevert(SeparatedPowers__ProposalCancelled.selector);
        vm.prank(charlotte);
        daoMock.execute(laws[lawNumber], lawCalldata, keccak256(bytes(description)));
    }
}

//////////////////////////////////////////////////////////////
//                  ROLE AND LAW ADMIN                      //
//////////////////////////////////////////////////////////////
contract ConstituteTest is TestSetupSeparatedPowers {
    function testConstituteSetsLawsToActive() public {
        vm.prank(alice);
        DaoMock daoMockTest = new DaoMock();

        ILaw.LawConfig memory lawConfig;
        address[] memory laws = new address[](1);
        laws[0] = address(new OpenAction(
            "test law", 
            "This is a test Law", 
            address(daoMock), 
            ROLE_ONE,
            lawConfig
            ));

        vm.prank(alice);
        daoMockTest.constitute(
            laws, constituentRoles, constituentAccounts
        );

        for (uint32 i = 0; i < laws.length; i++) {
            bool active = daoMockTest.getActiveLaw(laws[i]);
            assertTrue(active);
        }
    }

    function testConstituteRevertsOnSecondCall() public {
        vm.prank(alice);
        DaoMock daoMockTest = new DaoMock();

        ILaw.LawConfig memory lawConfig; 
        address[] memory laws = new address[](1);
        laws[0] = address(new OpenAction(
            "test law", 
            "This is a test Law", 
            address(daoMock), 
            ROLE_ONE,
            lawConfig
            ));

        vm.prank(alice);
        daoMockTest.constitute(
            laws, constituentRoles, constituentAccounts
        );

        vm.expectRevert(SeparatedPowers__ConstitutionAlreadyExecuted.selector);
        vm.prank(alice);
        daoMockTest.constitute(
            laws, constituentRoles, constituentAccounts
        );
    }

    function testConstituteCannotBeCalledByNonAdmin() public {
        vm.prank(alice);
        DaoMock daoMockTest = new DaoMock();
        
        ILaw.LawConfig memory lawConfig; 
        address[] memory laws = new address[](1);
        laws[0] = address(new OpenAction(
            "test law", 
            "This is a test Law", 
            address(daoMock), 
            ROLE_ONE,
            lawConfig
            ));

        vm.expectRevert(SeparatedPowers__AccessDenied.selector);
        vm.prank(bob);
        daoMockTest.constitute(laws, constituentRoles, constituentAccounts);
    }
}

contract SetLawTest is
    TestSetupSeparatedPowers // also tests revokeLaw function
{
    function testSetLawSetsNewLaw() public {
        ILaw.LawConfig memory lawConfig; 
        address newLaw = address(new OpenAction(
            "test law", 
            "This is a test Law", 
            address(daoMock), 
            ROLE_ONE,
            lawConfig
            ));

        vm.prank(address(daoMock));
        daoMock.adoptLaw(newLaw);

        assertTrue(daoMock.getActiveLaw(newLaw));
    }

    function testSetLawEmitsEvent() public {
        ILaw.LawConfig memory lawConfig; 
        address newLaw = address(new OpenAction(
            "test law", 
            "This is a test Law", 
            address(daoMock), 
            ROLE_ONE,
            lawConfig
            ));

        vm.expectEmit(true, false, false, false);
        emit LawSet(newLaw);
        vm.prank(address(daoMock));
        daoMock.adoptLaw(newLaw);
    }

    function testSetLawRevertsIfNotCalledFromSeparatedPowers() public {
        ILaw.LawConfig memory lawConfig; 
        address newLaw = address(new OpenAction(
            "test law", 
            "This is a test Law", 
            address(daoMock), 
            ROLE_ONE,
            lawConfig
            ));
        
        vm.expectRevert(SeparatedPowers__OnlySeparatedPowers.selector);
        vm.prank(alice);
        daoMock.adoptLaw(newLaw);
    }

    function testSetLawRevertsIfAddressNotALaw() public {
        address newNotALaw = address(3333);

        vm.expectRevert(SeparatedPowers__IncorrectInterface.selector);
        vm.prank(address(daoMock));
        daoMock.adoptLaw(newNotALaw);
    }
}

contract SetRoleTest is TestSetupSeparatedPowers {
    function testSetRoleSetsNewRole() public {
        // prep: check that bob does not have ROLE_THREE
        assertEq(daoMock.hasRoleSince(helen, ROLE_THREE), 0);

        // act
        vm.prank(address(daoMock));
        daoMock.assignRole(ROLE_THREE, helen);

        // assert: bob now holds ROLE_THREE
        assertNotEq(daoMock.hasRoleSince(helen, ROLE_THREE), 0);
    }

    function testSetRoleRevertsWhenCalledFromOutsidePropotocol() public {
        vm.prank(alice);
        vm.expectRevert(SeparatedPowers__OnlySeparatedPowers.selector);
        daoMock.assignRole(ROLE_THREE, bob);
    }

    function testSetRoleRevertsIfAccountAlreadyHasRole() public {
        // prep: check that bob has ROLE_ONE
        assertNotEq(daoMock.hasRoleSince(bob, ROLE_ONE), 0);

        vm.prank(address(daoMock));
        vm.expectRevert(SeparatedPowers__RoleAccessNotChanged.selector);
        daoMock.assignRole(ROLE_ONE, bob);
    }

    function testAddingRoleAddsOneToAmountMembers() public {
        // prep
        uint256 amountMembersBefore = daoMock.getAmountRoleHolders(ROLE_THREE);
        assertEq(daoMock.hasRoleSince(helen, ROLE_THREE), 0);

        // act
        vm.prank(address(daoMock));
        daoMock.assignRole(ROLE_THREE, helen);

        // assert
        uint256 amountMembersAfter = daoMock.getAmountRoleHolders(ROLE_THREE);
        assertNotEq(daoMock.hasRoleSince(helen, ROLE_THREE), 0);
        assertEq(amountMembersAfter, amountMembersBefore + 1);
    }

    function testRemovingRoleSubtractsOneFromAmountMembers() public {
        // prep
        uint256 amountMembersBefore = daoMock.getAmountRoleHolders(ROLE_ONE);
        assertNotEq(daoMock.hasRoleSince(bob, ROLE_ONE), 0);

        // act
        vm.prank(address(daoMock));
        daoMock.revokeRole(ROLE_ONE, bob);

        // assert
        uint256 amountMembersAfter = daoMock.getAmountRoleHolders(ROLE_ONE);
        assertEq(daoMock.hasRoleSince(bob, ROLE_ONE), 0);
        assertEq(amountMembersAfter, amountMembersBefore - 1);
    }

    function testSetRoleSetsEmitsEvent() public {
        // act & assert
        vm.expectEmit(true, false, false, false);
        emit RoleSet(ROLE_THREE, helen);
        vm.prank(address(daoMock));
        daoMock.assignRole(ROLE_THREE, helen);
    }
}
