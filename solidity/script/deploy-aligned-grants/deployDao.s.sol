// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import { Script, console2 } from "lib/forge-std/src/Script.sol";

// core contracts
import { SeparatedPowers } from "../../src/SeparatedPowers.sol"; 
import { Law } from "../../src/Law.sol";
import { SeparatedPowersTypes } from "../../src/interfaces/SeparatedPowersTypes.sol";
import { AlignedGrants } from "../../src/implementations/daos/AlignedGrants.sol";
import { ERC1155Mock } from "../../src/implementations/mocks/ERC1155Mock.sol"; 
import { Constitution } from "./Constitution.s.sol";
import { Founders } from "./Founders.s.sol";

contract DeployDao is Script {
    /* Functions */
    function run() external returns (AlignedGrants, ERC1155Mock) {
      Constitution constitution = new Constitution();
      Founders founders = new Founders();
        //
        vm.startBroadcast();
        AlignedGrants agDao = new AlignedGrants();
        ERC1155Mock mock1155 = new ERC1155Mock(payable(address(agDao)));
        
        ( 
          address[] memory laws,
          uint32[] memory allowedRoles,
          uint8[] memory quorums,
          uint8[] memory succeedAts, 
          uint32[] memory votingPeriods
          ) = constitution.initiate(payable(address(agDao)), payable(address((mock1155))));
        
        (
          uint32[] memory constituentRoles,
          address[] memory constituentAccounts
          ) = founders.get();  
                
        agDao.constitute(
          laws, allowedRoles, quorums, succeedAts, votingPeriods, 
          constituentRoles, constituentAccounts
        ); 
        vm.stopBroadcast(); 

        return (agDao, mock1155);
    }
}
