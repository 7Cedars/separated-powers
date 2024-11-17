// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.26;

import  "forge-std/Test.sol";
import { SeparatedPowers } from  "../../src/SeparatedPowers.sol";
import { TestSetup } from "../TestSetup.t.sol";

/// @notice Unit tests for the core Separated Powers protocol.
/// @dev tests build on the Hats protocol example. See // https.... £todo 


//////////////////////////////////////////////////////////////
//            TESTING GOVERNANCE LOGIC                      //
//////////////////////////////////////////////////////////////
contract DeployTest is TestSetup {
    function testDeployAlignedGrants() public {
      assertEq(daoMock.name(), daoNames[0]);
      assertEq(daoMock.version(), "1");

      assert(daoMock.hasRoleSince(alice, ROLE_ONE) != 0);    
    }

    function testReceive() public {
        vm.prank(alice);

        vm.expectEmit(true, false, false, false);
        emit FundsReceived(1 ether);
        address(daoMock).call{value: 1 ether}("");

        assertEq(address(daoMock).balance, 1 ether);
    }
}

contract ProposeTest is TestSetup {
    function testProposeRevertsWhenAccountLacksCredentials() public {
        string memory description = "Creating a proposal";
        bytes memory lawCalldata = abi.encode(true);
        // check if helen does not have ROLE_ONE 
        address mockAddress = makeAddr("mock");
        assertEq(daoMock.hasRoleSince(mockAddress, ROLE_ONE ), 0);

        vm.expectRevert(SeparatedPowers__AccessDenied.selector);
        vm.prank(mockAddress);
        daoMock.propose(laws[4], lawCalldata, description);
    }

    // function testProposeRevertsIfLawNotActive() public {
    //  Testing this needs a mock call.
    // The law needs to have been set, and then deactivated. 
    // That is the only scenario where this would happen I think.  
    // 
    // do later. 
    // }

    function testProposeRevertsIfLawDoesNotNeedVote() public {
        string memory description = "Creating a proposal";
        bytes memory lawCalldata = abi.encode("this is dummy Data");
        address lawThatDoesNotNeedVote = laws[2];
        // check if david has incorrect role
        assertEq(daoMock.hasRoleSince(david, allowedRoles[2]), 10);

        vm.prank(david);  
        vm.expectRevert(SeparatedPowers__NoVoteNeeded.selector);
        uint256 proposalId = daoMock.propose(lawThatDoesNotNeedVote, lawCalldata, description);
    }

    function testProposePassesWithCorrectCredentials() public {
        string memory description = "Creating a proposal";
        bytes memory lawCalldata = abi.encode(true);
        // check if charlotte has ROLE_ONE 
        assertEq(daoMock.hasRoleSince(charlotte, ROLE_ONE), 10);

        vm.prank(charlotte); 
        uint256 proposalId = daoMock.propose(laws[4], lawCalldata, description);

        ActionState proposalState = daoMock.state(proposalId);
        assert(uint8(proposalState) == uint8(ActionState.Active)); 
    }

    function testProposeEmitsEvents() public {
        string memory description = "Creating a proposal";
        bytes memory lawCalldata = abi.encode(true);
        address targetLaw = laws[4];
        // check if charlotte has ROLE_ONE 
        assertEq(daoMock.hasRoleSince(charlotte, ROLE_ONE), 10);

        uint256 actionId = hashExecutiveAction(targetLaw, lawCalldata, keccak256(bytes(description)));
        uint32 duration = votingPeriods[4]; 

        vm.expectEmit(true, false, false, false);
        emit ExecutiveActionCreated(
            actionId,
            charlotte,
            targetLaw,
            "",
            lawCalldata,
            block.number,
            block.timestamp + duration,
            description
        );
        vm.prank(charlotte); 
        uint256 proposalId = daoMock.propose(targetLaw, lawCalldata, description);
    }
}

// contract CancelTest is TestSetup {
//     function testCancellingExecutiveActionsEmitsCorrectEvent() public {
//         // prep
//         string memory description = "Inviting david to join senior role at alignedGrantsDao";
//         bytes memory lawCalldata = abi.encode(david);
//         vm.prank(charlotte); // = already a senior
//         uint256 proposalId = alignedGrantsDao.propose(laws[1], lawCalldata, description); //

//         vm.expectEmit(true, false, false, false);
//         emit SeparatedPowersEvents.ExecutiveActionCancelled(proposalId);
//         vm.prank(charlotte);
//         alignedGrantsDao.cancel(laws[1], lawCalldata, keccak256(bytes(description)));
//     }

//     function testCancellingExecutiveActionsSetsStateToCancelled() public {
//         // prep
//         string memory description = "Inviting david to join senior role at alignedGrantsDao";
//         bytes memory lawCalldata = abi.encode(david);
//         vm.prank(charlotte); // = already a senior
//         uint256 proposalId = alignedGrantsDao.propose(laws[1], lawCalldata, description); //

//         vm.prank(charlotte);
//         alignedGrantsDao.cancel(laws[1], lawCalldata, keccak256(bytes(description)));

