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
        address directSelect = laws[3];
        bytes memory lawCalldata = abi.encode(false); // revoke 
        bytes memory expectedCalldata = abi.encodeWithSelector(SeparatedPowers.setRole.selector, ROLE_THREE, charlotte, true);
        
        vm.startPrank(address(daoMock));
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
        address directSelect = laws[3];
        bytes memory lawCalldata = abi.encode(false); // revoke 
        bytes memory expectedCalldata = abi.encodeWithSelector(SeparatedPowers.setRole.selector, ROLE_THREE, alice, true);

        // act & assert
        vm.startPrank(address(daoMock));
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
        address directSelect = laws[3];
        bytes memory lawCalldata = abi.encode(true); // revoke 
        bytes memory expectedCalldata = abi.encodeWithSelector(SeparatedPowers.setRole.selector, ROLE_THREE, alice, false);
        vm.startPrank(address(daoMock));
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
        address directSelect = laws[3];
        bytes memory lawCalldata = abi.encode(true); // revoke 
        bytes memory expectedCalldata = abi.encodeWithSelector(SeparatedPowers.setRole.selector, ROLE_THREE, charlotte, false);

        // act & assert
        vm.expectRevert(DirectSelect__AccountDoesNotHaveRole.selector);
        vm.startPrank(address(daoMock));
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

    function testAssignRandomNominationSucceeds() public {
        // prep
        address randomlySelect = laws[4];
        bytes memory lawCalldata = abi.encode(true, false); // nominateMe, assignRoles  
        
        // act & assert
        vm.expectEmit(true, false, false, false);
        emit Randomly__NominationReceived(charlotte);
        vm.startPrank(address(daoMock));
        Law(randomlySelect).executeLaw(charlotte, lawCalldata, bytes32(0));
    }

    function testAssignRandomNominationReverts() public {
        // prep 
        address randomlySelect = laws[4];
        bytes memory lawCalldata = abi.encode(true, false); // nominateMe, assignRoles  
        
        // nominate once. 
        vm.startPrank(address(daoMock));
        Law(randomlySelect).executeLaw(charlotte, lawCalldata, bytes32(0));

        // try to nominate a second time. 
        vm.startPrank(address(daoMock));
        vm.expectRevert(RandomlySelect__NomineeAlreadyNominated.selector);
        Law(randomlySelect).executeLaw(charlotte, lawCalldata, bytes32(0));
    }

    function testRevokeRandomNominationSucceeds() public {
        // prep
        address randomlySelect = laws[4];
        bytes memory lawCalldata = abi.encode(true, false); // nominateMe, assignRoles  
        // charlotte nominates herself 
        vm.startPrank(address(daoMock));
        Law(randomlySelect).executeLaw(charlotte, lawCalldata, bytes32(0));

        // then revokes nomination. 
        bytes memory lawCalldata2 = abi.encode(false, false); // nominateMe, assignRoles  
        vm.expectEmit(true, false, false, false);
        emit Randomly__NominationRevoked(charlotte);
        vm.startPrank(address(daoMock));
        Law(randomlySelect).executeLaw(charlotte, lawCalldata2, bytes32(0));
    }

    function testRevokeRandomNominationReverts() public {
        // prep 
        address randomlySelect = laws[4];
        bytes memory lawCalldata = abi.encode(false, false); // nominateMe, assignRoles  
        
        // charlotte tries to revoke nomination, without being nominated. 
        vm.startPrank(address(daoMock));
        vm.expectRevert(RandomlySelect__NomineeNotNominated.selector);
        Law(randomlySelect).executeLaw(charlotte, lawCalldata, bytes32(0));
    }

    function testAssignRolesWithFewNominees() public {
        // prep -- nominate charlotte
        address randomlySelect = laws[4];
        bytes memory lawCalldataNominate = abi.encode(true, false); // nominateMe, assignRoles  
        bytes memory lawCalldataElect = abi.encode(false, true); // nominateMe, assignRoles  
        bytes memory expectedCalldata = abi.encodeWithSelector(SeparatedPowers.setRole.selector, ROLE_THREE, charlotte, true);
        vm.startPrank(address(daoMock));
        Law(randomlySelect).executeLaw(charlotte, lawCalldataNominate, bytes32(0));

        // act
        vm.startPrank(address(daoMock));
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

    function testAssignRandomRolesWithManyNominees() public {
        // prep -- nominate all users
        address randomlySelect = laws[4];
        bytes memory lawCalldataNominate = abi.encode(true, false); // nominateMe, assignRoles 
        for (uint256 i = 0; i < users.length; i++) {
            vm.startPrank(address(daoMock));
            Law(randomlySelect).executeLaw(users[i], lawCalldataNominate, bytes32(0));
        }
        // act
        bytes memory lawCalldataElect = abi.encode(false, true); // nominateMe, assignRoles 
        vm.startPrank(address(daoMock));
        (
            address[] memory targetsOut, 
            uint256[] memory valuesOut, 
            bytes[] memory calldatasOut
            ) = Law(randomlySelect).executeLaw(charlotte, lawCalldataElect, bytes32(0));

        // assert 
        assertEq(targetsOut.length, 3);
        assertEq(valuesOut.length, 3);
        assertEq(calldatasOut.length, 3);
        for (uint256 i = 0; i < targetsOut.length; i++) {
            assertEq(targetsOut[i], address(daoMock));
            assertEq(valuesOut[i], 0);
            if (i != 0) {
                assertNotEq(calldatasOut[i], calldatasOut[i - 1]);
            }
        }
    }

    function testRandomReelectionWorks() public {
        // prep -- nominate all users
        address randomlySelect = laws[4];
        bytes memory lawCalldataNominate = abi.encode(true, false); // nominateMe, assignRoles 
        for (uint256 i = 0; i < users.length; i++) {
            vm.startPrank(address(daoMock));
            Law(randomlySelect).executeLaw(users[i], lawCalldataNominate, bytes32(0));
        }
        // act: first election 
        bytes memory lawCalldataElect = abi.encode(false, true); // nominateMe, assignRoles 
        vm.startPrank(address(daoMock));
        (
            address[] memory targetsOut1, 
            uint256[] memory valuesOut1, 
            bytes[] memory calldatasOut1
            ) = Law(randomlySelect).executeLaw(charlotte, lawCalldataElect, bytes32(0));

        vm.roll(block.number + 100); 

        // act: second election
        vm.startPrank(address(daoMock));
        (
            address[] memory targetsOut2, 
            uint256[] memory valuesOut2, 
            bytes[] memory calldatasOut2
            ) = Law(randomlySelect).executeLaw(charlotte, lawCalldataElect, bytes32(0));

        // assert 
        assertEq(targetsOut2.length, 6);
        assertEq(valuesOut2.length, 6);
        assertEq(calldatasOut2.length, 6);
        assertNotEq(calldatasOut2, calldatasOut1);
    }
}

