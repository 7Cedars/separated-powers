// // SPDX-License-Identifier: UNLICENSED
// pragma solidity 0.8.26;

// import {Test, console, console2} from "lib/forge-std/src/Test.sol";
// import {DeployAgDao} from "../../../script/DeployAgDao.s.sol";
// import {SeparatedPowers} from "../src/SeparatedPowers.sol";
// import {AgDao} from   "../src/implementation/DAOs/AgDao.sol";
// import {AgCoins} from "../src/implementation/DAOs/AgCoins.sol";
// import {Law} from "../src/Law.sol";
// import {IAuthoritiesManager} from "../src/interfaces/IAuthoritiesManager.sol";
// import {ISeparatedPowers} from "../src/interfaces/ISeparatedPowers.sol";
// import "@openzeppelin/contracts/utils/ShortStrings.sol";

// // constitutional laws
// import {Admin_setLaw} from "../src/implementation/DAOs/laws/Admin_setLaw.sol";
// import {Public_assignRole} from "../src/implementation/DAOs/laws/Public_assignRole.sol";
// import {Public_challengeRevoke} from "../src/implementation/DAOs/laws/Public_challengeRevoke.sol";
// import {Member_proposeCoreValue} from "../src/implementation/DAOs/laws/Member_proposeCoreValue.sol";
// import {Senior_acceptProposedLaw} from "../src/implementation/DAOs/laws/Senior_acceptProposedLaw.sol";
// import {Senior_assignRole} from "../src/implementation/DAOs/laws/Senior_assignRole.sol";
// import {Senior_reinstateMember} from "../src/implementation/DAOs/laws/Senior_reinstateMember.sol";
// import {Senior_revokeRole} from "../src/implementation/DAOs/laws/Senior_revokeRole.sol";
// import {Whale_acceptCoreValue} from "../src/implementation/DAOs/laws/Whale_acceptCoreValue.sol";
// import {Member_assignWhale} from "../src/implementation/DAOs/laws/Member_assignWhale.sol";
// import {Whale_proposeLaw} from "../src/implementation/DAOs/laws/Whale_proposeLaw.sol";
// import {Whale_revokeMember} from "../src/implementation/DAOs/laws/Whale_revokeMember.sol";

// contract Member_assignWhaleTest is Test {
//   using ShortStrings for *;

//   /* Type declarations */
//   SeparatedPowers separatedPowers;
//   AgDao agDao;
//   AgCoins agCoins;
//   address[] constituentLaws;

//   /* addresses */
//   address alice = makeAddr("alice");
//   address bob = makeAddr("bob");
//   address charlotte = makeAddr("charlotte");
//   address david = makeAddr("david");
//   address eve = makeAddr("eve");
//   address frank = makeAddr("frank");

//   /* state variables */
//   uint48 public constant ADMIN_ROLE = type(uint48).min; // == 0
//   uint48 public constant PUBLIC_ROLE = type(uint48).max; // == a lot. This role is for everyone.
//   uint48 public constant SENIOR_ROLE = 1;
//   uint48 public constant WHALE_ROLE = 2;
//   uint48 public constant MEMBER_ROLE = 3;
//   bytes32 SALT = bytes32(hex'7ceda5');

//   /* modifiers */

//   ///////////////////////////////////////////////
//   ///                   Setup                 ///
//   ///////////////////////////////////////////////
//   function setUp() public {
//     vm.roll(10);
//     vm.startBroadcast(alice);
//       agDao = new AgDao();
//       agCoins = new AgCoins(address(agDao));
//     vm.stopBroadcast();

//     /* setup roles */
//     IAuthoritiesManager.ConstituentRole[] memory constituentRoles = new IAuthoritiesManager.ConstituentRole[](10);
//     constituentRoles[0] = IAuthoritiesManager.ConstituentRole(alice, MEMBER_ROLE);
//     constituentRoles[1] = IAuthoritiesManager.ConstituentRole(bob, MEMBER_ROLE);
//     constituentRoles[2] = IAuthoritiesManager.ConstituentRole(charlotte, MEMBER_ROLE);
//     constituentRoles[3] = IAuthoritiesManager.ConstituentRole(david, MEMBER_ROLE);
//     constituentRoles[4] = IAuthoritiesManager.ConstituentRole(eve, MEMBER_ROLE);
//     constituentRoles[5] = IAuthoritiesManager.ConstituentRole(alice, SENIOR_ROLE);
//     constituentRoles[6] = IAuthoritiesManager.ConstituentRole(bob, SENIOR_ROLE);
//     constituentRoles[7] = IAuthoritiesManager.ConstituentRole(charlotte, SENIOR_ROLE);
//     constituentRoles[8] = IAuthoritiesManager.ConstituentRole(david, WHALE_ROLE);
//     constituentRoles[9] = IAuthoritiesManager.ConstituentRole(eve, WHALE_ROLE);

