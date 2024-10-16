// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.26;

import {Test, console, console2} from "lib/forge-std/src/Test.sol";
import {DeployAgDao} from "../../../script/DeployAgDao.s.sol";
import {SeparatedPowers} from "../../../src/SeparatedPowers.sol";
import {AgDao} from   "../../../src/implementation/AgDao.sol";
import {AgCoins} from "../../../src/implementation/AgCoins.sol";
import {Law} from "../../../src/Law.sol";
import {IAuthoritiesManager} from "../../../src/interfaces/IAuthoritiesManager.sol";
import {ISeparatedPowers} from "../../../src/interfaces/ISeparatedPowers.sol";
import "@openzeppelin/contracts/utils/ShortStrings.sol";

// constitutional laws
import {Admin_setLaw} from "../../../src/implementation/laws/Admin_setLaw.sol";
import {Member_assignRole} from "../../../src/implementation/laws/Member_assignRole.sol";
import {Member_challengeRevoke} from "../../../src/implementation/laws/Member_challengeRevoke.sol";
import {Member_proposeCoreValue} from "../../../src/implementation/laws/Member_proposeCoreValue.sol";
import {Senior_acceptProposedLaw} from "../../../src/implementation/laws/Senior_acceptProposedLaw.sol";
import {Senior_assignRole} from "../../../src/implementation/laws/Senior_assignRole.sol";
import {Senior_reinstateMember} from "../../../src/implementation/laws/Senior_reinstateMember.sol";
import {Senior_revokeRole} from "../../../src/implementation/laws/Senior_revokeRole.sol";
import {Whale_acceptCoreValue} from "../../../src/implementation/laws/Whale_acceptCoreValue.sol";
import {Whale_assignRole} from "../../../src/implementation/laws/Whale_assignRole.sol";
import {Whale_proposeLaw} from "../../../src/implementation/laws/Whale_proposeLaw.sol";
import {Whale_revokeMember} from "../../../src/implementation/laws/Whale_revokeMember.sol";

