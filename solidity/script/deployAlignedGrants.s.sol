// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import { Script, console2 } from "lib/forge-std/src/Script.sol";

// core contracts
import { SeparatedPowers } from "../../src/SeparatedPowers.sol";
import { Law } from "../../src/Law.sol";
import { SeparatedPowersTypes } from "../../src/interfaces/SeparatedPowersTypes.sol";
import { Erc1155Mock } from "../../src/implementations/mocks/Erc1155Mock.sol";
// dao 
import { AlignedGrants } from "../../src/implementations/daos/aligned-grants/AlignedGrants.sol";
import { Constitution } from "../../src/implementations/daos/aligned-grants/Constitution.sol";
import { Founders } from "../../src/implementations/daos/aligned-grants/Founders.sol";

contract DeployAlignedGrants is Script {
    address[] laws;
    uint32[] allowedRoles;
    uint8[] quorums;
    uint8[] succeedAts;
    uint32[] votingPeriods;  
    uint32[] constituentRoles; 
    address[] constituentAccounts; 

    /* Functions */
    function run(Erc1155Mock erc1155Mock) external returns (
        AlignedGrants, 
        address[] memory laws,
        uint32[] memory allowedRoles,
        uint8[] memory quorums,
        uint8[] memory succeedAts,
        uint32[] memory votingPeriods,  
        uint32[] memory constituentRoles, 
        address[] memory constituentAccounts 
        ) {
        Constitution constitution = new Constitution();
        Founders founders = new Founders();
        //
        vm.startBroadcast();
        AlignedGrants alignedGrants = new AlignedGrants();
        
        (
            laws,
            allowedRoles,
            quorums,
            succeedAts,
            votingPeriods
            ) = constitution.initiate(payable(address(alignedGrants)), payable(address((erc1155Mock))));

        (
            constituentRoles, 
            constituentAccounts
            ) = founders.get(payable(address(alignedGrants)));

        alignedGrants.constitute(laws, allowedRoles, quorums, succeedAts, votingPeriods, constituentRoles, constituentAccounts);
        vm.stopBroadcast();

        return (alignedGrants, laws, allowedRoles, quorums, succeedAts, votingPeriods, constituentRoles, constituentAccounts);
    }
}
