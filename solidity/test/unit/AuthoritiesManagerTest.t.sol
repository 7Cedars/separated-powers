// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.26;

import {Test, console, console2} from "lib/forge-std/src/Test.sol";
import {DeployAgDao} from "../../script/DeployAgDao.s.sol";
import {SeparatedPowers} from "../../src/SeparatedPowers.sol";
import {AgDao} from   "../../src/implementation/AgDao.sol";
import {AgCoins} from "../../src/implementation/AgCoins.sol";
import {Law} from "../../src/Law.sol";
import {AuthoritiesManager} from "../../src/AuthoritiesManager.sol";
import {IAuthoritiesManager} from "../../src/interfaces/IAuthoritiesManager.sol";
import {ISeparatedPowers} from "../../src/interfaces/ISeparatedPowers.sol";
import {ILawsManager} from "../../src/interfaces/ILawsManager.sol";

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

contract AuthoritiesManagerTest is Test {
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
    vm.roll(10); // for this protocol to work properly the block.number must be > 0. 
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
  ///                    Tests                ///
  ///////////////////////////////////////////////
  /* adding and removing roles */
  function testSetRoleCannotBeCalledFromOutsidePropotocol() public {
    vm.prank(alice); // = Admin  
    vm.expectRevert(); 
    agDao.setRole(WHALE_ROLE, bob, true);
  }

  function testAddingRoleAddsOneToAmountMembers() public {
    // prep 
    string memory requiredStatement = "I request membership to agDAO.";
    bytes32 requiredStatementHash = keccak256(bytes(requiredStatement));
    bytes memory lawCalldata = abi.encode(requiredStatementHash);
    uint256 amountMembersBefore = agDao.getAmountRoleHolders(MEMBER_ROLE);

    // act 
    vm.prank(frank); 
    agDao.execute(constituentLaws[0], lawCalldata, keccak256(bytes(requiredStatement)));

    // checks 
    uint48 since = agDao.hasRoleSince(frank, MEMBER_ROLE);
    assert (since != 0);
    uint256 amountMembersAfter = agDao.getAmountRoleHolders(MEMBER_ROLE);
    assert (amountMembersAfter == amountMembersBefore + 1);
  }

  function testRemovingRoleSubtratcsOneFromAmountMembers() public {
    // prep
    uint256 amountSeniorsBefore = agDao.getAmountRoleHolders(SENIOR_ROLE);
    string memory description = "Charlotte is getting booted as Senior.";
    bytes memory lawCalldata = abi.encode(charlotte); 

    // act  
    vm.prank(charlotte); // = already a senior
    uint256 proposalId = agDao.propose(constituentLaws[2], lawCalldata, description); 
    vm.prank(alice);
    agDao.castVote(proposalId, 1); // = For 
    vm.prank(bob); 
    agDao.castVote(proposalId, 1); // = For 
    vm.prank(charlotte); 
    agDao.castVote(proposalId, 1); // = For 

    // go forward in time. 
    vm.roll(4_000); // == beyond durintion of 150 
    ISeparatedPowers.ProposalState proposalState = agDao.state(proposalId); 
    assert(uint8(proposalState) == 3); // == ProposalState.Succeeded

    // execute
    vm.prank(bob); 
    agDao.execute(constituentLaws[2], lawCalldata, keccak256(bytes(description)));

    // check
    uint48 since = agDao.hasRoleSince(charlotte, SENIOR_ROLE);
    assert(since == 0); // charlotte should have lost here role. 

    uint256 amountSeniorsAfter = agDao.getAmountRoleHolders(SENIOR_ROLE);
    assert(amountSeniorsBefore - 1 == amountSeniorsAfter);
  }

  /* votes */
  function testAccountCannotVoteTwice() public {
    // prep
    string memory description = "Charlotte is getting booted as Senior.";
    bytes memory lawCalldata = abi.encode(charlotte); 

    // act  
    vm.prank(charlotte);
    uint256 proposalId = agDao.propose(constituentLaws[2], lawCalldata, description); 
    
    // alice votes once.. 
    vm.prank(alice);
    agDao.castVote(proposalId, 1); // = For 
    
    // alice tries to vote twice... 
    vm.prank(alice); 
    vm.expectRevert(abi.encodeWithSelector(
      AuthoritiesManager.AuthoritiesManager__AlreadyCastVote.selector, alice));
    agDao.castVote(proposalId, 1); // = For 
  }

  function testAgainstVoteIsCorrectlyCounted() public {
    // prep
    string memory description = "Charlotte is getting booted as Senior.";
    bytes memory lawCalldata = abi.encode(charlotte); 

    // act  
    vm.prank(charlotte); 
    uint256 proposalId = agDao.propose(constituentLaws[2], lawCalldata, description); 
    vm.prank(alice);
    agDao.castVote(proposalId, 0); // = against 
    vm.prank(bob); 
    agDao.castVote(proposalId, 0); // = against 
    vm.prank(charlotte); 
    agDao.castVote(proposalId, 0); // = against

    // check
    (uint256 againstVotes, , ) = agDao.proposalVotes(proposalId);
    assert (againstVotes == 3);
  }

  function testForVoteIsCorrectlyCounted() public {
    // prep
    string memory description = "Charlotte is getting booted as Senior.";
    bytes memory lawCalldata = abi.encode(charlotte); 

    // act  
    vm.prank(charlotte); 
    uint256 proposalId = agDao.propose(constituentLaws[2], lawCalldata, description); 
    vm.prank(alice);
    agDao.castVote(proposalId, 1); // = For 
    vm.prank(bob); 
    agDao.castVote(proposalId, 1); // = For 
    vm.prank(charlotte); 
    agDao.castVote(proposalId, 1); // = For

    // check 
    (, uint256 forVotes, ) = agDao.proposalVotes(proposalId);
    assert (forVotes == 3); 
  }


  function testAbstainVoteIsCorrectlyCounted() public {
    // prep
    string memory description = "Charlotte is getting booted as Senior.";
    bytes memory lawCalldata = abi.encode(charlotte); 

    // act  
    vm.prank(charlotte); 
    uint256 proposalId = agDao.propose(constituentLaws[2], lawCalldata, description); 
    vm.prank(alice);
    agDao.castVote(proposalId, 2); // = abstain 
    vm.prank(bob); 
    agDao.castVote(proposalId, 2); // = abstain 
    vm.prank(charlotte); 
    agDao.castVote(proposalId, 2); // = abstain

    // check 
    (, , uint256 abstainVotes) = agDao.proposalVotes(proposalId);
    assert (abstainVotes == 3); 
  }

  function testInvalidVoteRevertsCorrectly() public {
    // prep
    string memory description = "Charlotte is getting booted as Senior.";
    bytes memory lawCalldata = abi.encode(charlotte); 

    // act  
    vm.prank(charlotte); 
    uint256 proposalId = agDao.propose(constituentLaws[2], lawCalldata, description); 
    vm.prank(alice);
    vm.expectRevert(AuthoritiesManager.AuthoritiesManager__InvalidVoteType.selector);
    agDao.castVote(proposalId, 4); // = incorrect vote type  

    // check 
    (uint256 againstVotes, uint256 forVotes, uint256 abstainVotes) = agDao.proposalVotes(proposalId);
    assert (againstVotes == 0); 
    assert (forVotes == 0); 
    assert (abstainVotes == 0); 
  }

  function testHasVotedReturnCorrectData() public {
    // prep
    string memory description = "Charlotte is getting booted as Senior.";
    bytes memory lawCalldata = abi.encode(charlotte); 

    // act  
    vm.prank(charlotte); 
    uint256 proposalId = agDao.propose(constituentLaws[2], lawCalldata, description); 
    vm.prank(charlotte); 
    agDao.castVote(proposalId, 2); // = abstain

    // check 
    assert (agDao.hasVoted(proposalId, charlotte) == true);
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