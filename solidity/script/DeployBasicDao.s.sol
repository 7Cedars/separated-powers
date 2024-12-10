// // SPDX-License-Identifier: MIT
// pragma solidity 0.8.26;

// import { Script, console2 } from "lib/forge-std/src/Script.sol";

// // core contracts
// import { SeparatedPowers } from "../src/SeparatedPowers.sol";
// import { Law } from "../src/Law.sol";
// import { ILaw } from "../src/interfaces/ILaw.sol";
// import { SeparatedPowersTypes } from "../src/interfaces/SeparatedPowersTypes.sol";
// import { Erc20VotesMock } from "../test/mocks/Erc20VotesMock.sol";

// contract DeployBasicDao is Script {
//     /* Functions */
//     function run(Erc20VotesMock erc20VotesMock)
//         external
//         returns (
//             SeparatedPowers basicDao,
//             address[] memory laws,
//             uint32[] memory allowedRoles,
//             ILaw.LawConfig[] memory lawConfigs,
//             uint32[] memory constituentRoles,
//             address[] memory constituentAccounts
//         )
//     {
//         // initiating Constitution and Founders contracts.
//         Constitution constitution = new Constitution();
//         Founders founders = new Founders();

//         // Deploying contracts.
//         vm.startBroadcast();
//         basicDao = new SeparatedPowers("basicDao");

//         (laws, allowedRoles, lawConfigs) = constitution.initiate(
//             payable(address(basicDao)), payable(address((erc20VotesMock)))
//         );

//         (constituentRoles, constituentAccounts) = founders.get();

//         basicDao.constitute(
//             laws, allowedRoles, lawConfigs, constituentRoles, constituentAccounts
//         );
//         vm.stopBroadcast();

//         return (
//             basicDao, laws, allowedRoles, lawConfigs, constituentRoles, constituentAccounts
//         );
//     }
// }

///////////////////////////////////////////////////////////////////////////////////////////

// contract Constitution {
//     uint32 constant NUMBER_OF_LAWS = 6;

//     function initiate(address payable dao_, address payable mockErc20Votes_)
//         external
//         returns (
//             address[] memory laws,
//             uint32[] memory allowedRoles,
//             ILaw.LawConfig[] memory lawConfigs
//         )
//     {
//         laws = new address[](NUMBER_OF_LAWS);
//         allowedRoles = new uint32[](NUMBER_OF_LAWS);
//         lawConfigs = new ILaw.LawConfig[](NUMBER_OF_LAWS);

//     //////////////////////////////////////////////////////////////
//     //              CHAPTER 1: ELECT ROLES                      //
//     //////////////////////////////////////////////////////////////
//     laws[0] = address(
//         new NominateMe(
//             "Nominees for DELEGATE_ROLE", // max 31 chars
//             "Anyone can nominate themselves for a WHALE_ROLE",
//             dao_
//         )
//     );
//     allowedRoles[1] = type(uint32).max;

//     laws[1] = address(
//         new DelegateSelect(
//             "Anyone can elect delegates", // max 31 chars
//             "Anyone can call (and pay for) a delegate election at any time. The nominated accounts with most delegated vote tokens will be assigned the DELEGATE_ROLE.",
//             dao_, // separated powers protocol.
//             mockErc20Votes_, // the tokens that will be used as votes in the election.
//             laws[0], // nominateMe
//             25,
//             2
//         )
//     );
//     allowedRoles[1] = SeparatedPowers(dao_).PUBLIC_ROLE(); // anyone can call for an election at any time.

//     laws[2] = address(
//         new DirectSelect(
//             "Seniors elect seniors", // max 31 chars
//             "Seniors can propose and vote to (de)select an account for the SENIOR_ROLE.",
//             dao_,
//             1
//         )
//     );
//     allowedRoles[2] = 1;
//     lawConfigs[2].quorum = 20; // = Only 20% quorum needed
//     lawConfigs[2].succeedAt = 66; // = but at least 2/3 majority needed for assigning and revoking members.
//     lawConfigs[2].votingPeriod = 1200; // = number of blocks
//     // note: there is no maximum or minimum number of seniors. But at least one senior NEEDS TO BE ELECTED THROUGH CONSTITUTION OF THE DAO. Otherwise it will never be possible to elect seniors.

