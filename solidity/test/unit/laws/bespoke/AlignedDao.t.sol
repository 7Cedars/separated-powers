// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.26;

// test setup
import "forge-std/Test.sol";
import { TestSetupAlignedDao } from "../../../TestSetup.t.sol";

// protocol
import { SeparatedPowers } from "../../../../src/SeparatedPowers.sol";
import { Law } from "../../../../src/Law.sol";
import { Erc721Mock } from "../../../mocks/Erc721Mock.sol";

// law contracts being tested
import { RevokeMembership } from "../../../../src/laws/bespoke/alignedDao/RevokeMembership.sol";
import { ReinstateRole } from "../../../../src/laws/bespoke/alignedDao/ReinstateRole.sol";
import { RequestPayment } from "../../../../src/laws/bespoke/alignedDao/RequestPayment.sol";
import { NftSelfSelect } from "../../../../src/laws/bespoke/alignedDao/NftSelfSelect.sol";

// openzeppelin contracts
import { ERC1155 } from "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";

contract NftSelfSelectTest is TestSetupAlignedDao {
    error SelfSelect__AccountDoesNotHaveRole();
    error SelfSelect__AccountAlreadyHasRole();
    error Erc721Check__DoesNotOwnToken();

    function testSelfSelectPassesWithValidNft() public {
        // prep
        address nftSelfSelect = laws[0];
        bytes memory lawCalldata = abi.encode(
            false // revoke
        );
        // give alice an nft
        vm.prank(alice);
        erc721Mock.cheatMint(123);

        // act
        vm.startPrank(address(daoMock));
        (address[] memory targetsOut, uint256[] memory valuesOut, bytes[] memory calldatasOut) = Law(nftSelfSelect)
            .executeLaw(
            alice, // alice = initiator
            lawCalldata,
            keccak256("Alice applies for role 1 with a valid nft")
        );

        // assert output
        assertEq(targetsOut[0], address(daoMock));
        assertEq(valuesOut[0], 0);
        assertEq(
            calldatasOut[0],
            abi.encodeWithSelector(
                SeparatedPowers.assignRole.selector,
                1, // roleId
                alice
            )
        ); // initiator
    }

    function testSelfSelectFailsWithInvalidNft() public {
        // prep
        address nftSelfSelect = laws[0];
        bytes memory lawCalldata = abi.encode(
            false // revoke
        );

        // act _ assert revert
        vm.startPrank(address(daoMock));
        vm.expectRevert(Erc721Check__DoesNotOwnToken.selector);
        (address[] memory targetsOut, uint256[] memory valuesOut, bytes[] memory calldatasOut) = Law(nftSelfSelect)
            .executeLaw(
            alice, // alice = initiator
            lawCalldata,
            keccak256("Alice applies for role 1 without a valid nft")
        );
    }
}

contract RevokeMembershipTest is TestSetupAlignedDao {
    function testRevokeSuccessfulWithValidNftHolder() public {
        // prep
        // give alice an nft - id = 123
        vm.prank(alice);
        Erc721Mock(erc721Mock).cheatMint(123);
        // assertNotEq(daoMock.hasRoleSince(alice, ROLE_ONE), 0);
        // assign alice role 1
        vm.startPrank(address(daoMock));
        SeparatedPowers(daoMock).assignRole(1, alice);
        // address revokeMembership
        address revokeMembership = laws[1];
        bytes memory lawCalldata = abi.encode(
            123, // nft id
            alice // nft holder
        );

        // CONTINUE HERE
        // insnt this supposed to revert? As it is called from outside the dao? CHECK!
        // act
        (address[] memory targetsOut, uint256[] memory valuesOut, bytes[] memory calldatasOut) = Law(revokeMembership)
            .executeLaw(
            alice, // alice = initiator
            lawCalldata,
            keccak256("Alice gets her role revoked")
        );

        // assert output
        assertEq(targetsOut[0], address(daoMock));
        assertEq(valuesOut[0], 0);
        assertEq(
            calldatasOut[0],
            abi.encodeWithSelector(
                SeparatedPowers.revokeRole.selector,
                1, // roleId
                alice
            )
        );
        assertEq(targetsOut[1], address(erc721Mock));
        assertEq(valuesOut[1], 0);
        assertEq(
            calldatasOut[1],
            abi.encodeWithSelector(
                Erc721Mock.burnNFT.selector,
                123, // roleId
                alice
            )
        );
    }

    function testRevokeFailsWithInvalidNftHolder() public {
        // prep
        // give alice an nft - id = 123
        vm.prank(alice);
        Erc721Mock(erc721Mock).cheatMint(123);
        // assertNotEq(daoMock.hasRoleSince(alice, ROLE_ONE), 0);
        // assign alice role 1
        vm.startPrank(address(daoMock));
        SeparatedPowers(daoMock).assignRole(1, alice);
        // address revokeMembership
        address revokeMembership = laws[1];
        bytes memory lawCalldata = abi.encode(
            123, // nft id
            alice // nft holder
        );

        // act
        (address[] memory targetsOut, uint256[] memory valuesOut, bytes[] memory calldatasOut) = Law(revokeMembership)
            .executeLaw(
            alice, // alice = initiator
            lawCalldata,
            keccak256("Alice gets her role revoked")
        );

        // assert output
        assertEq(targetsOut[0], address(daoMock));
        assertEq(valuesOut[0], 0);
        assertEq(
            calldatasOut[0],
            abi.encodeWithSelector(
                SeparatedPowers.revokeRole.selector,
                1, // roleId
                alice
            )
        );
        assertEq(targetsOut[1], address(erc721Mock));
        assertEq(valuesOut[1], 0);
        assertEq(
            calldatasOut[1],
            abi.encodeWithSelector(
                Erc721Mock.burnNFT.selector,
                123, // roleId
                alice
            )
        );
    }
}