//         SeparatedPowersTypes.ActionState proposalState = alignedGrantsDao.state(proposalId);
//         assert(uint8(proposalState) == 1); // == ActionState.Cancelled
//     }

//     function testCancelRevertsWhenAccountDoesNotHaveCorrectRole() public {
//         // prep
//         string memory description = "Inviting david to join senior role at alignedGrantsDao";
//         bytes memory lawCalldata = abi.encode(david);
//         vm.prank(charlotte); // = charlotte is a senior
//         alignedGrantsDao.propose(laws[1], lawCalldata, description); //

//         vm.expectRevert(SeparatedPowersErrors.SeparatedPowers__AccessDenied.selector);
//         vm.prank(david);
//         alignedGrantsDao.cancel(laws[1], lawCalldata, keccak256(bytes(description)));
//     }

//     function testCancelledExecutiveActionsCannotBeExecuted() public {
//         // prep
//         string memory description = "Inviting david to join senior role at alignedGrantsDao";
//         bytes memory lawCalldata = abi.encode(david);
//         vm.prank(charlotte); // = already a senior
//         alignedGrantsDao.propose(laws[1], lawCalldata, description); //

//         vm.startPrank(charlotte);
//         alignedGrantsDao.cancel(laws[1], lawCalldata, keccak256(bytes(description)));

//         vm.expectRevert();
//         alignedGrantsDao.execute(laws[1], lawCalldata, keccak256(bytes(description)));
//         vm.stopPrank();
//     }
// }

// contract VoteTest is TestSetup {
//     function testVotingIsNotPossibleForExecutiveActionsOutsideCredentials() public {
//     // prep
//         string memory description = "Inviting david to join senior role at alignedGrantsDao";
//         bytes memory lawCalldata = abi.encode(david);
//         vm.prank(charlotte); // = already a senior
//         uint256 proposalId = alignedGrantsDao.propose(laws[1], lawCalldata, description);

//         vm.expectRevert(SeparatedPowersErrors.SeparatedPowers__AccessDenied.selector);
//         vm.prank(eve); // not a senior.
//         alignedGrantsDao.castVote(proposalId, 1);
//     }

//     function testVotingIsNotPossibleForDefeatedExecutiveActions() public {
//         // prep
//         string memory description = "Inviting david to join senior role at alignedGrantsDao";
//         bytes memory lawCalldata = abi.encode(david);
//         vm.prank(charlotte); // = already a senior
//         uint256 proposalId = alignedGrantsDao.propose(laws[1], lawCalldata, description);
//         vm.roll(4_000); // == beyond durintion of 75,proposal is defeated because quorum not reached.

//         vm.expectRevert(SeparatedPowersErrors.SeparatedPowers__ExecutiveActionNotActive.selector);
//         vm.prank(charlotte); // is a senior.
//         alignedGrantsDao.castVote(proposalId, 1);
//     }

//     function testExecutiveActionDefeatedIfQuorumNotReachedInTime () public {
//         // prep
//         string memory description = "Inviting david to join senior role at alignedGrantsDao";
//         bytes memory lawCalldata = abi.encode(david);
//         vm.prank(charlotte); // = already a senior
//         uint256 proposalId = alignedGrantsDao.propose(laws[1], lawCalldata, description);

//         // go forward in time. -- not votes are cast.
//         vm.roll(4_000); // == beyond durintion of 150
//         SeparatedPowersTypes.ActionState proposalState = alignedGrantsDao.state(proposalId);
//         assert(uint8(proposalState) == 2); // == ActionState.Defeated
//     }

//     function testExecutiveActionSucceededIfQuorumReachedInTime () public {
//         // prep
//         string memory description = "Inviting david to join senior role at alignedGrantsDao";
//         bytes memory lawCalldata = abi.encode(david);
//         vm.prank(charlotte); // = already a senior
//         uint256 proposalId = alignedGrantsDao.propose(laws[1], lawCalldata, description);

//         // members vote in 'for' in support of david joining.
//         vm.prank(alice);
//         alignedGrantsDao.castVote(proposalId, 1); // = For
//         vm.prank(bob);
//         alignedGrantsDao.castVote(proposalId, 1); // = For

//         // go forward in time.
//         vm.roll(4_000); // == beyond durintion of 150
//         SeparatedPowersTypes.ActionState proposalState = alignedGrantsDao.state(proposalId);
//         assert(uint8(proposalState) == 3); // == ActionState.Succeeded
//     }

//     function testVotesWithReasonsWorks() public {
//         // prep
//         string memory description = "Inviting david to join senior role at alignedGrantsDao";
//         bytes memory lawCalldata = abi.encode(david);
//         vm.prank(charlotte); // = already a senior
//         uint256 proposalId = alignedGrantsDao.propose(laws[1], lawCalldata, description);

//         // members vote in 'for' in support of david joining.
//         vm.prank(alice);
//         alignedGrantsDao.castVoteWithReason (proposalId, 1, "This is a test"); // = For
//         vm.prank(bob);
//         alignedGrantsDao.castVoteWithReason (proposalId, 1, "This is a test");  // = For

