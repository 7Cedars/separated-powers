// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import { Test, console, console2 } from "lib/forge-std/src/Test.sol";
import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";
import { ERC20Votes } from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol";

import { SeparatedPowers } from "../../../src/SeparatedPowers.sol";
import { SeparatedPowersEvents } from "../../../src/interfaces/SeparatedPowersEvents.sol";
import { Law } from "../../../src/Law.sol";
import { ILaw } from "../../../src/interfaces/ILaw.sol";

import { Erc721Mock } from "../../../test/mocks/Erc721Mock.sol";
import { Erc1155Mock } from "../../../test/mocks/Erc1155Mock.sol";
import { Erc20VotesMock } from "../../../test/mocks/Erc20VotesMock.sol";
import { StringsArray } from "../../../src/laws/state/StringsArray.sol";

import { TestSetupAlignedDao_fuzzIntegration } from "../../../test/TestSetup.t.sol";
import { HelperConfig } from "../../../script/HelperConfig.s.sol";

contract AlignedDao_fuzzIntegrationTest is TestSetupAlignedDao_fuzzIntegration {
    //////////////////////////////////////////////////////////////
    //              CHAPTER 1: EXECUTIVE ACTIONS                //
    //////////////////////////////////////////////////////////////
    function testFuzz_ProposeAndAdoptValues(
         uint256 step1,
         uint256 step2
    ) public {
        uint256 step1Chance = bound(step1, 0, 100); 
        uint256 step2Chance = bound(step2, 0, 100);
        uint256 seed = 530975438721; // additional randomiser
        uint256 numberOfValuesBefore = StringsArray(laws[1]).numberOfStrings();
        // need to check adopted strings before? 
        bool[] memory stepsPassed = new bool[](2);

        vm.startPrank(address(alignedDao));
        alignedDao.assignRole(0, alice); // ADMIN ROLE
        alignedDao.assignRole(1, bob); // role 1s
        alignedDao.assignRole(1, charlotte);
        alignedDao.assignRole(1, david);
        alignedDao.assignRole(1, eve);
        alignedDao.assignRole(1, frank);
        alignedDao.assignRole(2, gary); // role 2s
        alignedDao.assignRole(2, helen);
        vm.stopPrank();

        // step 0 action: propose a new value.
        string memory newValue = "Be nice";
        bool add = true; 

        lawCalldata = abi.encode("Be nice", true); // velue = "Be nice", add = true 
        description = "Propose to add `Be nice` to the list of values of the Dao.";
        vm.prank(bob); // has role 1.
        proposalId = alignedDao.propose(laws[0], lawCalldata, description);

        (roleCount, againstVote, forVote, abstainVote) = voteOnProposal(
            payable(address(alignedDao)),
            laws[0],
            proposalId,
            users, 
            seed,
            step1Chance
        );

        // step 0 results.
        (quorum, succeedAt, votingPeriod,,,,) = Law(laws[0]).config();
        quorumReached = (forVote + abstainVote) * 100 / roleCount > quorum;
        voteSucceeded = forVote * 100 / roleCount > succeedAt;
        stepsPassed[0] = quorumReached && voteSucceeded;
        // // role forward in time. 
        vm.roll(block.number + votingPeriod + 1);
        if (stepsPassed[0]) {
            console.log("step 0 action: Bob EXECUTES and thus formally proposes new value!");
            vm.expectEmit(true, false, false, false);
            emit SeparatedPowersEvents.ProposalCompleted(bob, laws[0], lawCalldata, keccak256(bytes(description)));
            vm.prank(bob);
            alignedDao.execute(laws[0], lawCalldata, description);
        }

        // // only resume if first proposal passed
        vm.assume(stepsPassed[0]);
        // step 1 action: propose and vote on newly accepted proposed value. 
        vm.prank(gary); // has role 2.
        proposalId = alignedDao.propose(laws[1], lawCalldata, description);

        (roleCount, againstVote, forVote, abstainVote) = voteOnProposal(
            payable(address(alignedDao)),
            laws[1],
            proposalId,
            users,
            seed,  
            step2Chance
        );

        // step 1 results.
        (quorum, succeedAt, votingPeriod,,, delayExecution,) = Law(laws[1]).config();
        quorumReached = (forVote + abstainVote) * 100 / roleCount > quorum;
        voteSucceeded = forVote * 100 / roleCount > succeedAt;
        stepsPassed[1] = quorumReached && voteSucceeded;
        vm.roll(block.number + votingPeriod + delayExecution + 1);
        console.log("step 1 result: quorum reached and vote succeeded?");
        console.log(quorumReached, voteSucceeded);

        // // step 2: conditional execute of proposal
        if (stepsPassed[1]) {
            console.log("step 1 action: ACTION WILL BE EXECUTED");
            vm.expectEmit(true, false, false, false);
            emit SeparatedPowersEvents.ProposalCompleted(gary, laws[1], lawCalldata, keccak256(bytes(description)));
            vm.prank(gary); // has role 1
            alignedDao.execute(laws[1], lawCalldata, description);
            uint256 numberOfValuesAfter = StringsArray(laws[1]).numberOfStrings();
            assertEq(numberOfValuesAfter, numberOfValuesBefore + 1);
        } else {
            vm.expectRevert();
            vm.prank(gary);
            alignedDao.execute(laws[1], lawCalldata, description);
            uint256 numberOfValuesAfter = StringsArray(laws[1]).numberOfStrings();
            assertEq(numberOfValuesAfter, numberOfValuesBefore);
        }
    }


    function testFuzz_RevokeAndReinstateMembership(
        uint256 step0,
        uint256 step1,
        uint256 step2,
        uint256 seed
    ) public {
        uint256 step0Chance = bound(step0, 0, 100); 
        uint256 step1Chance = bound(step1, 0, 100);
        uint256 step2Chance = bound(step2, 0, 100);
        uint256 seed = bound(seed, 100, 100_000);
        bool[] memory stepsPassed = new bool[](3);
        
        // give everyone a NFT. Note: NftId == index of user. 
        for (uint256 i = 0; i < users.length; i++) {
            vm.startPrank(users[i]);
            Erc721Mock(config.erc721Mock).cheatMint(i); 
            vm.stopPrank();
        }
        // assign roles. 
        vm.startPrank(address(alignedDao));
        alignedDao.assignRole(1, alice); // role 1s
        alignedDao.assignRole(1, bob); 
        alignedDao.assignRole(1, charlotte);
        alignedDao.assignRole(2, david); // role 2s
        alignedDao.assignRole(2, eve);
        alignedDao.assignRole(3, frank); // role 3s
        alignedDao.assignRole(3, gary); 
        alignedDao.assignRole(3, helen);
        vm.stopPrank();

        // step 0 action: propose to revoke membership.
        uint256 index = seed % 3;  // choose one of the users that has role 1. 
        lawCalldata = abi.encode(index, users[index]); // tokenId, address 
        description = "Propose to revoke a users membership.";
        vm.prank(frank); // has role 3.
        proposalId = alignedDao.propose(
            laws[2], // = RevokeMembership
            lawCalldata, 
            description
        );
        (roleCount, againstVote, forVote, abstainVote) = voteOnProposal(
            payable(address(alignedDao)),
            laws[2],
            proposalId,
            users,
            seed,  
            step0Chance
        );
        console.log("step 0 votes: roleCount, againstVote, forVote, abstainVote");
        console.log(roleCount, againstVote, forVote, abstainVote);

        // step 0 results 
        (quorum, succeedAt, votingPeriod,,, delayExecution,) = Law(laws[2]).config();
        quorumReached = roleCount * quorum <= (forVote + abstainVote) * 100;
        voteSucceeded = roleCount * succeedAt <= forVote * 100;
        stepsPassed[0] = quorumReached && voteSucceeded;
        vm.roll(block.number + votingPeriod + delayExecution + 1);
        console.log("step 0 result: quorum reached and vote succeeded?");
        console.log(quorumReached, voteSucceeded);
        if (stepsPassed[0]) {
            console.log("step 0 action: Frank EXECUTES and thus revokes membership!");
            vm.expectEmit(true, false, false, false);
            emit SeparatedPowersEvents.ProposalCompleted(frank, laws[2], lawCalldata, keccak256(bytes(description)));
            vm.prank(frank);
            alignedDao.execute(laws[2], lawCalldata, description);
        } else {
            vm.expectRevert();
            vm.prank(frank);
            alignedDao.execute(laws[2], lawCalldata, description);
        }

        // only continue if previous step passed. 
        vm.assume(stepsPassed[0]);
        
        // step 1: challenge revoke of membership.
        // NB: we do not know if Alice has had her role revoked, hence we need to select another person if she had. 
        bool aliceCanCall = SeparatedPowers(alignedDao).canCallLaw(alice, laws[3]);
        address caller; 
        if (!aliceCanCall) {
            caller = bob;  
        } else {
            caller = alice;
        }
        // has role 1.
        vm.prank(caller); 
        proposalId = alignedDao.propose(
            laws[3], // = ProposalOnly (reinstate membership)
            lawCalldata, // note: same lawCalldata as step 0.
            description // note: same description as step 0.
        );
        (roleCount, againstVote, forVote, abstainVote) = voteOnProposal(
            payable(address(alignedDao)),
            laws[3],
            proposalId,
            users,
            seed,  
            step1Chance
        );

        // step 1 results 
        (quorum, succeedAt, votingPeriod,,, delayExecution,) = Law(laws[3]).config();
        quorumReached = (forVote + abstainVote) * 100 / roleCount > quorum;
        voteSucceeded = forVote * 100 / roleCount > succeedAt;
        stepsPassed[1] = quorumReached && voteSucceeded;
        vm.roll(block.number + votingPeriod + delayExecution + 1);
        console.log("step 1 result: quorum reached and vote succeeded?");
        console.log(quorumReached, voteSucceeded);
        if (stepsPassed[1]) {
            console.log("step 1 action: caller EXECUTES and thus formalises challenge to revoke!");
            vm.expectEmit(true, false, false, false);
            emit SeparatedPowersEvents.ProposalCompleted(caller, laws[3], lawCalldata, keccak256(bytes(description)));
            vm.prank(caller);
            alignedDao.execute(laws[3], lawCalldata, description);
        } else {
            vm.expectRevert();
            vm.prank(caller);
            alignedDao.execute(laws[3], lawCalldata, description);
        }

        // only continue if previous step passed. 
        vm.assume(stepsPassed[1]);

        // step 2: accept challenge and reinstate membership.
        vm.prank(david); // has role 2.
        proposalId = alignedDao.propose(
            laws[4], // = ProposalOnly (reinstate membership)
            lawCalldata, // note: same lawCalldata as step 0.
            description // note: same description as step 0.
        );
        (roleCount, againstVote, forVote, abstainVote) = voteOnProposal(
            payable(address(alignedDao)),
            laws[4],
            proposalId,
            users,
            seed,  
            step2Chance
        );

        // step 2 results 
        (quorum, succeedAt, votingPeriod,,, delayExecution,) = Law(laws[4]).config();
        quorumReached = (forVote + abstainVote) * 100 / roleCount > quorum;
        voteSucceeded = forVote * 100 / roleCount > succeedAt;
        stepsPassed[2] = quorumReached && voteSucceeded;
        vm.roll(block.number + votingPeriod + delayExecution + 1);
        console.log("step 2 result: quorum reached and vote succeeded?");
        console.log(quorumReached, voteSucceeded);
        if (stepsPassed[2]) {
            console.log("step 2 action: david EXECUTES and reinstates membership!");
            vm.expectEmit(true, false, false, false);
            emit SeparatedPowersEvents.ProposalCompleted(david, laws[4], lawCalldata, keccak256(bytes(description)));
            vm.prank(david);
            alignedDao.execute(laws[4], lawCalldata, description);
        } else {
            vm.expectRevert();
            vm.prank(david);
            alignedDao.execute(laws[4], lawCalldata, description);
        }

        if (stepsPassed[0] && stepsPassed[1] && stepsPassed[2] ) {
            assertEq(SeparatedPowers(alignedDao).hasRoleSince(users[index], 1), block.number);        
        }
    }

    function testFuzz_MembersRequestPayment(
        uint256 selectUser, 
        uint256 duration, 
        uint256 numberSteps
    ) public {
        uint256 selectUser = bound(step0, 0, users.length); 
        uint256 duration = bound(step1, 1000, 2000);
        uint256 numberSteps = bound(step2, 5, 100);
        string memory description = "Request payment.";
        bytes me

        // mint funds
        vm.prank(address(alignedDao));
        Erc1155Mock(config.erc1155Mock).mintCoins(1_000_000)

        // assign roles. 
        vm.startPrank(address(alignedDao));
        alignedDao.assignRole(1, alice); // role 1s
        alignedDao.assignRole(1, bob); 
        alignedDao.assignRole(1, charlotte);
        alignedDao.assignRole(1, david); 
        alignedDao.assignRole(1, eve);
        vm.stopPrank();

        // step 0: select user. 
        vm.prank(users[selectUser]);
        alignedDao.execute(laws[5], abi.encode(), description);
   
    
    // fuzz on member. 
    // fuzz on block steps. 
    // expect revert if not member or not beyond claim period.   

    }

    //////////////////////////////////////////////////////////////
    //              CHAPTER 2: ELECT ROLES                      //
    //////////////////////////////////////////////////////////////
    function testFuzz_SelfSelectRoleWithNft(
        uint256 seed,
        uint256 density
    ) public {
        density = bound(density, 0, 100);
        // step 0: distribute nfts. NFTs are distributed randomly.
        distributeNFTs(config.erc721Mock, users, seed, density);

        // step 1: assert that only accounts with an NFT can claim role.
        for (uint256 i = 0; i < users.length; i++) {
            bool hasNFT = Erc721Mock(config.erc721Mock).balanceOf(users[i]) > 0; // does user have NFT? 
            string memory description = string.concat("Account claims role: ", Strings.toString(i));

            if (hasNFT) {
                vm.expectEmit(true, false, false, false);
                emit SeparatedPowersEvents.ProposalCompleted(users[i], laws[6], abi.encode(), keccak256(bytes(description)));
                vm.prank(users[i]);
                alignedDao.execute(laws[6], abi.encode(false), description);
            } else {
                vm.expectRevert();
                vm.prank(users[i]);
                alignedDao.execute(laws[6], abi.encode(false), description);
            }
        }
    }

    function testFuzz_DelegateElect(uint256 numNominees, uint256 voteTokensRandomiser) public {
        numNominees = bound(numNominees, 4, 10);
        voteTokensRandomiser = bound(voteTokensRandomiser, 100_000, type(uint256).max);

        address oracle = makeAddr("oracle");

        vm.startPrank(address(alignedDao));
        alignedDao.assignRole(0, alice); // alice is assigned ADMIN ROLE
        vm.stopPrank();

        // step 0a: distribute tokens. Tokens are distributed randomly.
        distributeTokens(config.erc20VotesMock, users, voteTokensRandomiser);
        // step 0b: set oracle address
        vm.prank(alice); // alice = admin. 
        alignedDao.execute(laws[11], abi.encode(false, oracle), "The admin sets the oracle address.");

        // step 1: people nominate their accounts.
        bytes memory lawCalldataNominate = abi.encode(true); // nominateMe = true

        for (uint256 i = 0; i < numNominees; i++) {
            vm.prank(users[i]);
            alignedDao.execute(
                 laws[7], lawCalldataNominate, string.concat("Account nominates themselves: ", Strings.toString(i))
            );
        }
        // step 2: run election.
        bytes memory lawCalldataElect = abi.encode(); // empty calldata
        vm.prank(oracle);
        alignedDao.execute(laws[8], lawCalldataElect, "The oracle executes an election.");

        // step 3: assert that the elected accounts are correct.
        for (uint256 i = 0; i < numNominees; i++) {
            for (uint256 j = 0; j < numNominees; j++) {
                address nominee = users[i];
                address nominee2 = users[j];
                if (alignedDao.hasRoleSince(nominee, 2) != 0 && alignedDao.hasRoleSince(nominee2, 2) == 0) {
                    uint256 balanceNominee = Erc20VotesMock(config.erc20VotesMock).balanceOf(nominee);
                    uint256 balanceNominee2 = Erc20VotesMock(config.erc20VotesMock).balanceOf(nominee2);
                    assertGe(balanceNominee, balanceNominee2); // assert that nominee has more tokens than nominee2.
                }
                if (alignedDao.hasRoleSince(nominee, 2) == 0 && alignedDao.hasRoleSince(nominee2, 2) != 0) {
                    uint256 balanceNominee = Erc20VotesMock(config.erc20VotesMock).balanceOf(nominee);
                    uint256 balanceNominee2 = Erc20VotesMock(config.erc20VotesMock).balanceOf(nominee2);
                    assertLe(balanceNominee, balanceNominee2); // assert that nominee has fewer tokens than nominee2.
                }
            }
        }
    }

    function testFuzz_PeerSelect( 
        uint256 succeedPassChance
    ) public { 
        succeedPassChance = bound(succeedPassChance, 0, 100);

        // assigning necessary roles.
        vm.startPrank(address(alignedDao));
        alignedDao.assignRole(3, alice);
        alignedDao.assignRole(3, bob);
        alignedDao.assignRole(3, charlotte);
        alignedDao.assignRole(3, david);
        vm.stopPrank();

        // step 1: people nominate their accounts.
        uint256 numNominees;
        for (uint256 i = 0; i < users.length; i++) {
            if (alignedDao.hasRoleSince(users[i], 1) == 0) {
                vm.prank(users[i]);
                alignedDao.execute(
                     laws[9], abi.encode(true), string.concat("Account nominates themself", Strings.toString(i))
                );
            }
            numNominees++;
        }

        // step 2: propose action and run election.
        bytes memory lawCalldataSelect = abi.encode(0, false); // = revoke = false
        string memory descriptionSelect = "Elect an account to role 3.";
        vm.prank(charlotte); // already has role 3.
        uint256 proposalId = alignedDao.propose(laws[10], lawCalldataSelect, descriptionSelect);

        (uint256 roleCount, uint256 againstVote, uint256 forVote, uint256 abstainVote) = voteOnProposal(
            payable(address(alignedDao)), 
            laws[10], 
            proposalId, 
            users, 
            243432432,
            succeedPassChance
        );

        // step 3:  assert that the elected accounts are correct.
        (uint8 quorum, uint8 succeedAt, uint32 votingPeriod,,,,) = Law(laws[10]).config();
        bool quorumReached = (forVote + abstainVote) * 100 / roleCount > quorum;
        bool succeeded = forVote * 100 / roleCount > succeedAt;

        vm.roll(block.number + votingPeriod + 1);
        console.log(uint8(alignedDao.state(proposalId)));
        if (quorumReached && succeeded) {
            vm.expectEmit(true, false, false, false);
            emit SeparatedPowersEvents.ProposalCompleted(alice, laws[10], lawCalldataSelect, keccak256(bytes(descriptionSelect)));
            vm.prank(alice);
            alignedDao.execute(laws[10], lawCalldataSelect, descriptionSelect);
        } else {
            vm.expectRevert();
            vm.prank(alice);
            alignedDao.execute(laws[10], lawCalldataSelect, descriptionSelect);
        }
    }
}




