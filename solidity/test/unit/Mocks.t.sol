// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.26;

import "forge-std/Test.sol";
import { Erc20VotesMock } from "../mocks/Erc20VotesMock.sol";
import { Erc721Mock } from "../mocks/Erc721Mock.sol";
import { Erc1155Mock } from "../mocks/Erc1155Mock.sol";


contract Erc20VotesMockTest is Test {
  Erc20VotesMock erc20VotesMock;
  
  function setUp() public {
    erc20VotesMock = new Erc20VotesMock();  
  }

  function testDeploy() public {
    assertEq(erc20VotesMock.totalSupply(), 0);
    assertEq(erc20VotesMock.name(), "Mock");
    assertEq(erc20VotesMock.symbol(), "MOCK");
  }

  function testMintVotesRevertsWithZeroAmount() public { 
    vm.expectRevert(Erc20VotesMock.Erc20Mock__NoZeroAmount.selector);
    erc20VotesMock.mintVotes(0);
  }  

  function testMintVotesRevertsIfMaxAmountExceeded() public {
    uint256 maxAmount = 100_000_000; 

    vm.expectRevert(abi.encodeWithSelector(
      Erc20VotesMock.Erc20Mock__AmountExceedsMax.selector, maxAmount + 1, maxAmount)
      );
    erc20VotesMock.mintVotes(maxAmount + 1);
  }

  function testMint() public {
    //prep 
    uint256 amountToMint = 50; 
    address mockAddress = makeAddr("mock");
    uint256 amountBeforeMint = erc20VotesMock.balanceOf(mockAddress);
    
    // act 
    vm.prank(mockAddress);
    erc20VotesMock.mintVotes(amountToMint);
    
    // assert 
    uint256 amountAfterMint = erc20VotesMock.balanceOf(mockAddress);
    assertEq(amountBeforeMint, 0);
    assertEq(amountAfterMint, amountToMint);
  }
}

contract Erc721MockTest is Test {
  Erc721Mock erc721Mock;
  
  function setUp() public {
    erc721Mock = new Erc721Mock();  
  }

  function testDeploy() public {
    assertEq(erc721Mock.name(), "mock");
    assertEq(erc721Mock.symbol(), "MOCK");
  }

  function testMintNFT() public {
    //prep 
    uint256 NftToMint = 5; 
    address mockAddress = makeAddr("mock");
    // check not owner before mint 
    assertEq(erc721Mock.balanceOf(mockAddress), 0);
    
    // act 
    vm.prank(mockAddress);
    erc721Mock.mintNFT(NftToMint);
    
    // assert owner after mint. 
    assertEq(erc721Mock.balanceOf(mockAddress), 1);
    assertEq(erc721Mock.ownerOf(NftToMint), mockAddress);
  }
}

contract Erc1155MockTest is Test {
  Erc1155Mock erc1155Mock;
  
  function setUp() public {
    erc1155Mock = new Erc1155Mock();  
  }

  function testDeploy() public {
    assertEq(erc1155Mock.uri(0), "mock");
  }

  function testMintCoinsRevertsWithZeroAmount() public { 
    vm.expectRevert(Erc1155Mock.Erc1155Mock__NoZeroAmount.selector);
    erc1155Mock.mintCoins(0);
  }  

  function testMintVotesRevertsIfMaxAmountExceeded() public {
    uint256 maxAmount = 100_000_000; 

    vm.expectRevert(abi.encodeWithSelector(
      Erc1155Mock.Erc1155Mock__AmountExceedsMax.selector, maxAmount + 1, maxAmount)
      );
    erc1155Mock.mintCoins(maxAmount + 1);
  }

  function testMint() public {
    //prep 
    uint256 amountToMint = 50; 
    address mockAddress = makeAddr("MockAddress");
    uint256 amountBeforeMint = erc1155Mock.balanceOf(mockAddress, 0);
    
    // act 
    vm.prank(mockAddress);
    erc1155Mock.mintCoins(amountToMint);
    
    // assert 
    uint256 amountAfterMint = erc1155Mock.balanceOf(mockAddress, 0);
    assertEq(amountBeforeMint, 0);
    assertEq(amountAfterMint, amountToMint);
  }
}

