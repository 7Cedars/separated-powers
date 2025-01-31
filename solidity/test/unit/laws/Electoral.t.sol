// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.26;

import "forge-std/Test.sol";
import "@openzeppelin/contracts/utils/ShortStrings.sol";
import { SeparatedPowers } from "../../../src/SeparatedPowers.sol";
import { TestSetupLaws } from "../../TestSetup.t.sol";
import { Law } from "../../../src/Law.sol";
import { Erc1155Mock } from "../../mocks/Erc1155Mock.sol";
import { OpenAction } from "../../../src/laws/executive/OpenAction.sol";

contract DirectSelectTest is TestSetupLaws {
    using ShortStrings for *;

    error DirectSelect__AccountDoesNotHaveRole();
    error DirectSelect__AccountAlreadyHasRole();

    function testAssignSucceeds() public {
        // prep: check if alice does NOT have role 3
        assertEq(daoMock.hasRoleSince(charlotte, ROLE_THREE), 0);
        address directSelect = laws[4];
        bytes memory lawCalldata = abi.encode(false, charlotte); // revoke
        bytes memory expectedCalldata =
            abi.encodeWithSelector(SeparatedPowers.assignRole.selector, ROLE_THREE, charlotte);

        vm.startPrank(address(daoMock));
        (address[] memory targetsOut, uint256[] memory valuesOut, bytes[] memory calldatasOut) =
            Law(directSelect).executeLaw(charlotte, lawCalldata, bytes32(0));

        assertEq(targetsOut[0], address(daoMock));
        assertEq(valuesOut[0], 0);
        assertEq(calldatasOut[0], expectedCalldata);
    }

    function testAssignReverts() public {
        // prep: check if alice does have role 3
        assertNotEq(daoMock.hasRoleSince(alice, ROLE_THREE), 0);
        address directSelect = laws[4];
        bytes memory lawCalldata = abi.encode(false, alice); // revoke
        abi.encodeWithSelector(SeparatedPowers.assignRole.selector, ROLE_THREE, alice);

        // act & assert
        vm.startPrank(address(daoMock));
        vm.expectRevert(DirectSelect__AccountAlreadyHasRole.selector);
        Law(directSelect).executeLaw(alice, lawCalldata, bytes32(0));
    }

    function testRevokeSucceeds() public {
        // prep: check if alice does have role 3
        assertNotEq(daoMock.hasRoleSince(alice, ROLE_THREE), 0);
        address directSelect = laws[4];
        bytes memory lawCalldata = abi.encode(true, alice); // revoke
        bytes memory expectedCalldata = abi.encodeWithSelector(SeparatedPowers.revokeRole.selector, ROLE_THREE, alice);
        vm.startPrank(address(daoMock));
        (address[] memory targetsOut, uint256[] memory valuesOut, bytes[] memory calldatasOut) =
            Law(directSelect).executeLaw(alice, lawCalldata, bytes32(0));

        assertEq(targetsOut[0], address(daoMock));
        assertEq(valuesOut[0], 0);
        assertEq(calldatasOut[0], expectedCalldata);
    }

    function testRevokeReverts() public {
        // prep: check if alice does have role 3
        assertEq(daoMock.hasRoleSince(charlotte, ROLE_THREE), 0);
        address directSelect = laws[4];
        bytes memory lawCalldata = abi.encode(true, charlotte); // revoke
        abi.encodeWithSelector(SeparatedPowers.revokeRole.selector, ROLE_THREE, charlotte);

        // act & assert
        vm.expectRevert(DirectSelect__AccountDoesNotHaveRole.selector);
        vm.startPrank(address(daoMock));
        Law(directSelect).executeLaw(charlotte, lawCalldata, bytes32(0));
    }
}