//         // go forward in time.
//         vm.roll(4_000); // == beyond durintion of 150
//         SeparatedPowersTypes.ActionState proposalState = alignedGrantsDao.state(proposalId);
//         assert(uint8(proposalState) == 3); // == ActionState.Succeeded
//     }

//     function testExecutiveActionDefeatedIfQuorumReachedButNotEnoughForVotes () public {
//         // prep
//         string memory description = "Inviting david to join senior role at alignedGrantsDao";
//         bytes memory lawCalldata = abi.encode(david);
//         vm.prank(charlotte); // = already a senior
//         uint256 proposalId = alignedGrantsDao.propose(laws[1], lawCalldata, description);

//         // members vote in 'for' in support of david joining.
//         vm.prank(alice);
//         alignedGrantsDao.castVote(proposalId, 0); // = against
//         vm.prank(bob);
//         alignedGrantsDao.castVote(proposalId, 0); // = against
//         vm.prank(charlotte);
//         alignedGrantsDao.castVote(proposalId, 1); // = For

//         alignedGrantsDao.proposalVotes(proposalId);

//         // go forward in time.
//         vm.roll(4_000); // == beyond durintion of 150
//         SeparatedPowersTypes.ActionState proposalState = alignedGrantsDao.state(proposalId);
//         assert(uint8(proposalState) == 2); // == ActionState.Defeated
//     }

//     // function testLawsWithQuorumZeroIsAlwaysSucceeds() public {
//         // £todo Complete this one later because it is necessary to go through whole governance trajectory to call a relevant law ({Public_challengeRevoke})
//     // }

// }

// contract ExecuteTest is TestSetup {
//     function testWhenExecutiveActionPassesLawCanBeExecuted() public {
//         // prep
//         string memory description = "Inviting david to join senior role at alignedGrantsDao";
//         bytes memory lawCalldata = abi.encode(david);
//         vm.prank(charlotte); // = already a senior
//         uint256 proposalId = alignedGrantsDao.propose(laws[1], lawCalldata, description); //

//         // members vote in 'for' in support of david joining.
//         vm.prank(alice);
//         alignedGrantsDao.castVote(proposalId, 1); // = For
//         vm.prank(bob);
//         alignedGrantsDao.castVote(proposalId, 1); // = For

//         // go forward in time.
//         vm.roll(4_000); // == beyond durintion of 150
//         SeparatedPowersTypes.ActionState proposalState = alignedGrantsDao.state(proposalId);
//         assert(uint8(proposalState) == 3); // == ActionState.Succeeded

//         // execute
//         vm.prank(charlotte);
//         alignedGrantsDao.execute(laws[1], lawCalldata, keccak256(bytes(description)));

//         // check
//         uint48 since = alignedGrantsDao.hasRoleSince(david, SENIOR_ROLE);
//         assert(since != 0);
//     }

//     // function testWhenExecutiveActionDefeatsLawCannotBeExecuted() public {
//     //     // prep
//     //     string memory description = "Inviting david to join senior role at alignedGrantsDao";
//     //     bytes memory lawCalldata = abi.encode(david);
//     //     vm.prank(charlotte); // = already a senior
//     //     uint256 proposalId = alignedGrantsDao.propose(laws[1], lawCalldata, description); //

//     //     // members vote 'against' support of david joining.
//     //     vm.prank(alice);
//     //     alignedGrantsDao.castVote(proposalId, 0); // = against
//     //     vm.prank(bob);
//     //     alignedGrantsDao.castVote(proposalId, 0); // = against
//     //     vm.prank(charlotte);
//     //     alignedGrantsDao.castVote(proposalId, 1); // = for

//     //     // go forward in time.
//     //     vm.roll(4_000); // == beyond durintion of 150
//     //     SeparatedPowersTypes.ActionState proposalState = alignedGrantsDao.state(proposalId);
//     //     assert(uint8(proposalState) == 2); // == ActionState.Defeated

//     //     // execute
//     //     vm.expectRevert(abi.encodeWithSelector(
//     //         Senior_assignRole.Senior_assignRole__ExecutiveActionVoteNotSucceeded.selector, proposalId
//     //     ));
//     //     vm.prank(charlotte);
//     //     alignedGrantsDao.execute(laws[1], lawCalldata, keccak256(bytes(description)));
//     // }

//     function testExecuteLawSetsExecutiveActionToCompleted() public {
//         // prep
//         string memory description = "Inviting david to join senior role at alignedGrantsDao";
//         bytes memory lawCalldata = abi.encode(david);
//         vm.prank(charlotte); // = already a senior
//         uint256 proposalId = alignedGrantsDao.propose(laws[1], lawCalldata, description);

//         // seniors vote 'for' support of david joining.
//         vm.prank(alice);
//         alignedGrantsDao.castVote(proposalId, 1); // = for
//         vm.prank(bob);
//         alignedGrantsDao.castVote(proposalId, 1); // = for
//         vm.prank(charlotte);
//         alignedGrantsDao.castVote(proposalId, 1); // = for

//         // go forward in time.
//         vm.roll(4_000); // == beyond duration of 150
//         SeparatedPowersTypes.ActionState proposalState1 = alignedGrantsDao.state(proposalId);
//         assert(uint8(proposalState1) == 3); // == ActionState.Succeeded