contract TokenSelectTest is TestSetupImplementations {
    using ShortStrings for *;
    error TokensSelect__NomineeAlreadyNominated();
    error TokensSelect__NomineeNotNominated();

    event TokensSelect__NominationReceived(address indexed nominee);
    event TokensSelect__NominationRevoked(address indexed nominee);

    function testAssignTokenNominationSucceeds() public {
        // prep
        address tokenSelect = laws[5];
        bytes memory lawCalldata = abi.encode(true, false); // nominateMe, assignRoles  
        
        // act & assert
        vm.expectEmit(true, false, false, false);
        emit TokensSelect__NominationReceived(charlotte);
        vm.startPrank(address(daoMock));
        Law(tokenSelect).executeLaw(charlotte, lawCalldata, bytes32(0));
    }

    function testAssignTokenNominationReverts() public {
        // prep 
        address tokenSelect = laws[5];
        bytes memory lawCalldata = abi.encode(true, false); // nominateMe, assignRoles  
        
        // nominate once. 
        vm.startPrank(address(daoMock));
        Law(tokenSelect).executeLaw(charlotte, lawCalldata, bytes32(0));

        // try to nominate a second time. 
        vm.startPrank(address(daoMock));
        vm.expectRevert(TokensSelect__NomineeAlreadyNominated.selector);
        Law(tokenSelect).executeLaw(charlotte, lawCalldata, bytes32(0));
    }

    function testRevokeTokenNominationSucceeds() public {
        // prep
        address tokenSelect = laws[5];
        bytes memory lawCalldata = abi.encode(true, false); // nominateMe, assignRoles  
        // charlotte nominates herself 
        vm.startPrank(address(daoMock));
        Law(tokenSelect).executeLaw(charlotte, lawCalldata, bytes32(0));

        // then revokes nomination. 
        bytes memory lawCalldata2 = abi.encode(false, false); // nominateMe, assignRoles  
        vm.expectEmit(true, false, false, false);
        emit TokensSelect__NominationRevoked(charlotte);
        vm.startPrank(address(daoMock));
        Law(tokenSelect).executeLaw(charlotte, lawCalldata2, bytes32(0));
    }

    function testRevokeRandomNominationReverts() public {
        // prep 
        address tokenSelect = laws[5];
        bytes memory lawCalldata = abi.encode(false, false); // nominateMe, assignRoles  
        
        // charlotte tries to revoke nomination, without being nominated. 
        vm.startPrank(address(daoMock));
        vm.expectRevert(TokensSelect__NomineeNotNominated.selector);
        Law(tokenSelect).executeLaw(charlotte, lawCalldata, bytes32(0));
    }

    function testAssignTokenRolesWithFewNominees() public {
        // prep -- nominate charlotte
        address tokenSelect = laws[5];
        bytes memory lawCalldataNominate = abi.encode(true, false); // nominateMe, assignRoles  
        bytes memory lawCalldataElect = abi.encode(false, true); // nominateMe, assignRoles  
        bytes memory expectedCalldata = abi.encodeWithSelector(SeparatedPowers.setRole.selector, ROLE_THREE, charlotte, true);
        vm.startPrank(address(daoMock));
        Law(tokenSelect).executeLaw(charlotte, lawCalldataNominate, bytes32(0));

        // act
        vm.startPrank(address(daoMock));
        (
            address[] memory targetsOut, 
            uint256[] memory valuesOut, 
            bytes[] memory calldatasOut
            ) = Law(tokenSelect).executeLaw(charlotte, lawCalldataElect, bytes32(0));

        // assert 
        assertEq(targetsOut.length, 1);
        assertEq(valuesOut.length, 1);
        assertEq(calldatasOut.length, 1);
        assertEq(targetsOut[0], address(daoMock));
        assertEq(valuesOut[0], 0);
        assertEq(calldatasOut[0], expectedCalldata);
    }

    function testAssignTokenRolesWithManyNominees() public {
        // prep -- nominate all users
        address tokenSelect = laws[5];
        bytes memory lawCalldataNominate = abi.encode(true, false); // nominateMe, assignRoles 
        for (uint256 i = 0; i < users.length; i++) {
            vm.startPrank(address(daoMock));
            Law(tokenSelect).executeLaw(users[i], lawCalldataNominate, bytes32(0));
        }
        // act
        bytes memory lawCalldataElect = abi.encode(false, true); // nominateMe, assignRoles 
        vm.startPrank(address(daoMock));
        (
            address[] memory targetsOut, 
            uint256[] memory valuesOut, 
            bytes[] memory calldatasOut
            ) = Law(tokenSelect).executeLaw(charlotte, lawCalldataElect, bytes32(0));

        // assert 
        assertEq(targetsOut.length, 3);
        assertEq(valuesOut.length, 3);
        assertEq(calldatasOut.length, 3);
        for (uint256 i = 0; i < targetsOut.length; i++) {
            assertEq(targetsOut[i], address(daoMock));
            assertEq(valuesOut[i], 0);
            if (i != 0) {
                assertNotEq(calldatasOut[i], calldatasOut[i - 1]);
            }
        }
    }

    function testTokensReelectionWorks() public {
        // prep -- nominate all users
        address tokenSelect = laws[5];
        bytes memory lawCalldataNominate = abi.encode(true, false); // nominateMe, assignRoles 
        for (uint256 i = 0; i < users.length; i++) {
            vm.startPrank(address(daoMock));
            Law(tokenSelect).executeLaw(users[i], lawCalldataNominate, bytes32(0));
        }
        // act: first election 
        bytes memory lawCalldataElect = abi.encode(false, true); // nominateMe, assignRoles 
        vm.startPrank(address(daoMock));
        (
            address[] memory targetsOut1, 
            uint256[] memory valuesOut1, 
            bytes[] memory calldatasOut1
            ) = Law(tokenSelect).executeLaw(charlotte, lawCalldataElect, bytes32(0));

        vm.roll(block.number + 100); 

        // act: second election
        vm.startPrank(address(daoMock));
        (
            address[] memory targetsOut2, 
            uint256[] memory valuesOut2, 
            bytes[] memory calldatasOut2
            ) = Law(tokenSelect).executeLaw(charlotte, lawCalldataElect, bytes32(0));

        // assert 
        assertEq(targetsOut2.length, 6);
        assertEq(valuesOut2.length, 6);
        assertEq(calldatasOut2.length, 6);
        assertNotEq(calldatasOut2, calldatasOut1);
    }
}

