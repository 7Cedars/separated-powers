// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

contract Constitution {

  uint256 constant NUMBER_OF_LAWS = 12;

  function getConstitution(address payable dao_, address mock1155_) external view returns (
    address[] memory laws,
    uint32[] memory allowedRoles,
    uint8[] memory quorums,
    uint8[] memory succeedAts, 
    uint32[] memory votingPeriods
    ) {
        address[] memory laws = new address[](NUMBER_OF_LAWS);
        uint32[] memory allowedRoles = new uint32[](NUMBER_OF_LAWS);
        uint8[] memory quorums = new uint8[](NUMBER_OF_LAWS);
        uint8[] memory succeedAts = uint8[](NUMBER_OF_LAWS); 
        uint32[] memory votingPeriods = uint32[](NUMBER_OF_LAWS);

        
        //////////////////////////////////////////////////////////////
        //              CHAPTER 1: ELECT ROLES                      //
        //////////////////////////////////////////////////////////////

        ///////////////////////////////////////
        // Law 0: anyone can become a member // 
        ///////////////////////////////////////
        // initiate law
        laws[0] = address(new Direct(
          "Public can apply for member role", 
          "anyone can apply for a member role in the Aligned Grants Dao", 
          AlignedGrantsDao.MEMBER_ROLE()
        )); 

        // add configurations law 
        // note that voting quorum etc does not have to be set in this case. 
        allowedRoles[0] = AlignedGrantsDao.PUBLIC_ROLE();

        //////////////////////////////////////////////////////
        // Law 1: members can call election for Whale roles // 
        //////////////////////////////////////////////////////
        // step 1: initiate law //
        laws[1] = address(new Tokens(
          "Members can nominate themselves as a whale and call whale election", 
          "Members can call (and pay for) a whale election at any time. They can also nominate themselves. No vote needed", 
          address payable erc1155Token_,
          uint256 maxRoleHolders_,
          uint32 roleId_  
        )); 

        // step 3: add configuration law 
        // note that voting quorum etc does not have to be set in this case. 
        allowedRoles[1] = AlignedGrantsDao.MEMBER_ROLE();

        ////////////////////////////////////////////////////////////////////
        // Law 2 + 3: seniors can propose and vote to (de)select seniors  // 
        //////////////////////////////////////////////////////////////////// 
        // initiate law - the actual executive law is set at admin. 
        // no-one should be allowed to access this law directly. ADMIN_ROLE is meant for these cases. 
        laws[2] = address(new Direct(
          "Seniors elect seniors", 
          "Seniors can propose and vote to (de)select seniors.", 
          AlignedGrantsDao.SENIOR_ROLE(); 
        )); 
        allowedRoles[2] = AlignedGrantsDao.ADMIN_ROLE(); 
        
        // {NeedsVote} makes its parent law subject to a vote. 
        laws[3] = address(new NeedsVote(
          laws[2], // parent contract
          true // should it execute its parent contract if vote passes?  
        )); 
        allowedRoles[3] = AlignedGrantsDao.SENIOR_ROLE(); 
        quorums[3] = 30;  // = 30% quorum needed
        succeedAts[3] = 51;  // = 51% simple majority needed for assigning and revoking members. 
        votingPeriods[3] = 1200; // = number of blocks 


        //////////////////////////////////////////////////////////////
        //              CHAPTER 2: EXECUTIVE ACTIONS                //
        //////////////////////////////////////////////////////////////

        //////////////////////////////////////////////////////////////////////
        //       Law 4, 5, 6: members propose value, whales accept value    // 
        ////////////////////////////////////////////////////////////////////// 
        // initiate law - the actual executive law is set at admin. 
        // no-one should be allowed to access this law directly. ADMIN_ROLE is meant for these cases. 
        laws[4] = address(new AdoptValue(
          "Members propose, whales accept value", 
          "Members vote to propose a new value to be selected. Whales can accept a proposed vale and add it to the core values of the Dao"
        )); 
        allowedRoles[4] = AlignedGrantsDao.ADMIN_ROLE(); 
        
        // {NeedsVote} makes its parent law subject to a vote. 
        // in this case Members can vote on a proposal to execute law[4]. But they cannot execute it. 
        laws[5] = address(new NeedsVote(
          laws[4], // parent contract
          false // this vote should accept the proposal, but not execute  
        )); 
        allowedRoles[5] = AlignedGrantsDao.MEMBER_ROLE(); 
        quorums[5] = 60;  // = 60% quorum needed
        succeedAts[5] = 30;  // = 51% simple majority needed for assigning and revoking members. 
        votingPeriods[5] = 1200; // = number of blocks to vote 

        // {NeedsVote} makes its parent law subject to a vote. 
        // in this case Whales can vote on a proposal to execute law[4]. But they cannot execute it. 
        laws[6] = address(new NeedsVote(
          laws[5], // parent contract
          true // this vote should make execution possible. 
        )); 
        allowedRoles[6] = AlignedGrantsDao.WHALE_ROLE(); 
        quorums[6] = 30;  // = 30% quorum needed
        succeedAts[6] = 66;  // =  two/thirds majority needed for   
        votingPeriods[6] = 1200; // = number of blocks to vote 


        //////////////////////////////////////////////////////////////////////
        //        Law 7 + 8 Whales can vote to revoke a member's role       // 
        ////////////////////////////////////////////////////////////////////// 





        //////////////////////////////////////////////////////////////////////
        //     Law 9, 10, 11 Members can vote to revoke a member's role     // 
        ////////////////////////////////////////////////////////////////////// 



        //////////////////////////////////////////////////////////////
        //                  RETURN CONSTITUTION                     //
        //////////////////////////////////////////////////////////////
        return (laws, allowedRoles, quorums, succeedAts, votingPeriods)

  }

}