// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import { Script, console2 } from "lib/forge-std/src/Script.sol";
import { AlignedGrants } from "../../src/implementations/daos/AlignedGrants.sol";

contract Founders is Script {
    uint256 constant NUMBER_OF_FOUNDER_ROLES = 10;

    function get(address payable alignedGrants) external returns (uint32[] memory constituentRoles, address[] memory constituentAccounts) {
        AlignedGrants agDao = AlignedGrants(alignedGrants);
        
        constituentRoles = new uint32[](NUMBER_OF_FOUNDER_ROLES);
        constituentAccounts = new address[](NUMBER_OF_FOUNDER_ROLES);

        address alice = makeAddr("alice");
        address bob = makeAddr("bob");
        address charlotte = makeAddr("charlotte");
        address david = makeAddr("david");
        address eve = makeAddr("eve");
        address frank = makeAddr("frank");

        constituentAccounts[0] = alice;
        constituentRoles[0] = agDao.MEMBER_ROLE();
        constituentAccounts[1] = bob;
        constituentRoles[1] = agDao.MEMBER_ROLE();
        constituentAccounts[2] = charlotte;
        constituentRoles[2] = agDao.MEMBER_ROLE();
        constituentAccounts[3] = david;
        constituentRoles[3] = agDao.MEMBER_ROLE();
        constituentAccounts[4] = eve;
        constituentRoles[4] = agDao.MEMBER_ROLE();

        constituentAccounts[5] = alice;
        constituentRoles[5] = agDao.SENIOR_ROLE();
        constituentAccounts[6] = bob;
        constituentRoles[6] = agDao.SENIOR_ROLE();
        constituentAccounts[7] = charlotte;
        constituentRoles[7] = agDao.SENIOR_ROLE();
        
        constituentAccounts[8] = eve;
        constituentRoles[8] = agDao.WHALE_ROLE();
        constituentAccounts[9] = frank;
        constituentRoles[9] = agDao.WHALE_ROLE();

        //////////////////////////////////////////////////////////////
        //                    RETURN FOUNDERS                       //
        //////////////////////////////////////////////////////////////
        return (constituentRoles, constituentAccounts);
    }
}
