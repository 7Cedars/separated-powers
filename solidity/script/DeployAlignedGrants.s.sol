// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import "lib/forge-std/src/Script.sol";

// core protocol
import { SeparatedPowers } from "../src/SeparatedPowers.sol";
import { Law } from "../src/Law.sol";
import { ILaw } from "../src/interfaces/ILaw.sol";
import { SeparatedPowersTypes } from "../src/interfaces/SeparatedPowersTypes.sol";

// laws
import { NominateMe } from "../src/laws/electoral/NominateMe.sol";
import { DelegateSelect } from "../src/laws/electoral/DelegateSelect.sol";
import { DirectSelect } from "../src/laws/electoral/DirectSelect.sol";
import { PeerSelect } from "../src/laws/electoral/PeerSelect.sol";
import { ProposalOnly } from "../src/laws/executive/ProposalOnly.sol";
import { OpenAction } from "../src/laws/executive/OpenAction.sol";
import { PresetAction } from "../src/laws/executive/PresetAction.sol";

// config
import { HelperConfig } from "./HelperConfig.s.sol";

contract DeployAlignedGrants is Script {
  address[] laws;

    function run()
        external
        returns (address payable dao, address[] memory constituentLaws, HelperConfig.NetworkConfig memory config)
    {
        HelperConfig helperConfig = new HelperConfig();
        config = helperConfig.getConfigByChainId(block.chainid);

        // Initiating Dao.
        vm.startBroadcast();
        SeparatedPowers separatedPowers = new SeparatedPowers("Aligned Grants", "");
        vm.stopBroadcast();

        initiateConstitution(
            payable(address(separatedPowers)), payable(config.erc1155Mock), payable(config.erc20VotesMock), payable(config.erc721Mock)
        );

        // constitute dao.
        vm.startBroadcast();
        separatedPowers.constitute(laws);
        vm.stopBroadcast();

        return (payable(address(separatedPowers)), laws, config);
    }

    function initiateConstitution(address payable dao_, address payable mock1155_, address payable mock20_, address payable mock721_, ) public {
        Law law;
        ILaw.LawConfig memory lawConfig;

        //////////////////////////////////////////////////////////////
        //              CHAPTER 1: EXECUTIVE ACTIONS                //
        //////////////////////////////////////////////////////////////
        // setting up config file
        lawConfig.quorum = 60; // = 60% quorum needed
        lawConfig.succeedAt = 50; // = Simple majority vote needed.
        lawConfig.votingPeriod = 1200; // = number of blocks
        // setting up params
        uint8[] memory inputParams = new uint8[](1);
        inputParams[0] = "ShortString";
        // initiating law.
        vm.startBroadcast();
        law = new ProposalOnly(
                "Propose a value",
                "Propose a new value to be added to the Dao. Subject to a vote and cannot be implemented.",
                dao_,
                1, // access role
                lawConfig,
                inputParams // input parameters
            );
        vm.stopBroadcast();
        laws.push(address(law));

        // setting up config file
        delete lawConfig;
        lawConfig.quorum = 30; // = 30% quorum needed
        lawConfig.succeedAt = 66; // =  two/thirds majority needed for
        lawConfig.votingPeriod = 1200; // = number of blocks
        lawConfig.needCompleted = laws[4];
        // initiating law.
        vm.startBroadcast();
        law = new BespokeAction(
                "Accept a value",
                "Accept a proposed value and implement a new value that was proposed.",
                dao_, // separated powers
                2, // access role
                lawConfig,
                // bespoke configs for this law:
                dao_, // target contract
                AlignedGrants.addCoreValue.selector, // function selector
                params // input parameters, same as law4.
            );
        vm.stopBroadcast();
        laws.push(address(law));

        // setting up config file
        delete lawConfig;
        lawConfig.quorum = 80; // = 80% quorum needed
        lawConfig.succeedAt = 66; // =  two/thirds majority needed for
        lawConfig.votingPeriod = 1200; // = number of blocks
        // initiating law
        vm.startBroadcast();
        law = new RevokeRole(
                "Whales -> revoke member", // max 31 chars
                "Subject to a vote, whales can revoke a member's role",
                dao_,
                AlignedGrants(dao_).WHALE_ROLE(), // access role
                lawConfig,
                // bespoke configs for this law:
                AlignedGrants(dao_).MEMBER_ROLE() // 3 // AlignedGrants.MEMBER_ROLE(): the roleId to be revoked.
            );
        vm.stopBroadcast();
        laws.push(address(law));

        // setting up config file
        delete lawConfig;
        lawConfig.needCompleted = laws[6]; // NB! £todo all the law references need to be changed!
        // input params
        inputParams[0] = uint8(uint256(keccak256("address"));
        // initiating law
        vm.startBroadcast();
        law = new ProposalOnly(
                "Member challenge role revoke",
                "A members that had their role revoked can challenge this decision",
                dao_,
                AlignedGrants(dao_).MEMBER_ROLE(), // access role
                lawConfig,
                // bespoke configs for this law:
                params
            );
        vm.stopBroadcast();
        laws.push(address(law));

        // setting up config file
        delete lawConfig;
        lawConfig.quorum = 20; // = 20% quorum needed
        lawConfig.succeedAt = 67; // =  two/thirds majority needed for
        lawConfig.votingPeriod = 1200; // = number of blocks
        lawConfig.needCompleted = laws[7]; // NB! £todo all the law references need to be changed!
        //initiating law
        vm.startBroadcast();
        law = new ReinstateRole(
                "Reinstate member",
                "seniors can reinstated a member after it logged a challenge. This is done through a vote.",
                dao_,
                AlignedGrants(dao_).SENIOR_ROLE(), // access role
                lawConfig,
                // bespoke configs for this law:
                AlignedGrants(dao_).MEMBER_ROLE()
            );
        vm.stopBroadcast();
        laws.push(address(law));

        delete lawConfig;
        vm.startBroadcast();
        law = new RequestPayment(
                "Members request payment",
                "Members can request a payment of 5_000 tokens every 30 days.",
                dao_,
                AlignedGrants(dao_).MEMBER_ROLE(), // access role
                lawConfig, //  config
                // bespoke configs for this law:
                mock1155_, // token address.
                0, // token id
                5_000, // number of tokens
                216_000 // number of blocks = 30 days
            );
        vm.stopBroadcast();
        laws.push(address(law));


        //////////////////////////////////////////////////////////////
        //              CHAPTER 2: ELECT ROLES                      //
        //////////////////////////////////////////////////////////////

        vm.startBroadcast();
        law = new NftSelfSelect(
            "Elect self for role 1", // max 31 chars
            "Anyone who has a mock Erc721 token can (de)select themselves for role 1. See the treasury page for the contract where to mint one.",
            dao_,
            type(uint32).max, // access role = public access
            lawConfig,
            1, // role id
            mock721_
        );
        vm.stopBroadcast();
        laws.push(address(law));

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

        vm.startBroadcast();
        law = new DelegateSelect(
            "Call role 2 election", // max 31 chars
            "An election is called by an oracle, as set by the admin. The nominated accounts with most delegated vote tokens are then assigned to role 2.",
            dao_, // separated powers protocol.
            9, // oracle role id designation. 
            lawConfig, //  config file.
            mock20_, // the tokens that will be used as votes in the election.
            laws[xxx], // nominateMe // 
            5, // maximum amount of delegates
            2 // role id to be assigned
        );
        vm.stopBroadcast();
        laws.push(address(law));
        delete lawConfig;

        
        // setting config.
        lawConfig.quorum = 66; // = Two thirds quorum needed to pass the proposal
        lawConfig.succeedAt = 51; // = 51% simple majority needed for assigning and revoking members.
        lawConfig.votingPeriod = 7200; // = duration in number of blocks to vote, about one day.
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
        delete lawConfig;
}




//         // setting up config file
//         delete lawConfig;
//         lawConfig.quorum = 60; // = 60% quorum needed
//         lawConfig.succeedAt = 50; // = Simple majority vote needed.
//         lawConfig.votingPeriod = 1200; // = number of blocks
//         // setting up params
//         uint8[] memory params = new uint8[](1);
//         inputParams[0] = uint8(uint256(keccak256("ShortString"));
//         // initiating law.
//         vm.startBroadcast();
//         law = new ProposalOnly(
//                 "Members propose value",
//                 "Members can propose a new value to be selected. They cannot implement it.",
//                 dao_,
//                 AlignedGrants(dao_).MEMBER_ROLE(), // access role
//                 lawConfig,
//                 // bespoke configs for this law:
//                 params // input parameters
//             );
//         vm.stopBroadcast();
//         laws.push(address(law));

//         // setting up config file
//         delete lawConfig;
//         lawConfig.quorum = 30; // = 30% quorum needed
//         lawConfig.succeedAt = 66; // =  two/thirds majority needed for
//         lawConfig.votingPeriod = 1200; // = number of blocks
//         lawConfig.needCompleted = laws[4];
//         // initiating law.
//         vm.startBroadcast();
//         law = new BespokeAction(
//                 "Whales accept value",
//                 "Whales can accept and implement a new value that was proposed by members.",
//                 dao_, // separated powers
//                 AlignedGrants(dao_).WHALE_ROLE(), // access role
//                 lawConfig,
//                 // bespoke configs for this law:
//                 dao_, // target contract
//                 AlignedGrants.addCoreValue.selector, // function selector
//                 params // input parameters, same as law4.
//             );
//         vm.stopBroadcast();
//         laws.push(address(law));

//         // setting up config file
//         delete lawConfig;
//         lawConfig.quorum = 80; // = 80% quorum needed
//         lawConfig.succeedAt = 66; // =  two/thirds majority needed for
//         lawConfig.votingPeriod = 1200; // = number of blocks
//         // initiating law
//         vm.startBroadcast();
//         law = new RevokeRole(
//                 "Whales -> revoke member", // max 31 chars
//                 "Subject to a vote, whales can revoke a member's role",
//                 dao_,
//                 AlignedGrants(dao_).WHALE_ROLE(), // access role
//                 lawConfig,
//                 // bespoke configs for this law:
//                 AlignedGrants(dao_).MEMBER_ROLE() // 3 // AlignedGrants.MEMBER_ROLE(): the roleId to be revoked.
//             );
//         vm.stopBroadcast();
//         laws.push(address(law));

//         // setting up config file
//         delete lawConfig;
//         lawConfig.needCompleted = laws[6]; // NB! £todo all the law references need to be changed!
//         // input params
//         inputParams[0] = uint8(uint256(keccak256("address"));
//         // initiating law
//         vm.startBroadcast();
//         law = new ProposalOnly(
//                 "Member challenge role revoke",
//                 "A members that had their role revoked can challenge this decision",
//                 dao_,
//                 AlignedGrants(dao_).MEMBER_ROLE(), // access role
//                 lawConfig,
//                 // bespoke configs for this law:
//                 params
//             );
//         vm.stopBroadcast();
//         laws.push(address(law));

//         // setting up config file
//         delete lawConfig;
//         lawConfig.quorum = 20; // = 20% quorum needed
//         lawConfig.succeedAt = 67; // =  two/thirds majority needed for
//         lawConfig.votingPeriod = 1200; // = number of blocks
//         lawConfig.needCompleted = laws[7]; // NB! £todo all the law references need to be changed!
//         //initiating law
//         vm.startBroadcast();
//         law = new ReinstateRole(
//                 "Reinstate member",
//                 "seniors can reinstated a member after it logged a challenge. This is done through a vote.",
//                 dao_,
//                 AlignedGrants(dao_).SENIOR_ROLE(), // access role
//                 lawConfig,
//                 // bespoke configs for this law:
//                 AlignedGrants(dao_).MEMBER_ROLE()
//             );
//         vm.stopBroadcast();
//         laws.push(address(law));

//         delete lawConfig;
//         vm.startBroadcast();
//         law = new RequestPayment(
//                 "Members request payment",
//                 "Members can request a payment of 5_000 tokens every 30 days.",
//                 dao_,
//                 AlignedGrants(dao_).MEMBER_ROLE(), // access role
//                 lawConfig, //  config
//                 // bespoke configs for this law:
//                 mock1155_, // token address.
//                 0, // token id
//                 5_000, // number of tokens
//                 216_000 // number of blocks = 30 days
//             );
//         vm.stopBroadcast();
//         laws.push(address(law));

//         //////////////////////////////////////////////////////////////////////
//         //            Adding new laws and revoking existing ones            //
//         //////////////////////////////////////////////////////////////////////
//         // setting up config file
//         delete lawConfig;
//         lawConfig.quorum = 40; // = 20% quorum needed
//         lawConfig.succeedAt = 51; // =  two/thirds majority needed for
//         lawConfig.votingPeriod = 1200; // = number of blocks
//         // params
//         inputParams[0] = uint8(uint256(keccak256("address"));
//         // initiating law
//         vm.startBroadcast();
//         law = new ProposalOnly(
//                 "Whales propose laws",
//                 "Whales can propose new laws to be added to the Dao. Subject to a vote.",
//                 dao_,
//                 AlignedGrants(dao_).WHALE_ROLE(), // access role
//                 lawConfig,
//                 // bespoke configs for this law:
//                 params
//             );
//         vm.stopBroadcast();
//         laws.push(address(law));

//         // setting up config file
//         delete lawConfig;
//         lawConfig.quorum = 30; // = 20% quorum needed
//         lawConfig.succeedAt = 67; // =  two/thirds majority needed for
//         lawConfig.votingPeriod = 1200; // = number of blocks
//         lawConfig.needCompleted = laws[10];
//         // initiating law
//         vm.startBroadcast();
//         law = new ProposalOnly(
//                 "Seniors accept laws",
//                 "Seniors can accept laws proposed by whales. Subject to a vote.",
//                 dao_,
//                 AlignedGrants(dao_).SENIOR_ROLE(), // access role
//                 lawConfig,
//                 // bespoke configs for this law:
//                 params // same params as law10
//             );
//         vm.stopBroadcast();
//         laws.push(address(law));

//         delete lawConfig;
//         lawConfig.needCompleted = laws[11];
//         // initiate law
//         vm.startBroadcast();
//         law = new BespokeAction(
//                 "Admin implements laws",
//                 "The admin implements laws proposed by whales and accepted by seniors.",
//                 dao_,
//                 AlignedGrants(dao_).ADMIN_ROLE(), // access role
//                 lawConfig,
//                 // bespoke configs for this law:
//                 dao_,
//                 SeparatedPowers.adoptLaw.selector,
//                 params // same params as law10
//             );
//         vm.stopBroadcast();
//         laws.push(address(law));
//     }

//     function getFounders(address payable dao_) public {
//         AlignedGrants agDao = AlignedGrants(dao_);

//         address anvil_0 = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;
//         address anvil_1 = 0x70997970C51812dc3A010C7d01b50e0d17dc79C8;
//         address anvil_2 = 0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC;
//         address anvil_3 = 0x90F79bf6EB2c4f870365E785982E1f101E93b906;
//         address anvil_4 = 0x15d34AAf54267DB7D7c367839AAf71A00a2C6A65;
//         address anvil_5 = 0x9965507D1a55bcC2695C58ba16FB37d819B0A4dc;

//         constituentAccounts.push(anvil_0);
//         constituentRoles.push(agDao.MEMBER_ROLE());
//         constituentAccounts.push(anvil_1);
//         constituentRoles.push(agDao.MEMBER_ROLE());
//         constituentAccounts.push(anvil_2);
//         constituentRoles.push(agDao.MEMBER_ROLE());
//         constituentAccounts.push(anvil_3);
//         constituentRoles.push(agDao.MEMBER_ROLE());
//         constituentAccounts.push(anvil_4);
//         constituentRoles.push(agDao.MEMBER_ROLE());

//         constituentAccounts.push(anvil_0);
//         constituentRoles.push(agDao.SENIOR_ROLE());
//         constituentAccounts.push(anvil_1);
//         constituentRoles.push(agDao.SENIOR_ROLE());
//         constituentAccounts.push(anvil_2);
//         constituentRoles.push(agDao.SENIOR_ROLE());

//         constituentAccounts.push(anvil_4);
//         constituentRoles.push(agDao.WHALE_ROLE());
//         constituentAccounts.push(anvil_5);
//         constituentRoles.push(agDao.WHALE_ROLE());
//     }
// }
