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
