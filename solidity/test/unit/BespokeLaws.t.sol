// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.26;

import "forge-std/Test.sol";
import "@openzeppelin/contracts/utils/ShortStrings.sol";
import { SeparatedPowers } from "../../src/SeparatedPowers.sol";
import { TestSetupBespokeLaws } from "../TestSetup.t.sol";
import { Law } from "../../src/Law.sol";

contract RevokeRoleTest is TestSetupBespokeLaws {
    // £todo 
    // using ShortStrings for *;
    // event RevokeRole__Initialized(uint32 roleId);
    
    // function testRevokeSucceeds() public {
    //     // prep: check if alice does NOT have role 3
    //     assertEq(alignedGrants.hasRoleSince(charlotte, ROLE_THREE), 0);
    //     address directSelect = laws[4];
    //     bytes memory lawCalldata = abi.encode(false); // revoke 
    //     bytes memory expectedCalldata = abi.encodeWithSelector(SeparatedPowers.assignRole.selector, ROLE_THREE, charlotte);
        
    //     vm.startPrank(address(daoMock));
    //     (
    //         address[] memory targetsOut, 
    //         uint256[] memory valuesOut, 
    //         bytes[] memory calldatasOut
    //         ) = Law(directSelect).executeLaw(charlotte, lawCalldata, bytes32(0));

    //     assertEq(targetsOut[0], address(daoMock));
    //     assertEq(valuesOut[0], 0);
    //     assertEq(calldatasOut[0], expectedCalldata);
    //     // test all outputs. 
    // }

    // function testRevokeRevertsIfAccountDoesNotHaveMemberRole() public {
    //     // prep: check if alice does have role 3
    //     assertNotEq(daoMock.hasRoleSince(alice, ROLE_THREE), 0);
    //     address directSelect = laws[4];
    //     bytes memory lawCalldata = abi.encode(false); // revoke 
    //     bytes memory expectedCalldata = abi.encodeWithSelector(SeparatedPowers.assignRole.selector, ROLE_THREE, alice);

    //     // act & assert
    //     vm.startPrank(address(daoMock));
    //     vm.expectRevert(DirectSelect__AccountAlreadyHasRole.selector);
    //     (
    //         address[] memory targetsOut, 
    //         uint256[] memory valuesOut, 
    //         bytes[] memory calldatasOut
    //         ) = Law(directSelect).executeLaw(alice, lawCalldata, bytes32(0));
    // }

    // function testRevokeSucceeds() public {
    //     // prep: check if alice does have role 3
    //     assertNotEq(daoMock.hasRoleSince(alice, ROLE_THREE), 0);
    //     address directSelect = laws[4];
    //     bytes memory lawCalldata = abi.encode(true); // revoke 
    //     bytes memory expectedCalldata = abi.encodeWithSelector(SeparatedPowers.revokeRole.selector, ROLE_THREE, alice);
    //     vm.startPrank(address(daoMock));
    //     (
    //         address[] memory targetsOut, 
    //         uint256[] memory valuesOut, 
    //         bytes[] memory calldatasOut
    //         ) = Law(directSelect).executeLaw(alice, lawCalldata, bytes32(0));

    //     assertEq(targetsOut[0], address(daoMock));
    //     assertEq(valuesOut[0], 0);
    //     assertEq(calldatasOut[0], expectedCalldata);
    // }

    // function testRevokeReverts() public {
    //     // prep: check if alice does have role 3
    //     assertEq(daoMock.hasRoleSince(charlotte, ROLE_THREE), 0);
    //     address directSelect = laws[4];
    //     bytes memory lawCalldata = abi.encode(true); // revoke 
    //     bytes memory expectedCalldata = abi.encodeWithSelector(SeparatedPowers.revokeRole.selector, ROLE_THREE, charlotte);

    //     // act & assert
    //     vm.expectRevert(DirectSelect__AccountDoesNotHaveRole.selector);
    //     vm.startPrank(address(daoMock));
    //     (
    //         address[] memory targetsOut, 
    //         uint256[] memory valuesOut, 
    //         bytes[] memory calldatasOut
    //         ) = Law(directSelect).executeLaw(charlotte, lawCalldata, bytes32(0));
    // }
}

contract ReinstateRoleTest is TestSetupBespokeLaws {
    // £todo 
}

contract RequestPaymentTest is TestSetupBespokeLaws {
    // £todo 
}