//         // execute
//         vm.prank(charlotte);
//         alignedGrantsDao.execute(laws[1], lawCalldata, keccak256(bytes(description)));

//         // check
//         SeparatedPowersTypes.ActionState proposalState2 = alignedGrantsDao.state(proposalId);
//         assert(uint8(proposalState2) == 4); // == ActionState.Completed
//     }
// }


////////////////////////////////////////////////////////


//// These should not be here //// 
//   /* chain propsals */
//   function testSuccessfulChainOfExecutiveActionsLeadsToSuccessfulExecution() public {
//     /* PROPOSAL LINK 1: a whale proposes a law. */
//     // proposing...
//     address newLaw = address(new Public_assignRole(payable(address(alignedGrantsDao))));
//     string memory description = "Proposing to add a new Law";
//     bytes memory lawCalldata = abi.encode(newLaw, true);

//     vm.prank(eve); // = a whale
//     uint256 proposalIdOne = alignedGrantsDao.propose(
//       laws[4], // = Whale_proposeLaw
//       lawCalldata,
//       description
//     );

//     // whales vote... Only david and eve are whales.
//     vm.prank(david);
//     alignedGrantsDao.castVote(proposalIdOne, 1); // = for
//     vm.prank(eve);
//     alignedGrantsDao.castVote(proposalIdOne, 1); // = for

//     vm.roll(4_000);

//     // executing...
//     vm.prank(david);
//     alignedGrantsDao.execute(laws[4], lawCalldata, keccak256(bytes(description)));

//     // check
//     SeparatedPowersTypes.ActionState proposalStateOne = alignedGrantsDao.state(proposalIdOne);
//     assert(uint8(proposalStateOne) == 4); // == ActionState.Completed

//     /* PROPOSAL LINK 2: a seniors accept the proposed law. */
//     // proposing...
//     vm.roll(5_000);
//     vm.prank(charlotte); // = a senior
//     uint256 proposalIdTwo = alignedGrantsDao.propose(
//       laws[5], // = Senior_acceptProposedLaw
//       lawCalldata,
//       description
//     );

//     // seniors vote... alice, bob and charlotte are seniors.
//     vm.prank(alice);
//     alignedGrantsDao.castVote(proposalIdTwo, 1); // = for
//     vm.prank(bob);
//     alignedGrantsDao.castVote(proposalIdTwo, 1); // = for
//     vm.prank(charlotte);
//     alignedGrantsDao.castVote(proposalIdTwo, 1); // = for

//     vm.roll(9_000);

//     // executing...
//     vm.prank(bob);
//     alignedGrantsDao.execute(laws[5], lawCalldata, keccak256(bytes(description)));

//     // check
//     SeparatedPowersTypes.ActionState proposalStateTwo = alignedGrantsDao.state(proposalIdTwo);
//     assert(uint8(proposalStateTwo) == 4); // == ActionState.Completed

//     /* PROPOSAL LINK 3: the admin can execute a activation of the law. */
//     vm.roll(10_000);
//     vm.prank(alice); // = admin role
//     alignedGrantsDao.execute(laws[6], lawCalldata, keccak256(bytes(description)));

//     // check if law has been set to active.
//     bool active = alignedGrantsDao.activeLaws(newLaw);
//     assert (active == true);
//   }

//   function testWhaleDefeatStopsChain() public {
//     /* PROPOSAL LINK 1: a whale proposes a law. */
//     // proposing...
//     address newLaw = address(new Public_assignRole(payable(address(alignedGrantsDao))));
//     string memory description = "Proposing to add a new Law";
//     bytes memory lawCalldata = abi.encode(newLaw, true);

//     vm.prank(eve); // = a whale
//     uint256 proposalIdOne = alignedGrantsDao.propose(
//       laws[4], // = Whale_proposeLaw
//       lawCalldata,
//       description
//     );

//     // whales vote... Only david and eve are whales.
//     vm.prank(david);
//     alignedGrantsDao.castVote(proposalIdOne, 0); // = against
//     vm.prank(eve);
//     alignedGrantsDao.castVote(proposalIdOne, 0); // = against

//     vm.roll(4_000);

//     // executing does not work.
//     vm.prank(david);
//     vm.expectRevert(abi.encodeWithSelector(
//       Whale_proposeLaw.Whale_proposeLaw__ExecutiveActionVoteNotSucceeded.selector, proposalIdOne
//     ));
//     alignedGrantsDao.execute(laws[4], lawCalldata, keccak256(bytes(description)));

//     /* PROPOSAL LINK 2: a seniors accept the proposed law. */
//     // proposing...
//     vm.roll(5_000);
//     // NB: Note that it IS possible to create proposals that link back to non executed proposals.
//     // this is something to fix at a later date.
//     // proposals will not execute though. See below.
//     vm.prank(charlotte); // = a senior
//     uint256 proposalIdTwo = alignedGrantsDao.propose(
//       laws[5], // = Senior_acceptProposedLaw
//       lawCalldata,
//       description
//     );

