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
import { DaoMock } from "./mocks/DaoMock.sol";
import { ConstitutionMock } from "./mocks/ConstitutionMock.sol";
import { FoundersMock } from "./mocks/FoundersMock.sol";
import { Erc1155Mock } from "./mocks/Erc1155Mock.sol";

// laws 
import { VoteOnProposedAction } from "../src/implementations/laws/bespoke/VoteOnProposedAction.sol";
import { TokensSelect } from "../src/implementations/laws/electoral/TokensSelect.sol";
import { DirectSelect } from "../src/implementations/laws/electoral/DirectSelect.sol";
import { ProposalOnly } from "../src/implementations/laws/executive/ProposalOnly.sol";

abstract contract TestVariables is SeparatedPowersErrors, SeparatedPowersTypes, SeparatedPowersEvents {
    // protocol and mocks 
    SeparatedPowers separatedPowers;
    DaoMock daoMock;
    ConstitutionMock constitutionMock;
    FoundersMock foundersMock;
    Erc1155Mock erc1155Mock;

    // constitutute dao 
    address[] laws; 
    uint32[] allowedRoles; 
    uint8[] quorums; 
    uint8[] succeedAts; 
    uint32[] votingPeriods; 
    uint32[] constituentRoles; 
    address[] constituentAccounts;

    // laws 
    VoteOnProposedAction voteOnProposedAction;
    DirectSelect directSelect;
    TokensSelect tokensSelect;
    ProposalOnly proposalOnly;

    // roles 
    uint32 ROLE_ONE;
    uint32 ROLE_TWO;
    uint32 ROLE_THREE;

    // users 
    address alice;
    address bob;
    address charlotte;
    address david;
    address eve;
    address frank;
    address gary;
    address helen;
    address[] users;

    // list of dao names
    string[] daoNames;
}

abstract contract TestSetup is Test, TestVariables {
    function setUp() public virtual {
        vm.roll(10);
        setUpVariables();
    }

    // note that this setup does not scale very well re the number of daos.
    function setUpVariables() public virtual {
        ROLE_ONE = 1; 
        ROLE_TWO = 2;
        ROLE_THREE = 3;

        // users
        alice = makeAddr("alice");
        bob = makeAddr("bob");
        charlotte = makeAddr("charlotte");
        david = makeAddr("david");
        eve = makeAddr("eve");
        frank = makeAddr("frank");
        gary = makeAddr("gary");
        helen = makeAddr("helen");

        // assign funds 
        vm.deal(alice, 10 ether);
        vm.deal(bob, 10 ether);
        vm.deal(charlotte, 10 ether);
        vm.deal(david, 10 ether);
        vm.deal(eve, 10 ether);
        vm.deal(frank, 10 ether);
        vm.deal(gary, 10 ether);
        vm.deal(helen, 10 ether);

        users = [alice, bob, charlotte, david, eve, frank, gary, helen];

        // deploy mocks
        erc1155Mock = new Erc1155Mock();
        daoMock = new DaoMock();
        constitutionMock = new ConstitutionMock();
        foundersMock = new FoundersMock();

        // get constitution and founders lists. 
        (
            laws,
            allowedRoles,
            quorums,
            succeedAts,
            votingPeriods
            ) = constitutionMock.initiate(payable(address(daoMock)), payable(address((erc1155Mock))));

        (
            constituentRoles, 
            constituentAccounts
            ) = foundersMock.get(payable(address(daoMock)), users);

        // constitute daoMock. 
        daoMock.constitute(laws, allowedRoles, quorums, succeedAts, votingPeriods, constituentRoles, constituentAccounts);

        daoNames.push("DaoMock");
    }
}
