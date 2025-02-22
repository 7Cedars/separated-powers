// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.26;

import { Test, console, console2 } from "lib/forge-std/src/Test.sol";
import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";
import { ERC20Votes } from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol";

import { SeparatedPowers } from "../../../src/SeparatedPowers.sol";
import { SeparatedPowersEvents } from "../../../src/interfaces/SeparatedPowersEvents.sol";
import { Law } from "../../../src/Law.sol";
import { ILaw } from "../../../src/interfaces/ILaw.sol";

import { Erc1155Mock } from "../../../test/mocks/Erc1155Mock.sol";
import { Erc20VotesMock } from "../../../test/mocks/Erc20VotesMock.sol";

import { TestSetupBasicDao_fuzzIntegration } from "../../../test/TestSetup.t.sol";
import { HelperConfig } from "../../../script/HelperConfig.s.sol";

contract BasicDao_fuzzIntegrationTest is TestSetupBasicDao_fuzzIntegration {
    //////////////////////////////////////////////////////////////
    //              CHAPTER 1: EXECUTIVE ACTIONS                //
    //////////////////////////////////////////////////////////////
    function testFuzz_ProposeAndExecuteAnAction(
        uint256 step0Chance,
        uint256 step1Chance,
        uint256 step2Chance
    ) public {
        uint256 step0Chance = bound(step0Chance, 0, 100);
        uint256 step1Chance = bound(step1Chance, 0, 100);
        uint256 step2Chance = bound(step2Chance, 0, 100);
        uint256 balanceBefore = erc20VotesMock.balanceOf(address(basicDao));
        uint256 seed = 9034273427; 

        bool[] memory stepsPassed = new bool[](3);

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
            users,
            seed, 
            step0Chance
        );

        // step 0 results.
        (quorum, succeedAt, votingPeriod,,,,) = Law(laws[0]).config();
        quorumReached = (forVote + abstainVote) * 100 / roleCount > quorum;
        voteSucceeded = forVote * 100 / roleCount > succeedAt;
        stepsPassed[0] = quorumReached && voteSucceeded;
        vm.roll(block.number + votingPeriod + 1);
        if (stepsPassed[0]) {
            console.log("step 1 action: GARY EXECUTES!");
            vm.expectEmit(true, false, false, false);
            emit SeparatedPowersEvents.ProposalCompleted(gary, laws[0], lawCalldata, keccak256(bytes(description)));
            vm.prank(gary);
            basicDao.execute(laws[0], lawCalldata, description);
        }

        // step 1 action: cast veto?.
        if (step1Chance > 50) {
            console.log("step 2 action: ALICE CASTS VETO!");
            vm.expectEmit(true, false, false, false);
            emit SeparatedPowersEvents.ProposalCompleted(alice, laws[1], lawCalldata, keccak256(bytes(description)));
            vm.prank(alice); // has admin role.
            basicDao.execute(laws[1], lawCalldata, description);

            // step 1 results.
            descriptionHash = keccak256(bytes(description));
            proposalId = hashProposal(laws[1], lawCalldata, descriptionHash);
            uint8 vetoState = uint8(basicDao.state(proposalId));
            stepsPassed[1] = vetoState != uint8(ProposalState.Completed);
            console.log("step 2 result: proposal vetoState: ", vetoState);
        } else {
            console.log("step 2 action: ALICE DOES NOT CASTS VETO!");
            stepsPassed[1] = true;
        }

        // only resume if both steps passed
        vm.assume(stepsPassed[0] && stepsPassed[1]);
        // step 2 action: propose and vote on action. 
        vm.prank(bob); // has role 1.
        proposalId = basicDao.propose(laws[2], lawCalldata, description);

        (roleCount, againstVote, forVote, abstainVote) = voteOnProposal(
            payable(address(basicDao)),
            laws[2],
            proposalId,
            users,
            seed,
            step2Chance
        );

        // step 2 results.
        (quorum, succeedAt, votingPeriod,,, delayExecution,) = Law(laws[2]).config();
        quorumReached = (forVote + abstainVote) * 100 / roleCount > quorum;
        voteSucceeded = forVote * 100 / roleCount > succeedAt;
        stepsPassed[2] = quorumReached && voteSucceeded;
        vm.roll(block.number + votingPeriod + delayExecution + 1);
        console.log("step 3 result: quorum reached and vote succeeded?");
        console.log(quorumReached, voteSucceeded);

        // step 3: conditional execute of proposal
        if (stepsPassed[2]) {
            console.log("step 4 action: ACTION WILL BE EXECUTED");
            vm.expectEmit(true, false, false, false);
            emit SeparatedPowersEvents.ProposalCompleted(bob, laws[2], lawCalldata, keccak256(bytes(description)));
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
        distributeTokens(address(erc20VotesMock), users, voteTokensRandomiser);

        // step 1: people nominate their accounts.
        bytes memory lawCalldataNominate = abi.encode(true); // nominateMe = true

        for (uint256 i = 0; i < numNominees; i++) {
            vm.prank(users[i]);
            basicDao.execute(
                nominateMeLaw, lawCalldataNominate, string.concat("Account nominates themselves: ", Strings.toString(i))
            );
        }
        // step 2: run election.
        bytes memory lawCalldataElect = abi.encode(); // empty calldata
        address executioner = users[voteTokensRandomiser % users.length];
        vm.prank(executioner);
        basicDao.execute(delegateSelectLaw, lawCalldataElect, "Account executes an election.");

        // step 3: assert that the elected accounts are correct.
        for (uint256 i = 0; i < numNominees; i++) {
            for (uint256 j = 0; j < numNominees; j++) {
                address nominee = users[i];
                address nominee2 = users[j];
                if (basicDao.hasRoleSince(nominee, 2) != 0 && basicDao.hasRoleSince(nominee2, 2) == 0) {
                    uint256 balanceNominee = erc20VotesMock.balanceOf(nominee);
                    uint256 balanceNominee2 = erc20VotesMock.balanceOf(nominee2);
                    assertGe(balanceNominee, balanceNominee2); // assert that nominee has more tokens than nominee2.
                }
                if (basicDao.hasRoleSince(nominee, 2) == 0 && basicDao.hasRoleSince(nominee2, 2) != 0) {
                    uint256 balanceNominee = erc20VotesMock.balanceOf(nominee);
                    uint256 balanceNominee2 = erc20VotesMock.balanceOf(nominee2);
                    assertLe(balanceNominee, balanceNominee2); // assert that nominee has fewer tokens than nominee2.
                }
            }
        }
    }

    function testFuzz_PeerSelect(
        uint256 passChance
    ) public {
        passChance = bound(passChance, 0, 100);
        uint256 seed = 3298443729;  

        // assigning necessary roles.
        vm.startPrank(address(basicDao));
        basicDao.assignRole(1, alice);
        basicDao.assignRole(1, bob);
        basicDao.assignRole(1, charlotte);
        basicDao.assignRole(1, david);
        vm.stopPrank();

        // step 1: people nominate their accounts.
        uint256 numNominees;
        for (uint256 i = 0; i < users.length; i++) {
            if (basicDao.hasRoleSince(users[i], 1) == 0) {
                vm.prank(users[i]);
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
            payable(address(basicDao)), 
            laws[7], 
            proposalId, 
            users, 
            seed,  
            passChance
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
            assertNotEq(basicDao.hasRoleSince(users[0], 1), 0);
        } else {
            vm.expectRevert();
            vm.prank(alice);
            basicDao.execute(laws[7], lawCalldataSelect, descriptionSelect);
        }
    }
}
