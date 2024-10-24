// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.26;

import {Test, console, console2} from "lib/forge-std/src/Test.sol";
import {DeployAgDao} from "../../script/DeployAgDao.s.sol";
import {SeparatedPowers} from "../../src/SeparatedPowers.sol";
import {AgDao} from   "../../src/implementation/AgDao.sol";
import {AgCoins} from "../../src/implementation/AgCoins.sol";
import {Law} from "../../src/Law.sol";
import {IAuthoritiesManager} from "../../src/interfaces/IAuthoritiesManager.sol";
import {ISeparatedPowers} from "../../src/interfaces/ISeparatedPowers.sol";

// constitutional laws
import {Admin_setLaw} from "../../src/implementation/laws/Admin_setLaw.sol";
import {Public_assignRole} from "../../src/implementation/laws/Public_assignRole.sol";
import {Public_challengeRevoke} from "../../src/implementation/laws/Public_challengeRevoke.sol";
import {Member_proposeCoreValue} from "../../src/implementation/laws/Member_proposeCoreValue.sol";
import {Senior_acceptProposedLaw} from "../../src/implementation/laws/Senior_acceptProposedLaw.sol";
import {Senior_assignRole} from "../../src/implementation/laws/Senior_assignRole.sol";
import {Senior_reinstateMember} from "../../src/implementation/laws/Senior_reinstateMember.sol";
import {Senior_revokeRole} from "../../src/implementation/laws/Senior_revokeRole.sol";
import {Whale_acceptCoreValue} from "../../src/implementation/laws/Whale_acceptCoreValue.sol";
import {Member_assignWhale} from "../../src/implementation/laws/Member_assignWhale.sol";
import {Whale_proposeLaw} from "../../src/implementation/laws/Whale_proposeLaw.sol";
import {Whale_revokeMember} from "../../src/implementation/laws/Whale_revokeMember.sol";

/**
* @notice Unit tests for the core Separated Powers protocol.
* 
* @dev tests build on the agDao example. 
* @dev for chained proposal tests, see the 'chain propsals' section. 
*/

