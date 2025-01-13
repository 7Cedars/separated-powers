// // SPDX-License-Identifier: MIT
// pragma solidity 0.8.26;

// import { Script, console, console2 } from "lib/forge-std/src/Script.sol";

// // core contracts
// import { SeparatedPowers } from "../src/SeparatedPowers.sol";
// import { Law } from "../src/Law.sol";
// import { ILaw } from "../src/interfaces/ILaw.sol";
// import { Erc1155Mock } from "../test/mocks/Erc1155Mock.sol";
// // dao
// import { AlignedGrants } from "../src/daos/AlignedGrants.sol";
// import { HelperConfig } from "./HelperConfig.s.sol";

// // laws
// import { DirectSelect } from "../src/laws/electoral/DirectSelect.sol";
// import { DelegateSelect } from "../src/laws/electoral/DelegateSelect.sol";
// import { RandomlySelect } from "../src/laws/electoral/RandomlySelect.sol";
// import { TokensSelect } from "../src/laws/electoral/TokensSelect.sol";
// import { NominateMe } from "../src/laws/electoral/NominateMe.sol";

// import { ProposalOnly } from "../src/laws/executive/ProposalOnly.sol";
// import { OpenAction } from "../src/laws/executive/OpenAction.sol";
// import { PresetAction } from "../src/laws/executive/PresetAction.sol";
// import { BespokeAction } from "../src/laws/executive/BespokeAction.sol";

// import { ReinstateRole } from "../src/laws/bespoke/ReinstateRole.sol";
// import { RevokeRole } from "../src/laws/bespoke/RevokeRole.sol";
// import { RequestPayment } from "../src/laws/bespoke/RequestPayment.sol";

// contract DeployAlignedGrants is Script {
//     address[] laws;
//     uint32[] constituentRoles;
//     address[] constituentAccounts;

//     function run() external {
//         HelperConfig helperConfig = new HelperConfig();
//         HelperConfig.NetworkConfig memory config = helperConfig.getConfigByChainId(block.chainid);

//         // deploy dao.
//         vm.startBroadcast();
//         AlignedGrants alignedGrants = new SeparatedPowers("Aligned Grants DAO");
//         vm.stopBroadcast();

//         // initiate constitution & get founders' roles list
//         initiateConstitution(payable(address(alignedGrants)), payable(config.erc1155Mock));
//         getFounders(payable(address(alignedGrants)));

//         // constitute dao.
//         vm.startBroadcast();
//         alignedGrants.constitute(laws);
//         vm.stopBroadcast();
//     }

//     function initiateConstitution(address payable dao_, address payable mock1155_) public {
//         Law law;
//         ILaw.LawConfig memory lawConfig;

//         //////////////////////////////////////////////////////////////
//         //              CHAPTER 1: ELECT ROLES                      //
//         //////////////////////////////////////////////////////////////

//         vm.startBroadcast();
//         law = new DirectSelect(
//                 "Anyone can become member", // max 31 chars
//                 "Anyone can apply for a member role in the Aligned Grants Dao",
//                 dao_,
//                 type(uint32).max, // access role
//                 lawConfig, //  config file.
//                 // bespoke configs for this law:
//                 AlignedGrants(dao_).MEMBER_ROLE()
//             );
//         vm.stopBroadcast();
//         laws.push(address(law));

//         vm.startBroadcast();
//         law = new NominateMe(
//                 "Nominees for WHALE_ROLE", // max 31 chars
//                 "Anyone can nominate themselves for a role WHALE_ROLE",
//                 dao_,
//                 type(uint32).max, // access role
//                 lawConfig
//             );
//         vm.stopBroadcast();
//         laws.push(address(law));

//         vm.startBroadcast();
//         law = new TokensSelect(
//                 "Members select WHALE_ROLE", // max 31 chars
//                 "Members can call (and pay for) a whale election at any time. The nominated accounts with most tokens will be assigned the role.",
//                 dao_,
//                 AlignedGrants(dao_).MEMBER_ROLE(), // access role
//                 lawConfig, //  config file.
//                 // bespoke configs:
//                 mock1155_,
//                 laws[1],
//                 15,
//                 AlignedGrants(dao_).WHALE_ROLE() // 2 // AlignedGrants.WHALE_ROLE()
//             );
//         vm.stopBroadcast();
//         laws.push(address(law));

//         // setting up config file
//         lawConfig.quorum = 30; // = 30% quorum needed
//         lawConfig.succeedAt = 51; // = 51% simple majority needed for assigning and revoking members.
//         lawConfig.votingPeriod = 1200; // = number of blocks
//         // initiating law.
//         vm.startBroadcast();
//         law = new DirectSelect(
//                 "Seniors elect seniors", // max 31 chars
//                 "Seniors can propose and vote to (de)select an account for the SENIOR_ROLE.",
//                 dao_,
//                 AlignedGrants(dao_).SENIOR_ROLE(), // access role
//                 lawConfig,
//                 // bespoke configs for this law:
//                 AlignedGrants(dao_).SENIOR_ROLE() // 1 // AlignedGrants.SENIOR_ROLE()
//             );
//         vm.stopBroadcast();
//         laws.push(address(law));

//         //////////////////////////////////////////////////////////////
//         //              CHAPTER 2: EXECUTIVE ACTIONS                //
//         //////////////////////////////////////////////////////////////

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
