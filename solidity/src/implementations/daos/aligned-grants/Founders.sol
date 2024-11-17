// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import { AlignedGrants } from "./AlignedGrants.sol";

contract Founders {
    uint32[] constituentRoles;
    address[] constituentAccounts;

    function get(
        address payable alignedGrants, 
        address[] memory accounts
        ) external returns (
            uint32[] memory, 
            address[] memory
            ) {         
        AlignedGrants agDao = AlignedGrants(alignedGrants);

        for (uint32 i = 0; i < accounts.length; i++) {
            // MEMBER_ROLE
            constituentRoles.push(agDao.MEMBER_ROLE());
            constituentAccounts.push(accounts[i]);

            // SENIOR_ROLE
            if (i % 2 == 0) {
                constituentRoles.push(agDao.SENIOR_ROLE());
                constituentAccounts.push(accounts[i]);
            }
            
            // WHALE_ROLE
            if (i % 3 == 0) {
                constituentRoles.push(agDao.WHALE_ROLE());
                constituentAccounts.push(accounts[i]);
            }        
        }

        //////////////////////////////////////////////////////////////
        //                    RETURN FOUNDERS                       //
        //////////////////////////////////////////////////////////////
        return (constituentRoles, constituentAccounts);
    }
}
