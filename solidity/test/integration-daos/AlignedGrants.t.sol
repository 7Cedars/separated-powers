// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.26;

// import {Test, console, console2} from "lib/forge-std/src/Test.sol";
// import {DeployAgDao} from "../../../script/DeployAgDao.s.sol";
// import {SeparatedPowers} from "../src/SeparatedPowers.sol";
// import {AgDao} from   "../src/implementation/DAOs/AgDao.sol";
// import {AgCoins} from "../src/implementation/DAOs/AgCoins.sol";
// import {Law} from "../src/Law.sol";
// import {IAuthoritiesManager} from "../src/interfaces/IAuthoritiesManager.sol";
// import {ISeparatedPowers} from "../src/interfaces/ISeparatedPowers.sol";
// import "@openzeppelin/contracts/utils/ShortStrings.sol";

// // constitutional laws
// import {Admin_setLaw} from "../src/implementation/DAOs/laws/Admin_setLaw.sol";
// import {Public_assignRole} from "../src/implementation/DAOs/laws/Public_assignRole.sol";
// import {Public_challengeRevoke} from "../src/implementation/DAOs/laws/Public_challengeRevoke.sol";
// import {Member_proposeCoreValue} from "../src/implementation/DAOs/laws/Member_proposeCoreValue.sol";
// import {Senior_acceptProposedLaw} from "../src/implementation/DAOs/laws/Senior_acceptProposedLaw.sol";
// import {Senior_assignRole} from "../src/implementation/DAOs/laws/Senior_assignRole.sol";
// import {Senior_reinstateMember} from "../src/implementation/DAOs/laws/Senior_reinstateMember.sol";
// import {Senior_revokeRole} from "../src/implementation/DAOs/laws/Senior_revokeRole.sol";
// import {Whale_acceptCoreValue} from "../src/implementation/DAOs/laws/Whale_acceptCoreValue.sol";
// import {Member_assignWhale} from "../src/implementation/DAOs/laws/Member_assignWhale.sol";
// import {Whale_proposeLaw} from "../src/implementation/DAOs/laws/Whale_proposeLaw.sol";
// import {Whale_revokeMember} from "../src/implementation/DAOs/laws/Whale_revokeMember.sol";

//   /* chain propsals */
//   function testSuccessfulChainOfProposalsLeadsToSuccessfulExecution() public {
//     /* PROPOSAL LINK 1: a whale proposes a law. */
//     // proposing...
//     address newLaw = address(new Public_assignRole(payable(address(daoMock))));
//     string memory description = "Proposing to add a new Law";
//     bytes memory lawCalldata = abi.encode(newLaw, true);

//     vm.prank(eve); // = a whale
//     uint256 actionIdOne = daoMock.propose(
//       laws[4], // = Whale_proposeLaw
//       lawCalldata,
//       description
//     );

//     // whales vote... Only david and eve are whales.
//     vm.prank(david);
//     daoMock.castVote(actionIdOne, 1); // = for
//     vm.prank(eve);
//     daoMock.castVote(actionIdOne, 1); // = for

//     vm.roll(4_000);

//     // executing...
//     vm.prank(david);
//     daoMock.execute(laws[4], lawCalldata, keccak256(bytes(description)));

//     // check
//     SeparatedPowersTypes.ActionState proposalStateOne = daoMock.state(actionIdOne);
//     assert(uint8(proposalStateOne) == 4); // == ActionState.Completed

//     /* PROPOSAL LINK 2: a seniors accept the proposed law. */
//     // proposing...
//     vm.roll(5_000);
//     vm.prank(charlotte); // = a senior
//     uint256 actionIdTwo = daoMock.propose(
//       laws[5], // = Senior_acceptProposedLaw
//       lawCalldata,
//       description
//     );

//     // seniors vote... alice, bob and charlotte are seniors.
//     vm.prank(alice);
//     daoMock.castVote(actionIdTwo, 1); // = for
//     vm.prank(bob);
//     daoMock.castVote(actionIdTwo, 1); // = for
//     vm.prank(charlotte);
//     daoMock.castVote(actionIdTwo, 1); // = for

//     vm.roll(9_000);

//     // executing...
//     vm.prank(bob);
//     daoMock.execute(laws[5], lawCalldata, keccak256(bytes(description)));

//     // check
//     SeparatedPowersTypes.ActionState proposalStateTwo = daoMock.state(actionIdTwo);
//     assert(uint8(proposalStateTwo) == 4); // == ActionState.Completed