contract DelegateSelectTest is TestSetupImplementations {
    using ShortStrings for *;
    error DelegateSelect__NomineeAlreadyNominated();
    error DelegateSelect__NomineeNotNominated();

    event DelegateSelect__NominationReceived(address indexed nominee);
    event DelegateSelect__NominationRevoked(address indexed nominee);

    function testAssignDelegateNominationSucceeds() public {
        // prep
        address delegateSelect = laws[6];
        bytes memory lawCalldata = abi.encode(true, false); // nominateMe, assignRoles  
        
        // act & assert
        vm.expectEmit(true, false, false, false);
        emit DelegateSelect__NominationReceived(charlotte);
        vm.startPrank(address(daoMock));
        Law(delegateSelect).executeLaw(charlotte, lawCalldata, bytes32(0));
    }

    function testAssignDelegateNominationReverts() public {
        // prep 
        address delegateSelect = laws[6];
        bytes memory lawCalldata = abi.encode(true, false); // nominateMe, assignRoles  
        
        // nominate once. 
        vm.startPrank(address(daoMock));
        Law(delegateSelect).executeLaw(charlotte, lawCalldata, bytes32(0));

        // try to nominate a second time.
        vm.startPrank(address(daoMock)); 
        vm.expectRevert(DelegateSelect__NomineeAlreadyNominated.selector);
        Law(delegateSelect).executeLaw(charlotte, lawCalldata, bytes32(0));
    }

    function testRevokeDelegateNominationSucceeds() public {
        // prep
        address delegateSelect = laws[6];
        bytes memory lawCalldata = abi.encode(true, false); // nominateMe, assignRoles  
        // charlotte nominates herself 
        vm.startPrank(address(daoMock));
        Law(delegateSelect).executeLaw(charlotte, lawCalldata, bytes32(0));

        // then revokes nomination. 
        bytes memory lawCalldata2 = abi.encode(false, false); // nominateMe, assignRoles  
        vm.expectEmit(true, false, false, false);
        emit DelegateSelect__NominationRevoked(charlotte);
        vm.startPrank(address(daoMock));
        Law(delegateSelect).executeLaw(charlotte, lawCalldata2, bytes32(0));
    }

    function testRevokeRandomNominationReverts() public {
        // prep 
        address delegateSelect = laws[6];
        bytes memory lawCalldata = abi.encode(false, false); // nominateMe, assignRoles  
        
        // charlotte tries to revoke nomination, without being nominated.
        vm.startPrank(address(daoMock)); 
        vm.expectRevert(DelegateSelect__NomineeNotNominated.selector);
        Law(delegateSelect).executeLaw(charlotte, lawCalldata, bytes32(0));
    }

    function testAssignDelegateRolesWithFewNominees() public {
        // prep -- nominate charlotte
        address delegateSelect = laws[6];
        bytes memory lawCalldataNominate = abi.encode(true, false); // nominateMe, assignRoles  
        bytes memory lawCalldataElect = abi.encode(false, true); // nominateMe, assignRoles  
        bytes memory expectedCalldata = abi.encodeWithSelector(SeparatedPowers.setRole.selector, ROLE_THREE, charlotte, true);
        vm.startPrank(address(daoMock));
        Law(delegateSelect).executeLaw(charlotte, lawCalldataNominate, bytes32(0));

        // act
        vm.startPrank(address(daoMock));
        (
            address[] memory targetsOut, 
            uint256[] memory valuesOut, 
            bytes[] memory calldatasOut
            ) = Law(delegateSelect).executeLaw(charlotte, lawCalldataElect, bytes32(0));

        // assert 
        assertEq(targetsOut.length, 1);
        assertEq(valuesOut.length, 1);
        assertEq(calldatasOut.length, 1);
        assertEq(targetsOut[0], address(daoMock));
        assertEq(valuesOut[0], 0);
        assertEq(calldatasOut[0], expectedCalldata);
    }

    function testAssignDelegateRolesWithManyNominees() public {
        // prep -- nominate all users
        address delegateSelect = laws[6];
        bytes memory lawCalldataNominate = abi.encode(true, false); // nominateMe, assignRoles 
        for (uint256 i = 0; i < users.length; i++) {
            vm.startPrank(address(daoMock));
            Law(delegateSelect).executeLaw(users[i], lawCalldataNominate, bytes32(0));
        }
        // act
        bytes memory lawCalldataElect = abi.encode(false, true); // nominateMe, assignRoles 
        vm.startPrank(address(daoMock));
        (
            address[] memory targetsOut, 
            uint256[] memory valuesOut, 
            bytes[] memory calldatasOut
            ) = Law(delegateSelect).executeLaw(charlotte, lawCalldataElect, bytes32(0));

        // assert 
        assertEq(targetsOut.length, 3);
        assertEq(valuesOut.length, 3);
        assertEq(calldatasOut.length, 3);
        for (uint256 i = 0; i < targetsOut.length; i++) {
            assertEq(targetsOut[i], address(daoMock));
            assertEq(valuesOut[i], 0);
            if (i != 0) {
                assertNotEq(calldatasOut[i], calldatasOut[i - 1]);
            }
        }
    }
    function testDelegatesReelectionWorks() public {
        // prep -- nominate all users
        address randomlySelect = laws[4];
        bytes memory lawCalldataNominate = abi.encode(true, false); // nominateMe, assignRoles 
        for (uint256 i = 0; i < users.length; i++) {
            vm.startPrank(address(daoMock));
            Law(randomlySelect).executeLaw(users[i], lawCalldataNominate, bytes32(0));
        }
        // act: first election 
        bytes memory lawCalldataElect = abi.encode(false, true); // nominateMe, assignRoles 
        vm.startPrank(address(daoMock));
        (
            address[] memory targetsOut1, 
            uint256[] memory valuesOut1, 
            bytes[] memory calldatasOut1
            ) = Law(randomlySelect).executeLaw(charlotte, lawCalldataElect, bytes32(0));

        vm.roll(block.number + 100); 

        // act: second election
        vm.startPrank(address(daoMock));
        (
            address[] memory targetsOut2, 
            uint256[] memory valuesOut2, 
            bytes[] memory calldatasOut2
            ) = Law(randomlySelect).executeLaw(charlotte, lawCalldataElect, bytes32(0));

        // assert 
        assertEq(targetsOut2.length, 6);
        assertEq(valuesOut2.length, 6);
        assertEq(calldatasOut2.length, 6);
        assertNotEq(calldatasOut2, calldatasOut1);
    }
}

