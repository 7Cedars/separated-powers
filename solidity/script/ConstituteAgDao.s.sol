// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Script, console2} from "lib/forge-std/src/Script.sol";
import {AgDao} from "../src/implementation/AgDao.sol";
import {IAuthoritiesManager} from "../src/interfaces/IAuthoritiesManager.sol";

contract ConstituteAgDao is Script {
    error DeployFactoryProgrmas__DeployedContractAtAddress(address deploymentAddress);
    uint64 SENIOR_ROLE = 1;
    address agDaoAddress = 0x94Fff4779b8Cb2Ef0f8ec56A299DE77337AC6Ad7; 
    address[] constituentLaws = [0xfb87dB1576054C5C632dF4B87802E850F824B3f2, 0x2af29163AD35b0343dEe41e8497713DB8a7E718E, 0xf85e0De9A0A1d55B47D1f8Bbe96452fe97A29552, 0x7F74756788Dd81997Af7B2A4d291E973aD5Dfde0, 0xEDEb04270f7c23f80E3a4f6f6Be71Ec23dcDAc1C, 0xc3a6f9573f4Db4b60cbD9Ef66d67669eC9Ab55E2, 0xa87697369C1C707E57DfF642D8f7308b6050b39f, 0x49D0dDc72F33621E3956cD4Fc51E812427D1052e, 0x940b3009Cc6B5E847766d47b88bF0809D14caB3a, 0x81a54AdF57C6e74200E3d53C44BB2880D743C51E, 0x634519d3190c450660069F420eeb2B092d29D96a, 0x53ae4CCD9daC82b5D11911B456b3c71838Bf823D];
    /* Functions */
    function run() external {
       IAuthoritiesManager.ConstituentRole[] memory constituentRoles = new IAuthoritiesManager.ConstituentRole[](1);
       constituentRoles[0] = IAuthoritiesManager.ConstituentRole(vm.envAddress("DEV2_ADDRESS"), SENIOR_ROLE);

        vm.startBroadcast();
            AgDao(payable(agDaoAddress)).constitute(constituentLaws, constituentRoles);
        vm.stopBroadcast();
    }
}

