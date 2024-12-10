// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import "forge-std/Test.sol";

import { DaoMock } from "./DaoMock.sol";

contract FoundersMock is Test {
    //////////////////////////////////////////////////////////////
    //                  FIRST CONSTITUTION                      //
    //////////////////////////////////////////////////////////////
    function getFounders(address payable daoAddress)
        external
        returns (address[] memory constituentAccounts, uint32[] memory constituentRoles)
    {
        DaoMock daoMock = DaoMock(daoAddress);

        constituentAccounts = new address[](13);
        constituentRoles = new uint32[](13);

        address alice = makeAddr("alice");
        address bob = makeAddr("bob");
        address charlotte = makeAddr("charlotte");
        address david = makeAddr("david");
        address eve = makeAddr("eve");
        address frank = makeAddr("frank");
        address gary = makeAddr("gary");
        address helen = makeAddr("helen");

        constituentAccounts[0] = alice;
        constituentRoles[0] = daoMock.ROLE_ONE();
        constituentAccounts[1] = bob;
        constituentRoles[1] = daoMock.ROLE_ONE();
        constituentAccounts[2] = charlotte;
        constituentRoles[2] = daoMock.ROLE_ONE();
        constituentAccounts[3] = david;
        constituentRoles[3] = daoMock.ROLE_ONE();
        constituentAccounts[4] = eve;
        constituentRoles[4] = daoMock.ROLE_ONE();
        constituentAccounts[5] = frank;
        constituentRoles[5] = daoMock.ROLE_ONE();
        constituentAccounts[6] = gary;
        constituentRoles[6] = daoMock.ROLE_ONE();
        constituentAccounts[7] = helen;
        constituentRoles[7] = daoMock.ROLE_ONE();

        constituentAccounts[8] = alice;
        constituentRoles[8] = daoMock.ROLE_TWO();
        constituentAccounts[9] = bob;
        constituentRoles[9] = daoMock.ROLE_TWO();
        constituentAccounts[10] = charlotte;
        constituentRoles[10] = daoMock.ROLE_TWO();

        constituentAccounts[11] = alice;
        constituentRoles[11] = daoMock.ROLE_THREE();
        constituentAccounts[12] = bob;
        constituentRoles[12] = daoMock.ROLE_THREE();
    }

    function _createAddress(string memory name) internal returns (address addr) {
        return address(bytes20(keccak256(bytes(name))));
    }
}
