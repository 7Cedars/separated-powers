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
import { LawErrors } from "../src/interfaces/LawErrors.sol";
import { HelperConfig } from "../script/HelperConfig.s.sol";
import "@openzeppelin/contracts/utils/ShortStrings.sol";

import { PresetAction } from "../src/laws/executive/PresetAction.sol";

// mocks
import { DaoMock } from "./mocks/DaoMock.sol";
import { Erc1155Mock } from "./mocks/Erc1155Mock.sol";
import { Erc721Mock } from "./mocks/Erc721Mock.sol";
import { Erc20VotesMock } from "./mocks/Erc20VotesMock.sol";
import { ConstitutionsMock } from "./mocks/ConstitutionsMock.sol";

abstract contract TestVariables is SeparatedPowersErrors, SeparatedPowersTypes, SeparatedPowersEvents, LawErrors {
    // protocol and mocks
    SeparatedPowers separatedPowers;
    HelperConfig helperConfig;
    DaoMock daoMock;
    ConstitutionsMock constitutionsMock;
    Erc1155Mock erc1155Mock;
    Erc721Mock erc721Mock;
    Erc20VotesMock erc20VotesMock;
    HelperConfig.NetworkConfig config;

    address[] laws;

    // vote options
    uint8 AGAINST;
    uint8 FOR;
    uint8 ABSTAIN;

    // roles
    uint32 ADMIN_ROLE;
    uint32 PUBLIC_ROLE;
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

    // the only event in the Law contract
    event Law__Initialized(address indexed law, address indexed separatedPowers, bytes4[] params, string name, string description, uint48 allowedRole, ILaw.LawConfig config);
}

abstract contract TestHelpers is TestVariables {
    function hashProposal(address targetLaw, bytes memory lawCalldata, bytes32 descriptionHash)
        public
        pure
        virtual
        returns (uint256)
    {
        return uint256(keccak256(abi.encode(targetLaw, lawCalldata, descriptionHash)));
    }
}

abstract contract BaseSetup is Test, TestVariables, TestHelpers {
    function setUp() public virtual {
        vm.roll(block.number + 10);
        setUpVariables();
    }

    // // add this to be excluded from coverage report
    // function test() public {}

    function setUpVariables() public virtual {
        // votes types
        AGAINST = 0;
        FOR = 1;
        ABSTAIN = 2;

        // roles
        ADMIN_ROLE = 0;
        PUBLIC_ROLE = type(uint32).max;
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
        erc721Mock = new Erc721Mock();
        erc20VotesMock = new Erc20VotesMock();
        daoMock = new DaoMock();
        constitutionsMock = new ConstitutionsMock();
    }
}

abstract contract TestSetupSeparatedPowers is BaseSetup, ConstitutionsMock {
    function setUpVariables() public override {
        super.setUpVariables();

        // initiate constitution & get founders' roles list
        (address[] memory laws_) = constitutionsMock.initiateSeparatedPowersConstitution(
            payable(address(daoMock)), payable(address(erc1155Mock))
        );

        // constitute daoMock.
        laws = laws_;
        daoMock.constitute(laws);
        // assign Roles
        vm.roll(block.number + 4000);
        daoMock.execute(
            laws[laws.length - 1],
            abi.encode(), // empty calldata
            "assigning roles"
        );
        daoNames.push("DaoMock");
    }
}

abstract contract TestSetupLaw is BaseSetup, ConstitutionsMock {
    function setUpVariables() public override {
        super.setUpVariables();

        // initiate constitution & get founders' roles list
        (address[] memory laws_) =
            constitutionsMock.initiateLawTestConstitution(payable(address(daoMock)), payable(address(erc1155Mock)));
        laws = laws_;

        // constitute daoMock.
        daoMock.constitute(laws);
        // assign Roles
        vm.roll(block.number + 4000);
        daoMock.execute(
            laws[laws.length - 1],
            abi.encode(), // empty calldata
            "assigning roles"
        );
        daoNames.push("DaoMock");
    }
}

abstract contract TestSetupLaws is BaseSetup, ConstitutionsMock {
    function setUpVariables() public override {
        super.setUpVariables();

        // initiate constitution & get founders' roles list
        (address[] memory laws_) = constitutionsMock.initiateLawsTestConstitution(
            payable(address(daoMock)), payable(address(erc1155Mock)), payable(address(erc20VotesMock))
        );
        laws = laws_;

        // constitute daoMock.
        daoMock.constitute(laws);

        // testing...
        PresetAction presetAction = PresetAction(laws[laws.length - 1]);
        console.logAddress(presetAction.targets(0));

        // assign Roles
        vm.roll(block.number + 4000);
        daoMock.execute(
            laws[laws.length - 1],
            abi.encode(), // empty calldata
            "assigning roles"
        );
        daoNames.push("DaoMock");
    }
}
