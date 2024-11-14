// // SPDX-License-Identifier: UNLICENSED
// pragma solidity 0.8.26;

// import {Test, console, console2} from "lib/forge-std/src/Test.sol";
// import {DeployAgDao} from "../../../script/DeployAgDao.s.sol";
// import {AgDao} from   "../src/implementation/DAOs/AgDao.sol";
// import {AgCoins} from "../src/implementation/DAOs/AgCoins.sol";
// import {IAuthoritiesManager} from "../src/interfaces/IAuthoritiesManager.sol";

// contract DeployAgDaoTest is Test {

//   /* addresses */
//   address alice = makeAddr("alice");

//   ///////////////////////////////////////////////
//   ///                   Setup                 ///
//   ///////////////////////////////////////////////
//   function setUp() public {
//     vm.roll(10); // protocol only works correctly of block.number > 0
//   }

//   ///////////////////////////////////////////////
//   ///                   Tests                 ///
//   ///////////////////////////////////////////////

//   function testAgDaoIsDeployed() public {
//     DeployAgDao deployer = new DeployAgDao();
//     (AgDao agDao, ,  ) = deployer.run();
//     assert(address(agDao) != address(0));
//   }

//   function testAgCoinsIsDeployed() public {
//      DeployAgDao deployer = new DeployAgDao();
//     (, AgCoins agCoins, ) = deployer.run();
//     assert(address(agCoins) != address(0));
//   }

//   function testLawsAreDeployed() public {
//     DeployAgDao deployer = new DeployAgDao();
//     (, , address[] memory constituentLaws) = deployer.run();
//     for (uint256 i = 0; i < constituentLaws.length; i++) {
//       assert(constituentLaws[i].code.length != 0);
//     }
//   }

//   // function testLawsAreInitialisedCorrectly() public {
//   //   IAuthoritiesManager.ConstituentRole[] memory constitutionalRoles;
//   //   DeployAgDao deployer = new DeployAgDao();
//   //   (AgDao agDao, AgCoins agCoins, address[] memory constituentLaws) = deployer.run();
//   //   agDao.constitute(constituentLaws, constitutionalRoles);

//   //   for (uint256 i = 0; i < constituentLaws.length; i++) {
//   //     bool isActive = agDao.activeLaws(constituentLaws[i]);
//   //     assert(isActive);
//   //   }
//   // }
// }