//     /* PROPOSAL LINK 3: the admin can execute a activation of the law. */
//     vm.roll(10_000);
//     vm.prank(alice); // = admin role
//     daoMock.execute(laws[6], lawCalldata, keccak256(bytes(description)));

//     // check if law has been set to active.
//     bool active = daoMock.activeLaws(newLaw);
//     assert (active == true);
//   }

//   function testWhaleDefeatStopsChain() public {
//     /* PROPOSAL LINK 1: a whale proposes a law. */
//     // proposing...
//     address newLaw = address(new Public_assignRole(payable(address(daoMock))));
//     string memory description = "Proposing to add a new Law";
//     bytes memory lawCalldata = abi.encode(newLaw, true);

//     vm.prank(eve); // = a whale
//     uint256 actionIdOne = daoMock.propose(
//       laws[4], // = Whale_proposeLaw
//       lawCalldata,
//       description
//     );

//     // whales vote... Only david and eve are whales.
//     vm.prank(david);
//     daoMock.castVote(actionIdOne, 0); // = against
//     vm.prank(eve);
//     daoMock.castVote(actionIdOne, 0); // = against

//     vm.roll(4_000);

//     // executing does not work.
//     vm.prank(david);
//     vm.expectRevert(abi.encodeWithSelector(
//       Whale_proposeLaw.Whale_proposeLaw__ProposalVoteNotSucceeded.selector, actionIdOne
//     ));
//     daoMock.execute(laws[4], lawCalldata, keccak256(bytes(description)));

//     /* PROPOSAL LINK 2: a seniors accept the proposed law. */
//     // proposing...
//     vm.roll(5_000);
//     // NB: Note that it IS possible to create proposals that link back to non executed proposals.
//     // this is something to fix at a later date.
//     // proposals will not execute though. See below.
//     vm.prank(charlotte); // = a senior
//     uint256 actionIdTwo = daoMock.propose(
//       laws[5], // = Senior_acceptProposedLaw
//       lawCalldata,
//       description
//     );

//     // seniors vote... alice, bob and charlotte are seniors.
//     vm.prank(alice);
//     daoMock.castVote(actionIdTwo, 1); // = for
//     vm.prank(bob);
//     daoMock.castVote(actionIdTwo, 1); // = for
//     vm.prank(charlotte);
//     daoMock.castVote(actionIdTwo, 1); // = for

//     vm.roll(9_000);

//     // executing...
//     vm.prank(bob);
//     vm.expectRevert(abi.encodeWithSelector(
//       Senior_acceptProposedLaw.Senior_acceptProposedLaw__ParentProposalNotCompleted.selector, actionIdOne
//     ));
//     daoMock.execute(laws[5], lawCalldata, keccak256(bytes(description)));
//   }

//   function testSeniorDefeatStopsChain() public {
//         /* PROPOSAL LINK 1: a whale proposes a law. */
//     // proposing...
//     address newLaw = address(new Public_assignRole(payable(address(daoMock))));
//     string memory description = "Proposing to add a new Law";
//     bytes memory lawCalldata = abi.encode(newLaw, true);

//     vm.prank(eve); // = a whale
//     uint256 actionIdOne = daoMock.propose(
//       laws[4], // = Whale_proposeLaw
//       lawCalldata,
//       description
//     );

//     // whales vote... Only david and eve are whales.
//     vm.prank(david);
//     daoMock.castVote(actionIdOne, 1); // = for
//     vm.prank(eve);
//     daoMock.castVote(actionIdOne, 1); // = for

//     vm.roll(4_000);

//     // executing...
//     vm.prank(david);
//     daoMock.execute(laws[4], lawCalldata, keccak256(bytes(description)));

//     /* PROPOSAL LINK 2: a seniors accept the proposed law. */
//     vm.roll(5_000);
//     vm.prank(charlotte); // = a senior
//     uint256 actionIdTwo = daoMock.propose(
//       laws[5], // = Senior_acceptProposedLaw
//       lawCalldata,
//       description
//     );

//     // seniors vote... alice, bob and charlotte are seniors.
//     vm.prank(alice);
//     daoMock.castVote(actionIdTwo, 0); // = against
//     vm.prank(bob);
//     daoMock.castVote(actionIdTwo, 0); // = against
//     vm.prank(charlotte);
//     daoMock.castVote(actionIdTwo, 0); // = against