contract NominateMeTest is TestSetupLaws {
    using ShortStrings for *;

    error NominateMe__NomineeAlreadyNominated();
    error NominateMe__NomineeNotNominated();

    event NominateMe__NominationReceived(address indexed nominee);
    event NominateMe__NominationRevoked(address indexed nominee);

    function testAssignNominationSucceeds() public {
        // prep
        address nominateMe = laws[3];
        bytes memory lawCalldata = abi.encode(true); // nominateMe

        // act & assert
        vm.expectEmit(true, false, false, false);
        emit NominateMe__NominationReceived(charlotte);
        vm.startPrank(address(daoMock));
        Law(nominateMe).executeLaw(charlotte, lawCalldata, bytes32(0));
    }

    // test addition to count

    function testAssignNominationRevertsWhenAlreadyNominated() public {
        // prep
        address nominateMe = laws[3];
        bytes memory lawCalldata = abi.encode(true); // nominateMe

        // nominate once..
        vm.startPrank(address(daoMock));
        Law(nominateMe).executeLaw(charlotte, lawCalldata, bytes32(0));

        // and try to nominate twice.
        vm.startPrank(address(daoMock));
        vm.expectRevert(NominateMe__NomineeAlreadyNominated.selector);
        Law(nominateMe).executeLaw(charlotte, lawCalldata, bytes32(0));
    }

    function testRevokeNominationSucceeds() public {
        // prep 1: nominate charlotte
        address nominateMe = laws[3];
        bytes memory lawCalldata1 = abi.encode(true); // nominateMe
        vm.startPrank(address(daoMock));
        Law(nominateMe).executeLaw(charlotte, lawCalldata1, bytes32(0));

        // prep 2: revoke nomination.
        bytes memory lawCalldata2 = abi.encode(false); // revokeNomination

        // act & assert
        vm.expectEmit(true, false, false, false);
        emit NominateMe__NominationRevoked(charlotte);
        vm.startPrank(address(daoMock));
        Law(nominateMe).executeLaw(charlotte, lawCalldata2, bytes32(0));
    }

    // test subtraction from count

    function testRevokeNominationRevertsWhenNotNominated() public {
        // prep
        address nominateMe = laws[3];
        bytes memory lawCalldata = abi.encode(false); // revokeNomination

        // charlotte tries to revoke nomination, without being nominated.
        vm.startPrank(address(daoMock));
        vm.expectRevert(NominateMe__NomineeNotNominated.selector);
        Law(nominateMe).executeLaw(charlotte, lawCalldata, bytes32(0));
    }
}

contract RandomlySelectTest is TestSetupLaws {
    using ShortStrings for *;

    function testAssignRolesWithFewNominees() public {
        // prep
        address nominateMe = laws[3];
        address randomlySelect = laws[5];

        bytes memory lawCalldataNominate = abi.encode(true);
        bytes memory lawCalldataElect = abi.encode(new address[](0)); // no one to revoke
        bytes memory expectedCalldata =
            abi.encodeWithSelector(SeparatedPowers.assignRole.selector, ROLE_THREE, charlotte);
        vm.startPrank(address(daoMock));
        Law(nominateMe).executeLaw(charlotte, lawCalldataNominate, bytes32(0));

        // act
        vm.startPrank(address(daoMock));
        (address[] memory targetsOut, uint256[] memory valuesOut, bytes[] memory calldatasOut) =
            Law(randomlySelect).executeLaw(charlotte, lawCalldataElect, bytes32(0));

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
        address nominateMe = laws[3];
        address randomlySelect = laws[5];

        bytes memory lawCalldataNominate = abi.encode(true); // nominateMe
        for (uint256 i = 0; i < users.length; i++) {
            vm.startPrank(address(daoMock));
            Law(nominateMe).executeLaw(users[i], lawCalldataNominate, bytes32(0));
        }
        // act
        bytes memory lawCalldataElect = abi.encode(new address[](0)); // no one to revoke
        vm.startPrank(address(daoMock));
        (address[] memory targetsOut, uint256[] memory valuesOut, bytes[] memory calldatasOut) =
            Law(randomlySelect).executeLaw(charlotte, lawCalldataElect, bytes32(0));

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
        address nominateMe = laws[3];
        address randomlySelect = laws[5];
        bytes memory lawCalldataNominate = abi.encode(true); // nominateMe
        for (uint256 i = 0; i < users.length; i++) {
            vm.startPrank(address(daoMock));
            Law(nominateMe).executeLaw(users[i], lawCalldataNominate, bytes32(0));
        }
        // act: first election
        bytes memory lawCalldataElect = abi.encode(new address[](0)); // no one to revoke
        vm.startPrank(address(daoMock));
        (,, bytes[] memory calldatasOut1) = Law(randomlySelect).executeLaw(charlotte, lawCalldataElect, bytes32(0));

        vm.roll(block.number + block.number + 100);

        // act: second election
        vm.startPrank(address(daoMock));
        address[] memory revokees = new address[](3);
        revokees[0] = users[0];
        revokees[1] = users[1];
        revokees[2] = users[2];
        bytes memory lawCalldataElect2 = abi.encode(revokees); // no one to revoke
        (address[] memory targetsOut2, uint256[] memory valuesOut2, bytes[] memory calldatasOut2) =
            Law(randomlySelect).executeLaw(charlotte, lawCalldataElect2, bytes32(0));

        // assert
        assertEq(targetsOut2.length, 6);
        assertEq(valuesOut2.length, 6);
        assertEq(calldatasOut2.length, 6);
        assertNotEq(calldatasOut2, calldatasOut1);
    }
}

