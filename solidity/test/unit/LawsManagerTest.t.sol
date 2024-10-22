// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.26;

import {Test, console, console2} from "lib/forge-std/src/Test.sol";
import {DeployAgDao} from "../../script/DeployAgDao.s.sol";
import {SeparatedPowers} from "../../src/SeparatedPowers.sol";
import {AgDao} from   "../../src/implementation/AgDao.sol";
import {AgCoins} from "../../src/implementation/AgCoins.sol";
import {Law} from "../../src/Law.sol";
import {IAuthoritiesManager} from "../../src/interfaces/IAuthoritiesManager.sol";
import {ISeparatedPowers} from "../../src/interfaces/ISeparatedPowers.sol";
import {LawsManager} from "../../src/LawsManager.sol";

// constitutional laws
import {Admin_setLaw} from "../../src/implementation/laws/Admin_setLaw.sol";
import {Public_assignRole} from "../../src/implementation/laws/Public_assignRole.sol";
import {Public_challengeRevoke} from "../../src/implementation/laws/Public_challengeRevoke.sol";
import {Member_proposeCoreValue} from "../../src/implementation/laws/Member_proposeCoreValue.sol";
import {Senior_acceptProposedLaw} from "../../src/implementation/laws/Senior_acceptProposedLaw.sol";
import {Senior_assignRole} from "../../src/implementation/laws/Senior_assignRole.sol";
import {Senior_reinstateMember} from "../../src/implementation/laws/Senior_reinstateMember.sol";
import {Senior_revokeRole} from "../../src/implementation/laws/Senior_revokeRole.sol";
import {Whale_acceptCoreValue} from "../../src/implementation/laws/Whale_acceptCoreValue.sol";
import {Member_assignWhale} from "../../src/implementation/laws/Member_assignWhale.sol";
import {Whale_proposeLaw} from "../../src/implementation/laws/Whale_proposeLaw.sol";
import {Whale_revokeMember} from "../../src/implementation/laws/Whale_revokeMember.sol";