//     vm.roll(9_000);

//     // executing...
//     vm.prank(bob);
//     vm.expectRevert(abi.encodeWithSelector(
//       Senior_acceptProposedLaw.Senior_acceptProposedLaw__ProposalNotSucceeded.selector, actionIdTwo
//     ));
//     daoMock.execute(laws[5], lawCalldata, keccak256(bytes(description)));

//     /* PROPOSAL LINK 3: the admin can execute a activation of the law. */
//     vm.roll(10_000);
//     vm.prank(alice); // = admin role
//     vm.expectRevert();
//     daoMock.execute(laws[6], lawCalldata, keccak256(bytes(description)));
//   }

// contract AgDaoTest is Test {
//   using ShortStrings for *;

//   /* Type declarations */
//   SeparatedPowers separatedPowers;
//   AgDao agDao;
//   AgCoins agCoins;
//   address[] constituentLaws;

//   /* addresses */
//   address alice = makeAddr("alice");
//   address bob = makeAddr("bob");
//   address charlotte = makeAddr("charlotte");
//   address david = makeAddr("david");
//   address eve = makeAddr("eve");
//   address frank = makeAddr("frank");

//   /* state variables */
//   uint48 public constant ADMIN_ROLE = type(uint48).min; // == 0
//   uint48 public constant PUBLIC_ROLE = type(uint48).max; // == a lot. This role is for everyone.
//   uint48 public constant SENIOR_ROLE = 1;
//   uint48 public constant WHALE_ROLE = 2;
//   uint48 public constant MEMBER_ROLE = 3;
//   bytes32 SALT = bytes32(hex'7ceda5');

//   /* modifiers */

//   ///////////////////////////////////////////////
//   ///                   Setup                 ///
//   ///////////////////////////////////////////////
//   function setUp() public {
//     vm.roll(10);
//     vm.startBroadcast(alice);
//       agDao = new AgDao();
//       agCoins = new AgCoins(address(agDao));
//     vm.stopBroadcast();

//     /* setup roles */
//     IAuthoritiesManager.ConstituentRole[] memory constituentRoles = new IAuthoritiesManager.ConstituentRole[](10);
//     constituentRoles[0] = IAuthoritiesManager.ConstituentRole(alice, MEMBER_ROLE);
//     constituentRoles[1] = IAuthoritiesManager.ConstituentRole(bob, MEMBER_ROLE);
//     constituentRoles[2] = IAuthoritiesManager.ConstituentRole(charlotte, MEMBER_ROLE);
//     constituentRoles[3] = IAuthoritiesManager.ConstituentRole(david, MEMBER_ROLE);
//     constituentRoles[4] = IAuthoritiesManager.ConstituentRole(eve, MEMBER_ROLE);
//     constituentRoles[5] = IAuthoritiesManager.ConstituentRole(alice, SENIOR_ROLE);
//     constituentRoles[6] = IAuthoritiesManager.ConstituentRole(bob, SENIOR_ROLE);
//     constituentRoles[7] = IAuthoritiesManager.ConstituentRole(charlotte, SENIOR_ROLE);
//     constituentRoles[8] = IAuthoritiesManager.ConstituentRole(david, WHALE_ROLE);
//     constituentRoles[9] = IAuthoritiesManager.ConstituentRole(eve, WHALE_ROLE);

//     /* setup laws */
//     constituentLaws = _deployLaws(payable(address(agDao)), address(agCoins));

//     vm.startBroadcast(alice);
//     agDao.constitute(constituentLaws, constituentRoles);
//     vm.stopBroadcast();
//   }

//   ///////////////////////////////////////////////
//   ///                   Tests                 ///
//   ///////////////////////////////////////////////

//   function testRequirementCanBeAdded() public {
//     /* PROPOSAL LINK 1: a whale proposes a law. */
//     // proposing...
//     string memory newValueString = 'accounts need to be human';
//     ShortString newValue = newValueString.toShortString();
//     string memory description = "This is a crucial value to the DAO. It needs to be included among our core values!";
//     bytes memory lawCalldata = abi.encode(newValue);

//     vm.prank(eve); // = a member
//     uint256 proposalIdOne = agDao.propose(
//       constituentLaws[7], // = Member_proposeCoreValue
//       lawCalldata,
//       description
//     );

