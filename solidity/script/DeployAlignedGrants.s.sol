// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import { Script, console, console2 } from "lib/forge-std/src/Script.sol";

// core contracts
import { SeparatedPowers } from "../src/SeparatedPowers.sol";
import { Law } from "../src/Law.sol";
import { ILaw } from "../src/interfaces/ILaw.sol";
import { Erc1155Mock } from "../test/mocks/Erc1155Mock.sol";
// dao
import { AlignedGrants } from "../src/implementations/daos/aligned-grants/AlignedGrants.sol";
import { Constitution } from "../src/implementations/daos/aligned-grants/Constitution.sol";
import { Founders } from "../src/implementations/daos/aligned-grants/Founders.sol";
import { HelperConfig } from "./HelperConfig.s.sol";

contract DeployAlignedGrants is Script {
    // constitute dao
    address[] laws;
    uint32[] allowedRoles;
    // ILaw.LawConfig[] lawsConfig;
    uint32[] constituentRoles;
    address[] constituentAccounts;

    /* Functions */
    function run() external {
        // initiating Constitution and Founders contracts. 
        
        // Constitution constitution = new Constitution();
        // Founders founders = new Founders();
        HelperConfig helperConfig = new HelperConfig();
        HelperConfig.NetworkConfig memory config = helperConfig.getConfigByChainId(block.chainid);        

        // Deploying contracts.
        vm.startBroadcast();
        AlignedGrants alignedGrants = new AlignedGrants();
        vm.stopBroadcast();
       

        ILaw.LawConfig[] memory lawsConfig;
        (laws, allowedRoles, lawsConfig) = Constitution.initiate(
            payable(address(alignedGrants)), payable(config.erc1155Mock));
     
        (constituentRoles, constituentAccounts) = Founders.get(payable(address(alignedGrants)));
        
        alignedGrants.constitute(
            // testLaws, testAllowedRoles, testLawConfigs, constituentRoles, constituentAccounts
            laws, allowedRoles, lawsConfig, constituentRoles, constituentAccounts
        );
    }

    function initiateConstitution() public returns (address[] memory constitutionalLaws) { 




    }
}
