// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import { Script, console2 } from "lib/forge-std/src/Script.sol";

// core contracts
import { AlignedGrantsDao } from "../src/implementation/daos/AlignedGrantsDao.sol";
import { ERC1155Mock } from "../mocks/ERC1155Mock.sol"
import { Law } from "../src/Law.sol";
import { SeparatedPowersTypes } from "../src/interfaces/SeparatedPowersTypes.sol";
import { SeparatedPowers } from "../src/SeparatedPowers.sol"; 

contract DeployAlignedGrantsDao is Script {

    /* Functions */
    function run() external returns (AlignedGrantsDao, ERC1155Mock) {
        //
        vm.startBroadcast();
        AlignedGrantsDao agDao = new AlignedGrantsDao();
        ERC1155Mock mock1155 = new ERC1155Mock(payable(address(agDao)));
        vm.stopBroadcast();

        ( 
          address[] memory laws,
          uint32[] memory allowedRoles,
          uint8[] memory quorums,
          uint8[] memory succeedAts, 
          uint32[] memory votingPeriods
          ) = _createLegalFramework(payable(address(agDao)), address(mock1155));
        
        (
          uint48[] memory constituentRoles,
          address[] memory constituentAccounts
          ) = _createRoles();  
                
        vm.startBroadcast();
        agDao.constitute(
          laws, allowedRoles, quorums, succeedAts, votingPeriods, 
          constituentRoles, constituentAccounts
        ); 
        vm.stopBroadcast(); 

        return (agDao, mock1155); //
    }

    /* internal functions */
    function _createLegalFramework(address payable agDaoAddress_, address mock1155_)
        internal
        returns (
          address[] memory laws,
          uint32[] memory allowedRoles,
          uint8[] memory quorums,
          uint8[] memory succeedAts, 
          uint32[] memory votingPeriods
        )
    {
        address[] memory laws = new address[](12);
        uint32[] memory allowedRoles = new uint32[](12);
        uint8[] memory quorums = new uint8[](12);
        uint8[] memory succeedAts = uint8[](12); 
        uint32[] memory votingPeriods = uint32[](12);

        ///////////////////////////////////////
        // Law 0: anyone can become a member // 
        ///////////////////////////////////////
        // step 1: initiate law //
        laws[0] = address(new Direct(
          "Public can apply for member role", 
          "anyone can apply for a member role in the Aligned Grants Dao", 
          AlignedGrantsDao.MEMBER_ROLE()
        )); 

        // step 3: add configuration law 
        // note that voting quorum etc does not have to be set in this case. 
        allowedRoles = AlignedGrantsDao.PUBLIC_ROLE();

        //////////////////////////////////////////////////////
        // Law 1: members can call election for Whale roles // 
        //////////////////////////////////////////////////////
        // step 1: initiate law //
        laws[1] = address(new Tokens(
          "Members can call whale elections", 
          "Members can call (and pay for) whale election.", 
          address payable erc1155Token_,
          uint256 maxRoleHolders_,
          uint32 roleId_  
        )); 

        // step 3: add configuration law 
        // note that voting quorum etc does not have to be set in this case. 
        allowedRoles = AlignedGrantsDao.PUBLIC_ROLE(); 

        // continue here. // 



        ///////////////////////////////////////
        //      Return legal framework       // 
        ///////////////////////////////////////
        return (laws, allowedRoles, quorums, succeedAts, votingPeriods)
    }

    function _createRoles() internal returns (
      uint48[] memory constituentRoles, 
      address[] memory constituentAccounts
      ) {
        uint48[] memory constituentRoles = new uint48[](0); 
        address[] memory constituentAccounts = new address[](0);  

        return (constituentRoles, constituentAccounts); 
    }
}
