// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import { Script, console2 } from "lib/forge-std/src/Script.sol";

// core contracts
import { SeparatedPowers } from "../../src/SeparatedPowers.sol";
import { Law } from "../../src/Law.sol";
import { SeparatedPowersTypes } from "../../src/interfaces/SeparatedPowersTypes.sol";
import { AlignedGrants } from "../../src/implementations/daos/AlignedGrants.sol";
import { Erc1155Mock } from "../../src/implementations/mocks/Erc1155Mock.sol";
import { Constitution } from "./Constitution.s.sol";
import { Founders } from "./Founders.s.sol";

contract DeployAlignedGrants is Script {
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
            address[] memory laws,
            uint32[] memory allowedRoles,
            uint8[] memory quorums,
            uint8[] memory succeedAts,
            uint32[] memory votingPeriods
            ) = constitution.initiate(payable(address(alignedGrants)), payable(address((erc1155Mock))));

        (
            uint32[] memory constituentRoles, 
            address[] memory constituentAccounts
            ) = founders.get(payable(address(alignedGrants)));

        alignedGrants.constitute(laws, allowedRoles, quorums, succeedAts, votingPeriods, constituentRoles, constituentAccounts);
        vm.stopBroadcast();

        return (alignedGrants, laws, allowedRoles, quorums, succeedAts, votingPeriods, constituentRoles, constituentAccounts);
    }
}
