// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import "lib/forge-std/src/Script.sol";

// core protocol
import { Powers} from "../src/Powers.sol";
import { Law } from "../src/Law.sol";
import { ILaw } from "../src/interfaces/ILaw.sol";
import { PowersTypes } from "../src/interfaces/PowersTypes.sol";

// config
import { HelperConfig } from "./HelperConfig.s.sol";

// laws
import { NominateMe } from "../src/laws/state/NominateMe.sol"; 
import { DelegateSelect } from "../src/laws/electoral/DelegateSelect.sol";
import { DirectSelect } from "../src/laws/electoral/DirectSelect.sol";
import { PeerSelect } from "../src/laws/electoral/PeerSelect.sol";
import { ElectionTally } from "../src/laws/electoral/ElectionTally.sol";
import { ElectionCall } from "../src/laws/electoral/ElectionCall.sol";
import { ProposalOnly } from "../src/laws/executive/ProposalOnly.sol";
import { BespokeAction } from "../src/laws/executive/BespokeAction.sol";
import { PresetAction } from "../src/laws/executive/PresetAction.sol";
import { Grant } from "../src/laws/bespoke/diversifiedGrants/Grant.sol";
import { StartGrant } from "../src/laws/bespoke/diversifiedGrants/StartGrant.sol";
import { StopGrant } from "../src/laws/bespoke/diversifiedGrants/StopGrant.sol";
import { SelfDestructPresetAction } from "../src/laws/bespoke/diversifiedGrants/SelfDestructPresetAction.sol";
import { RoleByTaxPaid } from "../src/laws/bespoke/diversifiedGrants/RoleByTaxPaid.sol";
// borrowing one law from another bespoke folder. Not ideal, but ok for now.
import { NftSelfSelect } from "../src/laws/bespoke/alignedDao/NftSelfSelect.sol";

// mocks 
import { Erc20VotesMock } from "../test/mocks/Erc20VotesMock.sol";
import { Erc20TaxedMock } from "../test/mocks/Erc20TaxedMock.sol";
import { Erc721Mock } from "../test/mocks/Erc721Mock.sol";
import { Erc1155Mock } from "../test/mocks/Erc1155Mock.sol";

