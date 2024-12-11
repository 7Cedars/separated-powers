// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import { Script, console2 } from "lib/forge-std/src/Script.sol";

// core protocol
import { SeparatedPowers } from "../src/SeparatedPowers.sol";
import { Law } from "../src/Law.sol";
import { ILaw } from "../src/interfaces/ILaw.sol";
import { SeparatedPowersTypes } from "../src/interfaces/SeparatedPowersTypes.sol";

// laws
import { NominateMe } from "../src/laws/electoral/NominateMe.sol";
import { DelegateSelect } from "../src/laws/electoral/DelegateSelect.sol";
import { DirectSelect } from "../src/laws/electoral/DirectSelect.sol";
import { ProposalOnly } from "../src/laws/executive/ProposalOnly.sol";
import { OpenAction } from "../src/laws/executive/OpenAction.sol";

// mock & config 
import { Erc20VotesMock } from "../test/mocks/Erc20VotesMock.sol";
import { HelperConfig } from "./HelperConfig.s.sol";


/// @notice core script to deploy a dao
/// Note the {run} function for deploying the dao can be used without changes.
/// Note  the {initiateConstitution} function for creating bespoke constitution for the DAO.
/// Note the {getFounders} function for setting founders' roles.
contract DeployBasicDao is Script {
    address[] laws;
    uint32[] constituentRoles;
    address[] constituentAccounts;

    function run() external {
        HelperConfig helperConfig = new HelperConfig();
        HelperConfig.NetworkConfig memory config = helperConfig.getConfigByChainId(block.chainid);

        // Deploying contracts.
        vm.startBroadcast();
        SeparatedPowers separatedPowers = new SeparatedPowers("Basic Dao");
        vm.stopBroadcast();

        // initiate constitution & get founders' roles list
        initiateConstitution(payable(address(separatedPowers)), payable(config.erc1155Mock), payable(config.erc20VotesMock));
        getFounders(payable(address(separatedPowers)));

        // constitute dao.
        vm.startBroadcast();
        separatedPowers.constitute(laws, constituentRoles, constituentAccounts);
        vm.stopBroadcast();
    }


  function initiateConstitution(address payable dao_, address payable mock1155_, address payable mock20_) public {
      Law law;
      ILaw.LawConfig memory lawConfig;

      //////////////////////////////////////////////////////////////
      //              CHAPTER 1: ELECT ROLES                      //
      //////////////////////////////////////////////////////////////

      vm.startBroadcast();
      law = new NominateMe(
              "Nominees for DELEGATE_ROLE", // max 31 chars
              "Anyone can nominate themselves for a WHALE_ROLE",
              dao_, 
              type(uint32).max, // access role = public access
              lawConfig
      );
      vm.stopBroadcast();
      laws.push(address(law));

      vm.startBroadcast();
      law = new DelegateSelect(
              "Anyone can elect delegates", // max 31 chars
              "Anyone can call (and pay for) a delegate election at any time. The nominated accounts with most delegated vote tokens will be assigned the DELEGATE_ROLE.",
              dao_, // separated powers protocol.
              type(uint32).max, // public access 
              lawConfig, //  config file.
              mock20_, // the tokens that will be used as votes in the election.
              laws[0], // nominateMe
              25,
              2
          ); 
      vm.stopBroadcast();
      laws.push(address(law));

      // setup 
      lawConfig.quorum = 20; // = Only 20% quorum needed
      lawConfig.succeedAt = 66; // = but at least 2/3 majority needed for assigning and revoking members.
      lawConfig.votingPeriod = 1200; // = number of blocks
      // initiate law
      vm.startBroadcast();
      law = new DirectSelect(
              "Seniors elect seniors", // max 31 chars
              "Seniors can propose and vote to (de)select an account for the SENIOR_ROLE.",
              dao_,
              1, // access role
              lawConfig,
              1
          );
      vm.stopBroadcast();
      laws.push(address(law)); // log address
      delete lawConfig; // reset lawConfig before next usage.   
      // note: there is no maximum or minimum number of seniors. But at least one senior NEEDS TO BE ELECTED THROUGH CONSTITUTION OF THE DAO. Otherwise it will never be possible to elect seniors.

      //////////////////////////////////////////////////////////////
      //              CHAPTER 2: EXECUTIVE ACTIONS                //
      //////////////////////////////////////////////////////////////

      // setting input params.     
      bytes4[] memory paramsAction = new bytes4[](3);
      paramsAction[0] = bytes4(keccak256("address[]")); // targets
      paramsAction[1] = bytes4(keccak256("uint256[]")); // values
      paramsAction[2] = bytes4(keccak256("bytes[]")); // calldatas
      // setting config. 
      lawConfig.quorum = 66; // = Two thirds quorum needed to pass the proposal
      lawConfig.succeedAt = 51; // = 51% simple majority needed for assigning and revoking members.
      lawConfig.votingPeriod = 50400; // = duration in number of blocks to vote, about one week.
      // initiating law
      vm.startBroadcast();
      law = new ProposalOnly(
              "Delegates propose actions",
              "Delegates can propose new actions to be executed. They cannot implement it.",
              dao_,
              2, // access role
              lawConfig,
              paramsAction
          );
      vm.stopBroadcast();
      laws.push(address(law));
      delete lawConfig;

      vm.startBroadcast(); 
      law = new ProposalOnly(
            "Admin can veto actions",
            "An admin can veto any action. No vote as only one address holds the ADMIN_ROLE.",
            dao_,
            0, // access role
            lawConfig,
            paramsAction
      ); 
      vm.stopBroadcast();
      laws.push(address(law));
      delete lawConfig;

      // setting config.
      lawConfig.quorum = 51; // = 51 majority of seniors need to vote.
      lawConfig.succeedAt = 66; // =  two/thirds majority FOR vote needed to pass.
      lawConfig.votingPeriod = 50400; // = duration in number of blocks to vote, about one week.
      lawConfig.needCompleted = laws[3]; // needs the proposal by Delegates to be completed.
      lawConfig.delayExecution = 25200; // = duration in number of blocks (= half a week).
      lawConfig.needNotCompleted = laws[4]; // needs the admin NOT to have cast a veto.
      // initiate law 
      vm.startBroadcast(); 
      law = new OpenAction(
            "Seniors execute actions",
            "Seniors can execute actions that delegates proposed. By vote. Admin can veto any execution.",
            dao_, // separated powers
            1, // access role
            lawConfig
      ); 
      vm.stopBroadcast();
      laws.push(address(law));
      delete lawConfig;
  }


  function getFounders(address payable dao_) public {
    uint256 LOCAL_CHAIN_ID = 31337; 

    if (block.chainid == LOCAL_CHAIN_ID) {
    return getFoundersLocal();
        // } else if (chainId == ETH_SEPOLIA_CHAIN_ID) {
        // return getFoundersEthSepolia();
        // etc...
        // }
    } else {
    revert("ChainId not supported");
    }
  }
  
  function getFoundersLocal() internal {
        address anvil_0 = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;
        address anvil_1 = 0x70997970C51812dc3A010C7d01b50e0d17dc79C8;
        address anvil_2 = 0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC;

        constituentAccounts.push(anvil_0);
        constituentRoles.push(1);
        constituentAccounts.push(anvil_1);
        constituentRoles.push(1);
        constituentAccounts.push(anvil_2);
        constituentRoles.push(1);
  }
}
