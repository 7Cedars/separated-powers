// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import { DaoMock } from "./DaoMock.sol";

contract FoundersMock {
    uint32[] constituentRoles;
    address[] constituentAccounts;

    function get(
        address payable daoAddress, 
        address[] memory accounts
        ) external returns (
            uint32[] memory, 
            address[] memory
            ) {         
        DaoMock daoMock = DaoMock(daoAddress);

        for (uint32 i = 0; i < accounts.length; i++) {
            // MEMBER_ROLE
            constituentRoles.push(daoMock.ROLE_ONE());
            constituentAccounts.push(accounts[i]);

            // SENIOR_ROLE
            if (i % 2 == 0) {
                constituentRoles.push(daoMock.ROLE_TWO());
                constituentAccounts.push(accounts[i]);
            }
            
            // WHALE_ROLE
            if (i % 3 == 0) {
                constituentRoles.push(daoMock.ROLE_THREE());
                constituentAccounts.push(accounts[i]);
            }        
        }

        //////////////////////////////////////////////////////////////
        //                    RETURN FOUNDERS                       //
        //////////////////////////////////////////////////////////////
        return (constituentRoles, constituentAccounts);
    }
}