//     // seniors vote... alice, bob and charlotte are seniors.
//     vm.prank(alice);
//     alignedGrantsDao.castVote(proposalIdTwo, 1); // = for
//     vm.prank(bob);
//     alignedGrantsDao.castVote(proposalIdTwo, 1); // = for
//     vm.prank(charlotte);
//     alignedGrantsDao.castVote(proposalIdTwo, 1); // = for

//     vm.roll(9_000);

//     // executing...
//     vm.prank(bob);
//     vm.expectRevert(abi.encodeWithSelector(
//       Senior_acceptProposedLaw.Senior_acceptProposedLaw__ParentExecutiveActionNotCompleted.selector, proposalIdOne
//     ));
//     alignedGrantsDao.execute(laws[5], lawCalldata, keccak256(bytes(description)));
//   }

//   function testSeniorDefeatStopsChain() public {
//         /* PROPOSAL LINK 1: a whale proposes a law. */
//     // proposing...
//     address newLaw = address(new Public_assignRole(payable(address(alignedGrantsDao))));
//     string memory description = "Proposing to add a new Law";
//     bytes memory lawCalldata = abi.encode(newLaw, true);

//     vm.prank(eve); // = a whale
//     uint256 proposalIdOne = alignedGrantsDao.propose(
//       laws[4], // = Whale_proposeLaw
//       lawCalldata,
//       description
//     );

//     // whales vote... Only david and eve are whales.
//     vm.prank(david);
//     alignedGrantsDao.castVote(proposalIdOne, 1); // = for
//     vm.prank(eve);
//     alignedGrantsDao.castVote(proposalIdOne, 1); // = for

//     vm.roll(4_000);

//     // executing...
//     vm.prank(david);
//     alignedGrantsDao.execute(laws[4], lawCalldata, keccak256(bytes(description)));

//     /* PROPOSAL LINK 2: a seniors accept the proposed law. */
//     vm.roll(5_000);
//     vm.prank(charlotte); // = a senior
//     uint256 proposalIdTwo = alignedGrantsDao.propose(
//       laws[5], // = Senior_acceptProposedLaw
//       lawCalldata,
//       description
//     );

//     // seniors vote... alice, bob and charlotte are seniors.
//     vm.prank(alice);
//     alignedGrantsDao.castVote(proposalIdTwo, 0); // = against
//     vm.prank(bob);
//     alignedGrantsDao.castVote(proposalIdTwo, 0); // = against
//     vm.prank(charlotte);
//     alignedGrantsDao.castVote(proposalIdTwo, 0); // = against

//     vm.roll(9_000);

//     // executing...
//     vm.prank(bob);
//     vm.expectRevert(abi.encodeWithSelector(
//       Senior_acceptProposedLaw.Senior_acceptProposedLaw__ExecutiveActionNotSucceeded.selector, proposalIdTwo
//     ));
//     alignedGrantsDao.execute(laws[5], lawCalldata, keccak256(bytes(description)));

//     /* PROPOSAL LINK 3: the admin can execute a activation of the law. */
//     vm.roll(10_000);
//     vm.prank(alice); // = admin role
//     vm.expectRevert();
//     alignedGrantsDao.execute(laws[6], lawCalldata, keccak256(bytes(description)));
//   }

//   //////////////////////////////////////////////////////////////
//   //            TESTING LAW AND ROLE ADMIN                    //
//   //////////////////////////////////////////////////////////////

//   /* {constitute} */
//   function testDeployProtocolEmitsEvent() public {
//     vm.expectEmit(true, false, false, false);
//     emit SeparatedPowersEvents.SeparatedPowers__Initialized(address(alignedGrantsDao));

//     vm.prank(alice);
//     separatedPowers = new SeparatedPowers("TestDao");
//   }

//   function testDeployProtocolSetsSenderToAdmin () public {
//     vm.prank(alice);
//     separatedPowers = new SeparatedPowers("TestDao");

//     assert (separatedPowers.hasRoleSince(alice, ADMIN_ROLE) != 0);
//   }

//   function testLawsRevertWhenNotActivated () public {
//     string memory requiredStatement = "I request membership to agDAO.";
//     bytes32 requiredStatementHash = keccak256(bytes(requiredStatement));
//     bytes memory lawCalldata = abi.encode(requiredStatementHash);

//     vm.startPrank(alice);
//     AgDao alignedGrantsDaoTest = new AgDao();
//     Law memberAssignRole = new Public_assignRole(payable(address(alignedGrantsDaoTest)));
//     vm.stopPrank();

//     vm.prank(bob);
//     alignedGrantsDaoTest.execute(address(memberAssignRole), lawCalldata, keccak256(bytes(requiredStatement)));
//   }

//   function testConstituteSetsLawsToActive() public {
//     SeparatedPowersTypes.ConstituentRole[] memory constituentRoles = new SeparatedPowersTypes.ConstituentRole[](1);
//     constituentRoles[0] = SeparatedPowersTypes.ConstituentRole(alice, MEMBER_ROLE);
//     laws = _deployLaws(payable(address(alignedGrantsDao)), address(agCoins));

