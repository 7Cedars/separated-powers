// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.26;

import { Test, console, console2 } from "lib/forge-std/src/Test.sol";
import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";
import { ERC20Votes } from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol";

import { SeparatedPowers } from "../../../src/SeparatedPowers.sol";
import { Law } from "../../../src/Law.sol";
import { ILaw } from "../../../src/interfaces/ILaw.sol";

import { Erc1155Mock } from "../../../test/mocks/Erc1155Mock.sol";
import { Erc20VotesMock } from "../../../test/mocks/Erc20VotesMock.sol";

import { TestSetupBasicDao_fuzzIntegration } from "../../../test/TestSetup.t.sol";
import { HelperConfig } from "../../../script/HelperConfig.s.sol";

/////////////////////////////////////////////////////
//                      Setup                      //
/////////////////////////////////////////////////////
contract BasicDao_fuzzIntegrationTest is TestSetupBasicDao_fuzzIntegration {
    //////////////////////////////////////////////////////////////
    //              CHAPTER 1: EXECUTIVE ACTIONS                //
    //////////////////////////////////////////////////////////////
    function testFuzz_ProposeAndExecuteAnAction(
        uint256 proposePassChance,
        uint256 vetoCastChance,
        uint256 executePassChance
    ) public {
        uint256 proposePassChance = bound(proposePassChance, 0, 100);
        uint256 vetoCastChance = bound(vetoCastChance, 0, 100);
        uint256 executePassChance = bound(executePassChance, 0, 100);
        uint256 balanceBefore = erc20VotesMock.balanceOf(address(basicDao));

        bool[] memory stepsPassed = new bool[](3);

        // assigning necessary roles.
        vm.startPrank(address(basicDao));
        basicDao.assignRole(0, alice); // ADMIN ROLE
        basicDao.assignRole(1, bob); // role 1s
        basicDao.assignRole(1, charlotte);
        basicDao.assignRole(1, david);
        basicDao.assignRole(1, eve);
        basicDao.assignRole(1, frank);
        basicDao.assignRole(2, gary); // role 2s
        basicDao.assignRole(2, helen);
        vm.stopPrank();

        // step 0 action: propose action and run election.
        targets = new address[](1);
        values = new uint256[](1);
        calldatas = new bytes[](1);
        targets[0] = address(erc20VotesMock);
        values[0] = 0;
        calldatas[0] = abi.encodeWithSelector(Erc20VotesMock.mintVotes.selector, 5000);

        lawCalldata = abi.encode(targets, values, calldatas); // = revoke = false
        description = "Propose minting 5000 coins to alice's account";
        vm.prank(gary); // has role 2.
        proposalId = basicDao.propose(laws[0], lawCalldata, description);

        (roleCount, againstVote, forVote, abstainVote) = voteOnProposal(
            payable(address(basicDao)),
            laws[0],
            proposalId,
            config.testAccounts,
            (proposePassChance + vetoCastChance) / 2,
            proposePassChance,
            vetoCastChance
        );

        // step 0 results.
        (quorum, succeedAt, votingPeriod,,,,) = Law(laws[0]).config();
        quorumReached = (forVote + abstainVote) * 100 / roleCount > quorum;
        voteSucceeded = forVote * 100 / roleCount > succeedAt;
        stepsPassed[0] = quorumReached && voteSucceeded;
        vm.roll(block.number + votingPeriod + 1);
        if (stepsPassed[0]) {
          vm.prank(gary);
          basicDao.execute(laws[0], lawCalldata, description);
        }

        // step 1 action: cast veto?.
        if (vetoCastChance > 50) {
            console.log("step 2 action: alice casts a veto!");
            vm.prank(alice); // has admin role.
            basicDao.execute(laws[1], lawCalldata, description);

            // step 1 results.
            descriptionHash = keccak256(bytes(description));
            proposalId = hashProposal(laws[1], lawCalldata, descriptionHash);
            uint8 vetoState = uint8(basicDao.state(proposalId));
            stepsPassed[1] = vetoState != uint8(ProposalState.Completed);
            console.log("step 2 result: proposal vetoState: ", vetoState);
        } else {
            console.log("step 2 action: alice does not cast a veto!");
            stepsPassed[1] = true;
        }

        // step 2 action: propose and vote on action.
        vm.prank(bob); // has role 1.
        proposalId = basicDao.propose(laws[2], lawCalldata, description);

        (roleCount, againstVote, forVote, abstainVote) = voteOnProposal(
            payable(address(basicDao)),
            laws[2],
            proposalId,
            config.testAccounts,
            (proposePassChance + vetoCastChance) / 2,
            proposePassChance,
            vetoCastChance
        );

        // step 2 results.
        (quorum, succeedAt, votingPeriod, , , delayExecution,) = Law(laws[2]).config();
        quorumReached = (forVote + abstainVote) * 100 / roleCount > quorum;
        voteSucceeded = forVote * 100 / roleCount > succeedAt;
        stepsPassed[2] = quorumReached && voteSucceeded;
        vm.roll(block.number + votingPeriod + delayExecution + 1);
        console.log("step 3 result: quorum reached and vote succeeded?");
        console.log(quorumReached, voteSucceeded);

        // step 3: conditional execute of proposal
        if (stepsPassed[0] && stepsPassed[1] && stepsPassed[2]) {
            console.log("step 4 action: ACTION WILL BE EXECUTED");
            vm.prank(bob); // has role 1
            basicDao.execute(laws[2], lawCalldata, description);
            uint256 balanceAfter = erc20VotesMock.balanceOf(address(basicDao));
            assertEq(balanceBefore + 5000, balanceAfter);
        } else {
            vm.expectRevert();
            vm.prank(bob);
            basicDao.execute(laws[2], lawCalldata, description);
        }
    }

    //////////////////////////////////////////////////////////////
    //              CHAPTER 2: ELECT ROLES                      //
    //////////////////////////////////////////////////////////////

    function testFuzz_DelegateElect(uint256 numNominees, uint256 voteTokensRandomiser) public {
        numNominees = bound(numNominees, 4, 10);
        voteTokensRandomiser = bound(voteTokensRandomiser, 100_000, type(uint256).max);

        address nominateMeLaw = laws[4];
        address delegateSelectLaw = laws[5];

        // step 0: distribute tokens. Tokens are distributed randomly.
        distributeTokens(config.erc20VotesMock, config.testAccounts, voteTokensRandomiser);

        // step 1: people nominate their accounts.
        bytes memory lawCalldataNominate = abi.encode(true); // nominateMe = true

        for (uint256 i = 0; i < numNominees; i++) {
            vm.prank(config.testAccounts[i]);
            basicDao.execute(
                nominateMeLaw, lawCalldataNominate, string.concat("Account nominates themselves: ", Strings.toString(i))
            );
        }
        // step 2: run election.
        bytes memory lawCalldataElect = abi.encode(); // empty calldata
        address executioner = config.testAccounts[voteTokensRandomiser % config.testAccounts.length];
        vm.prank(executioner);
        basicDao.execute(delegateSelectLaw, lawCalldataElect, "Account executes an election.");

        // step 3: assert that the elected accounts are correct.
        for (uint256 i = 0; i < numNominees; i++) {
            for (uint256 j = 0; j < numNominees; j++) {
                address nominee = config.testAccounts[i];
                address nominee2 = config.testAccounts[j];
                if (basicDao.hasRoleSince(nominee, 2) != 0 && basicDao.hasRoleSince(nominee2, 2) == 0) {
                    uint256 balanceNominee = Erc20VotesMock(config.erc20VotesMock).balanceOf(nominee);
                    uint256 balanceNominee2 = Erc20VotesMock(config.erc20VotesMock).balanceOf(nominee2);
                    assertGe(balanceNominee, balanceNominee2); // assert that nominee has more tokens than nominee2.
                }
                if (basicDao.hasRoleSince(nominee, 2) == 0 && basicDao.hasRoleSince(nominee2, 2) != 0) {
                    uint256 balanceNominee = Erc20VotesMock(config.erc20VotesMock).balanceOf(nominee);
                    uint256 balanceNominee2 = Erc20VotesMock(config.erc20VotesMock).balanceOf(nominee2);
                    assertLe(balanceNominee, balanceNominee2); // assert that nominee has fewer tokens than nominee2.
                }
            }
        }
    }

    function testFuzz_PeerSelect(
        uint256 numNominees,
        uint256 indexRandomiser,
        uint256 quorumPassChance,
        uint256 succeedPassChance
    ) public {
        quorumPassChance = bound(quorumPassChance, 0, 100);
        succeedPassChance = bound(succeedPassChance, 0, 100);
        // indexRandomiser = bound(indexRandomiser, 0, numNominees - 1);

        // assigning necessary roles.
        vm.startPrank(address(basicDao));
        basicDao.assignRole(1, alice);
        basicDao.assignRole(1, bob);
        basicDao.assignRole(1, charlotte);
        basicDao.assignRole(1, david);
        vm.stopPrank();

        // step 1: people nominate their accounts.
        uint256 numNominees;
        for (uint256 i = 0; i < config.testAccounts.length; i++) {
            if (basicDao.hasRoleSince(config.testAccounts[i], 1) == 0) {
                vm.prank(config.testAccounts[i]);
                basicDao.execute(
                    laws[6], abi.encode(true), string.concat("Account nominates themself", Strings.toString(i))
                );
            }
            numNominees++;
        }

        // step 2: propose action and run election.
        bytes memory lawCalldataSelect = abi.encode(0, false); // = revoke = false
        string memory descriptionSelect = "Elect an account to role 1.";
        vm.prank(alice); // already has role 1.
        uint256 proposalId = basicDao.propose(laws[7], lawCalldataSelect, descriptionSelect);

        (uint256 roleCount, uint256 againstVote, uint256 forVote, uint256 abstainVote) = voteOnProposal(
            payable(address(basicDao)), laws[7], proposalId, config.testAccounts, 0, quorumPassChance, succeedPassChance
        );

        // step 3:  assert that the elected accounts are correct.
        (uint8 quorum, uint8 succeedAt, uint32 votingPeriod,,,,) = Law(laws[7]).config();
        bool quorumReached = (forVote + abstainVote) * 100 / roleCount > quorum;
        bool succeeded = forVote * 100 / roleCount > succeedAt;

        vm.roll(block.number + votingPeriod + 1);
        console.log(uint8(basicDao.state(proposalId)));
        if (quorumReached && succeeded) {
            vm.prank(alice);
            basicDao.execute(laws[7], lawCalldataSelect, descriptionSelect);
            assertNotEq(basicDao.hasRoleSince(config.testAccounts[0], 1), 0);
        } else {
            vm.expectRevert();
            vm.prank(alice);
            basicDao.execute(laws[7], lawCalldataSelect, descriptionSelect);
        }
    }
}

