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

// daos 
import { AlignedGrants } from "../src/ implementations/daos/AlignedGrants.sol";

// laws 
import { ChallengeExecution } from "../src/implementations/laws/administrative/ChallengeExecution.sol";
import { NeedsVote } from "../src/implementations/laws/administrative/NeedsVote.sol";
import { LimitExecutions } from "../src/implementations/laws/administrative/LimitExecutions.sol";
import { Direct } from "../src/implementations/laws/electoral/Direct.sol";
import { Tokens } from "../src/implementations/laws/electoral/Tokens.sol";
import { Randomly } from "../src/implementations/laws/electoral/Randomly.sol";
import { Delegate } from "../src/implementations/laws/electoral/Delegate.sol";
import { AdoptValue } from "../src/implementations/laws/bespoke/AdoptValue.sol";
import { RevokeRole } from "../src/implementations/laws/bespoke/RevokeRole.sol";
import { RevertRevokeRole } from "../src/implementations/laws/bespoke/RevertRevokeRole.sol";

abstract contract TestVariables is SeparatedPowersErrors, SeparatedPowersTypes, SeparatedPowersEvents {
    // protocol and mocks 
    SeparatedPowers separatedPowers;
    Erc1155Mock erc1155Mock;

    // daos
    AlignedGrants alignedGrantsDao; 

    // laws. 
    ChallengeExecution challengeExecution;
    NeedsVote needsVote;
    LimitExecutions limitExecutions;
    Direct direct;
    Tokens tokens;
    Randomly randomly;
    Delegate delegate;
    AdoptValue adoptValue;
    RevokeRole revokeRole;
    RevertRevokeRole revertRevokeRole;

    // users 
    address userOne;
    address userTwo;
    address userThree;
    address userFour;
    address userFive;
    address userSix;

    // other 
    // ... 
}

abstract contract TestSetup is Test, TestVariables {
    function setUp() public virtual {
        bytes32 SALT = bytes32(hex"7ceda5");

        setUpVariables();

        // possible other function to add here.
    }

    // this should be conditional on selection of dao. 
    function setUpVariables() public virtual {
        // initiate daos + constitute 
        alignedGrantsDao = new AlignedGrants(name, );


        userOne = makeAddr("alice");
        userTwo = makeAddr("bob");
        userThree = makeAddr("charlotte");
        userFour = makeAddr("david");
        userFive = makeAddr("eve");
        userSix = makeAddr("frank");


        // possible other function to add here.
    }

}
