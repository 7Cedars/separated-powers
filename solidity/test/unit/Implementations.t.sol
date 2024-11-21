// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.26;

import "forge-std/Test.sol";
import "@openzeppelin/contracts/utils/ShortStrings.sol";
import { SeparatedPowers } from "../../src/SeparatedPowers.sol";
import { TestSetupImplementations } from "../TestSetup.t.sol";
import { Law } from "../../src/Law.sol";
import { OpenAction } from "../../src/implementations/laws/executive/OpenAction.sol";

//////////////////////////////////////////////////
//              BESPOKE LAWS                    //
//////////////////////////////////////////////////


//////////////////////////////////////////////////
//              ELECTORAL LAWS                  //
//////////////////////////////////////////////////
contract DirectSelectTest is TestSetupImplementations {
    using ShortStrings for *;
    error DirectSelect__AccountDoesNotHaveRole();
    error DirectSelect__AccountAlreadyHasRole();

    function testAssignSucceeds() public {
        // prep: check if alice does NOT have role 3
        assertEq(daoMock.hasRoleSince(charlotte, ROLE_THREE), 0);
        address directSelect = laws[7];
        bytes memory lawCalldata = abi.encode(false); // revoke 
        bytes memory expectedCalldata = abi.encodeWithSelector(SeparatedPowers.setRole.selector, ROLE_THREE, charlotte, true);
       
        (
            address[] memory targetsOut, 
            uint256[] memory valuesOut, 
            bytes[] memory calldatasOut
            ) = Law(directSelect).executeLaw(charlotte, lawCalldata, bytes32(0));

        assertEq(targetsOut[0], address(daoMock));
        assertEq(valuesOut[0], 0);
        assertEq(calldatasOut[0], expectedCalldata);
    }

    function testAssignReverts() public {
        // prep: check if alice does have role 3
        assertNotEq(daoMock.hasRoleSince(alice, ROLE_THREE), 0);
        address directSelect = laws[7];
        bytes memory lawCalldata = abi.encode(false); // revoke 
        bytes memory expectedCalldata = abi.encodeWithSelector(SeparatedPowers.setRole.selector, ROLE_THREE, alice, true);

        // act & assert
        vm.expectRevert(DirectSelect__AccountAlreadyHasRole.selector);
        (
            address[] memory targetsOut, 
            uint256[] memory valuesOut, 
            bytes[] memory calldatasOut
            ) = Law(directSelect).executeLaw(alice, lawCalldata, bytes32(0));
    }

    function testRevokeSucceeds() public {
        // prep: check if alice does have role 3
        assertNotEq(daoMock.hasRoleSince(alice, ROLE_THREE), 0);
        address directSelect = laws[7];
        bytes memory lawCalldata = abi.encode(true); // revoke 
        bytes memory expectedCalldata = abi.encodeWithSelector(SeparatedPowers.setRole.selector, ROLE_THREE, alice, false);
        (
            address[] memory targetsOut, 
            uint256[] memory valuesOut, 
            bytes[] memory calldatasOut
            ) = Law(directSelect).executeLaw(alice, lawCalldata, bytes32(0));

        assertEq(targetsOut[0], address(daoMock));
        assertEq(valuesOut[0], 0);
        assertEq(calldatasOut[0], expectedCalldata);
    }

    function testRevokeReverts() public {
        // prep: check if alice does have role 3
        assertEq(daoMock.hasRoleSince(charlotte, ROLE_THREE), 0);
        address directSelect = laws[7];
        bytes memory lawCalldata = abi.encode(true); // revoke 
        bytes memory expectedCalldata = abi.encodeWithSelector(SeparatedPowers.setRole.selector, ROLE_THREE, charlotte, false);

        // act & assert
        vm.expectRevert(DirectSelect__AccountDoesNotHaveRole.selector);
        (
            address[] memory targetsOut, 
            uint256[] memory valuesOut, 
            bytes[] memory calldatasOut
            ) = Law(directSelect).executeLaw(charlotte, lawCalldata, bytes32(0));
    }
}

