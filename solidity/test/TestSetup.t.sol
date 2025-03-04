// SPDX-License-Identifier: UNLICENSED
// This setup is an adaptation from the Hats protocol test. See //
pragma solidity ^0.8.13;

import "forge-std/Test.sol";

// protocol
import { Powers} from "../src/Powers.sol";
import { IPowers } from "../src/interfaces/IPowers.sol";
import { Law } from "../src/Law.sol";
import { ILaw } from "../src/interfaces/ILaw.sol";
import { PowersErrors } from "../src/interfaces/PowersErrors.sol";
import { PowersTypes } from "../src/interfaces/PowersTypes.sol";
import { PowersEvents } from "../src/interfaces/PowersEvents.sol";
import { LawErrors } from "../src/interfaces/LawErrors.sol";
import { HelperConfig } from "../script/HelperConfig.s.sol";

// openZeppelin
import { PresetAction } from "../src/laws/executive/PresetAction.sol"; 
import "@openzeppelin/contracts/utils/ShortStrings.sol";

// mocks
import { DaoMock } from "./mocks/DaoMock.sol";
import { Erc1155Mock } from "./mocks/Erc1155Mock.sol";
import { Erc721Mock } from "./mocks/Erc721Mock.sol";
import { Erc20VotesMock } from "./mocks/Erc20VotesMock.sol";
import { Erc20TaxedMock } from "./mocks/Erc20TaxedMock.sol";
import { ConstitutionsMock } from "./mocks/ConstitutionsMock.sol";

// deploy scripts 
import { DeployBasicDao } from "../script/DeployBasicDao.s.sol";
import { DeployAlignedDao } from "../script/DeployAlignedDao.s.sol";
import { DeployGovernYourTax } from "../script/DeployGovernYourTax.s.sol"; 