contract ReinstateRoleTest is TestSetupAlignedDao {
    function testReinstateSuccessfulWithValidRevokedRole() public {
        // prep
        address reinstateRole = laws[2];
        bytes memory lawCalldata = abi.encode(
            123, // roleId
            alice // nft holder
        );

        // note that this law needs to be deployed with a needCompleted check.
        // As this is not the case (we are only testing the law itself), this law can be used to give anyone role 1 + nft
        // act
        vm.prank(address(daoMock));
        (address[] memory targetsOut, uint256[] memory valuesOut, bytes[] memory calldatasOut) = Law(reinstateRole)
            .executeLaw(
            alice, // alice = initiator
            lawCalldata,
            keccak256("Alice gets role 1 + nft")
        );

        // assert output
        assertEq(targetsOut[0], address(daoMock));
        assertEq(valuesOut[0], 0);
        assertEq(
            calldatasOut[0],
            abi.encodeWithSelector(
                SeparatedPowers.assignRole.selector,
                1, // roleId
                alice
            )
        );
        assertEq(targetsOut[1], address(erc721Mock));
        assertEq(valuesOut[1], 0);
        assertEq(
            calldatasOut[1],
            abi.encodeWithSelector(
                Erc721Mock.mintNFT.selector,
                123, // token id
                alice // account
            )
        );
    }
}

contract RequestPaymentTest is TestSetupAlignedDao {
    function testRequestPaymentResultsInCorrectPayment() public {
        // prep
        address requestPayment = laws[3];
        bytes memory lawCalldata = abi.encode();

        vm.roll(block.number + 101); // delay set in law = 100

        // act
        vm.startPrank(address(daoMock));
        (address[] memory targetsOut, uint256[] memory valuesOut, bytes[] memory calldatasOut) = Law(requestPayment)
            .executeLaw(
            alice, // alice = initiator
            lawCalldata,
            keccak256("Alice requests payment")
        );

        // assert output
        assertEq(targetsOut[0], address(erc1155Mock));
        assertEq(valuesOut[0], 0);
        assertEq(
            calldatasOut[0],
            abi.encodeWithSelector(
                ERC1155.safeTransferFrom.selector,
                address(daoMock), // from
                alice, // to
                0, // tokenId
                5000, // amount
                "" // empty data
            )
        );
        // assert state
        uint256 paymentBlock = RequestPayment(requestPayment).lastTransaction(alice);
        assertEq(paymentBlock, block.number);
    }

    function testRequestPaymentRevertsIfDelayNotPassed() public {
        // prep
        address requestPayment = laws[3];
        bytes memory lawCalldata = abi.encode();
        uint256 timeslotOne = block.number + 101;
        uint256 timeslotTwo = timeslotOne + 10; // delay set in law = 100, 10 will not pass the delay.

        // first payment request
        vm.roll(timeslotOne);
        vm.startPrank(address(daoMock));
        Law(requestPayment).executeLaw(
            alice, // alice = initiator
            lawCalldata,
            keccak256("Alice requests payment")
        );

        // act, second payment request
        vm.expectRevert();
        vm.roll(timeslotTwo);
        vm.startPrank(address(daoMock));
        Law(requestPayment).executeLaw(
            alice, // alice = initiator
            lawCalldata,
            keccak256("Alice requests payment again")
        );
        // assert state
        uint256 paymentBlock = RequestPayment(requestPayment).lastTransaction(alice);
        assertEq(paymentBlock, timeslotOne);
    }
}