contract DeployGovernYourTax is Script {
    address[] laws;

    function run()
        external
        returns (
            address payable dao, 
            address[] memory constituentLaws, 
            HelperConfig.NetworkConfig memory config, 
            address payable mock20Taxed_
            )
    {
        HelperConfig helperConfig = new HelperConfig();
        config = helperConfig.getConfigByChainId(block.chainid);

        vm.startBroadcast();
        Powers powers = new Powers(
            "Govern Your Tax", 
            "https://aqua-famous-sailfish-288.mypinata.cloud/ipfs/bafkreid7bb6jueiqjn4mpkcy5ob7w6ulksfntobbwbn4feehvzjwe3tufe");
        Erc20TaxedMock erc20TaxedMock = new Erc20TaxedMock(
            7, // rate
            100, // denominator  
            7200 // 7% tax, (tax = 7, denominator = 2),  7200 block epoch, about one day. 
        );
        vm.stopBroadcast();

        dao = payable(address(powers));
        mock20Taxed_ = payable(address(erc20TaxedMock)); 
        initiateConstitution(dao, mock20Taxed_);

        // // constitute dao.
        vm.startBroadcast();
        powers.constitute(laws);
        // // transferring ownership of erc721 and erc20Taxed token contracts.. 
        erc20TaxedMock.transferOwnership(address(powers));
        vm.stopBroadcast();

        return (dao, laws, config, mock20Taxed_);
    }

    function initiateConstitution(
        address payable dao_,
        address payable mock20Taxed_
    ) public {
        Law law;
        ILaw.LawConfig memory lawConfig;

        //////////////////////////////////////////////////////////////
        //              CHAPTER 1: EXECUTIVE ACTIONS                //
        //////////////////////////////////////////////////////////////
        // laws[0]
        lawConfig.quorum = 60; // = 60% quorum needed
        lawConfig.succeedAt = 50; // = Simple majority vote needed.
        lawConfig.votingPeriod = 150; // = number of blocks (about half an hour) 
        // setting up params
        string[] memory inputParams = new string[](3);
        inputParams[0] = "address Grantee"; // grantee
        inputParams[1] = "address Grant"; // grant Law address
        inputParams[2] = "uint256 Quantity"; // amount
        // initiating law.
        vm.startBroadcast();
        // Note: the grant has its token pre specified.
        law = new ProposalOnly(
            "Make a proposal to a grant.",
            "Make a grant proposal that will be voted on by community members. It has to specify the grant address in the proposal. Input [0] = grantee address to transfer to. input[1] = grant address to transfer from.  input[2] =  quantity to transfer of token.",
            dao_,
            1, // access role
            lawConfig,
            inputParams // input parameters
        );
        vm.stopBroadcast();
        laws.push(address(law));
        delete lawConfig;

        // laws[1]
        lawConfig.quorum = 80; // = 80% quorum needed
        lawConfig.succeedAt = 66; // =  two/thirds majority needed for
        lawConfig.votingPeriod = 150; // = number of blocks (about half an hour) 
        // initiating law
        vm.startBroadcast();
        law = new StartGrant(
            "Create a grant", // max 31 chars
            "Subject to a vote, a grant can be created. The token, budget and duration are pre-specified, as well as the role Id that will govern the grant.",
            dao_, // separated powers
            2, // access role
            lawConfig, // bespoke configs for this law.
            laws[0] // law from where proposals need to be made.
        );
        vm.stopBroadcast();
        laws.push(address(law));
        delete lawConfig;

        // laws[2]
        // initiating law
        vm.startBroadcast();
        law = new StopGrant(
            "Stop a grant", // max 31 chars
            "When a grant's budget is spent, or the grant is expired, it can be stopped.",
            dao_, // separated powers
            2, // access role
            lawConfig // bespoke configs for this law.
        );
        vm.stopBroadcast();
        laws.push(address(law));
        delete lawConfig;

        // laws[3]
        lawConfig.quorum = 40; // = 40% quorum needed
        lawConfig.succeedAt = 80; // =  80 majority needed
        lawConfig.votingPeriod = 150; // = number of blocks (about half an hour) 
        // input params
        inputParams = new string[](1);
        inputParams[0] = "address Law";
        // initiating law.
        vm.startBroadcast();
        law = new BespokeAction(
            "Stop law",
            "The security Council can stop any active law.",
            dao_, // separated powers
            3, // access role
            lawConfig, // bespoke configs for this law
            dao_,
            Powers.revokeLaw.selector,
            inputParams
        );
        vm.stopBroadcast();
        laws.push(address(law));
        delete lawConfig;

        // laws[4]
        lawConfig.quorum = 50; // = 50% quorum needed
        lawConfig.succeedAt = 66; // =  two/thirds majority needed for
        lawConfig.votingPeriod = 150; // = number of blocks (about half an hour) 
        lawConfig.needCompleted = laws[3]; // NB! first a law needs to be stopped before it can be restarted!
        // This does mean that the reason given needs to be the same as when the law was stopped.
        // initiating law.
        vm.startBroadcast();
        law = new BespokeAction(
            "Restart law",
            "The security Council can restart a law. They can only restart a law that they themselves stopped.",
            dao_, // separated powers
            3, // access role
            lawConfig, // bespoke configs for this law
            dao_,
            Powers.adoptLaw.selector,
            inputParams // note: same inputParams as laws [2]
        );
        vm.stopBroadcast();
        laws.push(address(law));
        delete lawConfig;

        // laws[5]
        // mint tokens 
        lawConfig.quorum = 67; // = two-thirds quorum needed
        lawConfig.succeedAt = 67; // =  two/thirds majority needed for
        lawConfig.votingPeriod = 150; // = number of blocks (about half an hour) 
        // bespoke inputParams 
        inputParams = new string[](1);
        inputParams[0] = "uint256 Quantity"; // number of tokens to mint. 
        vm.startBroadcast();
        law = new BespokeAction(
            "Mint tokens",
            "Governors can decide to mint tokens.",
            dao_, // separated powers
            2, // access role
            lawConfig, // bespoke configs for this law
            mock20Taxed_,
            Erc20TaxedMock.mint.selector,
            inputParams  
        );
        vm.stopBroadcast();
        laws.push(address(law));

        // laws[6]
        // burn token 
        vm.startBroadcast();
        law = new BespokeAction(
            "Burn tokens",
            "Governors can decide to burn tokens.",
            dao_, // separated powers
            2, // access role
            lawConfig, // same lawConfig as laws[5] 
            mock20Taxed_,
            Erc20TaxedMock.burn.selector,
            inputParams // same lawConfig as laws[5]
        );
        vm.stopBroadcast();
        laws.push(address(law));
        delete lawConfig; // here we delete lawConfig. 

        //////////////////////////////////////////////////////////////
        //              CHAPTER 2: ELECT ROLES                      //
        //////////////////////////////////////////////////////////////
        // laws[7]
        vm.startBroadcast();
        law = new RoleByTaxPaid(
            "Elect self for role 1", // max 31 chars
            "Anyone who has paid sufficient tax (by using the Dao's ERC20 token) can claim a role 1. The threshold is 100MCK tokens per 100 blocks.",
            dao_,
            type(uint32).max, // access role = public access
            lawConfig,
            1, // role id
            mock20Taxed_,
            100 // have to see if this is a fair amount.
        );
        vm.stopBroadcast();
        laws.push(address(law));

        // laws[8]
        vm.startBroadcast();
        law = new NominateMe(
            "Nominate self for role 2", // max 31 chars
            "Anyone can nominate themselves for role 2.",
            dao_,
            type(uint32).max, // access role = public access
            lawConfig
        );
        vm.stopBroadcast();
        laws.push(address(law));

        // laws[9]
        vm.startBroadcast();
        law = new ElectionTally(
            "Tally role 2 election", // max 31 chars
            "Tally elections for role 2.",
            dao_, // separated powers protocol.
            1, // Note: any community member can tally the election. It can only be done after election duration has finished.
            lawConfig, //  config file.
            // bespoke configs for this law:
            laws[8], // law where nominations are made.
            3, // max role holders,
            3 // role id that is elected
        );
        vm.stopBroadcast();
        laws.push(address(law));
        delete lawConfig;

        // laws[10]
        vm.startBroadcast();
        law = new ElectionCall(
            "Call role 2 election", // max 31 chars
            "An election is called by an oracle, as set by the admin. The nominated accounts with most votes from role 1 holders are then assigned to role 2.",
            dao_, // separated powers protocol.
            9, // oracle role id designation.
            lawConfig, //  config file.
            // bespoke configs for this law:
            2, // role id that is allowed to vote.
            laws[8], // law where nominations are made.
            laws[9] // law where votes are tallied.
        );
        vm.stopBroadcast();
        laws.push(address(law));
        delete lawConfig;

        // laws[11]
        vm.startBroadcast();
        law = new NominateMe(
            "Nominate self for role 3", // max 31 chars
            "Nominate yourself for role 3.",
            dao_,
            1, // access role = 1
            lawConfig
        );
        vm.stopBroadcast();
        laws.push(address(law));

        // laws[12]: security council: peer select. - role 3
        lawConfig.quorum = 66; // = Two thirds quorum needed to pass the proposal
        lawConfig.succeedAt = 51; // = 51% simple majority needed for assigning and revoking members.
        lawConfig.votingPeriod = 150; // = number of blocks (about half an hour) 
        lawConfig.readStateFrom = laws[11]; // nominateMe
        //
        vm.startBroadcast();
        law = new PeerSelect(
            "Assign Role 3", // max 31 chars
            "Role 3 are assigned by their peers through a majority vote.",
            dao_, // separated powers protocol.
            3, // role 3 id designation.
            lawConfig, //  config file.
            3, // maximum elected to role 
            3 // role id to be assigned
        );
        vm.stopBroadcast();
        laws.push(address(law));
        delete lawConfig;

        // laws[13]: elect and revoke members to grant council A -- governance council votes.
        // lawConfig is for next three laws
        lawConfig.quorum = 70; // = 70% quorum needed
        lawConfig.succeedAt = 51; // =  simple majority sufficient
        lawConfig.votingPeriod = 150; // = number of blocks (about half an hour) 
        vm.startBroadcast();
        law = new DirectSelect(
            "Elect and revoke role 4", // max 31 chars
            "Elect and revoke members for role 4 (Grant council A)",
            dao_, // separated powers protocol.
            2, // governors.
            lawConfig, //  config file.
            4 // role id to be assigned
        );
        vm.stopBroadcast();
        laws.push(address(law));

        // laws[14]: elect and revoke members to grant council B -- governance council votes.
        vm.startBroadcast();
        law = new DirectSelect(
            "Elect and revoke role 5", // max 31 chars
            "Elect and revoke members for role 5 (Grant council B)",
            dao_, // separated powers protocol.
            2, // governors.
            lawConfig, //  config file. // same as law[9]
            5 // role id to be assigned
        );
        vm.stopBroadcast();
        laws.push(address(law));

        // laws[15]: elect and revoke members to grant council C -- governance council votes.
        vm.startBroadcast();
        law = new DirectSelect(
            "Elect and revoke role 6", // max 31 chars
            "Elect and revoke members for role 6 (Grant council C)",
            dao_, // separated powers protocol.
            2, // governors.
            lawConfig, //  config file. // same as law[9]
            6 // role id to be assigned
        );
        vm.stopBroadcast();
        laws.push(address(law));
        delete lawConfig; // here we delete the law config
        // note at the moment not possible to resign form these roles. In reality there should be a law that allows for resignations.
        
        // laws[16]
        vm.startBroadcast();
        law = new DirectSelect(
            "Set Oracle", // max 31 chars
            "The admin selects accounts for role 9, the oracle role.",
            dao_, // separated powers protocol.
            0, // admin.
            lawConfig, //  config file.
            9 // role id to be assigned
        );
        vm.stopBroadcast();
        laws.push(address(law));

        // laws[17]: selfDestructPresetAction: assign initial accounts to security council.
        address[] memory targets = new address[](3);
        uint256[] memory values = new uint256[](3);
        bytes[] memory calldatas = new bytes[](3);
        for (uint256 i = 0; i < targets.length; i++) {
            targets[i] = dao_;
        }
        calldatas[0] = abi.encodeWithSelector(
          Powers.assignRole.selector, 
          3, 
          0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266
        );
        calldatas[1] = abi.encodeWithSelector(
          Powers.assignRole.selector, 
          3, 
          0x70997970C51812dc3A010C7d01b50e0d17dc79C8
        );
        calldatas[2] = abi.encodeWithSelector(
          Powers.assignRole.selector, 
          3, 
          0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC
        );
        vm.startBroadcast();
        law = new SelfDestructPresetAction(
            "Set initial roles 3", // max 31 chars
            "The admin selects initial accounts for role 3. The law self destructs when executed.",
            dao_, // separated powers protocol.
            0, // admin.
            lawConfig, //  config file.
            targets,
            values,
            calldatas
        );
        vm.stopBroadcast();
        laws.push(address(law));
    }
}
