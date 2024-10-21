// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Script, console2} from "lib/forge-std/src/Script.sol";
import {AgDao} from "../src/implementation/AgDao.sol";
import {IAuthoritiesManager} from "../src/interfaces/IAuthoritiesManager.sol";

contract ConstituteAgDao is Script {
    error DeployFactoryProgrmas__DeployedContractAtAddress(address deploymentAddress);
    
    address agDaoAddress = 0xe55DbF3B724fc6a590630C94f5f63C976880235a; 
    address[] constituentLaws = [0x222132954f22E5fb097a5921b4A0e427cB75B218, 0x19A8EE0a026026e02186c1c8ab763e94037dAf14, 0xFF1fE9d55a314056F90dD6CA2DafC5c77473eDFf, 0xd2aBB3eb2E55a143c7CE4E7aC500701e5DA1fDE3, 0xb50d1ef36d391536fF3CC8B659EDd5E7CDe5aeD8, 0x95b3c9eB943f6f2f9A7428b712eEAC406c3D6763, 0x28488b3e7daD21f98d551db09fd4Eb02af0Af9eD, 0x8508D5b9bA7F255F70E8022A8aFbDe72083773f8, 0x84bb5992386442282964b65a1a6cb060B4924a75, 0x9179B96E052eDa5a2eE94774c630A74D052b4Fb8, 0xBc4995d96857C9cbaD3bcFe7B51cD1f5a56BA4cf, 0x4D871ede1C865aBC0acf658E6c290060b85cbFB8];
    
    /* Functions */
    function run() external {
       IAuthoritiesManager.ConstituentRole[] memory constituentRoles = new IAuthoritiesManager.ConstituentRole[](0);

        vm.startBroadcast();
            AgDao(payable(agDaoAddress)).constitute(constituentLaws, constituentRoles);
        vm.stopBroadcast();
    }
}