// /////////////////////////////////////////////////////
// //                      Tests                      //
// /////////////////////////////////////////////////////

// // Note: tests are subdivided by governance chains: linked laws that govern a certain functionality of the DAO.
// // single laws that have already had unit tests are skipped as much as possible. These are all integration tests.
// contract TokenNominationTest is TestSetupAlignedGrants { }

// contract SetCoreValueTest is TestSetupAlignedGrants { }

// contract RevokeAndReinstateMemberTest is TestSetupAlignedGrants { }

// contract SetLawTest is TestSetupAlignedGrants { }

// //   /* chain propsals */
// //   function testSuccessfulChainOfProposalsLeadsToSuccessfulExecution() public {
// //     /* PROPOSAL LINK 1: a whale proposes a law. */
// //     // proposing...
// //     address newLaw = address(new Public_assignRole(payable(address(daoMock))));
// //     string memory description = "Proposing to add a new Law";
// //     bytes memory lawCalldata = abi.encode(newLaw, true);

// //     vm.prank(eve); // = a whale
// //     uint256 actionIdOne = daoMock.propose(
// //       laws[4], // = Whale_proposeLaw
// //       lawCalldata,
// //       description
// //     );

// //     // whales vote... Only david and eve are whales.
// //     vm.prank(david);
// //     daoMock.castVote(actionIdOne, 1); // = for
// //     vm.prank(eve);
// //     daoMock.castVote(actionIdOne, 1); // = for