//     vm.startPrank(alice);
//     AgDao alignedGrantsDaoTest = new AgDao();
//     alignedGrantsDaoTest.constitute(laws, constituentRoles);
//     vm.stopPrank();

//     bool active = alignedGrantsDaoTest.activeLaws(laws[0]);
//     assert (active == true);
//   }

//   function testConstituteRevertsOnSecondCall () public {
//     SeparatedPowersTypes.ConstituentRole[] memory constituentRoles = new SeparatedPowersTypes.ConstituentRole[](1);
//     constituentRoles[0] = SeparatedPowersTypes.ConstituentRole(alice, MEMBER_ROLE);
//     laws = _deployLaws(payable(address(alignedGrantsDao)), address(agCoins));

//     vm.expectRevert(SeparatedPowersErrors.SeparatedPowers__ConstitutionAlreadyExecuted.selector);
//     vm.startBroadcast(alice); // = admin
//     alignedGrantsDao.constitute(laws, constituentRoles);
//     vm.stopBroadcast();
//   }

//   function testConstituteCannotBeCalledByNonAdmin() public {
//     vm.roll(15);
//     vm.startBroadcast(alice); // => alice automatically set as admin.
//       alignedGrantsDao = new AgDao();
//       agCoins = new AgCoins(address(alignedGrantsDao));
//     vm.stopBroadcast();

//     SeparatedPowersTypes.ConstituentRole[] memory constituentRoles = new SeparatedPowersTypes.ConstituentRole[](1);
//     constituentRoles[0] = SeparatedPowersTypes.ConstituentRole(alice, MEMBER_ROLE);
//     laws = _deployLaws(payable(address(alignedGrantsDao)), address(agCoins));

//     vm.expectRevert(SeparatedPowersErrors.SeparatedPowers__AccessDenied.selector);
//     vm.startBroadcast(bob); // != admin
//     alignedGrantsDao.constitute(laws, constituentRoles);
//     vm.stopBroadcast();
//   }

//   /* law management */

//   function testSetLawRevertsIfNotCalledFromSeparatedPowers() public {
//     address newLaw = address(new Public_assignRole(payable(address(alignedGrantsDao))));

//     vm.expectRevert(SeparatedPowersErrors.SeparatedPowers__NotAuthorized.selector);
//     vm.prank(alice);
//     alignedGrantsDao.setLaw(newLaw, true);
//   }

//   function testSetLawRevertsIfAddressNotALaw() public {
//     /* PROPOSAL LINK 1: a whale proposes a law. */
//     // proposing...
//     address thisIsNoLaw = address(new AgDao());
//     string memory description = "Proposing to add a new Law";
//     bytes memory lawCalldata = abi.encode(thisIsNoLaw, true);

//     vm.prank(eve); // = a whale
//     uint256 proposalIdOne = alignedGrantsDao.propose(
//       laws[4], // = Whale_proposeLaw
//       lawCalldata,
//       description
//     );

//     // whales vote... Only david and eve are whales.
//     vm.prank(david);
//     alignedGrantsDao.castVote(proposalIdOne, 1); // = for
//     vm.prank(eve);
//     alignedGrantsDao.castVote(proposalIdOne, 1); // = for

//     vm.roll(4_000);

//     // executing...
//     vm.prank(david);
//     alignedGrantsDao.execute(laws[4], lawCalldata, keccak256(bytes(description)));

//     // check
//     SeparatedPowersTypes.ActionState proposalStateOne = alignedGrantsDao.state(proposalIdOne);
//     assert(uint8(proposalStateOne) == 4); // == ActionState.Completed

//     /* PROPOSAL LINK 2: a seniors accept the proposed law. */
//     // proposing...
//     vm.roll(5_000);

//     vm.prank(charlotte); // = a senior
//     uint256 proposalIdTwo = alignedGrantsDao.propose(
//       laws[5], // = Senior_acceptProposedLaw
//       lawCalldata,
//       description
//     );

//     // seniors vote... alice, bob and charlotte are seniors.
//     vm.prank(alice);
//     alignedGrantsDao.castVote(proposalIdTwo, 1); // = for
//     vm.prank(bob);
//     alignedGrantsDao.castVote(proposalIdTwo, 1); // = for
//     vm.prank(charlotte);
//     alignedGrantsDao.castVote(proposalIdTwo, 1); // = for

//     vm.roll(9_000);

//     // executing...
//     vm.prank(bob);
//     alignedGrantsDao.execute(laws[5], lawCalldata, keccak256(bytes(description)));

//     // check
//     SeparatedPowersTypes.ActionState proposalStateTwo = alignedGrantsDao.state(proposalIdTwo);
//     assert(uint8(proposalStateTwo) == 4); // == ActionState.Completed

//     /* PROPOSAL LINK 3: the admin can execute a activation of the law. */
//     vm.roll(10_000);

//     vm.prank(alice); // = admin role
//     vm.expectRevert(abi.encodeWithSelector(
//     SeparatedPowersErrors.SeparatedPowers__IncorrectInterface.selector, thisIsNoLaw));
//      alignedGrantsDao.execute(laws[6], lawCalldata, keccak256(bytes(description)));
//   }

