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

// mocks
import { DaoMock } from "./mocks/DaoMock.sol";
import { ConstitutionsMock } from "./mocks/ConstitutionsMock.sol";
import { FoundersMock } from "./mocks/FoundersMock.sol";
import { Erc1155Mock } from "./mocks/Erc1155Mock.sol";
import { Erc20VotesMock } from "./mocks/Erc20VotesMock.sol";

abstract contract TestVariables is SeparatedPowersErrors, SeparatedPowersTypes, SeparatedPowersEvents, LawErrors {
    // the only event in the Law contract
    event Law__Initialized(address law);

    // protocol and mocks
    SeparatedPowers separatedPowers;
    DaoMock daoMock;
    ConstitutionsMock constitutionsMock;
    FoundersMock foundersMock;
    Erc1155Mock erc1155Mock;
    Erc20VotesMock erc20VotesMock;

    // constitute dao
    address[] laws;
    uint32[] allowedRoles;
    // ILaw.LawConfig[] lawsConfig;
    uint32[] constituentRoles;
    address[] constituentAccounts;

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
}

abstract contract TestHelpers {
    function hashProposal(address targetLaw, bytes memory lawCalldata, bytes32 descriptionHash)
        public
        pure
        virtual
        returns (uint256)
    {
        return uint256(keccak256(abi.encode(targetLaw, lawCalldata, descriptionHash)));
    }
}

abstract contract TestSetupSeparatedPowers is Test, TestVariables, TestHelpers {
    function setUp() public virtual {
        vm.roll(10);
        setUpVariables();
    }

    // note that this setup does not scale very well re the number of daos.
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
        erc20VotesMock = new Erc20VotesMock();
        daoMock = new DaoMock();
        constitutionsMock = new ConstitutionsMock();
        foundersMock = new FoundersMock();

        // get constitution and founders lists.
        // note: copying structs from memory to storage is not yet supported in solidity. 
        // Hence we need to create a memory variable to store lawsConfig, while laws and allowedRoles are stored in storage.
        ILaw.LawConfig[] memory lawsConfig; 
        (
            laws, 
            allowedRoles, 
            lawsConfig
            ) = constitutionsMock.initiateFirst(payable(address(daoMock)), payable(address((erc1155Mock))));

        (constituentRoles, constituentAccounts) = foundersMock.get(payable(address(daoMock)), users);

        // constitute daoMock.
        daoMock.constitute(
            laws, allowedRoles, lawsConfig,
            constituentRoles, constituentAccounts
        );

        daoNames.push("DaoMock");
    }
}


abstract contract TestSetupLaw is Test, TestVariables, TestHelpers {
    function setUp() public virtual {
        // the only law specific event that is emitted.
        vm.roll(10);
        setUpVariables();
    }

    // note that this setup does not scale very well re the number of daos.
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
        erc20VotesMock = new Erc20VotesMock();
        daoMock = new DaoMock();
        constitutionsMock = new ConstitutionsMock();
        foundersMock = new FoundersMock();

        // get constitution and founders lists.
        // note: copying structs from memory to storage is not yet supported in solidity. 
        // Hence we need to create a memory variable to store lawsConfig, while laws and allowedRoles are stored in storage.
        ILaw.LawConfig[] memory lawsConfig;
        (            
            laws, 
            allowedRoles, 
            lawsConfig
            ) = constitutionsMock.initiateThird(payable(address(daoMock)), payable(address((erc1155Mock))));

        (constituentRoles, constituentAccounts) = foundersMock.get(payable(address(daoMock)), users);

        // constitute daoMock.
        daoMock.constitute(
            laws, allowedRoles, lawsConfig,
            constituentRoles, constituentAccounts
        );

        daoNames.push("DaoMock");
    }
}


abstract contract TestSetupImplementations is Test, TestVariables, TestHelpers {
    function setUp() public virtual {
        // the only law specific event that is emitted.
        vm.roll(10);
        setUpVariables();
    }

    // note that this setup does not scale very well re the number of daos.
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

        // deploy mocks
        erc1155Mock = new Erc1155Mock();
        erc20VotesMock = new Erc20VotesMock();
        daoMock = new DaoMock();
        constitutionsMock = new ConstitutionsMock();
        foundersMock = new FoundersMock();

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

        // assign tokens to users. Increasing amount coins as we go down the list. 
        for (uint256 i; i < users.length; i++) {
            vm.startPrank(users[i]);
            erc1155Mock.mintCoins((i + 1) * 100);
            erc20VotesMock.mintVotes((i + 1) * 100);
            erc20VotesMock.delegate(users[i]); // users delegate votes to themselves. 
            vm.stopPrank();
        }
        
        // get constitution and founders lists.
        // note: copying structs from memory to storage is not yet supported in solidity. 
        // Hence we need to create a memory variable to store lawsConfig, while laws and allowedRoles are stored in storage.
        ILaw.LawConfig[] memory lawsConfig;
        (            
            laws, 
            allowedRoles, 
            lawsConfig
            ) = constitutionsMock.initiateFourth(
                payable(address(daoMock)), 
                payable(address((erc1155Mock))),
                payable(address((erc20VotesMock)))
                );
        
        (constituentRoles, constituentAccounts) = foundersMock.get(payable(address(daoMock)), users);

        // constitute daoMock.
        daoMock.constitute(
            laws, allowedRoles, lawsConfig,
            constituentRoles, constituentAccounts
        );

        daoNames.push("DaoMock");
    }
}