// //     vm.roll(block.number + 4_000);

// //     // executing...
// //     vm.prank(david);
// //     daoMock.execute(laws[4], lawCalldata, keccak256(bytes(description)));

// //     // check
// //     SeparatedPowersTypes.ProposalState proposalStateOne = daoMock.state(actionIdOne);
// //     assert(uint8(proposalStateOne) == 4); // == ProposalState.Completed

// //     /* PROPOSAL LINK 2: a seniors accept the proposed law. */
// //     // proposing...
// //     vm.roll(block.number + 5_000);
// //     vm.prank(charlotte); // = a senior
// //     uint256 actionIdTwo = daoMock.propose(
// //       laws[5], // = Senior_acceptProposedLaw
// //       lawCalldata,
// //       description
// //     );

// //     // seniors vote... alice, bob and charlotte are seniors.
// //     vm.prank(alice);
// //     daoMock.castVote(actionIdTwo, 1); // = for
// //     vm.prank(bob);
// //     daoMock.castVote(actionIdTwo, 1); // = for
// //     vm.prank(charlotte);
// //     daoMock.castVote(actionIdTwo, 1); // = for

// //     vm.roll(block.number + 9_000);

// //     // executing...
// //     vm.prank(bob);
// //     daoMock.execute(laws[5], lawCalldata, keccak256(bytes(description)));

