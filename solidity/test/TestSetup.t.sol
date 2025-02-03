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
import { Erc20TaxedMock } from "./mocks/Erc20TaxedMock.sol";
import { ConstitutionsMock } from "./mocks/ConstitutionsMock.sol";

import { DeployBasicDao } from "../script/DeployBasicDao.s.sol";

abstract contract TestVariables is SeparatedPowersErrors, SeparatedPowersTypes, SeparatedPowersEvents, LawErrors {
    // protocol and mocks
    SeparatedPowers separatedPowers;
    HelperConfig helperConfig;
    DaoMock daoMock;
    ConstitutionsMock constitutionsMock;
    Erc1155Mock erc1155Mock;
    Erc721Mock erc721Mock;
    Erc20VotesMock erc20VotesMock;
    Erc20TaxedMock erc20TaxedMock; 
    HelperConfig.NetworkConfig config;

    address[] laws;

    // vote options
    uint8 AGAINST;
    uint8 FOR;
    uint8 ABSTAIN;
    
    address[] targets; 
    uint256[] values;
    bytes[] calldatas; 
    bytes lawCalldata;
    string description;
    bytes32 descriptionHash;
    uint256 proposalId;

    uint256 roleCount;
    uint256 againstVote;
    uint256 forVote;
    uint256 abstainVote;

    uint8 quorum;
    uint8 succeedAt;
    uint32 votingPeriod;
    address needCompleted;
    address needNotCompleted;
    uint48 delayExecution;
    uint48 throttleExecution;
    bool quorumReached;
    bool voteSucceeded;

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
    event Law__Initialized(
        address indexed law,
        address indexed separatedPowers,
        string name,
        string description,
        uint48 allowedRole,
        ILaw.LawConfig config
    );
}

abstract contract TestHelpers is Test, TestVariables {
    function hashProposal(address targetLaw, bytes memory lawCalldata, bytes32 descriptionHash)
        public
        pure
        virtual
        returns (uint256)
    {
        return uint256(keccak256(abi.encode(targetLaw, lawCalldata, descriptionHash)));
    }

    function distributeTokens(address erc20VoteMock, address[] memory accounts, uint256 randomiser) public {
        uint256 currentRandomiser;
        for (uint256 i = 0; i < accounts.length; i++) {
            if (currentRandomiser < 10) {
                currentRandomiser = randomiser;
            } else {
                currentRandomiser = currentRandomiser / 10;
            }
            uint256 amount = (currentRandomiser % 10_000) + 1;
            vm.startPrank(accounts[i]);
            Erc20VotesMock(config.erc20VotesMock).mintVotes(amount);
            Erc20VotesMock(config.erc20VotesMock).delegate(accounts[i]); // delegate votes to themselves
            vm.stopPrank();
        }
    }

    function voteOnProposal(
        address payable dao,
        address law,
        uint256 proposalId,
        address[] memory accounts,
        uint256 randomiser,
        uint256 quorumPassChance, // in percentage
        uint256 successPassChance // in percentage
    ) public returns (uint256 roleCount, uint256 againstVote, uint256 forVote, uint256 abstainVote) {
        uint256 currentRandomiser;
        for (uint256 i = 0; i < accounts.length; i++) {
            // set randomiser..
            if (currentRandomiser < 10) {
                currentRandomiser = randomiser;
            } else {
                currentRandomiser = currentRandomiser / 10;
            }
            // vote
            if (SeparatedPowers(dao).canCallLaw(accounts[i], law)) {
                roleCount++;
                if (currentRandomiser % 100 < quorumPassChance && currentRandomiser % 100 < successPassChance) {
                    vm.prank(accounts[i]);
                    SeparatedPowers(dao).castVote(proposalId, 0); // = against
                    againstVote++;
                } else if (currentRandomiser % 100 < quorumPassChance && currentRandomiser % 100 >= successPassChance) {
                    vm.prank(accounts[i]);
                    SeparatedPowers(dao).castVote(proposalId, 1); // = for
                    forVote++;
                } else {
                    vm.prank(accounts[i]);
                    SeparatedPowers(dao).castVote(proposalId, 2); // = abstain
                    abstainVote++;
                }
            }
        }
    }
}

abstract contract BaseSetup is TestVariables, TestHelpers {
    function setUp() public virtual {
        vm.roll(block.number + 10);
        setUpVariables();
    }

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

        vm.startPrank(address(daoMock));
        erc721Mock = new Erc721Mock();
        erc20TaxedMock = new Erc20TaxedMock(
            7, // 7
            2, // decimals. Tax works out to 7 percent. ( 7 / 100) 
            100 // duration of epoch = 100 blocks 
        );
        vm.stopPrank();
    }
}

/////////////////////////////////////////////////////////////////////
//                           TEST SETUPS                           //
/////////////////////////////////////////////////////////////////////

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

abstract contract TestSetupElectoral is BaseSetup, ConstitutionsMock {
    function setUpVariables() public override {
        super.setUpVariables();

        // initiate constitution & get founders' roles list
        (address[] memory laws_) = constitutionsMock.initiateElectoralTestConstitution(
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

abstract contract TestSetupExecutive is BaseSetup, ConstitutionsMock {
    function setUpVariables() public override {
        super.setUpVariables();

        // initiate constitution & get founders' roles list
        (address[] memory laws_) = constitutionsMock.initiateExecutiveTestConstitution(
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

abstract contract TestSetupState is BaseSetup, ConstitutionsMock {
    function setUpVariables() public override {
        super.setUpVariables();

        // initiate constitution & get founders' roles list
        (address[] memory laws_) = constitutionsMock.initiateStateTestConstitution(
            payable(address(daoMock)), payable(address(erc1155Mock)), payable(address(erc20VotesMock))
        );
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

abstract contract TestSetupAlignedDao is BaseSetup, ConstitutionsMock {
    function setUpVariables() public override {
        super.setUpVariables();

        // initiate constitution & get founders' roles list
        (address[] memory laws_) = constitutionsMock.initiateAlignedDaoTestConstitution(
            payable(address(daoMock)),
            payable(address(erc1155Mock)),
            payable(address(erc20VotesMock)),
            payable(address(erc721Mock))
        );
        laws = laws_;

        // constitute daoMock.
        daoMock.constitute(laws);
        daoNames.push("AlignedDao");
    }
}

abstract contract TestSetupDiversifiedGrants is BaseSetup, ConstitutionsMock {
    function setUpVariables() public override {
        super.setUpVariables();

        // initiate constitution & get founders' roles list
        (address[] memory laws_) = constitutionsMock.initiateDiversifiedGrantsTestConstitution(
            payable(address(daoMock)), 
            payable(address(erc20VotesMock)),  
            payable(address(erc20TaxedMock)),  
            payable(address(erc1155Mock))
        );
        laws = laws_;

        // constitute daoMock.
        daoMock.constitute(laws);
        daoNames.push("DiversifiedGrants");
    }
}

abstract contract TestSetupBasicDao_fuzzIntegration is BaseSetup {
    SeparatedPowers basicDao;

    function setUpVariables() public override {
        super.setUpVariables();

        DeployBasicDao deployBasicDao = new DeployBasicDao();
        (address payable basicDaoAddress, address[] memory laws_, HelperConfig.NetworkConfig memory config_) =
            deployBasicDao.run();
        laws = laws_;
        config = config_;
        basicDao = SeparatedPowers(basicDaoAddress);
    }
}