//   function testSetLawDoesNotingIfNoChange() public {
//      /* PROPOSAL LINK 1: a whale proposes a law. */
//     // proposing...
//     // Note newLaw is actually an already existing law.
//     address newLaw = laws[0];
//     string memory description = "Proposing to add a new Law";
//     bytes memory lawCalldata = abi.encode(newLaw, true);

//     vm.prank(eve); // = a whale
//     uint256 proposalIdOne = alignedGrantsDao.propose(
//       laws[4], // = Whale_proposeLaw
//       lawCalldata,
//       description
//     );

//     // whales vote... Only david and eve are whales.
//     vm.prank(david);
//     alignedGrantsDao.castVote(proposalIdOne, 1); // = for
//     vm.prank(eve);
//     alignedGrantsDao.castVote(proposalIdOne, 1); // = for

//     vm.roll(4_000);

//     // executing...
//     vm.prank(david);
//     alignedGrantsDao.execute(laws[4], lawCalldata, keccak256(bytes(description)));

//     // check
//     SeparatedPowersTypes.ActionState proposalStateOne = alignedGrantsDao.state(proposalIdOne);
//     assert(uint8(proposalStateOne) == 4); // == ActionState.Completed

//     /* PROPOSAL LINK 2: a seniors accept the proposed law. */
//     // proposing...
//     vm.roll(5_000);

//     vm.prank(charlotte); // = a senior
//     uint256 proposalIdTwo = alignedGrantsDao.propose(
//       laws[5], // = Senior_acceptProposedLaw
//       lawCalldata,
//       description
//     );

//     // seniors vote... alice, bob and charlotte are seniors.
//     vm.prank(alice);
//     alignedGrantsDao.castVote(proposalIdTwo, 1); // = for
//     vm.prank(bob);
//     alignedGrantsDao.castVote(proposalIdTwo, 1); // = for
//     vm.prank(charlotte);
//     alignedGrantsDao.castVote(proposalIdTwo, 1); // = for

//     vm.roll(9_000);

//     // executing...
//     vm.prank(bob);
//     alignedGrantsDao.execute(laws[5], lawCalldata, keccak256(bytes(description)));

//     // check
//     SeparatedPowersTypes.ActionState proposalStateTwo = alignedGrantsDao.state(proposalIdTwo);
//     assert(uint8(proposalStateTwo) == 4); // == ActionState.Completed

//     /* PROPOSAL LINK 3: the admin can execute a activation of the law. */
//     vm.roll(10_000);

//     vm.expectEmit(true, false, false, false);
//     emit SeparatedPowersEvents.LawSet(newLaw, true, false);
//     vm.prank(alice); // = admin role
//     alignedGrantsDao.execute(laws[6], lawCalldata, keccak256(bytes(description)));
//   }

//   /* Role Management */
//   /* adding and removing roles */
//   function testSetRoleCannotBeCalledFromOutsidePropotocol() public {
//     vm.prank(alice); // = Admin
//     vm.expectRevert();
//     alignedGrantsDao.setRole(WHALE_ROLE, bob, true);
//   }

//   function testAddingRoleAddsOneToAmountMembers() public {
//     // prep
//     string memory requiredStatement = "I request membership to agDAO.";
//     bytes32 requiredStatementHash = keccak256(bytes(requiredStatement));
//     bytes memory lawCalldata = abi.encode(requiredStatementHash);
//     uint256 amountMembersBefore = alignedGrantsDao.getAmountRoleHolders(MEMBER_ROLE);

//     // act
//     vm.prank(frank);
//     alignedGrantsDao.execute(laws[0], lawCalldata, keccak256(bytes(requiredStatement)));

//     // checks
//     uint48 since = alignedGrantsDao.hasRoleSince(frank, MEMBER_ROLE);
//     assert (since != 0);
//     uint256 amountMembersAfter = alignedGrantsDao.getAmountRoleHolders(MEMBER_ROLE);
//     assert (amountMembersAfter == amountMembersBefore + 1);
//   }

//   function testRemovingRoleSubtratcsOneFromAmountMembers() public {
//     // prep
//     uint256 amountSeniorsBefore = alignedGrantsDao.getAmountRoleHolders(SENIOR_ROLE);
//     string memory description = "Charlotte is getting booted as Senior.";
//     bytes memory lawCalldata = abi.encode(charlotte);

//     // act
//     vm.prank(charlotte); // = already a senior
//     uint256 proposalId = alignedGrantsDao.propose(laws[2], lawCalldata, description);
//     vm.prank(alice);
//     alignedGrantsDao.castVote(proposalId, 1); // = For
//     vm.prank(bob);
//     alignedGrantsDao.castVote(proposalId, 1); // = For
//     vm.prank(charlotte);
//     alignedGrantsDao.castVote(proposalId, 1); // = For

//     // go forward in time.
//     vm.roll(4_000); // == beyond durintion of 150
//     SeparatedPowersTypes.ActionState proposalState = alignedGrantsDao.state(proposalId);
//     assert(uint8(proposalState) == 3); // == ActionState.Succeeded

//     // execute
//     vm.prank(bob);
//     alignedGrantsDao.execute(laws[2], lawCalldata, keccak256(bytes(description)));

