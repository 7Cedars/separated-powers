// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import { Script, console2 } from "lib/forge-std/src/Script.sol";

// core contracts
import { AlignedGrantsDao } from "../src/implementation/daos/AlignedGrantsDao.sol";
import { ERC1155Mock } from "../mocks/ERC1155Mock.sol"
import { Law } from "../src/Law.sol";
import { SeparatedPowersTypes } from "../src/interfaces/SeparatedPowersTypes.sol";
import { SeparatedPowers } from "../src/SeparatedPowers.sol"; 

contract DeployDao is Script {

    /* Functions */
    function run() external returns (AlignedGrantsDao, ERC1155Mock) {
        //
        vm.startBroadcast();
        AlignedGrantsDao agDao = new AlignedGrantsDao();
        ERC1155Mock mock1155 = new ERC1155Mock(payable(address(agDao)));
        vm.stopBroadcast();

        ( 
          address[] memory laws,
          uint32[] memory allowedRoles,
          uint8[] memory quorums,
          uint8[] memory succeedAts, 
          uint32[] memory votingPeriods
          ) = _createLegalFramework(payable(address(agDao)), address(mock1155));
        
        (
          uint48[] memory constituentRoles,
          address[] memory constituentAccounts
          ) = _createRoles();  
                
        vm.startBroadcast();
        agDao.constitute(
          laws, allowedRoles, quorums, succeedAts, votingPeriods, 
          constituentRoles, constituentAccounts
        ); 
        vm.stopBroadcast(); 

        return (agDao, mock1155); //
    }
}