// //     // check
// //     SeparatedPowersTypes.ProposalState proposalStateTwo = daoMock.state(actionIdTwo);
// //     assert(uint8(proposalStateTwo) == 4); // == ProposalState.Completed

// //     /* PROPOSAL LINK 3: the admin can execute a activation of the law. */
// //     vm.roll(block.number + 10_000);
// //     vm.prank(alice); // = admin role
// //     daoMock.execute(laws[6], lawCalldata, keccak256(bytes(description)));

// //     // check if law has been set to active.
// //     bool active = daoMock.activeLaws(newLaw);
// //     assert (active == true);
// //   }

// //   function testWhaleDefeatStopsChain() public {
// //     /* PROPOSAL LINK 1: a whale proposes a law. */
// //     // proposing...
// //     address newLaw = address(new Public_assignRole(payable(address(daoMock))));
// //     string memory description = "Proposing to add a new Law";
// //     bytes memory lawCalldata = abi.encode(newLaw, true);

// //     vm.prank(eve); // = a whale
// //     uint256 actionIdOne = daoMock.propose(
// //       laws[4], // = Whale_proposeLaw
// //       lawCalldata,
// //       description
// //     );

// //     // whales vote... Only david and eve are whales.
// //     vm.prank(david);
// //     daoMock.castVote(actionIdOne, 0); // = against
// //     vm.prank(eve);
// //     daoMock.castVote(actionIdOne, 0); // = against

// //     vm.roll(block.number + 4_000);

// //     // executing does not work.
// //     vm.prank(david);
// //     vm.expectRevert(abi.encodeWithSelector(
// //       Whale_proposeLaw.Whale_proposeLaw__ProposalVoteNotSucceeded.selector, actionIdOne
// //     ));
// //     daoMock.execute(laws[4], lawCalldata, keccak256(bytes(description)));

// //     /* PROPOSAL LINK 2: a seniors accept the proposed law. */
// //     // proposing...
// //     vm.roll(block.number + 5_000);
// //     // NB: Note that it IS possible to create proposals that link back to non executed proposals.
// //     // this is something to fix at a later date.
// //     // proposals will not execute though. See below.
// //     vm.prank(charlotte); // = a senior
// //     uint256 actionIdTwo = daoMock.propose(
// //       laws[5], // = Senior_acceptProposedLaw
// //       lawCalldata,
// //       description
// //     );

// //     // seniors vote... alice, bob and charlotte are seniors.
// //     vm.prank(alice);
// //     daoMock.castVote(actionIdTwo, 1); // = for
// //     vm.prank(bob);
// //     daoMock.castVote(actionIdTwo, 1); // = for
// //     vm.prank(charlotte);
// //     daoMock.castVote(actionIdTwo, 1); // = for

// //     vm.roll(block.number + 9_000);

// //     // executing...
// //     vm.prank(bob);
// //     vm.expectRevert(abi.encodeWithSelector(
// //       Senior_acceptProposedLaw.Senior_acceptProposedLaw__ParentProposalNotCompleted.selector, actionIdOne
// //     ));
// //     daoMock.execute(laws[5], lawCalldata, keccak256(bytes(description)));
// //   }

// //   function testSeniorDefeatStopsChain() public {
// //         /* PROPOSAL LINK 1: a whale proposes a law. */
// //     // proposing...
// //     address newLaw = address(new Public_assignRole(payable(address(daoMock))));
// //     string memory description = "Proposing to add a new Law";
// //     bytes memory lawCalldata = abi.encode(newLaw, true);

// //     vm.prank(eve); // = a whale
// //     uint256 actionIdOne = daoMock.propose(
// //       laws[4], // = Whale_proposeLaw
// //       lawCalldata,
// //       description
// //     );