//     //////////////////////////////////////////////////////////////
//     //              CHAPTER 2: ELECT ROLES                      //
//     //////////////////////////////////////////////////////////////





// import { Test, console, console2 } from "lib/forge-std/src/Test.sol";
// import "@openzeppelin/contracts/utils/ShortStrings.sol";

// import { SeparatedPowers } from "../../src/SeparatedPowers.sol";
// import { Law } from "../../src/Law.sol";
// import { ILaw } from "../../src/interfaces/ILaw.sol";

// import { DeployMocks } from "../../script/DeployMocks.s.sol";
// // import { DeployAlignedDao } from "../../script/DeployAlignedDao.s.sol";
// import { Erc1155Mock } from "../../test/mocks/Erc1155Mock.sol";
// import { Erc20VotesMock } from "../../test/mocks/Erc20VotesMock.sol";

// import { TestVariables, TestHelpers } from "../../test/TestSetup.t.sol";

// /////////////////////////////////////////////////////
// //                      Setup                      //
// /////////////////////////////////////////////////////
// abstract contract TestSetupAlignedGrants is Test, TestVariables, TestHelpers {
//     function TestA() public { }

//     function setUp() public virtual {
//         // the only law specific event that is emitted.
//         vm.roll(block.number + 10);
//         setUpVariables();
//     }

