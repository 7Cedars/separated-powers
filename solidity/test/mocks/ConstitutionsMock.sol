// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import "forge-std/Test.sol";
import { ISeparatedPowers } from "../../src/interfaces/ISeparatedPowers.sol";
import { Law } from "../../src/Law.sol";
import { ILaw } from "../../src/interfaces/ILaw.sol";
import { Erc1155Mock } from "./Erc1155Mock.sol";
import { DaoMock } from "./DaoMock.sol";
import { BaseSetup } from "../TestSetup.t.sol";

// electoral laws
import { TokensSelect } from "../../src/laws/electoral/TokensSelect.sol";
import { DirectSelect } from "../../src/laws/electoral/DirectSelect.sol";
import { DelegateSelect } from "../../src/laws/electoral/DelegateSelect.sol";
import { RandomlySelect } from "../../src/laws/electoral/RandomlySelect.sol";
import { ElectionCall } from "../../src/laws/electoral/ElectionCall.sol";
import { ElectionTally } from "../../src/laws/electoral/ElectionTally.sol";
// executive laws.
import { ProposalOnly } from "../../src/laws/executive/ProposalOnly.sol";
import { OpenAction } from "../../src/laws/executive/OpenAction.sol";
import { PresetAction } from "../../src/laws/executive/PresetAction.sol";
import { BespokeAction } from "../../src/laws/executive/BespokeAction.sol";
// state laws.
import { StringsArray } from "../../src/laws/state/StringsArray.sol";
import { TokensArray } from "../../src/laws/state/TokensArray.sol";
import { AddressesMapping } from "../../src/laws/state/AddressesMapping.sol";
import { NominateMe } from "../../src/laws/state/NominateMe.sol";
import { PeerVote } from "../../src/laws/state/PeerVote.sol";
// bespoke: aligned dao laws.
import { NftSelfSelect } from "../../src/laws/bespoke/alignedDao/NftSelfSelect.sol";
import { RequestPayment } from "../../src/laws/bespoke/alignedDao/RequestPayment.sol";
import { ReinstateRole } from "../../src/laws/bespoke/alignedDao/ReinstateRole.sol";
import { RevokeMembership } from "../../src/laws/bespoke/alignedDao/RevokeMembership.sol";
// bespoke: diversified grants laws.
import { Grant } from "../../src/laws/bespoke/diversifiedGrants/Grant.sol";
import { StartGrant } from "../../src/laws/bespoke/diversifiedGrants/StartGrant.sol";
import { StopGrant } from "../../src/laws/bespoke/diversifiedGrants/StopGrant.sol";
import { RoleByTaxPaid } from "../../src/laws/bespoke/diversifiedGrants/RoleByTaxPaid.sol";
import { SelfDestructPresetAction } from "../../src/laws/bespoke/diversifiedGrants/SelfDestructPresetAction.sol";
// bespoke: diversified roles laws.
import { RoleByKyc } from "../../src/laws/bespoke/diversifiedRoles/RoleByKyc.sol";
import { AiAgents } from "../../src/laws/bespoke/diversifiedRoles/AiAgents.sol";
import { BespokeActionFactory } from "../../src/laws/bespoke/diversifiedRoles/BespokeActionFactory.sol";
import { Members } from "../../src/laws/bespoke/diversifiedRoles/Members.sol";
import { RoleByKycFactory } from "../../src/laws/bespoke/diversifiedRoles/RoleByKycFactory.sol";