contract LawsManagerTest is Test {
  /* Type declarations */
  SeparatedPowers separatedPowers;
  AgDao agDao;
  AgCoins agCoins;
  address[] constituentLaws; 


  /* addresses */
  address alice = makeAddr("alice");
  address bob = makeAddr("bob");
  address charlotte = makeAddr("charlotte");
  address david = makeAddr("david");
  address eve = makeAddr("eve");
  address frank = makeAddr("frank");

  /* state variables */
  uint64 public constant ADMIN_ROLE = type(uint64).min; // == 0
  uint64 public constant PUBLIC_ROLE = type(uint64).max; // == a lot. This role is for everyone. 
  uint64 public constant SENIOR_ROLE = 1; 
  uint64 public constant WHALE_ROLE = 2; 
  uint64 public constant MEMBER_ROLE = 3; 
  bytes32 SALT = bytes32(hex'7ceda5'); 

  /* modifiers */

  ///////////////////////////////////////////////
  ///                   Setup                 ///
  ///////////////////////////////////////////////
  function setUp() public {     
    vm.roll(10); 
    vm.startBroadcast(alice);
      agDao = new AgDao();
      agCoins = new AgCoins(address(agDao));
    vm.stopBroadcast();

    /* setup roles */
    IAuthoritiesManager.ConstituentRole[] memory constituentRoles = new IAuthoritiesManager.ConstituentRole[](10);
    constituentRoles[0] = IAuthoritiesManager.ConstituentRole(alice, MEMBER_ROLE);
    constituentRoles[1] = IAuthoritiesManager.ConstituentRole(bob, MEMBER_ROLE);
    constituentRoles[2] = IAuthoritiesManager.ConstituentRole(charlotte, MEMBER_ROLE);
    constituentRoles[3] = IAuthoritiesManager.ConstituentRole(david, MEMBER_ROLE);
    constituentRoles[4] = IAuthoritiesManager.ConstituentRole(eve, MEMBER_ROLE);
    constituentRoles[5] = IAuthoritiesManager.ConstituentRole(alice, SENIOR_ROLE);
    constituentRoles[6] = IAuthoritiesManager.ConstituentRole(bob, SENIOR_ROLE);
    constituentRoles[7] = IAuthoritiesManager.ConstituentRole(charlotte, SENIOR_ROLE);
    constituentRoles[8] = IAuthoritiesManager.ConstituentRole(david, WHALE_ROLE);
    constituentRoles[9] = IAuthoritiesManager.ConstituentRole(eve, WHALE_ROLE);

    /* setup laws */
    constituentLaws = _deployLaws(payable(address(agDao)), address(agCoins));
    
    vm.startBroadcast(alice);
    agDao.constitute(constituentLaws, constituentRoles);
    vm.stopBroadcast();
  }

  ///////////////////////////////////////////////
  ///                   Tests                 ///
  ///////////////////////////////////////////////
  function testSetLawRevertsIfNotCalledFromSeparatedPowers() public {
    address newLaw = address(new Public_assignRole(payable(address(agDao))));
    
    vm.expectRevert(LawsManager.LawsManager__NotAuthorized.selector);
    vm.prank(alice);  
    agDao.setLaw(newLaw, true);
  }
  
  function testSetLawRevertsIfAddressNotALaw() public {
    /* PROPOSAL LINK 1: a whale proposes a law. */   
    // proposing... 
    address thisIsNoLaw = address(new AgDao());
    string memory description = "Proposing to add a new Law";
    bytes memory lawCalldata = abi.encode(thisIsNoLaw, true);  
    
    vm.prank(eve); // = a whale
    uint256 proposalIdOne = agDao.propose(
      constituentLaws[4], // = Whale_proposeLaw
      lawCalldata, 
      description
    );
    
    // whales vote... Only david and eve are whales. 
    vm.prank(david);
    agDao.castVote(proposalIdOne, 1); // = for 
    vm.prank(eve); 
    agDao.castVote(proposalIdOne, 1); // = for

    vm.roll(4_000);

    // executing... 
    vm.prank(david);
    agDao.execute(constituentLaws[4], lawCalldata, keccak256(bytes(description)));

    // check 
    ISeparatedPowers.ProposalState proposalStateOne = agDao.state(proposalIdOne); 
    assert(uint8(proposalStateOne) == 4); // == ProposalState.Completed

    /* PROPOSAL LINK 2: a seniors accept the proposed law. */   
    // proposing...
    vm.roll(5_000);

    vm.prank(charlotte); // = a senior
    uint256 proposalIdTwo = agDao.propose(
      constituentLaws[5], // = Senior_acceptProposedLaw
      lawCalldata, 
      description
    );

    // seniors vote... alice, bob and charlotte are seniors.
    vm.prank(alice);
    agDao.castVote(proposalIdTwo, 1); // = for 
    vm.prank(bob); 
    agDao.castVote(proposalIdTwo, 1); // = for
    vm.prank(charlotte); 
    agDao.castVote(proposalIdTwo, 1); // = for

    vm.roll(9_000);

    // executing... 
    vm.prank(bob);
    agDao.execute(constituentLaws[5], lawCalldata, keccak256(bytes(description)));

    // check 
    ISeparatedPowers.ProposalState proposalStateTwo = agDao.state(proposalIdTwo); 
    assert(uint8(proposalStateTwo) == 4); // == ProposalState.Completed

    /* PROPOSAL LINK 3: the admin can execute a activation of the law. */
    vm.roll(10_000);
    
    vm.prank(alice); // = admin role 
    vm.expectRevert(abi.encodeWithSelector(
    LawsManager.LawsManager__IncorrectInterface.selector, thisIsNoLaw));
     agDao.execute(constituentLaws[6], lawCalldata, keccak256(bytes(description)));
  }
  
  function testSetLawDoesNotingIfNoChange() public {
     /* PROPOSAL LINK 1: a whale proposes a law. */   
    // proposing... 
    // Note newLaw is actually an already existing law. 
    address newLaw = constituentLaws[0]; 
    string memory description = "Proposing to add a new Law";
    bytes memory lawCalldata = abi.encode(newLaw, true);  
    
    vm.prank(eve); // = a whale
    uint256 proposalIdOne = agDao.propose(
      constituentLaws[4], // = Whale_proposeLaw
      lawCalldata, 
      description
    );
    
    // whales vote... Only david and eve are whales. 
    vm.prank(david);
    agDao.castVote(proposalIdOne, 1); // = for 
    vm.prank(eve); 
    agDao.castVote(proposalIdOne, 1); // = for

    vm.roll(4_000);

    // executing... 
    vm.prank(david);
    agDao.execute(constituentLaws[4], lawCalldata, keccak256(bytes(description)));

    // check 
    ISeparatedPowers.ProposalState proposalStateOne = agDao.state(proposalIdOne); 
    assert(uint8(proposalStateOne) == 4); // == ProposalState.Completed

    /* PROPOSAL LINK 2: a seniors accept the proposed law. */   
    // proposing...
    vm.roll(5_000);

    vm.prank(charlotte); // = a senior
    uint256 proposalIdTwo = agDao.propose(
      constituentLaws[5], // = Senior_acceptProposedLaw
      lawCalldata, 
      description
    );

    // seniors vote... alice, bob and charlotte are seniors.
    vm.prank(alice);
    agDao.castVote(proposalIdTwo, 1); // = for 
    vm.prank(bob); 
    agDao.castVote(proposalIdTwo, 1); // = for
    vm.prank(charlotte); 
    agDao.castVote(proposalIdTwo, 1); // = for

    vm.roll(9_000);

    // executing... 
    vm.prank(bob);
    agDao.execute(constituentLaws[5], lawCalldata, keccak256(bytes(description)));

    // check 
    ISeparatedPowers.ProposalState proposalStateTwo = agDao.state(proposalIdTwo); 
    assert(uint8(proposalStateTwo) == 4); // == ProposalState.Completed

    /* PROPOSAL LINK 3: the admin can execute a activation of the law. */
    vm.roll(10_000);
    
    vm.expectEmit(true, false, false, false);
    emit LawsManager.LawSet(newLaw, true, false);
    vm.prank(alice); // = admin role 
    agDao.execute(constituentLaws[6], lawCalldata, keccak256(bytes(description)));
  }

  ///////////////////////////////////////////////
  ///                   Helpers               ///
  ///////////////////////////////////////////////
  function _deployLaws(address payable agDaoAddress_, address agCoinsAddress_) internal returns (address[] memory lawsArray) {
      address[] memory laws = new address[](12);

      // deploying laws //
      vm.startPrank(bob);
      // re assigning roles // 
      laws[0] = address(new Public_assignRole(agDaoAddress_));
      laws[1] = address(new Senior_assignRole(agDaoAddress_, agCoinsAddress_));
      laws[2] = address(new Senior_revokeRole(agDaoAddress_, agCoinsAddress_));
      laws[3] = address(new Member_assignWhale(agDaoAddress_, agCoinsAddress_));
      
      // re activating & deactivating laws  // 
      laws[4] = address(new Whale_proposeLaw(agDaoAddress_, agCoinsAddress_));
      laws[5] = address(new Senior_acceptProposedLaw(agDaoAddress_, agCoinsAddress_, address(laws[4])));
      laws[6] = address(new Admin_setLaw(agDaoAddress_, address(laws[5])));

      // re updating core values // 
      laws[7] = address(new Member_proposeCoreValue(agDaoAddress_, agCoinsAddress_));
      laws[8] = address(new Whale_acceptCoreValue(agDaoAddress_, agCoinsAddress_, address(laws[7])));
      
      // re enforcing core values as requirement for external funding //   
      laws[9] = address(new Whale_revokeMember(agDaoAddress_, agCoinsAddress_));
      laws[10] = address(new Public_challengeRevoke(agDaoAddress_, address(laws[9])));
      laws[11] = address(new Senior_reinstateMember(agDaoAddress_, agCoinsAddress_, address(laws[10])));
      vm.stopPrank();

      return laws; 
    }
}