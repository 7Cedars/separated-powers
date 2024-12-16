// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.26;

import "forge-std/Test.sol";
import "@openzeppelin/contracts/utils/ShortStrings.sol";
import { ERC1155 } from "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";

import { SeparatedPowers } from "../../../src/SeparatedPowers.sol";
import { TestSetupLaws } from "../../TestSetup.t.sol";
import { Law } from "../../../src/Law.sol";
import { ILaw } from "../../../src/interfaces/ILaw.sol";
import { Erc1155Mock } from "../../mocks/Erc1155Mock.sol";
import { OpenAction } from "../../../src/laws/executive/OpenAction.sol";

import { BlacklistAccount } from "../../../src/laws/bespoke/BlacklistAccount.sol";
import { CommunityValues } from "../../../src/laws/bespoke/CommunityValues.sol";
import { LawWithBlacklistCheck } from "../../../src/laws/bespoke/LawWithBlacklistCheck.sol";
import { RequestPayment } from "../../../src/laws/bespoke/RequestPayment.sol";

contract BlacklistAccountTest is TestSetupLaws {
    error BlacklistAccount__AlreadyBlacklisted();
    error BlacklistAccount__NotBlacklisted();

    event BlacklistAccount__Added(address account);
    event BlacklistAccount__Removed(address account);

    function testBlacklistAccountSucceeds() public {
        // prep
        address blacklistAccount = laws[9];
        bytes memory lawCalldata = abi.encode(bob, true); // blacklist = true

        // act
        vm.expectEmit(true, false, false, false);
        emit BlacklistAccount__Added(bob);
        vm.startPrank(address(daoMock));
        Law(blacklistAccount).executeLaw(alice, lawCalldata, bytes32(0));

        // assert
        assertTrue(BlacklistAccount(blacklistAccount).blacklistedAccounts(bob));
    }

    function testBlacklistAccountRevertsIfAlreadyBlacklisted() public {
        // prep
        address blacklistAccount = laws[9];
        bytes memory lawCalldata = abi.encode(bob, true); // blacklist = true

        // blacklisting bob...
        vm.startPrank(address(daoMock));
        Law(blacklistAccount).executeLaw(alice, lawCalldata, bytes32(0));
        assertTrue(BlacklistAccount(blacklistAccount).blacklistedAccounts(bob));

        // act
        vm.expectRevert();
        vm.startPrank(address(daoMock));
        Law(blacklistAccount).executeLaw(alice, lawCalldata, bytes32(0));
    }

    function testDeblacklistAccountSucceeds() public {
        // prep
        address blacklistAccount = laws[9];
        bytes memory lawCalldata1 = abi.encode(bob, true); // blacklist = true
        bytes memory lawCalldata2 = abi.encode(bob, false); // blacklist = false

        // blacklisting bob...
        vm.startPrank(address(daoMock));
        Law(blacklistAccount).executeLaw(alice, lawCalldata1, bytes32(0));
        assertTrue(BlacklistAccount(blacklistAccount).blacklistedAccounts(bob));

        // act
        vm.expectEmit(true, false, false, false);
        emit BlacklistAccount__Removed(bob);
        vm.startPrank(address(daoMock));
        Law(blacklistAccount).executeLaw(alice, lawCalldata2, bytes32(0));
        assertFalse(BlacklistAccount(blacklistAccount).blacklistedAccounts(bob));
    }

    function testDeblacklistAccountRevertsIfNotBlacklisted() public {
        // prep
        address blacklistAccount = laws[9];
        bytes memory lawCalldata = abi.encode(bob, false); // blacklist = true

        // act & assert
        // trying to deblacklist bob...
        vm.startPrank(address(daoMock));
        vm.expectRevert();
        Law(blacklistAccount).executeLaw(alice, lawCalldata, bytes32(0));
    }
}

contract CommunityValuesTest is TestSetupLaws {
    error CommunityValues__ValueNotFound();

    event CommunityValues__Added(string value);
    event CommunityValues__Removed(string value);

    function testAddingCommunityValuesSucceeds() public {
        // prep
        address communityValues = laws[10];
        bytes memory lawCalldata = abi.encode("This is a value", true); // addValue = true

        // act
        vm.expectEmit(true, false, false, false);
        emit CommunityValues__Added("This is a value");
        vm.startPrank(address(daoMock));
        Law(communityValues).executeLaw(alice, lawCalldata, bytes32(0));

        // assert
        assertEq(CommunityValues(communityValues).numberOfValues(), 1);
        assertEq(CommunityValues(communityValues).values(0), "This is a value");
    }

    function testRemovingCommunityValuesSucceeds() public {
        // prep
        address communityValues = laws[10];
        bytes memory lawCalldata1 = abi.encode("This is a value", true); // addValue = true
        bytes memory lawCalldata2 = abi.encode("This is a value", false); // addValue = true

        vm.startPrank(address(daoMock));
        Law(communityValues).executeLaw(alice, lawCalldata1, bytes32(0));

        vm.expectEmit(true, false, false, false);
        emit CommunityValues__Removed("This is a value");
        Law(communityValues).executeLaw(alice, lawCalldata2, bytes32(0));

        // assert
        assertEq(CommunityValues(communityValues).numberOfValues(), 0);
    }

    function testRemovingCommunityValuesRevertsIfNotAdded() public {
        // prep
        address communityValues = laws[10];
        bytes memory lawCalldata1 = abi.encode("This is a value", true); // addValue = true
        bytes memory lawCalldata2 = abi.encode("This is not a value", false); // addValue = true

        vm.startPrank(address(daoMock));
        Law(communityValues).executeLaw(alice, lawCalldata1, bytes32(0));

        vm.expectRevert(CommunityValues__ValueNotFound.selector);
        Law(communityValues).executeLaw(alice, lawCalldata2, bytes32(0));
    }
}