contract ConstitutionsMock is Test {
    //////////////////////////////////////////////////////////////
    //                  FIRST CONSTITUTION                      //
    //////////////////////////////////////////////////////////////
    function initiateSeparatedPowersConstitution(address payable dao_, address payable mock1155_)
        external
        returns (address[] memory laws)
    {
        Law law;
        ILaw.LawConfig memory lawConfig;
        laws = new address[](7);

        // dummy call.
        address[] memory targets = new address[](1);
        uint256[] memory values = new uint256[](1);
        bytes[] memory calldatas = new bytes[](1);
        targets[0] = address(123);
        calldatas[0] = abi.encode("mockCall");

        law = new DirectSelect(
            "1 = open", // max 31 chars
            "Anyone can apply for 1",
            dao_,
            type(uint32).max, // access role
            lawConfig, // empty config file.
            1
        );
        laws[0] = address(law);

        law = new NominateMe(
            "2 nominees", // max 31 chars
            "Anyone can nominate themselves for 2",
            dao_,
            type(uint32).max, // access role
            lawConfig // empty config file.
        );
        laws[1] = address(law);

        law = new TokensSelect(
            "1 elects 2", // max 31 chars
            "1 holders can call (and pay for) a whale election at any time. They can also nominate themselves.",
            dao_,
            1,
            lawConfig, // empty config file.
            // bespoke configs for this law:
            mock1155_,
            laws[1],
            15,
            2
        );
        laws[2] = address(law);

        // Note this proposalOnly law has no internal data, as such it cannot actually do anyting.
        // This law is only for example and testing purposes.
        string[] memory params = new string[](0);
        law = new ProposalOnly(
            "3 makes proposals", // max 31 chars
            "3 holders can make any proposal, without vote.",
            dao_,
            3,
            lawConfig, // empty config file.
            // bespoke configs for this law:
            params
        );
        laws[3] = address(law);

        // setting up config file
        lawConfig.quorum = 20; // = 30% quorum needed
        lawConfig.succeedAt = 66; // = 51% simple majority needed for assigning and revoking members.
        lawConfig.votingPeriod = 1200; // = number of blocks
        lawConfig.needCompleted = laws[2];
        // initiating law.
        law = new OpenAction(
            "2 accepts proposal", // max 31 chars
            "2 holders can vote on and accept proposal proposed by 3.",
            dao_,
            2, // access role
            lawConfig
        );
        // bespoke configs for this law:
        laws[4] = address(law);
        delete lawConfig;

        // setting up config file
        lawConfig.quorum = 30; // = 30% quorum needed
        lawConfig.succeedAt = 51; // = 51% simple majority needed for assigning and revoking members.
        lawConfig.votingPeriod = 1200; // = number of blocks
        // initiating law.
        law = new PresetAction(
            "1 votes on preset action", // max 31 chars
            "1 can vote on executing preset actions",
            dao_,
            1, // access role
            lawConfig, // config file.
            // bespoke configs for this law:
            targets,
            values,
            calldatas
        );
        laws[5] = address(law);
        delete lawConfig;

        (address[] memory targetsRoles, uint256[] memory valuesRoles, bytes[] memory calldatasRoles) = _getRoles(dao_);
        lawConfig.throttleExecution = type(uint48).max - uint48(block.number);
        law = new PresetAction(
            "Admin assigns initial roles",
            "The admin assigns initial roles. This law can only be used once.",
            dao_, // separated powers
            0, // access role = ADMIN
            lawConfig,
            targetsRoles,
            valuesRoles,
            calldatasRoles
        );
        laws[6] = address(law);
        delete lawConfig;
    }

    //////////////////////////////////////////////////////////////
    //                  SECOND CONSTITUTION                     //
    //////////////////////////////////////////////////////////////
    function initiateBasic(address payable dao_, address payable /* mock1155_ */ )
        external
        returns (address[] memory laws)
    {
        laws = new address[](1);

        Law law;
        ILaw.LawConfig memory lawConfig;
        law = new OpenAction(
            "Admin can do anything", // max 31 chars
            "The admin has the power to execute any internal or external action.",
            dao_,
            0, // access role
            lawConfig // empty config file.
                // bespoke configs for this law:
        );
        laws[0] = address(law);
    }

    //////////////////////////////////////////////////////////////
    //                  THIRD CONSTITUTION                     //
    //////////////////////////////////////////////////////////////
    function initiateLawTestConstitution(address payable dao_, address payable mock1155_)
        external
        returns (address[] memory laws)
    {
        Law law;
        laws = new address[](6);

        // dummy call: mint coins at mock1155 contract.
        address[] memory targets = new address[](1);
        uint256[] memory values = new uint256[](1);
        bytes[] memory calldatas = new bytes[](1);
        targets[0] = mock1155_;
        values[0] = 0;
        calldatas[0] = abi.encodeWithSelector(Erc1155Mock.mintCoins.selector, 123);

        // setting up config file
        ILaw.LawConfig memory lawConfig;
        lawConfig.quorum = 20; // = 30% quorum needed
        lawConfig.succeedAt = 66; // = 51% simple majority needed for assigning and revoking members.
        lawConfig.votingPeriod = 1200; // = number of blocks
        // initiating law.
        law = new PresetAction(
            "Needs Proposal Vote", // max 31 chars
            "Needs Proposal Vote to pass",
            dao_,
            1, // access role
            lawConfig, // empty config file.
            // bespoke configs for this law:
            targets,
            values,
            calldatas
        );
        laws[0] = address(law);

        // setting up config file
        delete lawConfig;
        lawConfig.needCompleted = laws[0];
        // initiating law.
        law = new PresetAction(
            "Needs Parent Completed", // max 31 chars
            "Needs Parent Completed to pass",
            dao_,
            1, // access role
            lawConfig, // empty config file.
            // bespoke configs for this law:
            targets,
            values,
            calldatas
        );
        laws[1] = address(law);

        // setting up config file
        delete lawConfig;
        lawConfig.needNotCompleted = laws[0];
        // initiating law.
        law = new PresetAction(
            "Parent Can Block", // max 31 chars
            "Parent can block a law, making it impossible to pass",
            dao_,
            1, // access role
            lawConfig, // empty config file.
            // bespoke configs for this law:
            targets,
            values,
            calldatas
        );
        laws[2] = address(law);

        // setting up config file
        delete lawConfig;
        lawConfig.quorum = 30; // = 30% quorum needed
        lawConfig.succeedAt = 51; // = 51% simple majority needed for assigning and revoking members.
        lawConfig.votingPeriod = 1200; // = number of blocks
        lawConfig.delayExecution = 5000;
        // initiating law.
        law = new PresetAction(
            "Delay Execution", // max 31 chars
            "Delay execution of a law, by a preset number of blocks . ",
            dao_,
            1, // access role
            lawConfig, // empty config file.
            // bespoke configs for this law:
            targets,
            values,
            calldatas
        );
        laws[3] = address(law);

        // setting up config file
        delete lawConfig;
        lawConfig.throttleExecution = 10;
        // initiating law.
        law = new PresetAction(
            "Throttle Executions", // max 31 chars
            "Throttle the number of executions of a by setting minimum time that should have passed since last execution.",
            dao_,
            1, // access role
            lawConfig, // empty config file.
            // bespoke configs for this law:
            targets,
            values,
            calldatas
        );
        laws[4] = address(law);

        // get calldata
        (address[] memory targetsRoles, uint256[] memory valuesRoles, bytes[] memory calldatasRoles) = _getRoles(dao_);
        // set config
        // setting the throttle to max means the law can only be called once.
        lawConfig.throttleExecution = type(uint48).max - uint48(block.number);
        // initiate law
        vm.startBroadcast();
        law = new PresetAction(
            "Admin assigns initial roles",
            "The admin assigns initial roles. This law can only be used once.",
            dao_, // separated powers
            0, // access role = ADMIN
            lawConfig,
            targetsRoles,
            valuesRoles,
            calldatasRoles
        );
        vm.stopBroadcast();
        laws[5] = address(law);
        delete lawConfig;
    }

    //////////////////////////////////////////////////////////////
    //            CONSTITUTION: Electoral Laws                  //
    //////////////////////////////////////////////////////////////
    function initiateElectoralTestConstitution(
        address payable dao_,
        address payable mock1155_,
        address payable mock20Votes_
    ) external returns (address[] memory laws) {
        Law law;
        laws = new address[](13);
        ILaw.LawConfig memory lawConfig;

        // dummy call: mint coins at mock1155 contract.
        address[] memory targets = new address[](1);
        uint256[] memory values = new uint256[](1);
        bytes[] memory calldatas = new bytes[](1);
        targets[0] = mock1155_;
        values[0] = 0;
        calldatas[0] = abi.encodeWithSelector(Erc1155Mock.mintCoins.selector, 123);

        // dummy params
        string[] memory params = new string[](0);

        law = new NominateMe(
            "Nominate for any role", // max 31 chars
            "This is a placeholder nomination law.",
            dao_,
            1, // access role
            lawConfig // empty config file.
                // bespoke configs for this law:
        );
        laws[0] = address(law);

        law = new NominateMe(
            "Nominate for any role", // max 31 chars
            "This is a placeholder nomination law.",
            dao_,
            1, // access role
            lawConfig // empty config file.
                // bespoke configs for this law:
        );
        laws[1] = address(law);

        // electoral laws //
        law = new DirectSelect(
            "Direct select role", // max 31 chars
            "Directly select a role.",
            dao_,
            1, // access role
            lawConfig, // empty config file.
            // bespoke configs for this law:
            3
        );
        laws[2] = address(law);

        law = new RandomlySelect(
            "Randomly select role", // max 31 chars
            "Randomly select a role.",
            dao_,
            1, // access role
            lawConfig, // empty config file.
            // bespoke configs for this law:
            laws[0],
            3, // max role holders
            3 // role id.
        );
        laws[3] = address(law);

        law = new TokensSelect(
            "1 can do anything", // max 31 chars
            "1 holders have the power to execute any internal or external action.",
            dao_,
            1, // access role
            lawConfig, // empty config file.
            // bespoke configs for this law:
            mock1155_,
            laws[0],
            3, // max role holders
            3 // role id.
        );
        laws[4] = address(law);

        law = new DelegateSelect(
            "Delegate Select", // max 31 chars
            "Select a role by delegated votes.",
            dao_,
            1, // access role
            lawConfig, // empty config file.
            // bespoke configs for this law:
            mock20Votes_,
            laws[0], // NominateMe contract.
            3, // max role holders
            3 // role id.
        );
        laws[5] = address(law);

        law = new ElectionTally(
            "Create election tally", // max 31 chars
            "Create a law that will count votes and assign accounts to role 3.",
            dao_,
            1, // access role
            lawConfig, // empty config file.
            // bespoke configs for this law:
            laws[0], // NominateMe contract.
            2, // max role holders
            3 // role id.
        );
        laws[6] = address(law);

        law = new ElectionTally(
            "Create election tally", // max 31 chars
            "Create a law that will count votes and assign accounts to role 3.",
            dao_,
            1, // access role
            lawConfig, // empty config file.
            // bespoke configs for this law:
            laws[0], // NominateMe contract.
            2, // max role holders
            3 // role id.
        );
        laws[7] = address(law);

        law = new PeerVote(
            "Mock PeerVote", // name
            "This is a placeholder PeerVote law.", // description
            dao_, // separated powers protocol.
            1,
            lawConfig,
            laws[0], // NominateMe contract.
            laws[6], // ElectionTally contract.
            50, // startVote
            150 // endVote
        );
        laws[8] = address(law);

        law = new PeerVote(
            "Mock PeerVote", // name
            "This is a placeholder PeerVote law.", // description
            dao_, // separated powers protocol.
            1,
            lawConfig,
            laws[1], // incorrect NominateMe contract.
            laws[6], // ElectionTally contract.
            50, // startVote
            150 // endVote
        );
        laws[9] = address(law);

        law = new PeerVote(
            "Mock PeerVote", // name
            "This is a placeholder PeerVote law.", // description
            dao_, // separated powers protocol.
            1,
            lawConfig,
            laws[0], // NominateMe contract.
            laws[7], // incorrect ElectionTally contract.
            50, // startVote
            150 // endVote
        );
        laws[10] = address(law);

        law = new ElectionCall(
            "Create Election", // max 31 chars
            "Create and call an election for an existing TallyVote law.",
            dao_,
            1, // access role
            lawConfig, // empty config file.
            // bespoke configs for this law:
            2, // voter role id
            laws[0], // NominateMe contract.
            laws[6] // ElectionTally contract.
        );
        laws[11] = address(law);

        // get calldata
        (address[] memory targetsRoles, uint256[] memory valuesRoles, bytes[] memory calldatasRoles) = _getRoles(dao_);
        // set config
        delete lawConfig; // reset lawConfig
        // config
        // setting the throttle to max means the law can only be called once.
        lawConfig.throttleExecution = type(uint48).max - uint48(block.number);
        // initiate law
        vm.startBroadcast();
        law = new PresetAction(
            "Admin assigns initial roles",
            "The admin assigns initial roles. This law can only be used once.",
            dao_, // separated powers
            0, // access role = ADMIN
            lawConfig,
            targetsRoles,
            valuesRoles,
            calldatasRoles
        );
        vm.stopBroadcast();
        laws[12] = address(law);
        delete lawConfig; // reset lawConfig
    }

    //////////////////////////////////////////////////////////////
    //            CONSTITUTION: Executive Laws                  //
    //////////////////////////////////////////////////////////////
    function initiateExecutiveTestConstitution(
        address payable dao_,
        address payable mock1155_,
        address payable mock20Votes_
    ) external returns (address[] memory laws) {
        Law law;
        laws = new address[](5);
        ILaw.LawConfig memory lawConfig;

        // dummy call: mint coins at mock1155 contract.
        address[] memory targets = new address[](1);
        uint256[] memory values = new uint256[](1);
        bytes[] memory calldatas = new bytes[](1);
        targets[0] = mock1155_;
        values[0] = 0;
        calldatas[0] = abi.encodeWithSelector(Erc1155Mock.mintCoins.selector, 123);

        // dummy params
        string[] memory params = new string[](0);

        // setting up config file
        lawConfig.quorum = 30; // = 30% quorum needed
        lawConfig.succeedAt = 51; // = 51% simple majority needed for assigning and revoking members.
        lawConfig.votingPeriod = 1200; // = number of blocks
        // initiating law.
        law = new ProposalOnly(
            "Proposal Only With Vote", // max 31 chars
            "Proposal Only With Vote to pass.",
            dao_,
            1, // access role
            lawConfig, // empty config file.
            // bespoke configs for this law:
            params
        );
        laws[0] = address(law);
        delete lawConfig; // reset lawConfig.

        law = new OpenAction(
            "Open Action", // max 31 chars
            "Execute an action, any action.",
            dao_,
            1, // access role
            lawConfig // empty config file.
                // bespoke configs for this law:
        );
        laws[1] = address(law);

        // need to setup a memory array of bytes4 for setting bespoke params
        string[] memory bespokeParams = new string[](1);
        bespokeParams[0] = "uint256";
        law = new BespokeAction(
            "Bespoke Action", // max 31 chars
            "Execute any action, but confined by a contract and function selector.",
            dao_,
            1, // access role
            lawConfig, // empty config file.
            // bespoke configs for this law:
            mock1155_, // target contract that can be called.
            Erc1155Mock.mintCoins.selector, // the function selector that can be called.
            bespokeParams
        );
        laws[2] = address(law);

        law = new ProposalOnly(
            "Proposal Only", // max 31 chars
            "Proposal Only without vote or other checks.",
            dao_,
            1, // access role
            lawConfig, // empty config file.
            // bespoke configs for this law:
            params
        );
        laws[3] = address(law);

        // get calldata
        (address[] memory targetsRoles, uint256[] memory valuesRoles, bytes[] memory calldatasRoles) = _getRoles(dao_);
        // set config
        delete lawConfig; // reset lawConfig
        // config
        // setting the throttle to max means the law can only be called once.
        lawConfig.throttleExecution = type(uint48).max - uint48(block.number);
        // initiate law
        vm.startBroadcast();
        law = new PresetAction(
            "Admin assigns initial roles",
            "The admin assigns initial roles. This law can only be used once.",
            dao_, // separated powers
            0, // access role = ADMIN
            lawConfig,
            targetsRoles,
            valuesRoles,
            calldatasRoles
        );
        vm.stopBroadcast();
        laws[4] = address(law);
        delete lawConfig; // reset lawConfig
    }

    //////////////////////////////////////////////////////////////
    //                CONSTITUTION: STATE LAWS                  //
    //////////////////////////////////////////////////////////////
    function initiateStateTestConstitution(
        address payable dao_,
        address payable mock1155_,
        address payable mock20Votes_
    ) external returns (address[] memory laws) {
        Law law;
        laws = new address[](6);
        ILaw.LawConfig memory lawConfig;

        // dummy params
        string[] memory params = new string[](0);
        // initiating law.
        law = new AddressesMapping(
            "Free Address Mapping", // max 31 chars
            "Free address mapping without additional checks.",
            dao_,
            1, // access role
            lawConfig // empty config file.
        );
        laws[0] = address(law);

        law = new StringsArray(
            "Free String Array", // max 31 chars
            "Save strings in an array. No additional checks.",
            dao_,
            1, // access role
            lawConfig // empty config file.
        );
        laws[1] = address(law);

        law = new TokensArray(
            "Free token Array", // max 31 chars
            "Save tokens in an array. No additional checks.",
            dao_,
            1, // access role
            lawConfig // empty config file.
        );
        laws[2] = address(law);

        law = new NominateMe(
            "Nominate for any role", // max 31 chars
            "This is a placeholder nomination law.",
            dao_,
            1, // access role
            lawConfig // empty config file.
        );
        laws[3] = address(law);

        law = new PeerVote(
            "Nominate for any role", // max 31 chars
            "This is a placeholder nomination law.",
            dao_,
            1, // access role
            lawConfig, // empty config file.
            // bespoke configs for this law:
            laws[3], // nominate me
            address(123), // tally vote
            50, // start vote in block number
            150 // end vote in block number.
        );
        laws[4] = address(law);

        (address[] memory targetsRoles, uint256[] memory valuesRoles, bytes[] memory calldatasRoles) = _getRoles(dao_);
        lawConfig.throttleExecution = type(uint48).max - uint48(block.number);
        law = new PresetAction(
            "Admin assigns initial roles",
            "The admin assigns initial roles. This law can only be used once.",
            dao_, // separated powers
            0, // access role = ADMIN
            lawConfig,
            targetsRoles,
            valuesRoles,
            calldatasRoles
        );
        laws[5] = address(law);
        delete lawConfig; // reset lawConfig
    }

    //////////////////////////////////////////////////////////////
    //        SIXTH CONSTITUTION: test AlignedGrants            //
    //////////////////////////////////////////////////////////////
    function initiateAlignedDaoTestConstitution(
        address payable dao_,
        address payable mock1155_,
        address payable mock20Votes_,
        address payable mock721_
    ) external returns (address[] memory laws) {
        Law law;
        laws = new address[](4);
        ILaw.LawConfig memory lawConfig;

        // initiating law.
        law = new NftSelfSelect(
            "Claim role", // max 31 chars
            "Claim role 1, conditional on owning an NFT. See asset page for address of ERC721 contract.",
            dao_,
            type(uint32).max, // access role = public.
            lawConfig, // empty config file.
            1,
            mock721_
        );
        laws[0] = address(law);

        law = new RevokeMembership(
            "Membership can be revoked", // max 31 chars
            "Anyone can revoke membership for role 1. This law is unrestricted for this test.",
            dao_,
            1, // access role
            lawConfig, // empty config file.
            mock721_
        );
        laws[1] = address(law);

        law = new ReinstateRole(
            "Reinstate role 1.", // max 31 chars
            "Roles can be reinstated and NFTs returned. Note that this laws usually should be conditional on a needCompleted[RevokeMembership]",
            dao_,
            1, // access role
            lawConfig,
            mock721_
        );
        laws[2] = address(law);
        delete lawConfig;

        law = new RequestPayment(
            "Request preset payment", // max 31 chars
            "Every 100 blocks, role 1 holders can request payment of 5000 ERC1155(0) tokens.",
            dao_,
            1, // access role
            lawConfig, // empty config file.
            mock1155_,
            0, // tokenId
            5000, // amount
            100 // delay
        );
        laws[3] = address(law);
    }

    //////////////////////////////////////////////////////////////
    //      SEVENTH CONSTITUTION: test Diversified Grants       //
    //////////////////////////////////////////////////////////////
    function initiateDiversifiedGrantsTestConstitution(
        address payable dao_,
        address payable mock20Votes_,
        address payable mock20Taxed_,
        address payable mock1155_
    ) external returns (address[] memory laws) {
        Law law;
        laws = new address[](7);
        ILaw.LawConfig memory lawConfig;

        // initiating law.
        law = new Grant(
            "Open Erc1155 Grant", // max 31 chars
            "A test grant that anyone can apply to until it is empty or it expires.",
            dao_,
            type(uint32).max, // access role = public.
            lawConfig, // empty config file.
            // grant config
            2700, // duration
            5000, // budget
            mock1155_, // contract
            Grant.TokenType.ERC1155, // token type
            0 // token id.
        );
        laws[0] = address(law);

        // initiating law.
        law = new Grant(
            "Open Erc20 Grant", // max 31 chars
            "A test grant that anyone can apply to until it is empty or it expires.",
            dao_,
            type(uint32).max, // access role = public.
            lawConfig, // empty config file.
            // grant config
            2700, // duration
            5000, // budget
            mock20Votes_, // contract
            Grant.TokenType.ERC20, // token type
            0 // unused param for ERC20 grants.
        );
        laws[1] = address(law);

        // grant input params.
        string[] memory inputParams = new string[](3);
        inputParams[0] = "address"; // grantee address
        inputParams[1] = "address"; // grant address = address(this). This is needed to make abuse of proposals across contracts impossible.
        inputParams[2] = "uint256"; // quantity to transfer
        // deploy law
        law = new ProposalOnly(
            "Proposals for grant requests", // max 31 chars
            "Here anyone can make a proposal for a grant request.",
            dao_,
            1, // access role
            lawConfig, // empty config file.
            // bespoke configs for this law:
            inputParams
        );
        laws[2] = address(law);

        law = new StartGrant(
            "Start a grant", // max 31 chars
            "Start a grant with a bespoke role restriction, token, budget and duration.",
            dao_,
            2, // access role
            lawConfig, // empty config file.
            // start grant config
            laws[2] // proposals that need to be completed before grant can be considered.
        );
        laws[3] = address(law);

        law = new StopGrant(
            "Stop a grant", // max 31 chars
            "Delete Grant that has either expired or has spent its budget.",
            dao_,
            2, // access role
            lawConfig
        );
        laws[4] = address(law);

        law = new RoleByTaxPaid(
            "(De)select role by tax paid", // max 31 chars
            "(De)select an account for role 3 on the basis of tax paid.",
            dao_,
            2, // access role
            lawConfig,
            3, // role Id to be assigned
            mock20Taxed_,
            100 // threshold tax paid per epoch.
        );
        laws[5] = address(law);

        (address[] memory targetsRoles, uint256[] memory valuesRoles, bytes[] memory calldatasRoles) = _getRoles(dao_);
        law = new SelfDestructPresetAction(
            "Admin assigns initial roles",
            "The admin assigns initial roles. This law will self destruct when used.",
            dao_, // separated powers
            0, // access role = ADMIN
            lawConfig,
            targetsRoles,
            valuesRoles,
            calldatasRoles
        );
        laws[6] = address(law);
        delete lawConfig; // reset lawConfig
    }

    //////////////////////////////////////////////////////////////
    //      EIGHT CONSTITUTION: test Diversified Roles          //
    //////////////////////////////////////////////////////////////
    // £todo

    //////////////////////////////////////////////////////////////
    //                  INTERNAL HELPER FUNCTION                //
    //////////////////////////////////////////////////////////////
    function _getRoles(address payable dao_)
        internal
        returns (address[] memory targets, uint256[] memory values, bytes[] memory calldatas)
    {
        // create addresses.
        address alice = makeAddr("alice");
        address bob = makeAddr("bob");
        address charlotte = makeAddr("charlotte");
        address david = makeAddr("david");
        address eve = makeAddr("eve");
        address frank = makeAddr("frank");
        address gary = makeAddr("gary");
        address helen = makeAddr("helen");

        // call to set initial roles. Also used as dummy call data.
        targets = new address[](12);
        values = new uint256[](12);
        calldatas = new bytes[](12);
        for (uint256 i = 0; i < targets.length; i++) {
            targets[i] = dao_;
        }

        calldatas[0] = abi.encodeWithSelector(ISeparatedPowers.assignRole.selector, 1, alice);
        calldatas[1] = abi.encodeWithSelector(ISeparatedPowers.assignRole.selector, 1, bob);
        calldatas[2] = abi.encodeWithSelector(ISeparatedPowers.assignRole.selector, 1, charlotte);
        calldatas[3] = abi.encodeWithSelector(ISeparatedPowers.assignRole.selector, 1, david);
        calldatas[4] = abi.encodeWithSelector(ISeparatedPowers.assignRole.selector, 1, eve);
        calldatas[5] = abi.encodeWithSelector(ISeparatedPowers.assignRole.selector, 1, frank);
        calldatas[6] = abi.encodeWithSelector(ISeparatedPowers.assignRole.selector, 1, gary);
        calldatas[7] = abi.encodeWithSelector(ISeparatedPowers.assignRole.selector, 2, alice);
        calldatas[8] = abi.encodeWithSelector(ISeparatedPowers.assignRole.selector, 2, bob);
        calldatas[9] = abi.encodeWithSelector(ISeparatedPowers.assignRole.selector, 2, charlotte);
        calldatas[10] = abi.encodeWithSelector(ISeparatedPowers.assignRole.selector, 3, alice);
        calldatas[11] = abi.encodeWithSelector(ISeparatedPowers.assignRole.selector, 3, bob);

        return (targets, values, calldatas);
    }
}