//     // check
//     uint48 since = alignedGrantsDao.hasRoleSince(charlotte, SENIOR_ROLE);
//     assert(since == 0); // charlotte should have lost here role.

//     uint256 amountSeniorsAfter = alignedGrantsDao.getAmountRoleHolders(SENIOR_ROLE);
//     assert(amountSeniorsBefore - 1 == amountSeniorsAfter);
//   }

//   /* votes */
//   function testAccountCannotVoteTwice() public {
//     // prep
//     string memory description = "Charlotte is getting booted as Senior.";
//     bytes memory lawCalldata = abi.encode(charlotte);

//     // act
//     vm.prank(charlotte);
//     uint256 proposalId = alignedGrantsDao.propose(laws[2], lawCalldata, description);

//     // alice votes once..
//     vm.prank(alice);
//     alignedGrantsDao.castVote(proposalId, 1); // = For

//     // alice tries to vote twice...
//     vm.prank(alice);
//     vm.expectRevert(abi.encodeWithSelector(
//       SeparatedPowersErrors.SeparatedPowers__AlreadyCastVote.selector, alice));
//     alignedGrantsDao.castVote(proposalId, 1); // = For
//   }

//   function testAgainstVoteIsCorrectlyCounted() public {
//     // prep
//     string memory description = "Charlotte is getting booted as Senior.";
//     bytes memory lawCalldata = abi.encode(charlotte);

//     // act
//     vm.prank(charlotte);
//     uint256 proposalId = alignedGrantsDao.propose(laws[2], lawCalldata, description);
//     vm.prank(alice);
//     alignedGrantsDao.castVote(proposalId, 0); // = against
//     vm.prank(bob);
//     alignedGrantsDao.castVote(proposalId, 0); // = against
//     vm.prank(charlotte);
//     alignedGrantsDao.castVote(proposalId, 0); // = against

//     // check
//     (uint256 againstVotes, , ) = alignedGrantsDao.proposalVotes(proposalId);
//     assert (againstVotes == 3);
//   }

//   function testForVoteIsCorrectlyCounted() public {
//     // prep
//     string memory description = "Charlotte is getting booted as Senior.";
//     bytes memory lawCalldata = abi.encode(charlotte);

//     // act
//     vm.prank(charlotte);
//     uint256 proposalId = alignedGrantsDao.propose(laws[2], lawCalldata, description);
//     vm.prank(alice);
//     alignedGrantsDao.castVote(proposalId, 1); // = For
//     vm.prank(bob);
//     alignedGrantsDao.castVote(proposalId, 1); // = For
//     vm.prank(charlotte);
//     alignedGrantsDao.castVote(proposalId, 1); // = For

//     // check
//     (, uint256 forVotes, ) = alignedGrantsDao.proposalVotes(proposalId);
//     assert (forVotes == 3);
//   }

//   function testAbstainVoteIsCorrectlyCounted() public {
//     // prep
//     string memory description = "Charlotte is getting booted as Senior.";
//     bytes memory lawCalldata = abi.encode(charlotte);

//     // act
//     vm.prank(charlotte);
//     uint256 proposalId = alignedGrantsDao.propose(laws[2], lawCalldata, description);
//     vm.prank(alice);
//     alignedGrantsDao.castVote(proposalId, 2); // = abstain
//     vm.prank(bob);
//     alignedGrantsDao.castVote(proposalId, 2); // = abstain
//     vm.prank(charlotte);
//     alignedGrantsDao.castVote(proposalId, 2); // = abstain

//     // check
//     (, , uint256 abstainVotes) = alignedGrantsDao.proposalVotes(proposalId);
//     assert (abstainVotes == 3);
//   }

//   function testInvalidVoteRevertsCorrectly() public {
//     // prep
//     string memory description = "Charlotte is getting booted as Senior.";
//     bytes memory lawCalldata = abi.encode(charlotte);

//     // act
//     vm.prank(charlotte);
//     uint256 proposalId = alignedGrantsDao.propose(laws[2], lawCalldata, description);
//     vm.prank(alice);
//     vm.expectRevert(SeparatedPowersErrors.SeparatedPowers__InvalidVoteType.selector);
//     alignedGrantsDao.castVote(proposalId, 4); // = incorrect vote type

//     // check
//     (uint256 againstVotes, uint256 forVotes, uint256 abstainVotes) = alignedGrantsDao.proposalVotes(proposalId);
//     assert (againstVotes == 0);
//     assert (forVotes == 0);
//     assert (abstainVotes == 0);
//   }

//   function testHasVotedReturnCorrectData() public {
//     // prep
//     string memory description = "Charlotte is getting booted as Senior.";
//     bytes memory lawCalldata = abi.encode(charlotte);

//     // act
//     vm.prank(charlotte);
//     uint256 proposalId = alignedGrantsDao.propose(laws[2], lawCalldata, description);
//     vm.prank(charlotte);
//     alignedGrantsDao.castVote(proposalId, 2); // = abstain

//     // check
//     assert (alignedGrantsDao.hasVoted(proposalId, charlotte) == true);
//   }
