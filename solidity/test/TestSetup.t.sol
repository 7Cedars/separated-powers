// SPDX-License-Identifier: UNLICENSED
// This setup is an adaptation from the Hats protocol test. See //
pragma solidity ^0.8.13;

import "forge-std/Test.sol";

// protocol 
import { SeparatedPowers } from "../src/SeparatedPowers.sol";
import { ISeparatedPowers } from "../src/interfaces/ISeparatedPowers.sol";
import { Law } from "../src/Law.sol";
import { ILaw } from "../src/interfaces/ILaw.sol";
import { SeparatedPowersErrors } from "../src/interfaces/SeparatedPowersErrors.sol";
import { SeparatedPowersTypes } from "../src/interfaces/SeparatedPowersTypes.sol";
import { SeparatedPowersEvents } from "../src/interfaces/SeparatedPowersEvents.sol";

// mocks 
import { Erc1155Mock } from "../src/implementations/mocks/Erc1155Mock.sol";

// deploy scripts 
import { DeployAlignedGrants } from "../script/deploy-aligned-grants/deployAlignedGrants.s.sol";

// daos 
import { AlignedGrants } from "../src/implementations/daos/AlignedGrants.sol";

// laws 
import { ChallengeExecution } from "../src/implementations/laws/administrative/ChallengeExecution.sol";
import { NeedsVote } from "../src/implementations/laws/administrative/NeedsVote.sol";
import { LimitExecutions } from "../src/implementations/laws/administrative/LimitExecutions.sol";
import { Direct } from "../src/implementations/laws/electoral/Direct.sol";
import { Tokens } from "../src/implementations/laws/electoral/Tokens.sol";
import { Randomly } from "../src/implementations/laws/electoral/Randomly.sol";
import { AdoptValue } from "../src/implementations/laws/bespoke/AdoptValue.sol";
import { RevokeRole } from "../src/implementations/laws/bespoke/RevokeRole.sol";
import { RevertRevokeRole } from "../src/implementations/laws/bespoke/RevertRevokeRole.sol";

abstract contract TestVariables is SeparatedPowersErrors, SeparatedPowersTypes, SeparatedPowersEvents {
    // protocol and mocks 
    SeparatedPowers separatedPowers;
    Erc1155Mock erc1155Mock;

    // deploy scripts 
    DeployAlignedGrants deployAlignedGrants;

    // daos
    AlignedGrants alignedGrantsDao; 
    address[] laws; 
    uint32[] allowedRoles; 
    uint8[] quorums; 
    uint8[] succeedAts; 
    uint32[] votingPeriods; 
    uint32[] constituentRoles; 
    address[] constituentAccounts;

    // laws 
    ChallengeExecution challengeExecution;
    NeedsVote needsVote;
    LimitExecutions limitExecutions;
    Direct direct;
    Tokens tokens;
    Randomly randomly;
    AdoptValue adoptValue;
    RevokeRole revokeRole;
    RevertRevokeRole revertRevokeRole;

    // roles 
    uint32 SENIOR_ROLE;
    uint32 WHALE_ROLE;
    uint32 MEMBER_ROLE;

    // users 
    address alice;
    address bob;
    address charlotte;
    address david;
    address eve;
    address frank;

    // other 
    string[] daoNames;
}

abstract contract TestSetup is Test, TestVariables {
    function setUp() public virtual {
        bytes32 SALT = bytes32(hex"7ceda5");
        vm.roll(10);
        setUpVariables();
    }

    // note that this setup does not scale very well re the number of daos.
    function setUpVariables() public virtual {
        SENIOR_ROLE = 1; 
        WHALE_ROLE = 2;
        MEMBER_ROLE = 3;

        // users
        alice = makeAddr("alice");
        bob = makeAddr("bob");
        charlotte = makeAddr("charlotte");
        david = makeAddr("david");
        eve = makeAddr("eve");
        frank = makeAddr("frank");

        // assign funds 
        vm.deal(alice, 10 ether);
        vm.deal(bob, 10 ether);
        vm.deal(charlotte, 10 ether);
        vm.deal(david, 10 ether);
        vm.deal(eve, 10 ether);
        vm.deal(frank, 10 ether);

        // deploy mocks
        erc1155Mock = new Erc1155Mock();

        // deploy daos (and laws). 
        deployAlignedGrants = new DeployAlignedGrants();
        (
            alignedGrantsDao, 
            laws, 
            allowedRoles, 
            quorums, 
            succeedAts, 
            votingPeriods, 
            constituentRoles, 
            constituentAccounts
            ) = deployAlignedGrants.run(erc1155Mock);
        daoNames.push("AlignedGrants");
    }
}
