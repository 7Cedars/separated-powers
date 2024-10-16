// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.26;

import {Test, console, console2} from "lib/forge-std/src/Test.sol";
import {DeployAgDao} from "../../../script/DeployAgDao.s.sol";
import {AgDao} from   "../../../src/implementation/AgDao.sol";
import {AgCoins} from "../../../src/implementation/AgCoins.sol";

contract SeparatedPowersTest is Test {
  DeployAgDao deployer = new DeployAgDao();

  ///////////////////////////////////////////////
  ///                   Setup                 ///
  ///////////////////////////////////////////////
  function setUp() public {     
    vm.roll(10); // protocol only works correctly of block.number > 0 
  }

  ///////////////////////////////////////////////
  ///                   Tests                 ///
  ///////////////////////////////////////////////

  function testAgDaoIsDeployed() public {
    (AgDao agDao, AgCoins agCoins, address[] memory constituentLaws ) = deployer.run(); 
    assert(address(agDao) != address(0));
  }

  function testAgCoinsIsDeployed() public {
    (AgDao agDao, AgCoins agCoins, address[] memory constituentLaws) = deployer.run(); 
    assert(address(agCoins) != address(0));
  }

  function testLawsAreDeployed() public {
    (AgDao agDao, AgCoins agCoins, address[] memory constituentLaws) = deployer.run(); 
    for (uint256 i = 0; i < constituentLaws.length; i++) {
      assert(constituentLaws[i].code.length != 0);
    }
  }

  function testLawsAreInitialisedCorrectly() public { 
    (AgDao agDao, AgCoins agCoins, address[] memory constituentLaws) = deployer.run(); 
    for (uint256 i = 0; i < constituentLaws.length; i++) {
      bool isActive = agDao.activeLaws(constituentLaws[i]);  
      assert(isActive);
    }
  }
}