contract RandomlySelectTest is TestSetupImplementations {
    using ShortStrings for *;
    error RandomlySelect__NomineeAlreadyNominated();
    error RandomlySelect__NomineeNotNominated();

    event Randomly__NominationReceived(address indexed nominee);
    event Randomly__NominationRevoked(address indexed nominee);

    function testAssignNominationSucceeds() public {
        // prep
        address randomlySelect = laws[8];
        bytes memory lawCalldata = abi.encode(true, false); // nominateMe, assignRoles  
        
        // act & assert
        vm.expectEmit(true, false, false, false);
        emit Randomly__NominationReceived(charlotte);
        Law(randomlySelect).executeLaw(charlotte, lawCalldata, bytes32(0));
    }

    function testAssignNominationReverts() public {
        // prep 
        address randomlySelect = laws[8];
        bytes memory lawCalldata = abi.encode(true, false); // nominateMe, assignRoles  
        
        // nominate once. 
        Law(randomlySelect).executeLaw(charlotte, lawCalldata, bytes32(0));

        // try to nominate a second time. 
        vm.expectRevert(RandomlySelect__NomineeAlreadyNominated.selector);
        Law(randomlySelect).executeLaw(charlotte, lawCalldata, bytes32(0));
    }

    function testRevokeNominationSucceeds() public {
        // prep
        address randomlySelect = laws[8];
        bytes memory lawCalldata = abi.encode(true, false); // nominateMe, assignRoles  
        // charlotte nominates herself 
        Law(randomlySelect).executeLaw(charlotte, lawCalldata, bytes32(0));

        // then revokes nomination. 
        bytes memory lawCalldata2 = abi.encode(false, false); // nominateMe, assignRoles  
        vm.expectEmit(true, false, false, false);
        emit Randomly__NominationRevoked(charlotte);
        Law(randomlySelect).executeLaw(charlotte, lawCalldata2, bytes32(0));
    }

    function testRevokeNominationReverts() public {
        // prep 
        address randomlySelect = laws[8];
        bytes memory lawCalldata = abi.encode(false, false); // nominateMe, assignRoles  
        
        // charlotte tries to revoke nomination, without being nominated. 
        vm.expectRevert(RandomlySelect__NomineeNotNominated.selector);
        Law(randomlySelect).executeLaw(charlotte, lawCalldata, bytes32(0));
    }

    function testAssignRolesWithFewNominees() public {
        // prep -- nominate charlotte
        address randomlySelect = laws[8];
        bytes memory lawCalldataNominate = abi.encode(true, false); // nominateMe, assignRoles  
        bytes memory lawCalldataElect = abi.encode(false, true); // nominateMe, assignRoles  
        bytes memory expectedCalldata = abi.encodeWithSelector(SeparatedPowers.setRole.selector, ROLE_THREE, charlotte, true);
        Law(randomlySelect).executeLaw(charlotte, lawCalldataNominate, bytes32(0));

        // act
        (
            address[] memory targetsOut, 
            uint256[] memory valuesOut, 
            bytes[] memory calldatasOut
            ) = Law(randomlySelect).executeLaw(charlotte, lawCalldataElect, bytes32(0));

        // assert 
        assertEq(targetsOut.length, 1);
        assertEq(valuesOut.length, 1);
        assertEq(calldatasOut.length, 1);
        assertEq(targetsOut[0], address(daoMock));
        assertEq(valuesOut[0], 0);
        assertEq(calldatasOut[0], expectedCalldata);
    }

    // function testAssignRolesWithManyNominees() public {
    //     // prep -- nominate all users
    //     address randomlySelect = laws[8];
    //     bytes memory lawCalldataNominate = abi.encode(true, false); // nominateMe, assignRoles 
    //     for (uint256 i = 0; i < users.length; i++) {
    //         Law(randomlySelect).executeLaw(users[i], lawCalldataNominate, bytes32(0));
    //     }
    //     // act
    //     bytes memory lawCalldataElect = abi.encode(false, true); // nominateMe, assignRoles 
    //     (
    //         address[] memory targetsOut, 
    //         uint256[] memory valuesOut, 
    //         bytes[] memory calldatasOut
    //         ) = Law(randomlySelect).executeLaw(charlotte, lawCalldataElect, bytes32(0));

    //     // assert 
    //     assertEq(targetsOut.length, 3);
    //     assertEq(valuesOut.length, 3);
    //     assertEq(calldatasOut.length, 3);
    //     for (uint256 i = 0; i < targetsOut.length; i++) {
    //         assertEq(targetsOut[i], address(daoMock));
    //         assertEq(valuesOut[i], 0);
    //     }
    // }

    // function testReelectionWorks() public {
    //     // prep -- nominate all users
    //     address randomlySelect = laws[8];
    //     bytes memory lawCalldataNominate = abi.encode(true, false); // nominateMe, assignRoles 
    //     for (uint256 i = 0; i < users.length; i++) {
    //         Law(randomlySelect).executeLaw(users[i], lawCalldataNominate, bytes32(0));
    //     }
    //     // act: first election 
    //     bytes memory lawCalldataElect = abi.encode(false, true); // nominateMe, assignRoles 
    //     (
    //         address[] memory targetsOut1, 
    //         uint256[] memory valuesOut1, 
    //         bytes[] memory calldatasOut1
    //         ) = Law(randomlySelect).executeLaw(charlotte, lawCalldataElect, bytes32(0));

    //     vm.roll(block.number + 100); 

    //     // act: second election
    //     (
    //         address[] memory targetsOut2, 
    //         uint256[] memory valuesOut2, 
    //         bytes[] memory calldatasOut2
    //         ) = Law(randomlySelect).executeLaw(charlotte, lawCalldataElect, bytes32(0));

    //     // assert 
    //     assertEq(targetsOut2.length, 3);
    //     assertEq(valuesOut2.length, 3);
    //     assertEq(calldatasOut2.length, 3);
    //     assertNotEq(calldatasOut2, calldatasOut1);
    // }
}

