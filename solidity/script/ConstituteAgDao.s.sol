// // SPDX-License-Identifier: MIT
// pragma solidity 0.8.26;

// import { Script, console2 } from "lib/forge-std/src/Script.sol";
// import { AgDao } from "../src/implementation/DAOs/AgDao.sol";
// import { SeparatedPowersTypes } from "../src/interfaces/SeparatedPowersTypes.sol";

// contract ConstituteAgDao is Script {
//     error DeployFactoryProgrmas__DeployedContractAtAddress(address deploymentAddress);

//     uint48 SENIOR_ROLE = 1;
//     address agDaoAddress = 0x001A6a16D2fc45248e00351314bCE898B7d8578f;
//     address[] constituentLaws = [
//         0x7Dcbd2DAc6166F77E8e7d4b397EB603f4680794C,
//         0x420bf9045BFD5449eB12E068AEf31251BEb576b1,
//         0x3216EB8D8fF087536835600a7e0B32687744Ef65,
//         0xbb45079e74399e7238AAF63C764C3CeE7D77712F,
//         0x0Ea769CD03D6159088F14D3b23bF50702b5d4363,
//         0xa2c0C9d9762c51DA258d008C92575A158121c87d,
//         0xfb7291B8FbA99C9FC29E95797914777562983D71,
//         0x8383547475d9ade41cE23D9Aa4D81E85D1eAdeBD,
//         0xBfa0747E3AC40c628352ff65a1254cC08f1957Aa,
//         0x71504Ced3199f8a0B32EaBf4C274D1ddD87Ecc4d,
//         0x0735199AeDba32A4E1BaF963A3C5C1D2930BdfFd,
//         0x57C9a89c8550fAf69Ab86a9A4e5c96BcBC270af9
//     ];

//     /* Functions */
//     function run() external {
//         SeparatedPowersTypes.ConstituentRole[] memory constituentRoles = new SeparatedPowersTypes.ConstituentRole[](1);
//         constituentRoles[0] = SeparatedPowersTypes.ConstituentRole(vm.envAddress("DEV2_ADDRESS"), SENIOR_ROLE);

//         vm.startBroadcast();
//         AgDao(payable(agDaoAddress)).constitute(constituentLaws, constituentRoles);
//         vm.stopBroadcast();
//     }
// }