//     // members vote in support.
//     vm.prank(alice);
//     agDao.castVote(proposalIdOne, 1); // = for
//     vm.prank(bob);
//     agDao.castVote(proposalIdOne, 1); // = for
//     vm.prank(charlotte);
//     agDao.castVote(proposalIdOne, 1); // = for
//     vm.prank(david);
//     agDao.castVote(proposalIdOne, 1); // = for
//     vm.prank(eve);
//     agDao.castVote(proposalIdOne, 1); // = for

//     vm.roll(4_000);

//     // executing...
//     vm.prank(eve);
//     agDao.execute(constituentLaws[7], lawCalldata, keccak256(bytes(description)));

//     // check
//     SeparatedPowersTypes.ActionState proposalStateOne = agDao.state(proposalIdOne);
//     assert(uint8(proposalStateOne) == 4); // == ActionState.Completed

//     /* PROPOSAL LINK 2: a seniors accept the proposed law. */
//     // proposing...
//     vm.roll(5_000);

//     vm.prank(david); // = a whale
//     uint256 proposalIdTwo = agDao.propose(
//       constituentLaws[8], // = Whale_acceptCoreValue
//       lawCalldata,
//       description
//     );

//     // seniors vote... david and eve are whales.
//     vm.prank(david);
//     agDao.castVote(proposalIdTwo, 1); // = for
//     vm.prank(eve);
//     agDao.castVote(proposalIdTwo, 1); // = for

//     vm.roll(9_000);

//     // executing...
//     vm.prank(eve);
//     agDao.execute(constituentLaws[8], lawCalldata, keccak256(bytes(description)));

//     // check
//     SeparatedPowersTypes.ActionState proposalStateTwo = agDao.state(proposalIdTwo);
//     assert(uint8(proposalStateTwo) == 4); // == ActionState.Completed

//     ShortString newRequirement = agDao.coreRequirements(1);
//     string memory requirement = newRequirement.toString();
//     console2.logString(requirement);
//     vm.assertEq(abi.encode(requirement), abi.encode('accounts need to be human'));
//   }

//   function testGetCoreValues() public {
//     string[] memory coreValues = agDao.getCoreValues();
//     assert(coreValues.length == 1);
//     console2.logString(coreValues[0]);
//   }

//   function testRemovedMemberCannotBeReinstituted() public {
//     // proposing...
//     address memberToRevoke = alice;
//     string memory description = "Alice will be member no more in the DAO.";
//     bytes memory lawCalldata = abi.encode(memberToRevoke);

//     vm.prank(eve); // = a whale
//     uint256 proposalIdOne = agDao.propose(
//       constituentLaws[9], // = Whale_revokeMember
//       lawCalldata,
//       description
//     );

//     // whales vote... Only david and eve are whales.
//     vm.prank(david);
//     agDao.castVote(proposalIdOne, 1); // = for
//     vm.prank(eve);
//     agDao.castVote(proposalIdOne, 1); // = for

//     vm.roll(4_000);

//     // executing...
//     vm.prank(david);
//     agDao.execute(constituentLaws[9], lawCalldata, keccak256(bytes(description)));

//     // check
//     SeparatedPowersTypes.ActionState proposalStateOne = agDao.state(proposalIdOne);
//     assert(uint8(proposalStateOne) == 4); // == ActionState.Completed
//     assert (agDao.blacklistedAccounts(alice) == true);

//     // Alice tries to reinstate themselves as member.
//     vm.prank(alice);
//     vm.expectRevert(Public_assignRole.Public_assignRole__AccountBlacklisted.selector);
//     agDao.execute(constituentLaws[0], lawCalldata, keccak256(bytes("I request membership to agDAO.")));
//   }

//   function testWhenReinstatedAccountNoLongerBlackListed() public {
//     // PROPOSAL LINK 1: revoking member
//     // proposing...
//     address memberToRevoke = alice;
//     string memory description = "Alice will be member no more in the DAO.";
//     bytes memory lawCalldata = abi.encode(memberToRevoke);

//     vm.prank(eve); // = a whale
//     uint256 proposalIdOne = agDao.propose(
//       constituentLaws[9], // = Whale_revokeMember
//       lawCalldata,
//       description
//     );

//     // whales vote... Only david and eve are whales.
//     vm.prank(david);
//     agDao.castVote(proposalIdOne, 1); // = for
//     vm.prank(eve);
//     agDao.castVote(proposalIdOne, 1); // = for

//     vm.roll(4_000);

//     // executing...
//     vm.prank(david);
//     agDao.execute(constituentLaws[9], lawCalldata, keccak256(bytes(description)));