//     // note that this setup does not scale very well re the number of daos.
//     function setUpVariables() public virtual {
//         // // votes types
//         // AGAINST = 0;
//         // FOR = 1;
//         // ABSTAIN = 2;

//         // // roles
//         // ADMIN_ROLE = 0;
//         // PUBLIC_ROLE = type(uint32).max;
//         // ROLE_ONE = 1;
//         // ROLE_TWO = 2;
//         // ROLE_THREE = 3;

//         // // deploy mocks
//         // erc1155Mock = new Erc1155Mock();
//         // erc20VotesMock = new Erc20VotesMock();
//         // alignedGrants = new AlignedGrants();

//         // // users
//         // alice = makeAddr("alice");
//         // bob = makeAddr("bob");
//         // charlotte = makeAddr("charlotte");
//         // david = makeAddr("david");
//         // eve = makeAddr("eve");
//         // frank = makeAddr("frank");
//         // gary = makeAddr("gary");
//         // helen = makeAddr("helen");

//         // // assign funds
//         // vm.deal(alice, 10 ether);
//         // vm.deal(bob, 10 ether);
//         // vm.deal(charlotte, 10 ether);
//         // vm.deal(david, 10 ether);
//         // vm.deal(eve, 10 ether);
//         // vm.deal(frank, 10 ether);
//         // vm.deal(gary, 10 ether);
//         // vm.deal(helen, 10 ether);