contract LawWithBlacklistCheckTest is TestSetupLaws {
    error LawWithBlacklistCheck__NoZeroAddress();
    error LawWithBlacklistCheck__AccountBlacklisted();

    function testBlacklistAccountSucceeds() public {
        // prep
        address blacklistAccount = laws[9];
        address blacklistCheck = laws[11];
        bytes memory lawCalldata = abi.encode(bob, true); // blacklist = true

        // blacklisting bob...
        vm.startPrank(address(daoMock));
        Law(blacklistAccount).executeLaw(alice, lawCalldata, bytes32(0));
        assertTrue(BlacklistAccount(blacklistAccount).blacklistedAccounts(bob));

        // trying to execute law as bob.
        vm.expectRevert(LawWithBlacklistCheck__AccountBlacklisted.selector);
        vm.startPrank(address(daoMock));
        Law(blacklistCheck).executeLaw(bob, lawCalldata, bytes32(0));
    }

    function testBlacklistAccountRevertsIfZeroAddress() public {
        // prep
        ILaw.LawConfig memory lawConfig;

        // act
        vm.expectRevert(LawWithBlacklistCheck__NoZeroAddress.selector);
        new LawWithBlacklistCheck(
            "Law with Blacklist", // max 31 chars
            "A law that has a blacklist check added to the normal checks.",
            address(daoMock),
            1,
            lawConfig,
            address(0) // zero address
        );
    }
}

contract RequestPaymentTest is TestSetupLaws {
    error RequestPayment__DelayNotPassed();
    error RequestPayment__IncompleteConstructionParams();

    function testDeployRevertsWithZeroAddress() public {
        // prep
        ILaw.LawConfig memory lawConfig;

        // act
        vm.expectRevert(RequestPayment__IncompleteConstructionParams.selector);
        new RequestPayment(
            "Request Payment With 0 Address", // max 31 chars
            "A request payment law that has a zero address as input.",
            address(daoMock),
            1,
            lawConfig,
            address(0), // address erc1155Contract_, // = zero address
            0, // uint256 tokenId_,
            200, // uint256 amount_,
            200 // uint48 personalDelay_
        );
    }

    function testDeployRevertsWithZeroAmount() public {
        // prep
        ILaw.LawConfig memory lawConfig;

        // act
        vm.expectRevert(RequestPayment__IncompleteConstructionParams.selector);
        new RequestPayment(
            "Request Payment With 0 Amount", // max 31 chars
            "A request payment law that has a zero amount as input.",
            address(daoMock),
            1,
            lawConfig,
            address(123), // address erc1155Contract_,
            0, // uint256 tokenId_,
            0, // uint256 amount_, // = zero amount
            200 // uint48 personalDelay_
        );
    }

    function testDeploySucceeds() public {
        address requestPayment = laws[12];

        assertEq(RequestPayment(requestPayment).erc1155Contract(), address(erc1155Mock));
        assertEq(RequestPayment(requestPayment).tokenId(), 0);
        assertEq(RequestPayment(requestPayment).amount(), 300);
        assertEq(RequestPayment(requestPayment).personalDelay(), 200);
    }

    function testRequestPaymentSucceeds() public {
        // prep
        vm.roll(block.number + block.number + 400); // make sure we passed the delay for request.
        address requestPayment = laws[12];
        bytes memory lawCalldata = abi.encode(); // note: empty calldata
        bytes memory expectedCalldata =
            abi.encodeWithSelector(ERC1155.safeTransferFrom.selector, address(daoMock), alice, 300, 0, "");

        // act
        vm.startPrank(address(daoMock));
        (address[] memory targets, uint256[] memory values, bytes[] memory calldatas) =
            Law(requestPayment).executeLaw(alice, lawCalldata, bytes32(0));

        // assert
        assertEq(targets.length, 1);
        assertEq(values.length, 1);
        assertEq(calldatas.length, 1);
        assertEq(targets[0], address(erc1155Mock));
        assertEq(values[0], 0);
        assertEq(calldatas[0], expectedCalldata);

        // + test output.
    }

    function testRequestPaymentRevertsIfDelayNotPassed() public {
        // prep
        // note: no role. We are still at block.number 10.
        address requestPayment = laws[12];
        bytes memory lawCalldata = abi.encode(); // note: empty calldata

        vm.startPrank(address(daoMock));
        Law(requestPayment).executeLaw(alice, lawCalldata, bytes32(0));

        // at same time, try a second call...
        // act
        vm.startPrank(address(daoMock));
        vm.expectRevert(RequestPayment__DelayNotPassed.selector);
        Law(requestPayment).executeLaw(alice, lawCalldata, bytes32(0));
    }
}