//     // check if alice has indeed been blacklisted.
//     SeparatedPowersTypes.ActionState proposalStateOne = agDao.state(proposalIdOne);
//     assert(uint8(proposalStateOne) == 4); // == ActionState.Completed
//     assert (agDao.blacklistedAccounts(alice) == true);

//     vm.roll(5_000);
//     // PROPOSAL LINK 2: challenge revoke decision
//     // proposing...
//     string memory descriptionChallenge = "I challenge the revoking of my membership to agDAO.";
//     bytes memory lawCalldataChallenge = abi.encode(keccak256(bytes(description)), lawCalldata);

//     vm.prank(alice); // = a whale
//     uint256 proposalIdTwo = agDao.propose(
//       constituentLaws[10], // = Public_challengeRevoke
//       lawCalldataChallenge,
//       descriptionChallenge
//     );

//     vm.roll(9_000); // No vote needed, but does need pass time for vote to be executed.

//     vm.prank(alice);
//     agDao.execute(constituentLaws[10], lawCalldataChallenge, keccak256(bytes(descriptionChallenge)));

//     // check
//     SeparatedPowersTypes.ActionState proposalStateTwo = agDao.state(proposalIdTwo);
//     assert(uint8(proposalStateTwo) == 4); // == ActionState.Completed

//     vm.roll(10_000);
//     // PROPOSAL LINK 3: challenge is accepted by Seniors, member is reinstated.
//     vm.prank(bob); // = a senior
//     uint256 proposalIdThree = agDao.propose(
//       constituentLaws[11], // = Senior_reinstateMember
//       lawCalldataChallenge,
//       descriptionChallenge
//     );

//     // whales vote... all vote in favour (incl alice ;)
//     vm.prank(alice);
//     agDao.castVote(proposalIdThree, 1); // = for
//     vm.prank(bob);
//     agDao.castVote(proposalIdThree, 1); // = for
//     vm.prank(charlotte);
//     agDao.castVote(proposalIdThree, 1); // = for

//     vm.roll(14_000);

//     // executing...
//     vm.prank(bob);
//     agDao.execute(constituentLaws[11], lawCalldataChallenge, keccak256(bytes(descriptionChallenge)));

//     // check
//     SeparatedPowersTypes.ActionState proposalStateThree = agDao.state(proposalIdThree);
//     assert(uint8(proposalStateThree) == 4); // == ActionState.Completed

//     // check if alice has indeed been reinstated.
//     agDao.hasRoleSince(alice, MEMBER_ROLE);
//   }

//   ///////////////////////////////////////////////
//   ///                   Helpers               ///
//   ///////////////////////////////////////////////
//   function _deployLaws(address payable agDaoAddress_, address agCoinsAddress_) internal returns (address[] memory lawsArray) {
//       address[] memory laws = new address[](12);

//       // deploying laws //
//       vm.startPrank(bob);
//       // re assigning roles //
//       laws[0] = address(new Public_assignRole(agDaoAddress_));
//       laws[1] = address(new Senior_assignRole(agDaoAddress_, agCoinsAddress_));
//       laws[2] = address(new Senior_revokeRole(agDaoAddress_, agCoinsAddress_));
//       laws[3] = address(new Member_assignWhale(agDaoAddress_, agCoinsAddress_));

//       // re activating & deactivating laws  //
//       laws[4] = address(new Whale_proposeLaw(agDaoAddress_, agCoinsAddress_));
//       laws[5] = address(new Senior_acceptProposedLaw(agDaoAddress_, agCoinsAddress_, address(laws[4])));
//       laws[6] = address(new Admin_setLaw(agDaoAddress_, address(laws[5])));

//       // re updating core values //
//       laws[7] = address(new Member_proposeCoreValue(agDaoAddress_, agCoinsAddress_));
//       laws[8] = address(new Whale_acceptCoreValue(agDaoAddress_, agCoinsAddress_, address(laws[7])));

//       // re enforcing core values as requirement for external funding //
//       laws[9] = address(new Whale_revokeMember(agDaoAddress_, agCoinsAddress_));
//       laws[10] = address(new Public_challengeRevoke(agDaoAddress_, address(laws[9])));
//       laws[11] = address(new Senior_reinstateMember(agDaoAddress_, agCoinsAddress_, address(laws[10])));
//       vm.stopPrank();

//       return laws;
//     }
// }