//////////////////////////////////////////////////
//              EXECUTIVE LAWS                  //
//////////////////////////////////////////////////
contract OpenActionTest is TestSetupImplementations {
    using ShortStrings for *;

    // function testDeploy() public {
    //     address openAction = laws[10]; 
        
    //     string memory name = Law(openAction).name().toString();
    //     string memory description = Law(openAction).description();
    //     address daoMockAddress = Law(openAction).separatedPowers();
    //     uint48 execution = Law(openAction).executions(0);
    //     address parentLaw = Law(openAction).parentLaw();

    //     assertEq(name, "Open Action");
    //     assertEq(description, "Execute an action, any action.");
    //     assertEq(daoMockAddress, address(daoMock));
    //     assertEq(execution, 0);
    //     assertEq(parentLaw, address(0));
    // }

    function testExecuteAction() public {
        address[] memory targetsIn = new address[](1);
        uint256[] memory valuesIn = new uint256[](1);
        bytes[] memory calldatasIn = new bytes[](1);
        targetsIn[0] = address(erc1155Mock);
        valuesIn[0] = 0;
        calldatasIn[0] = abi.encodeWithSignature("mintCoins(uint256)", 123);

        address openAction = laws[10];
        bytes memory lawCalldata = abi.encode(targetsIn, valuesIn, calldatasIn);
        (
            address[] memory targetsOut, 
            uint256[] memory valuesOut, 
            bytes[] memory calldatasOut
            ) = Law(openAction).executeLaw(address(0), lawCalldata, bytes32(0));

        assertEq(targetsOut[0], targetsIn[0]);
        assertEq(valuesOut[0], valuesIn[0]);
        assertEq(calldatasOut[0], calldatasIn[0]);
    }
}