abstract contract TestVariables is PowersErrors, PowersTypes, PowersEvents, LawErrors {
    // protocol and mocks
    Powers powers;
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
    address ian;
    address jacob;
    address kate;
    address lisa;
    address oracle; 
    address[] users;

    // list of dao names
    string[] daoNames;

    // loop variables.
    uint256 i; 
    uint256 j; 

    mapping (address => uint256) taxPaid;
    mapping (address => uint256) votesReceived;
    mapping (address => bool) hasVoted;    

    // the only event in the Law contract
    event Law__Initialized(
        address indexed law,
        address indexed powers,
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
            Erc20VotesMock(erc20VotesMock).mintVotes(amount);
            Erc20VotesMock(erc20VotesMock).delegate(accounts[i]); // delegate votes to themselves
            vm.stopPrank();
        }
    }

    function distributeNFTs(address erc721Mock, address[] memory accounts, uint256 randomiser, uint256 density) public {
        uint256 currentRandomiser;
        randomiser = bound(randomiser, 10, 100 * 10 ** 18);
        for (uint256 i = 0; i < accounts.length; i++) {
            if (currentRandomiser < 10) {
                currentRandomiser = randomiser;
            } else {
                currentRandomiser = currentRandomiser / 10;
            }
            bool getNft = (currentRandomiser % 100) < density;
            if (getNft) {
                vm.prank(accounts[i]);
                Erc721Mock(erc721Mock).cheatMint(randomiser + i);
            }
        }
    }

    function voteOnProposal(
        address payable dao,
        address law,
        uint256 proposalId,
        address[] memory accounts,
        uint256 randomiser,
        uint256 passChance // in percentage
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
            if (Powers(dao).canCallLaw(accounts[i], law)) {
                roleCount++;
                if (currentRandomiser % 100 >= passChance) {
                    vm.prank(accounts[i]);
                    Powers(dao).castVote(proposalId, 0); // = against
                    againstVote++;
                } else if (currentRandomiser % 100 < passChance) {
                    vm.prank(accounts[i]);
                    Powers(dao).castVote(proposalId, 1); // = for
                    forVote++;
                } else {
                    vm.prank(accounts[i]);
                    Powers(dao).castVote(proposalId, 2); // = abstain
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
        ian = makeAddr("ian");
        jacob = makeAddr("jacob");
        kate = makeAddr("kate");
        lisa = makeAddr("lisa");
        oracle = makeAddr("oracle"); 

        // assign funds
        vm.deal(alice, 10 ether);
        vm.deal(bob, 10 ether);
        vm.deal(charlotte, 10 ether);
        vm.deal(david, 10 ether);
        vm.deal(eve, 10 ether);
        vm.deal(frank, 10 ether);
        vm.deal(gary, 10 ether);
        vm.deal(helen, 10 ether);
        vm.deal(ian, 10 ether);
        vm.deal(jacob, 10 ether);
        vm.deal(kate, 10 ether);
        vm.deal(lisa, 10 ether);
        vm.deal(oracle, 10 ether);

        users = [alice, bob, charlotte, david, eve, frank, gary, helen, ian, jacob, kate, lisa];

        // deploy mocks
        erc1155Mock = new Erc1155Mock();
        erc20VotesMock = new Erc20VotesMock();
        daoMock = new DaoMock();
        constitutionsMock = new ConstitutionsMock();

        vm.startPrank(address(daoMock));
        erc721Mock = new Erc721Mock();
        erc20TaxedMock = new Erc20TaxedMock(
            7, // 7
            100, // denominator works out to 7 percent (7 / 100). 
            100 // duration of epoch = 100 blocks 
        );
        vm.stopPrank();
    }
}

/////////////////////////////////////////////////////////////////////
//                           TEST SETUPS                           //
/////////////////////////////////////////////////////////////////////

abstract contract TestSetupPowers is BaseSetup, ConstitutionsMock {
    function setUpVariables() public override {
        super.setUpVariables();

        // initiate constitution & get founders' roles list
        (address[] memory laws_) = constitutionsMock.initiatePowersConstitution(
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
            payable(address(erc20VotesMock)),
            payable(address(erc20TaxedMock)),
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
        (address[] memory laws_) = constitutionsMock.initiateGovernYourTaxTestConstitution(
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
    Powers basicDao;

    function setUpVariables() public override {
        super.setUpVariables();

        DeployBasicDao deployBasicDao = new DeployBasicDao();
        (
            address payable basicDaoAddress, 
            address[] memory laws_, 
            HelperConfig.NetworkConfig memory config_,
            address mock20_ 
            ) = deployBasicDao.run();
        laws = laws_;
        config = config_;

        erc20VotesMock = Erc20VotesMock(mock20_);  
        basicDao = Powers(basicDaoAddress);
    }
}

abstract contract TestSetupAlignedDao_fuzzIntegration is BaseSetup {
    Powers alignedDao;

    function setUpVariables() public override {
        super.setUpVariables();
        
        DeployAlignedDao deployAlignedDao = new DeployAlignedDao();
        (
            address payable alignedDaoAddress, 
            address[] memory laws_, 
            HelperConfig.NetworkConfig memory config_, 
            address mock20votes_, 
            address mock20taxed_,
            address mock721_ 
            ) = deployAlignedDao.run();
        laws = laws_;
        config = config_;

        erc20VotesMock = Erc20VotesMock(mock20votes_); 
        erc20TaxedMock = Erc20TaxedMock(mock20taxed_); 
        erc721Mock = Erc721Mock(mock721_); 
        alignedDao = Powers(alignedDaoAddress);
    } 
}

abstract contract TestSetupGovernYourTax_fuzzIntegration is BaseSetup {
    Powers governYourTax;

    function setUpVariables() public override {
        super.setUpVariables();

        DeployGovernYourTax deployGovernYourTax = new DeployGovernYourTax();
        (
            address payable governYourTaxAddress, 
            address[] memory laws_, 
            HelperConfig.NetworkConfig memory config_, 
            address mock20Taxed_
            ) = deployGovernYourTax.run();
        laws = laws_;
        config = config_;

        erc20TaxedMock = Erc20TaxedMock(mock20Taxed_); 
        
        governYourTax = Powers(governYourTaxAddress);
    }
}