//         // users = [alice, bob, charlotte, david, eve, frank, gary, helen];

//         // // assign tokens to users. Increasing amount coins as we go down the list.
//         // for (uint256 i; i < users.length; i++) {
//         //     vm.startPrank(users[i]);
//         //     erc1155Mock.mintCoins((i + 1) * 100);
//         //     erc20VotesMock.mintVotes((i + 1) * 100);
//         //     erc20VotesMock.delegate(users[i]); // users delegate votes to themselves.
//         //     vm.stopPrank();
//         // }

//         // // get constitution and founders lists.
//         // // note: copying structs from memory to storage is not yet supported in solidity.
//         // // Hence we need to create a memory variable to store lawsConfig, while laws and allowedRoles are stored in storage.
//         // ILaw.LawConfig[] memory lawsConfig;
//         // (
//         //     laws,
//         //     allowedRoles,
//         //     lawsConfig
//         //     ) = constitution.initiate(
//         //         payable(address(alignedGrants)),
//         //         payable(address((erc1155Mock)))
//         //         );

//         // (constituentRoles, constituentAccounts) = founders.get(payable(address(alignedGrants)));

//         // // constitute daoMock.
//         // alignedGrants.constitute(
//         //     laws, constituentRoles, constituentAccounts
//         // );
//     }
// }

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