// //     // whales vote... Only david and eve are whales.
// //     vm.prank(david);
// //     daoMock.castVote(actionIdOne, 1); // = for
// //     vm.prank(eve);
// //     daoMock.castVote(actionIdOne, 1); // = for

// //     vm.roll(block.number + 4_000);

// //     // executing...
// //     vm.prank(david);
// //     daoMock.execute(laws[4], lawCalldata, keccak256(bytes(description)));

// //     /* PROPOSAL LINK 2: a seniors accept the proposed law. */
// //     vm.roll(block.number + 5_000);
// //     vm.prank(charlotte); // = a senior
// //     uint256 actionIdTwo = daoMock.propose(
// //       laws[5], // = Senior_acceptProposedLaw
// //       lawCalldata,
// //       description
// //     );

// //     // seniors vote... alice, bob and charlotte are seniors.
// //     vm.prank(alice);
// //     daoMock.castVote(actionIdTwo, 0); // = against
// //     vm.prank(bob);
// //     daoMock.castVote(actionIdTwo, 0); // = against
// //     vm.prank(charlotte);
// //     daoMock.castVote(actionIdTwo, 0); // = against

// //     vm.roll(block.number + 9_000);

// //     // executing...
// //     vm.prank(bob);
// //     vm.expectRevert(abi.encodeWithSelector(
// //       Senior_acceptProposedLaw.Senior_acceptProposedLaw__ProposalNotSucceeded.selector, actionIdTwo
// //     ));
// //     daoMock.execute(laws[5], lawCalldata, keccak256(bytes(description)));

// //     /* PROPOSAL LINK 3: the admin can execute a activation of the law. */
// //     vm.roll(block.number + 10_000);
// //     vm.prank(alice); // = admin role
// //     vm.expectRevert();
// //     daoMock.execute(laws[6], lawCalldata, keccak256(bytes(description)));
// //   }

// // contract AgDaoTest is Test {
// //   using ShortStrings for *;

// //   /* Type declarations */
// //   SeparatedPowers separatedPowers;
// //   AgDao agDao;
// //   AgCoins agCoins;
// //   address[] constituentLaws;

// //   /* addresses */
// //   address alice = makeAddr("alice");
// //   address bob = makeAddr("bob");
// //   address charlotte = makeAddr("charlotte");
// //   address david = makeAddr("david");
// //   address eve = makeAddr("eve");
// //   address frank = makeAddr("frank");

// //   /* state variables */
// //   uint48 public constant ADMIN_ROLE = type(uint48).min; // == 0
// //   uint48 public constant PUBLIC_ROLE = type(uint48).max; // == a lot. This role is for everyone.
// //   uint48 public constant SENIOR_ROLE = 1;
// //   uint48 public constant WHALE_ROLE = 2;
// //   uint48 public constant MEMBER_ROLE = 3;
// //   bytes32 SALT = bytes32(hex'7ceda5');

// //   /* modifiers */

// //   ///////////////////////////////////////////////
// //   ///                   Setup                 ///
// //   ///////////////////////////////////////////////
// //   function setUp() public {
// //     vm.roll(block.number + 10);
// //     vm.startBroadcast(alice);
// //       agDao = new AgDao();
// //       agCoins = new AgCoins(address(agDao));
// //     vm.stopBroadcast();

// //     /* setup roles */
// //     IAuthoritiesManager.ConstituentRole[] memory constituentRoles = new IAuthoritiesManager.ConstituentRole[](10);
// //     constituentRoles[0] = IAuthoritiesManager.ConstituentRole(alice, MEMBER_ROLE);
// //     constituentRoles[1] = IAuthoritiesManager.ConstituentRole(bob, MEMBER_ROLE);
// //     constituentRoles[2] = IAuthoritiesManager.ConstituentRole(charlotte, MEMBER_ROLE);
// //     constituentRoles[3] = IAuthoritiesManager.ConstituentRole(david, MEMBER_ROLE);
// //     constituentRoles[4] = IAuthoritiesManager.ConstituentRole(eve, MEMBER_ROLE);
// //     constituentRoles[5] = IAuthoritiesManager.ConstituentRole(alice, SENIOR_ROLE);
// //     constituentRoles[6] = IAuthoritiesManager.ConstituentRole(bob, SENIOR_ROLE);
// //     constituentRoles[7] = IAuthoritiesManager.ConstituentRole(charlotte, SENIOR_ROLE);
// //     constituentRoles[8] = IAuthoritiesManager.ConstituentRole(david, WHALE_ROLE);
// //     constituentRoles[9] = IAuthoritiesManager.ConstituentRole(eve, WHALE_ROLE);