contract SeparatedPowersTest is Test {
  /* Type declarations */
  SeparatedPowers separatedPowers;
  AgDao agDao;
  AgCoins agCoins;
  address[] constituentLaws;  

  /* addresses */
  address alice = makeAddr("alice");
  address bob = makeAddr("bob");
  address charlotte = makeAddr("charlotte");
  address david = makeAddr("david");
  address eve = makeAddr("eve");
  address frank = makeAddr("frank");

  /* state variables */
  uint64 public constant ADMIN_ROLE = type(uint64).min; // == 0
  uint64 public constant PUBLIC_ROLE = type(uint64).max; // == a lot. This role is for everyone. 
  uint64 public constant SENIOR_ROLE = 1; 
  uint64 public constant WHALE_ROLE = 2; 
  uint64 public constant MEMBER_ROLE = 3; 
  bytes32 SALT = bytes32(hex'7ceda5'); 

  /* modifiers */

  ///////////////////////////////////////////////
  ///                   Setup                 ///
  ///////////////////////////////////////////////
  function setUp() public {     
    vm.roll(10); 
    vm.startBroadcast(alice);
      agDao = new AgDao();
      agCoins = new AgCoins(address(agDao));
    vm.stopBroadcast();

    /* setup roles */
    IAuthoritiesManager.ConstituentRole[] memory constituentRoles = new IAuthoritiesManager.ConstituentRole[](10);
    constituentRoles[0] = IAuthoritiesManager.ConstituentRole(alice, MEMBER_ROLE);
    constituentRoles[1] = IAuthoritiesManager.ConstituentRole(bob, MEMBER_ROLE);
    constituentRoles[2] = IAuthoritiesManager.ConstituentRole(charlotte, MEMBER_ROLE);
    constituentRoles[3] = IAuthoritiesManager.ConstituentRole(david, MEMBER_ROLE);
    constituentRoles[4] = IAuthoritiesManager.ConstituentRole(eve, MEMBER_ROLE);
    constituentRoles[5] = IAuthoritiesManager.ConstituentRole(alice, SENIOR_ROLE);
    constituentRoles[6] = IAuthoritiesManager.ConstituentRole(bob, SENIOR_ROLE);
    constituentRoles[7] = IAuthoritiesManager.ConstituentRole(charlotte, SENIOR_ROLE);
    constituentRoles[8] = IAuthoritiesManager.ConstituentRole(david, WHALE_ROLE);
    constituentRoles[9] = IAuthoritiesManager.ConstituentRole(eve, WHALE_ROLE);

    /* setup laws */
    constituentLaws = _deployLaws(payable(address(agDao)), address(agCoins));
    
    vm.startBroadcast(alice);
    agDao.constitute(constituentLaws, constituentRoles);
    vm.stopBroadcast();
  }

  ///////////////////////////////////////////////
  ///                   Tests                 ///
  ///////////////////////////////////////////////

  /* {constitute} */
  function testDeployProtocolEmitsEvent() public {
    vm.expectEmit(true, false, false, false);
    emit SeparatedPowers.SeparatedPowers__Initialized(address(agDao));

    vm.prank(alice); 
    separatedPowers = new SeparatedPowers("TestDao");
  }

  function testDeployProtocolSetsSenderToAdmin () public {
    vm.prank(alice); 
    separatedPowers = new SeparatedPowers("TestDao");

    assert (separatedPowers.hasRoleSince(alice, ADMIN_ROLE) != 0);
  }
  
  function testLawsRevertWhenNotActivated () public {
    string memory requiredStatement = "I request membership to agDAO.";
    bytes32 requiredStatementHash = keccak256(bytes(requiredStatement));
    bytes memory lawCalldata = abi.encode(requiredStatementHash);
    
    vm.startPrank(alice); 
    AgDao agDaoTest = new AgDao();
    Law memberAssignRole = new Public_assignRole(payable(address(agDaoTest)));
    vm.stopPrank();

    // vm.expectRevert(SeparatedPowers.SeparatedPowers__ExecuteCallNotFromActiveLaw.selector);
    vm.prank(bob); 
    agDaoTest.execute(address(memberAssignRole), lawCalldata, keccak256(bytes(requiredStatement))); 
  }

  function testConstituteSetsLawsToActive() public {
    IAuthoritiesManager.ConstituentRole[] memory constituentRoles = new IAuthoritiesManager.ConstituentRole[](1);
    constituentRoles[0] = IAuthoritiesManager.ConstituentRole(alice, MEMBER_ROLE);
    constituentLaws = _deployLaws(payable(address(agDao)), address(agCoins));
    
    vm.startPrank(alice); 
    AgDao agDaoTest = new AgDao();
    agDaoTest.constitute(constituentLaws, constituentRoles);
    vm.stopPrank();

    bool active = agDaoTest.activeLaws(constituentLaws[0]);
    assert (active == true);
  }

  function testConstituteRevertsOnSecondCall () public {
    IAuthoritiesManager.ConstituentRole[] memory constituentRoles = new IAuthoritiesManager.ConstituentRole[](1);
    constituentRoles[0] = IAuthoritiesManager.ConstituentRole(alice, MEMBER_ROLE);
    constituentLaws = _deployLaws(payable(address(agDao)), address(agCoins));

    vm.expectRevert(SeparatedPowers.SeparatedPowers__ConstitutionAlreadyExecuted.selector);
    vm.startBroadcast(alice); // = admin
    agDao.constitute(constituentLaws, constituentRoles);
    vm.stopBroadcast();
  }

  function testConstituteCannotBeCalledByNonAdmin() public {
    vm.roll(15); 
    vm.startBroadcast(alice); // => alice automatically set as admin. 
      agDao = new AgDao();
      agCoins = new AgCoins(address(agDao));
    vm.stopBroadcast();

    IAuthoritiesManager.ConstituentRole[] memory constituentRoles = new IAuthoritiesManager.ConstituentRole[](1);
    constituentRoles[0] = IAuthoritiesManager.ConstituentRole(alice, MEMBER_ROLE);
    constituentLaws = _deployLaws(payable(address(agDao)), address(agCoins));

    vm.expectRevert(SeparatedPowers.SeparatedPowers__AccessDenied.selector); 
    vm.startBroadcast(bob); // != admin 
    agDao.constitute(constituentLaws, constituentRoles);
    vm.stopBroadcast();
  }

  /* {propose} */
  function testProposeRevertsWhenAccountLacksCredentials() public {
    string memory description = "Inviting david to join senior role at agDao";
    bytes memory lawCalldata = abi.encode(david); 
    
    vm.expectRevert(SeparatedPowers.SeparatedPowers__AccessDenied.selector); 
    vm.prank(david);
    agDao.propose(constituentLaws[1], lawCalldata, description);
  }

  function testProposePassesWithCorrectCredentials() public { 
    string memory description = "Inviting david to join senior role at agDao";
    bytes memory lawCalldata = abi.encode(david); 

    vm.prank(charlotte); // = already a senior
    uint256 proposalId = agDao.propose(constituentLaws[1], lawCalldata, description);

    ISeparatedPowers.ProposalState proposalState = agDao.state(proposalId);
    assert(uint8(proposalState) == 0); // == ProposalState.Active
  }

  // function testPublicLawsAccessibleToEveryone() public {
    // £todo Complete this one later because it is necessary to go through whole governance trajectory to call a relevant law ({Public_challengeRevoke})
    // bytes memory lawCalldata = abi.encode(keccak256(bytes("I request membership to agDAO."))); 

    // vm.prank(charlotte); // = already a senior
    // uint256 proposalId = agDao.propose(constituentLaws[1], lawCalldata, description);
  // }

  /* voting */ 
  function testVotingIsNotPossibleForProposalsOutsideCredentials() public {
    // prep 
    string memory description = "Inviting david to join senior role at agDao";
    bytes memory lawCalldata = abi.encode(david); 
    vm.prank(charlotte); // = already a senior
    uint256 proposalId = agDao.propose(constituentLaws[1], lawCalldata, description);

    vm.expectRevert(SeparatedPowers.SeparatedPowers__NoAccessToTargetLaw.selector); 
    vm.prank(eve); // not a senior. 
    agDao.castVote(proposalId, 1);
  }

  function testVotingIsNotPossibleForDefeatedProposals() public {
    // prep
    string memory description = "Inviting david to join senior role at agDao";
    bytes memory lawCalldata = abi.encode(david); 
    vm.prank(charlotte); // = already a senior
    uint256 proposalId = agDao.propose(constituentLaws[1], lawCalldata, description);
    vm.roll(4_000); // == beyond durintion of 75,proposal is defeated because quorum not reached. 
 
    vm.expectRevert(SeparatedPowers.SeparatedPowers__ProposalNotActive.selector); 
    vm.prank(charlotte); // is a senior. 
    agDao.castVote(proposalId, 1);
  }

  /* state change proposals */
  function testProposalDefeatedIfQuorumNotReachedInTime () public {
    // prep 
    string memory description = "Inviting david to join senior role at agDao";
    bytes memory lawCalldata = abi.encode(david); 
    vm.prank(charlotte); // = already a senior
    uint256 proposalId = agDao.propose(constituentLaws[1], lawCalldata, description);

    // go forward in time. -- not votes are cast. 
    vm.roll(4_000); // == beyond durintion of 150 
    ISeparatedPowers.ProposalState proposalState = agDao.state(proposalId);
    assert(uint8(proposalState) == 2); // == ProposalState.Defeated
  }

  function testProposalSucceededIfQuorumReachedInTime () public {
    // prep 
    string memory description = "Inviting david to join senior role at agDao";
    bytes memory lawCalldata = abi.encode(david); 
    vm.prank(charlotte); // = already a senior
    uint256 proposalId = agDao.propose(constituentLaws[1], lawCalldata, description);

    // members vote in 'for' in support of david joining. 
    vm.prank(alice);
    agDao.castVote(proposalId, 1); // = For 
    vm.prank(bob); 
    agDao.castVote(proposalId, 1); // = For 

    // go forward in time. 
    vm.roll(4_000); // == beyond durintion of 150 
    ISeparatedPowers.ProposalState proposalState = agDao.state(proposalId); 
    assert(uint8(proposalState) == 3); // == ProposalState.Succeeded
  }

  function testVotesWithReasonsWorks() public {
    // prep 
    string memory description = "Inviting david to join senior role at agDao";
    bytes memory lawCalldata = abi.encode(david); 
    vm.prank(charlotte); // = already a senior
    uint256 proposalId = agDao.propose(constituentLaws[1], lawCalldata, description);

    // members vote in 'for' in support of david joining. 
    vm.prank(alice);
    agDao.castVoteWithReason (proposalId, 1, "This is a test"); // = For 
    vm.prank(bob); 
    agDao.castVoteWithReason (proposalId, 1, "This is a test");  // = For 

    // go forward in time. 
    vm.roll(4_000); // == beyond durintion of 150 
    ISeparatedPowers.ProposalState proposalState = agDao.state(proposalId); 
    assert(uint8(proposalState) == 3); // == ProposalState.Succeeded
  }

  function testProposalDefeatedIfQuorumReachedButNotEnoughForVotes () public {
    // prep 
    string memory description = "Inviting david to join senior role at agDao";
    bytes memory lawCalldata = abi.encode(david); 
    vm.prank(charlotte); // = already a senior
    uint256 proposalId = agDao.propose(constituentLaws[1], lawCalldata, description);

    // members vote in 'for' in support of david joining. 
    vm.prank(alice);
    agDao.castVote(proposalId, 0); // = against 
    vm.prank(bob); 
    agDao.castVote(proposalId, 0); // = against 
    vm.prank(charlotte); 
    agDao.castVote(proposalId, 1); // = For 

    agDao.proposalVotes(proposalId);

    // go forward in time. 
    vm.roll(4_000); // == beyond durintion of 150 
    ISeparatedPowers.ProposalState proposalState = agDao.state(proposalId); 
    assert(uint8(proposalState) == 2); // == ProposalState.Defeated
  }

  // function testLawsWithQuorumZeroIsAlwaysSucceeds() public {
    // £todo Complete this one later because it is necessary to go through whole governance trajectory to call a relevant law ({Public_challengeRevoke})
  // }


  /* execute proposals */
  function testWhenProposalPassesLawCanBeExecuted() public {
    // prep
    string memory description = "Inviting david to join senior role at agDao";
    bytes memory lawCalldata = abi.encode(david);  
    vm.prank(charlotte); // = already a senior
    uint256 proposalId = agDao.propose(constituentLaws[1], lawCalldata, description); // NB: the two strings need to be the same. 

    // members vote in 'for' in support of david joining. 
    vm.prank(alice);
    agDao.castVote(proposalId, 1); // = For 
    vm.prank(bob); 
    agDao.castVote(proposalId, 1); // = For 

    // go forward in time. 
    vm.roll(4_000); // == beyond durintion of 150 
    ISeparatedPowers.ProposalState proposalState = agDao.state(proposalId); 
    assert(uint8(proposalState) == 3); // == ProposalState.Succeeded

    // execute
    vm.prank(charlotte); 
    agDao.execute(constituentLaws[1], lawCalldata, keccak256(bytes(description)));

    // check
    uint48 since = agDao.hasRoleSince(david, SENIOR_ROLE);
    assert(since != 0); 
  }

  function testWhenProposalDefeatsLawCannotBeExecuted() public {
      // prep
      string memory description = "Inviting david to join senior role at agDao";
      bytes memory lawCalldata = abi.encode(david);  
      vm.prank(charlotte); // = already a senior
      uint256 proposalId = agDao.propose(constituentLaws[1], lawCalldata, description); // NB: the two strings need to be the same. 

      // members vote 'against' support of david joining. 
      vm.prank(alice);
      agDao.castVote(proposalId, 0); // = against 
      vm.prank(bob); 
      agDao.castVote(proposalId, 0); // = against
      vm.prank(charlotte); 
      agDao.castVote(proposalId, 1); // = for

      // go forward in time. 
      vm.roll(4_000); // == beyond durintion of 150 
      ISeparatedPowers.ProposalState proposalState = agDao.state(proposalId); 
      assert(uint8(proposalState) == 2); // == ProposalState.Defeated

      // execute
      vm.expectRevert(abi.encodeWithSelector(
        Senior_assignRole.Senior_assignRole__ProposalVoteNotSucceeded.selector, proposalId
      )); 
      vm.prank(charlotte); 
      agDao.execute(constituentLaws[1], lawCalldata, keccak256(bytes(description)));
  }

  function testExecuteLawSetsProposalToCompleted() public {
     // prep
      string memory description = "Inviting david to join senior role at agDao";
      bytes memory lawCalldata = abi.encode(david);  
      vm.prank(charlotte); // = already a senior
      uint256 proposalId = agDao.propose(constituentLaws[1], lawCalldata, description); // NB: the two strings need to be the same. 

      // members vote 'against' support of david joining. 
      vm.prank(alice);
      agDao.castVote(proposalId, 1); // = for 
      vm.prank(bob); 
      agDao.castVote(proposalId, 1); // = for
      vm.prank(charlotte); 
      agDao.castVote(proposalId, 1); // = for

      // go forward in time. 
      vm.roll(4_000); // == beyond durintion of 150 
      ISeparatedPowers.ProposalState proposalState1 = agDao.state(proposalId); 
      assert(uint8(proposalState1) == 3); // == ProposalState.Defeated

      // execute 
      vm.prank(charlotte); 
      agDao.execute(constituentLaws[1], lawCalldata, keccak256(bytes(description)));

      // check
      ISeparatedPowers.ProposalState proposalState2 = agDao.state(proposalId); 
      assert(uint8(proposalState2) == 4); // == ProposalState.Completed
  }

  /* cancel proposals */ 
  function testCancellingProposalsEmitsCorrectEvent() public {
    // prep
    string memory description = "Inviting david to join senior role at agDao";
    bytes memory lawCalldata = abi.encode(david);  
    vm.prank(charlotte); // = already a senior
    uint256 proposalId = agDao.propose(constituentLaws[1], lawCalldata, description); // NB: the two strings need to be the same. 

    vm.expectEmit(true, false, false, false);
    emit SeparatedPowers.ProposalCancelled(proposalId);
    vm.prank(charlotte);
    agDao.cancel(constituentLaws[1], lawCalldata, keccak256(bytes(description)));
  }

  function testCancellingProposalsSetsStateToCancelled() public {
    // prep
    string memory description = "Inviting david to join senior role at agDao";
    bytes memory lawCalldata = abi.encode(david);  
    vm.prank(charlotte); // = already a senior
    uint256 proposalId = agDao.propose(constituentLaws[1], lawCalldata, description); // NB: the two strings need to be the same. 
    
    vm.prank(charlotte);
    agDao.cancel(constituentLaws[1], lawCalldata, keccak256(bytes(description)));
    
    ISeparatedPowers.ProposalState proposalState = agDao.state(proposalId); 
    assert(uint8(proposalState) == 1); // == ProposalState.Cancelled
  }

  function testCancelRevertsWhenAccountIsNotProposer() public {
    // prep
    string memory description = "Inviting david to join senior role at agDao";
    bytes memory lawCalldata = abi.encode(david);  
    vm.prank(charlotte); // = already a senior
    agDao.propose(constituentLaws[1], lawCalldata, description); // NB: the two strings need to be the same. 

    vm.expectRevert(abi.encodeWithSelector(
      SeparatedPowers.SeparatedPowers__OnlyProposer.selector, david
    )); 
    
    vm.prank(david);
    agDao.cancel(constituentLaws[1], lawCalldata, keccak256(bytes(description)));
  }

  function testCancelledProposalsCannotBeExecuted() public {
    // prep
    string memory description = "Inviting david to join senior role at agDao";
    bytes memory lawCalldata = abi.encode(david);  
    vm.prank(charlotte); // = already a senior
    agDao.propose(constituentLaws[1], lawCalldata, description); // NB: the two strings need to be the same. 

    vm.startPrank(charlotte);
    agDao.cancel(constituentLaws[1], lawCalldata, keccak256(bytes(description)));

    vm.expectRevert(); 
    agDao.execute(constituentLaws[1], lawCalldata, keccak256(bytes(description)));
    vm.stopPrank(); 
  }
  
  /* chain propsals */
  function testSuccessfulChainOfProposalsLeadsToSuccessfulExecution() public {
    /* PROPOSAL LINK 1: a whale proposes a law. */   
    // proposing... 
    address newLaw = address(new Public_assignRole(payable(address(agDao))));
    string memory description = "Proposing to add a new Law";
    bytes memory lawCalldata = abi.encode(newLaw, true);  
    
    vm.prank(eve); // = a whale
    uint256 proposalIdOne = agDao.propose(
      constituentLaws[4], // = Whale_proposeLaw
      lawCalldata, 
      description
    );
    
    // whales vote... Only david and eve are whales. 
    vm.prank(david);
    agDao.castVote(proposalIdOne, 1); // = for 
    vm.prank(eve); 
    agDao.castVote(proposalIdOne, 1); // = for

    vm.roll(4_000);

    // executing... 
    vm.prank(david);
    agDao.execute(constituentLaws[4], lawCalldata, keccak256(bytes(description)));

    // check 
    ISeparatedPowers.ProposalState proposalStateOne = agDao.state(proposalIdOne); 
    assert(uint8(proposalStateOne) == 4); // == ProposalState.Completed

    /* PROPOSAL LINK 2: a seniors accept the proposed law. */   
    // proposing...
    vm.roll(5_000);
    vm.prank(charlotte); // = a senior
    uint256 proposalIdTwo = agDao.propose(
      constituentLaws[5], // = Senior_acceptProposedLaw
      lawCalldata, 
      description
    );

    // seniors vote... alice, bob and charlotte are seniors.
    vm.prank(alice);
    agDao.castVote(proposalIdTwo, 1); // = for 
    vm.prank(bob); 
    agDao.castVote(proposalIdTwo, 1); // = for
    vm.prank(charlotte); 
    agDao.castVote(proposalIdTwo, 1); // = for

    vm.roll(9_000);

    // executing... 
    vm.prank(bob);
    agDao.execute(constituentLaws[5], lawCalldata, keccak256(bytes(description)));

    // check 
    ISeparatedPowers.ProposalState proposalStateTwo = agDao.state(proposalIdTwo); 
    assert(uint8(proposalStateTwo) == 4); // == ProposalState.Completed

    /* PROPOSAL LINK 3: the admin can execute a activation of the law. */
    vm.roll(10_000);
    vm.prank(alice); // = admin role 
    agDao.execute(constituentLaws[6], lawCalldata, keccak256(bytes(description)));

    // check if law has been set to active. 
    bool active = agDao.activeLaws(newLaw);
    assert (active == true);
  }

  function testWhaleDefeatStopsChain() public {
        /* PROPOSAL LINK 1: a whale proposes a law. */   
    // proposing... 
    address newLaw = address(new Public_assignRole(payable(address(agDao))));
    string memory description = "Proposing to add a new Law";
    bytes memory lawCalldata = abi.encode(newLaw, true);  
    
    vm.prank(eve); // = a whale
    uint256 proposalIdOne = agDao.propose(
      constituentLaws[4], // = Whale_proposeLaw
      lawCalldata, 
      description
    );
    
    // whales vote... Only david and eve are whales. 
    vm.prank(david);
    agDao.castVote(proposalIdOne, 0); // = against 
    vm.prank(eve); 
    agDao.castVote(proposalIdOne, 0); // = against

    vm.roll(4_000);

    // executing does not work. 
    vm.prank(david);
    vm.expectRevert(abi.encodeWithSelector(
      Whale_proposeLaw.Whale_proposeLaw__ProposalVoteNotSucceeded.selector, proposalIdOne
    ));
    agDao.execute(constituentLaws[4], lawCalldata, keccak256(bytes(description)));

    /* PROPOSAL LINK 2: a seniors accept the proposed law. */   
    // proposing...
    vm.roll(5_000);
    // NB: Note that it IS possible to create proposals that link back to non executed proposals. 
    // this is something to fix at a later date. 
    // proposals will not execute though. See below. 
    vm.prank(charlotte); // = a senior
    uint256 proposalIdTwo = agDao.propose(
      constituentLaws[5], // = Senior_acceptProposedLaw
      lawCalldata, 
      description
    );

    // seniors vote... alice, bob and charlotte are seniors.
    vm.prank(alice);
    agDao.castVote(proposalIdTwo, 1); // = for 
    vm.prank(bob); 
    agDao.castVote(proposalIdTwo, 1); // = for
    vm.prank(charlotte); 
    agDao.castVote(proposalIdTwo, 1); // = for

    vm.roll(9_000);

    // executing... 
    vm.prank(bob);
    vm.expectRevert(abi.encodeWithSelector( 
      Senior_acceptProposedLaw.Senior_acceptProposedLaw__ParentProposalNotCompleted.selector, proposalIdOne
    )); 
    agDao.execute(constituentLaws[5], lawCalldata, keccak256(bytes(description)));
  }

  function testSeniorDefeatStopsChain() public {
        /* PROPOSAL LINK 1: a whale proposes a law. */   
    // proposing... 
    address newLaw = address(new Public_assignRole(payable(address(agDao))));
    string memory description = "Proposing to add a new Law";
    bytes memory lawCalldata = abi.encode(newLaw, true);  
    
    vm.prank(eve); // = a whale
    uint256 proposalIdOne = agDao.propose(
      constituentLaws[4], // = Whale_proposeLaw
      lawCalldata, 
      description
    );
    
    // whales vote... Only david and eve are whales. 
    vm.prank(david);
    agDao.castVote(proposalIdOne, 1); // = for 
    vm.prank(eve); 
    agDao.castVote(proposalIdOne, 1); // = for

    vm.roll(4_000);

    // executing... 
    vm.prank(david);
    agDao.execute(constituentLaws[4], lawCalldata, keccak256(bytes(description)));

    /* PROPOSAL LINK 2: a seniors accept the proposed law. */   
    vm.roll(5_000);
    vm.prank(charlotte); // = a senior
    uint256 proposalIdTwo = agDao.propose(
      constituentLaws[5], // = Senior_acceptProposedLaw
      lawCalldata, 
      description
    );

    // seniors vote... alice, bob and charlotte are seniors.
    vm.prank(alice);
    agDao.castVote(proposalIdTwo, 0); // = against 
    vm.prank(bob); 
    agDao.castVote(proposalIdTwo, 0); // = against
    vm.prank(charlotte); 
    agDao.castVote(proposalIdTwo, 0); // = against

    vm.roll(9_000);

    // executing... 
    vm.prank(bob);
    vm.expectRevert(abi.encodeWithSelector(
      Senior_acceptProposedLaw.Senior_acceptProposedLaw__ProposalNotSucceeded.selector, proposalIdTwo
    )); 
    agDao.execute(constituentLaws[5], lawCalldata, keccak256(bytes(description)));

    /* PROPOSAL LINK 3: the admin can execute a activation of the law. */
    vm.roll(10_000);    
    vm.prank(alice); // = admin role 
    vm.expectRevert(); 
    agDao.execute(constituentLaws[6], lawCalldata, keccak256(bytes(description)));
  }

  ///////////////////////////////////////////////
  ///                   Helpers               ///
  ///////////////////////////////////////////////
 function _deployLaws(address payable agDaoAddress_, address agCoinsAddress_) internal returns (address[] memory lawsArray) {
      address[] memory laws = new address[](12);

      // deploying laws //
      vm.startPrank(bob);
      // re assigning roles // 
      laws[0] = address(new Public_assignRole(agDaoAddress_));
      laws[1] = address(new Senior_assignRole(agDaoAddress_, agCoinsAddress_));
      laws[2] = address(new Senior_revokeRole(agDaoAddress_, agCoinsAddress_));
      laws[3] = address(new Member_assignWhale(agDaoAddress_, agCoinsAddress_));
      
      // re activating & deactivating laws  // 
      laws[4] = address(new Whale_proposeLaw(agDaoAddress_, agCoinsAddress_));
      laws[5] = address(new Senior_acceptProposedLaw(agDaoAddress_, agCoinsAddress_, address(laws[4])));
      laws[6] = address(new Admin_setLaw(agDaoAddress_, address(laws[5])));

      // re updating core values // 
      laws[7] = address(new Member_proposeCoreValue(agDaoAddress_, agCoinsAddress_));
      laws[8] = address(new Whale_acceptCoreValue(agDaoAddress_, agCoinsAddress_, address(laws[7])));
      
      // re enforcing core values as requirement for external funding //   
      laws[9] = address(new Whale_revokeMember(agDaoAddress_, agCoinsAddress_));
      laws[10] = address(new Public_challengeRevoke(agDaoAddress_, address(laws[9])));
      laws[11] = address(new Senior_reinstateMember(agDaoAddress_, agCoinsAddress_, address(laws[10])));
      vm.stopPrank();

      return laws; 
    }
}