// //   ///////////////////////////////////////////////
// //   ///                   Helpers               ///
// //   ///////////////////////////////////////////////
// //   function _deployLaws(address payable agDaoAddress_, address agCoinsAddress_) internal returns (address[] memory lawsArray) {
// //       address[] memory laws = new address[](12);

// //       // deploying laws //
// //       vm.startPrank(bob);
// //       // re assigning roles //
// //       laws[0] = address(new Public_assignRole(agDaoAddress_));
// //       laws[1] = address(new Senior_assignRole(agDaoAddress_, agCoinsAddress_));
// //       laws[2] = address(new Senior_revokeRole(agDaoAddress_, agCoinsAddress_));
// //       laws[3] = address(new Member_assignWhale(agDaoAddress_, agCoinsAddress_));

// //       // re activating & deactivating laws  //
// //       laws[4] = address(new Whale_proposeLaw(agDaoAddress_, agCoinsAddress_));
// //       laws[5] = address(new Senior_acceptProposedLaw(agDaoAddress_, agCoinsAddress_, address(laws[4])));
// //       laws[6] = address(new Admin_setLaw(agDaoAddress_, address(laws[5])));

// //       // re updating core values //
// //       laws[7] = address(new Member_proposeCoreValue(agDaoAddress_, agCoinsAddress_));
// //       laws[8] = address(new Whale_acceptCoreValue(agDaoAddress_, agCoinsAddress_, address(laws[7])));

// //       // re enforcing core values as requirement for external funding //
// //       laws[9] = address(new Whale_revokeMember(agDaoAddress_, agCoinsAddress_));
// //       laws[10] = address(new Public_challengeRevoke(agDaoAddress_, address(laws[9])));
// //       laws[11] = address(new Senior_reinstateMember(agDaoAddress_, agCoinsAddress_, address(laws[10])));
// //       vm.stopPrank();

// //       return laws;
// //     }
// // }
