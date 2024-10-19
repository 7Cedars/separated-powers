// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Script, console2} from "lib/forge-std/src/Script.sol";
import {AgDao} from "../src/implementation/AgDao.sol";
import {IAuthoritiesManager} from "../src/interfaces/IAuthoritiesManager.sol";

contract ConstituteAgDao is Script {
    error DeployFactoryProgrmas__DeployedContractAtAddress(address deploymentAddress);
    
    address agDaoAddress = 0x5FbDB2315678afecb367f032d93F642f64180aa3; 
    address[] constituentLaws = [0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0, 0xCf7Ed3AccA5a467e9e704C703E8D87F634fB0Fc9, 0xDc64a140Aa3E981100a9becA4E685f962f0cF6C9, 0x5FC8d32690cc91D4c39d9d3abcBD16989F875707, 0x0165878A594ca255338adfa4d48449f69242Eb8F, 0xa513E6E4b8f2a923D98304ec87F64353C4D5C853, 0x2279B7A0a67DB372996a5FaB50D91eAA73d2eBe6, 0x8A791620dd6260079BF849Dc5567aDC3F2FdC318, 0x610178dA211FEF7D417bC0e6FeD39F05609AD788, 0xB7f8BC63BbcaD18155201308C8f3540b07f84F5e, 0xA51c1fc2f0D1a1b8494Ed1FE312d7C3a78Ed91C0, 0x0DCd1Bf9A1b36cE34237eEaFef220932846BCD82];

    /* Functions */
    function run() external {
       IAuthoritiesManager.ConstituentRole[] memory constituentRoles = new IAuthoritiesManager.ConstituentRole[](0);

        vm.startBroadcast();
            AgDao(payable(agDaoAddress)).constitute(constituentLaws, constituentRoles);
        vm.stopBroadcast();
    }
}

