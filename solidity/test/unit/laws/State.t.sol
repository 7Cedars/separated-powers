// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.26;

// test setup
import "forge-std/Test.sol";
import { TestSetupState } from "../../TestSetup.t.sol";

// protocol
import { SeparatedPowers } from "../../../src/SeparatedPowers.sol";
import { Law } from "../../../src/Law.sol";

// law contracts being tested
import { AddressesMapping } from "../../../src/laws/state/AddressesMapping.sol";
import { StringsArray } from "../../../src/laws/state/StringsArray.sol";
import { TokensArray } from "../../../src/laws/state/TokensArray.sol";

contract AddressMappingTest is TestSetupState {
    error AddressesMapping__AlreadyTrue();
    error AddressesMapping__AlreadyFalse();

    event AddressesMapping__Added(address account);
    event AddressesMapping__Removed(address account);

    function testSuccessfulAddingAddress() public {
        // prep
        address addressesMapping = laws[0];
        bytes memory lawCalldata = abi.encode(
            address(123), // address
            true // add
        );

        // act + assert emit
        vm.expectEmit(true, false, false, false);
        emit AddressesMapping__Added(address(123));
        vm.startPrank(address(daoMock));
        (address[] memory targetsOut, uint256[] memory valuesOut, bytes[] memory calldatasOut) =
            Law(addressesMapping).executeLaw(address(0), lawCalldata, keccak256("Adding an address"));

        // assert state
        assertEq(AddressesMapping(addressesMapping).addresses(address(123)), true);

        // assert output
        assertEq(targetsOut[0], address(1));
        assertEq(valuesOut[0], 0);
        assertEq(calldatasOut[0], abi.encode());
    }

    function testAddingAddressRevertsIfAlreadyAdded() public {
        // prep
        address addressesMapping = laws[0];
        bytes memory lawCalldata = abi.encode(
            address(123), // address
            true // add
        );
        vm.startPrank(address(daoMock));
        Law(addressesMapping).executeLaw(address(0), lawCalldata, keccak256("Adding an address first time"));

        // act
        vm.startPrank(address(daoMock));
        vm.expectRevert(AddressesMapping__AlreadyTrue.selector);
        Law(addressesMapping).executeLaw(address(0), lawCalldata, keccak256("Adding an address a second time"));

        // assert state
        assertEq(AddressesMapping(addressesMapping).addresses(address(123)), true);
    }

    function testSuccessfulRemovingAddress() public {
        // prep
        address addressesMapping = laws[0];
        bytes memory lawCalldataAdd = abi.encode(
            address(123), // address
            true // add
        );
        bytes memory lawCalldataRemove = abi.encode(
            address(123), // address
            false // add
        );

        vm.startPrank(address(daoMock));
        Law(addressesMapping).executeLaw(address(0), lawCalldataAdd, keccak256("Adding an address to be removed"));

        // act + emit
        vm.startPrank(address(daoMock));
        vm.expectEmit(true, false, false, false);
        emit AddressesMapping__Removed(address(123));
        (address[] memory targetsOut, uint256[] memory valuesOut, bytes[] memory calldatasOut) =
            Law(addressesMapping).executeLaw(address(0), lawCalldataRemove, keccak256("Removing an address"));

        // assert state
        assertEq(AddressesMapping(addressesMapping).addresses(address(123)), false);
        // assert output
        assertEq(targetsOut[0], address(1));
        assertEq(valuesOut[0], 0);
        assertEq(calldatasOut[0], abi.encode());
    }

    function testRemovingAddressRevertsIfNotAdded() public {
        // prep
        address addressesMapping = laws[0];
        bytes memory lawCalldata = abi.encode(
            address(123), // address
            false // add
        );

        // act
        vm.startPrank(address(daoMock));
        vm.expectRevert(AddressesMapping__AlreadyFalse.selector);
        Law(addressesMapping).executeLaw(address(0), lawCalldata, keccak256("Removing an address not added"));

        // assert state
        assertEq(AddressesMapping(addressesMapping).addresses(address(123)), false);
    }
}