// //     /* setup laws */
// //     constituentLaws = _deployLaws(payable(address(agDao)), address(agCoins));

// //     vm.startBroadcast(alice);
// //     agDao.constitute(constituentLaws, constituentRoles);
// //     vm.stopBroadcast();
// //   }

// //   ///////////////////////////////////////////////
// //   ///                   Tests                 ///
// //   ///////////////////////////////////////////////

// //   function testRequirementCanBeAdded() public {
// //     /* PROPOSAL LINK 1: a whale proposes a law. */
// //     // proposing...
// //     string memory newValueString = 'accounts need to be human';
// //     ShortString newValue = newValueString.toShortString();
// //     string memory description = "This is a crucial value to the DAO. It needs to be included among our core values!";
// //     bytes memory lawCalldata = abi.encode(newValue);

// //     vm.prank(eve); // = a member
// //     uint256 proposalIdOne = agDao.propose(
// //       constituentLaws[7], // = Member_proposeCoreValue
// //       lawCalldata,
// //       description
// //     );

// //     // members vote in support.
// //     vm.prank(alice);
// //     agDao.castVote(proposalIdOne, 1); // = for
// //     vm.prank(bob);
// //     agDao.castVote(proposalIdOne, 1); // = for
// //     vm.prank(charlotte);
// //     agDao.castVote(proposalIdOne, 1); // = for
// //     vm.prank(david);
// //     agDao.castVote(proposalIdOne, 1); // = for
// //     vm.prank(eve);
// //     agDao.castVote(proposalIdOne, 1); // = for

// //     vm.roll(block.number + 4_000);

// //     // executing...
// //     vm.prank(eve);
// //     agDao.execute(constituentLaws[7], lawCalldata, keccak256(bytes(description)));

// //     // check
// //     SeparatedPowersTypes.ProposalState proposalStateOne = agDao.state(proposalIdOne);
// //     assert(uint8(proposalStateOne) == 4); // == ProposalState.Completed

// //     /* PROPOSAL LINK 2: a seniors accept the proposed law. */
// //     // proposing...
// //     vm.roll(block.number + 5_000);

// //     vm.prank(david); // = a whale
// //     uint256 proposalIdTwo = agDao.propose(
// //       constituentLaws[8], // = Whale_acceptCoreValue
// //       lawCalldata,
// //       description
// //     );

// //     // seniors vote... david and eve are whales.
// //     vm.prank(david);
// //     agDao.castVote(proposalIdTwo, 1); // = for
// //     vm.prank(eve);
// //     agDao.castVote(proposalIdTwo, 1); // = for

// //     vm.roll(block.number + 9_000);

// //     // executing...
// //     vm.prank(eve);
// //     agDao.execute(constituentLaws[8], lawCalldata, keccak256(bytes(description)));

// //     // check
// //     SeparatedPowersTypes.ProposalState proposalStateTwo = agDao.state(proposalIdTwo);
// //     assert(uint8(proposalStateTwo) == 4); // == ProposalState.Completed

// //     ShortString newRequirement = agDao.coreRequirements(1);
// //     string memory requirement = newRequirement.toString();
// //     console2.logString(requirement);
// //     vm.assertEq(abi.encode(requirement), abi.encode('accounts need to be human'));
// //   }

// //   function testGetCoreValues() public {
// //     string[] memory coreValues = agDao.getCoreValues();
// //     assert(coreValues.length == 1);
// //     console2.logString(coreValues[0]);
// //   }

// //   function testRemovedMemberCannotBeReinstituted() public {
// //     // proposing...
// //     address memberToRevoke = alice;
// //     string memory description = "Alice will be member no more in the DAO.";
// //     bytes memory lawCalldata = abi.encode(memberToRevoke);

// //     vm.prank(eve); // = a whale
// //     uint256 proposalIdOne = agDao.propose(
// //       constituentLaws[9], // = Whale_revokeMember
// //       lawCalldata,
// //       description
// //     );

// //     // whales vote... Only david and eve are whales.
// //     vm.prank(david);
// //     agDao.castVote(proposalIdOne, 1); // = for
// //     vm.prank(eve);
// //     agDao.castVote(proposalIdOne, 1); // = for

// //     vm.roll(block.number + 4_000);

