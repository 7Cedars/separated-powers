// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.26;

// test setup
import "forge-std/Test.sol";
import { TestSetupAlignedDao } from "../../../TestSetup.t.sol";

// protocol 
import { SeparatedPowers } from "../../../../src/SeparatedPowers.sol";
import { Law } from "../../../../src/Law.sol";

// law contracts being tested
import { RevokeMembership } from "../../../../src/laws/bespoke/alignedDao/RevokeMembership.sol";
import { ReinstateRole } from "../../../../src/laws/bespoke/alignedDao/ReinstateRole.sol";
import { RequestPayment } from "../../../../src/laws/bespoke/alignedDao/RequestPayment.sol";
import { NftSelfSelect } from "../../../../src/laws/bespoke/alignedDao/NftSelfSelect.sol";

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
    (
      address[] memory targetsOut, 
      uint256[] memory valuesOut, 
      bytes[] memory calldatasOut
      ) = Law(nftSelfSelect).executeLaw(
        alice, // alice = initiator
        lawCalldata, 
        keccak256("Alice applies for role 1 with a valid nft")
        );

    // assert output
    assertEq(targetsOut[0], address(daoMock));
    assertEq(valuesOut[0], 0);
    assertEq(calldatasOut[0], abi.encodeWithSelector(
      SeparatedPowers.assignRole.selector, 
      1, // roleId
      alice
    )); // initiator
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
    (
      address[] memory targetsOut, 
      uint256[] memory valuesOut, 
      bytes[] memory calldatasOut
      ) = Law(nftSelfSelect).executeLaw(
        alice, // alice = initiator
        lawCalldata, 
        keccak256("Alice applies for role 1 without a valid nft")
        );
  }
}

contract RevokeMembershipTest is TestSetupAlignedDao {
  function testRevokeSuccessfulWithValidNftHolder() public {
    // prep 

    // act + emit

    // assert output
    // assert state
  }

  function testRevokeFailsWithInvalidNftHolder() public {
    // prep 

    // act + assert revert

    // assert state
  }
    
 
}

contract ReinstateRoleTest is TestSetupAlignedDao {
  function testReinstateSuccessfulWithValidRevokedRole() public {
    // prep 

    // act + emit

    // assert output
    // assert state
  
  }

  function testReinstateFailsWithInvalidRevokedRole() public {
    // prep 

    // act + assert revert

    // assert state
  }
}


contract RequestPaymentTest is TestSetupAlignedDao {
  function testRequestPaymentResultsInCorrectPayment() public {
    // prep 

    // act + emit

    // assert output
    // assert state
    
  }

  function testRequestPaymentRevertsIfDelayNotPassed() public {
    // prep 

    // act + assert revert

    // assert state
  }

  function testRequestPaymentRevertsIfNotEnoughFunds() public {
    // prep 

    // act + assert revert

    // assert state
  }
}