contract StringsArrayTest is TestSetupState {
    error StringsArray__StringNotFound();

    event StringsArray__StringAdded(string str);
    event StringsArray__StringRemoved(string str);

    function testSuccessfulAddingString() public {
        address stringsArray = laws[1];
        // prep
        bytes memory lawCalldata = abi.encode("hello world", true);

        // act + assert emit
        vm.startPrank(address(daoMock));
        vm.expectEmit(true, false, false, false);
        emit StringsArray__StringAdded("hello world");
        (address[] memory targetsOut, uint256[] memory valuesOut, bytes[] memory calldatasOut) =
            Law(stringsArray).executeLaw(address(0), lawCalldata, keccak256("Adding a string"));

        // assert state
        assertEq(StringsArray(stringsArray).strings(0), "hello world");
        assertEq(StringsArray(stringsArray).numberOfStrings(), 1);
        // assert output
        assertEq(targetsOut[0], address(1));
        assertEq(valuesOut[0], 0);
        assertEq(calldatasOut[0], abi.encode());
    }

    function testSuccessfulRemovingString() public {
        // prep
        address stringsArray = laws[1];
        bytes memory lawCalldataAdd = abi.encode("hello world", true);
        bytes memory lawCalldataRemove = abi.encode("hello world", false);

        vm.startPrank(address(daoMock));
        Law(stringsArray).executeLaw(address(0), lawCalldataAdd, keccak256("Adding a string to be removed"));

        vm.startPrank(address(daoMock));
        vm.expectEmit(true, false, false, false);
        emit StringsArray__StringRemoved("hello world");
        (address[] memory targetsOut, uint256[] memory valuesOut, bytes[] memory calldatasOut) =
            Law(stringsArray).executeLaw(address(0), lawCalldataRemove, keccak256("Removing a string"));

        // assert state
        assertEq(StringsArray(stringsArray).numberOfStrings(), 0);
        // assert output
        assertEq(targetsOut[0], address(1));
        assertEq(valuesOut[0], 0);
        assertEq(calldatasOut[0], abi.encode());
    }

    function testRemovingStringRevertsIfNoneAdded() public {
        // prep
        address stringsArray = laws[1];
        bytes memory lawCalldata = abi.encode("hello world", false);

        // act
        vm.startPrank(address(daoMock));
        vm.expectRevert(StringsArray__StringNotFound.selector);
        Law(stringsArray).executeLaw(address(0), lawCalldata, keccak256("Removing a string not added"));
    }

    function testRemovingStringRevertsIfStringNotFound() public {
        // prep
        address stringsArray = laws[1];
        bytes memory lawCalldataAdd = abi.encode("hello world", true);
        bytes memory lawCalldataRemove = abi.encode("another string", false);

        vm.startPrank(address(daoMock));
        Law(stringsArray).executeLaw(address(0), lawCalldataAdd, keccak256("Adding a string not to be removed"));

        // act
        vm.startPrank(address(daoMock));
        vm.expectRevert(StringsArray__StringNotFound.selector);
        Law(stringsArray).executeLaw(address(0), lawCalldataRemove, keccak256("Removing a string that does not exist"));
    }
}

contract TokensArrayTest is TestSetupState {
    error TokensArray__TokenNotFound();

    event TokensArray__TokenAdded(address indexed tokenAddress, TokensArray.TokenType tokenType);
    event TokensArray__TokenRemoved(address indexed tokenAddress, TokensArray.TokenType tokenType);

    function testSuccessfulAddingToken() public {
        // prep
        address tokensArray = laws[2];
        bytes memory lawCalldata = abi.encode(
            address(123), // token address
            0, // token type
            true // add
        );

        // act + assert emit
        vm.startPrank(address(daoMock));
        vm.expectEmit(true, false, false, false);
        emit TokensArray__TokenAdded(address(123), TokensArray.TokenType(0));
        (address[] memory targetsOut, uint256[] memory valuesOut, bytes[] memory calldatasOut) =
            Law(tokensArray).executeLaw(address(0), lawCalldata, keccak256("Adding a token"));

        // assert state
        (address tokenAddress, TokensArray.TokenType tokenType) = TokensArray(tokensArray).tokens(0);
        assertEq(tokenAddress, address(123));
        assertEq(TokensArray(tokensArray).numberOfTokens(), 1);

        // assert output
        assertEq(targetsOut[0], address(1));
        assertEq(valuesOut[0], 0);
        assertEq(calldatasOut[0], abi.encode());
    }

    function testSuccessfulRemovingToken() public {
        // prep
        address tokensArray = laws[2];
        bytes memory lawCalldataAdd = abi.encode(
            address(123), // token address
            0, // token type
            true // add
        );
        bytes memory lawCalldataRemove = abi.encode(
            address(123), // token address
            0, // token type
            false // remove
        );
        vm.startPrank(address(daoMock));
        Law(tokensArray).executeLaw(address(0), lawCalldataAdd, keccak256("Adding a token"));

        // act + assert emit
        vm.startPrank(address(daoMock));
        vm.expectEmit(true, false, false, false);
        emit TokensArray__TokenRemoved(address(123), TokensArray.TokenType(0));
        (address[] memory targetsOut, uint256[] memory valuesOut, bytes[] memory calldatasOut) =
            Law(tokensArray).executeLaw(address(0), lawCalldataRemove, keccak256("Removing a token"));

        // assert state
        assertEq(TokensArray(tokensArray).numberOfTokens(), 0);
        // assert output
        assertEq(targetsOut[0], address(1));
        assertEq(valuesOut[0], 0);
        assertEq(calldatasOut[0], abi.encode());
    }

    function testRemovingTokenRevertsIfNotAdded() public {
        // prep
        address tokensArray = laws[2];
        bytes memory lawCalldataRemove = abi.encode(
            address(123), // token address
            0, // token type
            false // remove
        );

        // act + assert revert
        vm.startPrank(address(daoMock));
        vm.expectRevert(TokensArray__TokenNotFound.selector);
        Law(tokensArray).executeLaw(address(0), lawCalldataRemove, keccak256("Removing a non-existent token"));

        // assert state
        assertEq(TokensArray(tokensArray).numberOfTokens(), 0);
    }

    function testRemovingTokenRevertsIfTokenNotFound() public {
        // prep
        address tokensArray = laws[2];
        bytes memory lawCalldataAdd = abi.encode(
            address(321), // token address
            1, // token type
            true // add
        );
        bytes memory lawCalldataRemove = abi.encode(
            address(123), // token address
            0, // token type
            false // remove
        );
        vm.startPrank(address(daoMock));
        Law(tokensArray).executeLaw(address(0), lawCalldataAdd, keccak256("Adding a token"));

        // act + assert revert
        vm.startPrank(address(daoMock));
        vm.expectRevert(TokensArray__TokenNotFound.selector);
        Law(tokensArray).executeLaw(
            address(0), lawCalldataRemove, keccak256("Removing a token that had not been added")
        );

        // assert state
        assertEq(TokensArray(tokensArray).numberOfTokens(), 1);
    }
}