// //     // executing...
// //     vm.prank(david);
// //     agDao.execute(constituentLaws[9], lawCalldata, keccak256(bytes(description)));

// //     // check
// //     SeparatedPowersTypes.ProposalState proposalStateOne = agDao.state(proposalIdOne);
// //     assert(uint8(proposalStateOne) == 4); // == ProposalState.Completed
// //     assert (agDao.blacklistedAccounts(alice) == true);

// //     // Alice tries to reinstate themselves as member.
// //     vm.prank(alice);
// //     vm.expectRevert(Public_assignRole.Public_assignRole__AccountBlacklisted.selector);
// //     agDao.execute(constituentLaws[0], lawCalldata, keccak256(bytes("I request membership to agDAO.")));
// //   }

// //   function testWhenReinstatedAccountNoLongerBlackListed() public {
// //     // PROPOSAL LINK 1: revoking member
// //     // proposing...
// //     address memberToRevoke = alice;
// //     string memory description = "Alice will be member no more in the DAO.";
// //     bytes memory lawCalldata = abi.encode(memberToRevoke);

// //     vm.prank(eve); // = a whale
// //     uint256 proposalIdOne = agDao.propose(
// //       constituentLaws[9], // = Whale_revokeMember
// //       lawCalldata,
// //       description
// //     );

// //     // whales vote... Only david and eve are whales.
// //     vm.prank(david);
// //     agDao.castVote(proposalIdOne, 1); // = for
// //     vm.prank(eve);
// //     agDao.castVote(proposalIdOne, 1); // = for

// //     vm.roll(block.number + 4_000);

// //     // executing...
// //     vm.prank(david);
// //     agDao.execute(constituentLaws[9], lawCalldata, keccak256(bytes(description)));

// //     // check if alice has indeed been blacklisted.
// //     SeparatedPowersTypes.ProposalState proposalStateOne = agDao.state(proposalIdOne);
// //     assert(uint8(proposalStateOne) == 4); // == ProposalState.Completed
// //     assert (agDao.blacklistedAccounts(alice) == true);

// //     vm.roll(block.number + 5_000);
// //     // PROPOSAL LINK 2: challenge revoke decision
// //     // proposing...
// //     string memory descriptionChallenge = "I challenge the revoking of my membership to agDAO.";
// //     bytes memory lawCalldataChallenge = abi.encode(keccak256(bytes(description)), lawCalldata);

// //     vm.prank(alice); // = a whale
// //     uint256 proposalIdTwo = agDao.propose(
// //       constituentLaws[10], // = Public_challengeRevoke
// //       lawCalldataChallenge,
// //       descriptionChallenge
// //     );

// //     vm.roll(block.number + 9_000); // No vote needed, but does need pass time for vote to be executed.

// //     vm.prank(alice);
// //     agDao.execute(constituentLaws[10], lawCalldataChallenge, keccak256(bytes(descriptionChallenge)));

// //     // check
// //     SeparatedPowersTypes.ProposalState proposalStateTwo = agDao.state(proposalIdTwo);
// //     assert(uint8(proposalStateTwo) == 4); // == ProposalState.Completed

// //     vm.roll(block.number + 10_000);
// //     // PROPOSAL LINK 3: challenge is accepted by Seniors, member is reinstated.
// //     vm.prank(bob); // = a senior
// //     uint256 proposalIdThree = agDao.propose(
// //       constituentLaws[11], // = Senior_reinstateMember
// //       lawCalldataChallenge,
// //       descriptionChallenge
// //     );

// //     // whales vote... all vote in favour (incl alice ;)
// //     vm.prank(alice);
// //     agDao.castVote(proposalIdThree, 1); // = for
// //     vm.prank(bob);
// //     agDao.castVote(proposalIdThree, 1); // = for
// //     vm.prank(charlotte);
// //     agDao.castVote(proposalIdThree, 1); // = for

// //     vm.roll(block.number + 14_000);

// //     // executing...
// //     vm.prank(bob);
// //     agDao.execute(constituentLaws[11], lawCalldataChallenge, keccak256(bytes(descriptionChallenge)));

// //     // check
// //     SeparatedPowersTypes.ProposalState proposalStateThree = agDao.state(proposalIdThree);
// //     assert(uint8(proposalStateThree) == 4); // == ProposalState.Completed

// //     // check if alice has indeed been reinstated.
// //     agDao.hasRoleSince(alice, MEMBER_ROLE);
// //   }