contract SeparatedPowersTest is Test {
  using ShortStrings for *;

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

  function testRequirementCanBeAdded() public {
    /* PROPOSAL LINK 1: a whale proposes a law. */   
    // proposing... 
    string memory newValueString = 'accounts need to be human'; 
    ShortString newValue = newValueString.toShortString();
    string memory memberDescription = "This is a crucial value to the DAO. It needs to be included among our core values!";
    bytes memory memberLawCalldata = abi.encode(newValue, keccak256(bytes(memberDescription))); 
    
    vm.prank(eve); // = a member
    uint256 proposalIdOne = agDao.propose(
      constituentLaws[7], // = Member_proposeCoreValue
      memberLawCalldata, 
      memberDescription
    );

    console2.log("at Test");
    console2.logBytes32(keccak256(bytes(memberDescription))); 
    
    // members vote in support. 
    vm.prank(alice);
    agDao.castVote(proposalIdOne, 1); // = for 
    vm.prank(bob);
    agDao.castVote(proposalIdOne, 1); // = for 
    vm.prank(charlotte);
    agDao.castVote(proposalIdOne, 1); // = for 
    vm.prank(david);
    agDao.castVote(proposalIdOne, 1); // = for 
    vm.prank(eve); 
    agDao.castVote(proposalIdOne, 1); // = for

    vm.roll(4_000);

    // executing... 
    vm.prank(eve);
    Law(constituentLaws[7]).executeLaw(memberLawCalldata);

    // check 
    ISeparatedPowers.ProposalState proposalStateOne = agDao.state(proposalIdOne); 
    assert(uint8(proposalStateOne) == 4); // == ProposalState.Completed

    /* PROPOSAL LINK 2: a seniors accept the proposed law. */   
    // proposing...
    vm.roll(5_000);
    string memory whaleDescription = "Whale accepting new core value.";
    bytes memory whaleLawCalldata = abi.encode(newValue, keccak256(bytes(memberDescription)), keccak256(bytes(whaleDescription)));  

    vm.prank(david); // = a whale
    uint256 proposalIdTwo = agDao.propose(
      constituentLaws[8], // = Whale_acceptCoreValue
      whaleLawCalldata, 
      whaleDescription
    );

    // seniors vote... david and eve are whales.
    vm.prank(david);
    agDao.castVote(proposalIdTwo, 1); // = for 
    vm.prank(eve); 
    agDao.castVote(proposalIdTwo, 1); // = for

    vm.roll(9_000);

    // executing... 
    vm.prank(eve);
    Law(constituentLaws[8]).executeLaw(whaleLawCalldata);

    // check 
    ISeparatedPowers.ProposalState proposalStateTwo = agDao.state(proposalIdTwo); 
    assert(uint8(proposalStateTwo) == 4); // == ProposalState.Completed

    ShortString newRequirement = agDao.coreRequirements(0);
    string memory requirement = newRequirement.toString(); 
    console2.logString(requirement);  
    vm.assertEq(abi.encode(requirement), abi.encode('accounts need to be human'));
  }

  // function testRequirementCanBeRemoved() public {
  //   // NOT implemented.  
  // }

  function testRemovedMemberCannotBeReinstituted() public {
    // proposing... 
    address memberToRevoke = alice;
    string memory description = "Alice will be member no more in the DAO.";
    bytes memory lawCalldata = abi.encode(memberToRevoke, keccak256(bytes(description)));  
    
    vm.prank(eve); // = a whale
    uint256 proposalIdOne = agDao.propose(
      constituentLaws[9], // = Whale_revokeMember
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
    Law(constituentLaws[9]).executeLaw(lawCalldata);

    // check 
    ISeparatedPowers.ProposalState proposalStateOne = agDao.state(proposalIdOne); 
    assert(uint8(proposalStateOne) == 4); // == ProposalState.Completed
    assert (agDao.blacklistedAccounts(alice) == true);
    
    // Alice tries to reinstate themselves as member.
    bytes memory memberLawCalldata = abi.encode(keccak256(bytes("I request membership to agDAO."))); 
    vm.prank(alice);  
    vm.expectRevert(Member_assignRole.Member_assignRole__AccountBlacklisted.selector);
    Law(constituentLaws[0]).executeLaw(memberLawCalldata);  // = Member_assignRole
  }

  function testWhenReinstatedAccountNoLongerBlackListed() public {
    // PROPOSAL LINK 1: revoking member
    // proposing... 
    address memberToRevoke = alice;
    string memory description = "Alice will be member no more in the DAO.";
    bytes memory lawCalldata = abi.encode(memberToRevoke, keccak256(bytes(description)));  
    
    vm.prank(eve); // = a whale
    uint256 proposalIdOne = agDao.propose(
      constituentLaws[9], // = Whale_revokeMember
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
    Law(constituentLaws[9]).executeLaw(lawCalldata);

    // check if alice has indeed been blacklisted. 
    ISeparatedPowers.ProposalState proposalStateOne = agDao.state(proposalIdOne); 
    assert(uint8(proposalStateOne) == 4); // == ProposalState.Completed
    assert (agDao.blacklistedAccounts(alice) == true);

    // PROPOSAL LINK 2: challenge revoke decision 


    
  }


  ///////////////////////////////////////////////
  ///                   Helpers               ///
  ///////////////////////////////////////////////
  function _deployLaws(address payable agDaoAddress_, address agCoinsAddress_) internal returns (address[] memory constituentLaws) {
      address[] memory constituentLaws = new address[](12);

      // deploying laws //
      vm.startPrank(bob);
      // re assigning roles // 
      constituentLaws[0] = address(new Member_assignRole(agDaoAddress_));
      constituentLaws[1] = address(new Senior_assignRole(agDaoAddress_, agCoinsAddress_));
      constituentLaws[2] = address(new Senior_revokeRole(agDaoAddress_, agCoinsAddress_));
      constituentLaws[3] = address(new Whale_assignRole(agDaoAddress_, agCoinsAddress_));
      
      // re activating & deactivating laws  // 
      constituentLaws[4] = address(new Whale_proposeLaw(agDaoAddress_, agCoinsAddress_));
      constituentLaws[5] = address(new Senior_acceptProposedLaw(agDaoAddress_, agCoinsAddress_, address(constituentLaws[4])));
      constituentLaws[6] = address(new Admin_setLaw(agDaoAddress_, address(constituentLaws[5])));

      // re updating core values // 
      constituentLaws[7] = address(new Member_proposeCoreValue(agDaoAddress_, agCoinsAddress_));
      constituentLaws[8] = address(new Whale_acceptCoreValue(agDaoAddress_, agCoinsAddress_, address(constituentLaws[7])));
      
      // re enforcing core values as requirement for external funding //   
      constituentLaws[9] = address(new Whale_revokeMember(agDaoAddress_, agCoinsAddress_));
      constituentLaws[10] = address(new Member_challengeRevoke(agDaoAddress_, address(constituentLaws[9])));
      constituentLaws[11] = address(new Senior_reinstateMember(agDaoAddress_, agCoinsAddress_, address(constituentLaws[10])));
      vm.stopPrank();

      return constituentLaws; 
    }
}