//     /* setup laws */
//     constituentLaws = _deployLaws(payable(address(agDao)), address(agCoins));

//     vm.startBroadcast(alice);
//     agDao.constitute(constituentLaws, constituentRoles);
//     vm.stopBroadcast();
//   }

//   ///////////////////////////////////////////////
//   ///                    Tests                ///
//   ///////////////////////////////////////////////
//   function testWhaleRoleAssignedIfSufficientCoins() public {
//     vm.prank(alice);
//     agCoins.mintCoins(1_500_000);

//     uint256 balance = agCoins.balanceOf(alice);
//     assert(balance > 1_000_000);

//     string memory description = "Alice should be a whale.";
//     bytes memory lawCalldata = abi.encode(alice);

//     vm.prank(bob); // = is a member
//     agDao.execute(constituentLaws[3], lawCalldata, keccak256(bytes(description))); // = Member_assignWhale

//     uint48 since = agDao.hasRoleSince(alice, WHALE_ROLE);
//     assert(since != 0);
//   }

//   function testWhaleRoleNotAssignedIfInsufficientCoins() public {
//     uint256 balance = agCoins.balanceOf(alice);
//     assert(balance < 1_000_000);

//     string memory description = "Alice should be a whale.";
//     bytes memory lawCalldata = abi.encode(alice);

//     vm.prank(bob); // = is a member
//     vm.expectRevert(Member_assignWhale.Member_assignWhale__Error.selector);
//     agDao.execute(constituentLaws[3], lawCalldata, keccak256(bytes(description))); // = Member_assignWhale
//   }

//   function testWhaleRoleRevokedIfInsufficientCoins() public {
//     uint256 balance = agCoins.balanceOf(david); // = whale
//     assert(balance < 1_000_000); // david has fewer than 1_000_000 coins.

//     string memory description = "Eve is delisting david as whale.";
//     bytes memory lawCalldata = abi.encode(david);

//     vm.prank(eve); // = is a whale
//     agDao.execute(constituentLaws[3], lawCalldata, keccak256(bytes(description))); // = Member_assignWhale

//     uint48 since = agDao.hasRoleSince(david, WHALE_ROLE);
//     assert(since == 0);
//   }

//   function testWhaleRoleNotRevokedIfSufficientCoins() public {
//     vm.prank(david);
//     agCoins.mintCoins(1_500_000);
//     uint256 balance = agCoins.balanceOf(david); // = whale
//     assert(balance > 1_000_000); // david has more than 1_000_000 coins.

//     string memory description = "Eve is trying to delist david as whale but will fail.";
//     bytes memory lawCalldata = abi.encode(david);

//     vm.prank(eve); // = is a whale
//     vm.expectRevert(Member_assignWhale.Member_assignWhale__Error.selector);
//     agDao.execute(constituentLaws[3], lawCalldata, keccak256(bytes(description))); // = Member_assignWhale
//   }

//   ///////////////////////////////////////////////
//   ///                   Helpers               ///
//   ///////////////////////////////////////////////
//   function _deployLaws(address payable agDaoAddress_, address agCoinsAddress_) internal returns (address[] memory lawsArray) {
//       address[] memory laws = new address[](12);

//       // deploying laws //
//       vm.startPrank(bob);
//       // re assigning roles //
//       laws[0] = address(new Public_assignRole(agDaoAddress_));
//       laws[1] = address(new Senior_assignRole(agDaoAddress_, agCoinsAddress_));
//       laws[2] = address(new Senior_revokeRole(agDaoAddress_, agCoinsAddress_));
//       laws[3] = address(new Member_assignWhale(agDaoAddress_, agCoinsAddress_));

//       // re activating & deactivating laws  //
//       laws[4] = address(new Whale_proposeLaw(agDaoAddress_, agCoinsAddress_));
//       laws[5] = address(new Senior_acceptProposedLaw(agDaoAddress_, agCoinsAddress_, address(laws[4])));
//       laws[6] = address(new Admin_setLaw(agDaoAddress_, address(laws[5])));

//       // re updating core values //
//       laws[7] = address(new Member_proposeCoreValue(agDaoAddress_, agCoinsAddress_));
//       laws[8] = address(new Whale_acceptCoreValue(agDaoAddress_, agCoinsAddress_, address(laws[7])));

//       // re enforcing core values as requirement for external funding //
//       laws[9] = address(new Whale_revokeMember(agDaoAddress_, agCoinsAddress_));
//       laws[10] = address(new Public_challengeRevoke(agDaoAddress_, address(laws[9])));
//       laws[11] = address(new Senior_reinstateMember(agDaoAddress_, agCoinsAddress_, address(laws[10])));
//       vm.stopPrank();

//       return laws;
//     }
// }
