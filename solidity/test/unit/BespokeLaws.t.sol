// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.26;

import "forge-std/Test.sol";
import "@openzeppelin/contracts/utils/ShortStrings.sol";
import { SeparatedPowers } from "../../src/SeparatedPowers.sol";
import { TestSetupBespokeLaws } from "../TestSetup.t.sol";
import { Law } from "../../src/Law.sol";

contract RevokeRoleTest is TestSetupBespokeLaws {
    using ShortStrings for *;
    
    error DirectSelect__AccountDoesNotHaveRole();
    error DirectSelect__AccountAlreadyHasRole();

    event RevokeRole__Initialized(uint32 roleId);

    // function testDeploy() public {

    // }

    // function testRevokeSucceeds() public {
    //     // prep: check if alice does have role 3
    //     assertNotEq(daoMock.hasRoleSince(alice, ROLE_THREE), 0);
    //     address revokeRole = laws[0];
    //     bytes memory lawCalldata = abi.encode(alice);  
    //     bytes memory expectedCalldata1 = abi.encodeWithSelector(SeparatedPowers.revokeRole.selector, ROLE_THREE, alice);
    //     bytes memory expectedCalldata2 = abi.encodeWithSelector(AlignedGrants.setBlacklistAccount.selector, alice, true);
        
    //     vm.startPrank(address(daoMock));
    //     (
    //         address[] memory targetsOut, 
    //         uint256[] memory valuesOut, 
    //         bytes[] memory calldatasOut
    //         ) = Law(directSelect).executeLaw(charlotte, lawCalldata, bytes32(0));
        
    //     // test all outputs. 
    //     assertEq(targetsOut[0], address(daoMock));
    //     assertEq(valuesOut[0], 0);
    //     assertEq(calldatasOut[0], expectedCalldata);
    // }

    // function testRevokeReverts() public {
    //     // prep: check if alice does have role 3
    //     assertNotEq(daoMock.hasRoleSince(alice, ROLE_THREE), 0);
    //     address directSelect = laws[4];
    //     bytes memory lawCalldata = abi.encode(false); // revoke = false 
    //     bytes memory expectedCalldata = abi.encodeWithSelector(SeparatedPowers.assignRole.selector, ROLE_THREE, alice);

    //     // act & assert
    //     vm.startPrank(address(daoMock));
    //     vm.expectRevert(DirectSelect__AccountAlreadyHasRole.selector);
    //     Law(directSelect).executeLaw(alice, lawCalldata, bytes32(0));
    // }
}

contract ReinstateRoleTest is TestSetupBespokeLaws {
    // £todo 
}

contract RequestPaymentTest is TestSetupBespokeLaws {
    // £todo 
}