contract TokenSelectTest is TestSetupLaws {
    using ShortStrings for *;

    function testAssignTokenRolesWithFewNominees() public {
        // prep -- nominate charlotte
        address nominateMe = laws[3];
        address tokenSelect = laws[6];
        bytes memory lawCalldataNominate = abi.encode(true); // nominateMe
        bytes memory lawCalldataElect = abi.encode(new address[](0)); // no one to revoke
        bytes memory expectedCalldata =
            abi.encodeWithSelector(SeparatedPowers.assignRole.selector, ROLE_THREE, charlotte);
        vm.startPrank(address(daoMock));
        Law(nominateMe).executeLaw(charlotte, lawCalldataNominate, bytes32(0));

        // act
        vm.startPrank(address(daoMock));
        (address[] memory targetsOut, uint256[] memory valuesOut, bytes[] memory calldatasOut) =
            Law(tokenSelect).executeLaw(charlotte, lawCalldataElect, bytes32(0));

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
        address nominateMe = laws[3];
        address tokenSelect = laws[6];
        bytes memory lawCalldataNominate = abi.encode(true); // nominateMe
        for (uint256 i = 0; i < users.length; i++) {
            vm.startPrank(address(daoMock));
            Law(nominateMe).executeLaw(users[i], lawCalldataNominate, bytes32(0));
        }
        // act
        bytes memory lawCalldataElect = abi.encode(new address[](0)); // no one to revoke
        vm.startPrank(address(daoMock));
        (address[] memory targetsOut, uint256[] memory valuesOut, bytes[] memory calldatasOut) =
            Law(tokenSelect).executeLaw(charlotte, lawCalldataElect, bytes32(0));

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
        address nominateMe = laws[3];
        address tokenSelect = laws[6];
        bytes memory lawCalldataNominate = abi.encode(true); // nominateMe
        for (uint256 i = 0; i < users.length; i++) {
            vm.startPrank(address(daoMock));
            Law(nominateMe).executeLaw(users[i], lawCalldataNominate, bytes32(0));
        }
        // act: first election
        bytes memory lawCalldataElect = abi.encode(new address[](0)); // no one to revoke
        vm.startPrank(address(daoMock));
        (,, bytes[] memory calldatasOut1) = Law(tokenSelect).executeLaw(charlotte, lawCalldataElect, bytes32(0));

        vm.roll(block.number + block.number + 100);

        // act: second election
        address[] memory revokees = new address[](3);
        revokees[0] = users[0];
        revokees[1] = users[1];
        revokees[2] = users[2];
        bytes memory lawCalldataElect2 = abi.encode(revokees);
        vm.startPrank(address(daoMock));
        (address[] memory targetsOut2, uint256[] memory valuesOut2, bytes[] memory calldatasOut2) =
            Law(tokenSelect).executeLaw(charlotte, lawCalldataElect2, bytes32(0));

        // assert
        assertEq(targetsOut2.length, 6);
        assertEq(valuesOut2.length, 6);
        assertEq(calldatasOut2.length, 6);
        assertNotEq(calldatasOut2, calldatasOut1);
    }
}