//     //////////////////////////////////////////////////////////////
//     //              CHAPTER 2: EXECUTIVE ACTIONS                //
//     //////////////////////////////////////////////////////////////

//     // note: no guardrails on the parameters of the action. Anything can be proposed.
//     bytes4[] memory paramsAction = new bytes4[](3);
//     paramsAction[0] = bytes4(keccak256("address[]")); // targets
//     paramsAction[1] = bytes4(keccak256("uint256[]")); // values
//     paramsAction[2] = bytes4(keccak256("bytes[]")); // calldatas

//     laws[3] = address(
//         new ProposalOnly(
//             "Delegates propose actions",
//             "Delegates can propose new actions to be executed. They cannot implement it.",
//             dao_,
//             paramsAction
//         )
//     );
//     allowedRoles[3] = 2;
//     lawConfigs[3].quorum = 66; // = Two thirds quorum needed to pass the proposal
//     lawConfigs[3].succeedAt = 51; // = 51% simple majority needed for assigning and revoking members.
//     lawConfigs[3].votingPeriod = 50400; // = duration in number of blocks to vote, about one week.

//     laws[4] = address(
//         new OpenAction(
//             "Seniors execute actions",
//             "Seniors can execute actions that delegates proposed. By vote. Admin can veto any execution.",
//             dao_ // separated powers
//         )
//     );
//     allowedRoles[4] = 1;
//     lawConfigs[4].quorum = 51; // = 51 majority of seniors need to vote.
//     lawConfigs[4].succeedAt = 66; // =  two/thirds majority FOR vote needed to pass.
//     lawConfigs[4].votingPeriod = 50400; // = duration in number of blocks to vote, about one week.
//     lawConfigs[4].needCompleted = laws[3]; // needs the proposal by Delegates to be completed.
//     lawConfigs[4].delayExecution = 25200; // = duration in number of blocks (= half a week).
//     lawConfigs[4].needNotCompleted = laws[5]; // needs the admin NOT to have cast a veto.

//     laws[5] = address(
//         new ProposalOnly(
//             "Admin can veto actions",
//             "An admin can veto any action. No vote as only one address holds the ADMIN_ROLE.",
//             dao_,
//             paramsAction
//         )
//     );
//     allowedRoles[5] = SeparatedPowers(dao_).ADMIN_ROLE();
//     }
// }

//////////////////////////////////////////////////////////////////////////////////

// contract Founders {
//     uint256 constant LOCAL_CHAIN_ID = 31_337;
//     // uint256 constant ETH_SEPOLIA_CHAIN_ID = 11155111;
//     // uint256 constant OPT_SEPOLIA_CHAIN_ID = 11155420;
//     // uint256 constant ARB_SEPOLIA_CHAIN_ID = 421614;
//     // uint256 constant BASE_SEPOLIA_CHAIN_ID = 84532;

//     function get()
//         external
//         returns (uint32[] memory constituentRoles, address[] memory constituentAccounts)
//     {
//         return getFoundersByChainId(block.chainid);
//     }

//     function getFoundersByChainId(uint256 chainId)
//         internal
//         returns (uint32[] memory constituentRoles, address[] memory constituentAccounts)
//     {
//         if (chainId == LOCAL_CHAIN_ID) {
//             return getFoundersLocal();
//             // } else if (chainId == ETH_SEPOLIA_CHAIN_ID) {
//             // return getFoundersEthSepolia();
//             // etc...
//             // }
//         } else {
//             revert("ChainId not supported");
//         }
//     }

//     function getFoundersLocal()
//         internal
//         returns (uint32[] memory constituentRoles, address[] memory constituentAccounts)
//     {
//         constituentRoles = new uint32[](3);
//         constituentAccounts = new address[](3);

//         address anvil_0 = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;
//         address anvil_1 = 0x70997970C51812dc3A010C7d01b50e0d17dc79C8;
//         address anvil_2 = 0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC;

//         constituentAccounts[0] = anvil_0;
//         constituentRoles[0] = 1;
//         constituentAccounts[1] = anvil_1;
//         constituentRoles[1] = 1;
//         constituentAccounts[2] = anvil_2;
//         constituentRoles[2] = 1;

//         return (constituentRoles, constituentAccounts);
//     }
// }