//////////////////////////////////////////////////
//              EXECUTIVE LAWS                  //
//////////////////////////////////////////////////
contract OpenActionTest is TestSetupImplementations {
    using ShortStrings for *;

    function testExecuteAction() public {
        address[] memory targetsIn = new address[](1);
        uint256[] memory valuesIn = new uint256[](1);
        bytes[] memory calldatasIn = new bytes[](1);
        targetsIn[0] = address(erc1155Mock);
        valuesIn[0] = 0;
        calldatasIn[0] = abi.encodeWithSignature("mintCoins(uint256)", 123);

        address openAction = laws[1];
        bytes memory lawCalldata = abi.encode(targetsIn, valuesIn, calldatasIn);
        vm.startPrank(address(daoMock));
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

contract ProposalOnlyTest is TestSetupImplementations {
    using ShortStrings for *;

    function testReturnDataProposalOnly() public {
        address proposalOnly = laws[7];
        bytes memory lawCalldata = abi.encode("mintCoins(uint256)", 123);

        vm.startPrank(address(daoMock));
        (
            address[] memory targetsOut, 
            uint256[] memory valuesOut, 
            bytes[] memory calldatasOut
            ) = Law(proposalOnly).executeLaw(address(0), lawCalldata, keccak256("this is a proposal"));

        assertEq(targetsOut[0], address(1));
        assertEq(valuesOut[0], 0);
    }
}

contract BespokeActionTest is TestSetupImplementations {
    function testReturnDataBespokeAction() public {
        // this bespoke action mints coins in the mock1155 contract. 
        address bespokeAction = laws[2];
        bytes memory lawCalldata = abi.encode(123); // the amount of coins to mint. 
        bytes memory expectedCalldata = abi.encodeWithSignature("mintCoins(uint256)", 123);  

        vm.startPrank(address(daoMock));
        (
            address[] memory targetsOut, 
            uint256[] memory valuesOut, 
            bytes[] memory calldatasOut
            ) = Law(bespokeAction).executeLaw(address(0), lawCalldata, keccak256("this is a proposal"));

        assertEq(targetsOut[0], address(erc1155Mock));
        assertEq(valuesOut[0], 0);
        assertEq(calldatasOut[0], expectedCalldata);
    }
}