contract DelegateSelectTest is TestSetupLaws {
    using ShortStrings for *;

    function testAssignDelegateRolesWithFewNominees() public {
        // prep -- nominate charlotte
        address nominateMe = laws[3];
        address delegateSelect = laws[7];
        bytes memory lawCalldataNominate = abi.encode(true); // nominateMe
        bytes memory lawCalldataElect = abi.encode(); // empty calldata
        bytes memory expectedCalldata =
            abi.encodeWithSelector(SeparatedPowers.assignRole.selector, ROLE_THREE, charlotte);
        vm.startPrank(address(daoMock));
        Law(nominateMe).executeLaw(charlotte, lawCalldataNominate, bytes32(0));

        // act
        vm.startPrank(address(daoMock));
        (address[] memory targetsOut, uint256[] memory valuesOut, bytes[] memory calldatasOut) =
            Law(delegateSelect).executeLaw(charlotte, lawCalldataElect, bytes32(0));

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
        address nominateMe = laws[3];
        address delegateSelect = laws[7];
        bytes memory lawCalldataNominate = abi.encode(true); // nominateMe
        // nominate
        for (uint256 i = 4; i < users.length; i++) {
            vm.prank(address(daoMock));
            Law(nominateMe).executeLaw(users[i], lawCalldataNominate, bytes32(0));
            vm.stopPrank();
        }
        // mint vote
        for (uint256 i = 0; i < users.length; i++) {
            vm.startPrank(users[i]);
            erc20VotesMock.mintVotes(100 + i * 2);
            erc20VotesMock.delegate(users[i]); // delegate votes to themselves
            vm.stopPrank();
        }

        // act
        bytes memory lawCalldataElect = abi.encode(new address[](0)); // empty calldata
        vm.startPrank(address(daoMock));
        (address[] memory targetsOut, uint256[] memory valuesOut, bytes[] memory calldatasOut) =
            Law(delegateSelect).executeLaw(charlotte, lawCalldataElect, bytes32(0));

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
        address nominateMe = laws[3];
        address delegateSelect = laws[7];
        bytes memory lawCalldataNominate = abi.encode(true); // nominateMe
        for (uint256 i = 0; i < users.length; i++) {
            vm.startPrank(address(daoMock));
            Law(nominateMe).executeLaw(users[i], lawCalldataNominate, bytes32(0));
        }
        // act: first election
        bytes memory lawCalldataElect = abi.encode(new address[](0)); // empty calldata
        vm.startPrank(address(daoMock));
        (,, bytes[] memory calldatasOut1) = Law(delegateSelect).executeLaw(charlotte, lawCalldataElect, bytes32(0));

        vm.roll(block.number + block.number + 100);

        // act: second election
        address[] memory revokees = new address[](3);
        revokees[0] = users[0];
        revokees[1] = users[1];
        revokees[2] = users[2];
        bytes memory lawCalldataElect2 = abi.encode(revokees);
        vm.startPrank(address(daoMock));
        (address[] memory targetsOut2, uint256[] memory valuesOut2, bytes[] memory calldatasOut2) =
            Law(delegateSelect).executeLaw(charlotte, lawCalldataElect2, bytes32(0));

        // assert
        assertEq(targetsOut2.length, 6);
        assertEq(valuesOut2.length, 6);
        assertEq(calldatasOut2.length, 6);
        assertNotEq(calldatasOut2, calldatasOut1);
    }
}
