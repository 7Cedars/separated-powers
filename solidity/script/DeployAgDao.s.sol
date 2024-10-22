// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Script, console2} from "lib/forge-std/src/Script.sol";

// core contracts 
import {AgDao} from "../src/implementation/AgDao.sol";
import {AgCoins} from "../src/implementation/AgCoins.sol";
import {Law} from "../src/Law.sol";
import {IAuthoritiesManager} from "../src/interfaces/IAuthoritiesManager.sol";

// constitutional laws
import {Admin_setLaw} from "../src/implementation/laws/Admin_setLaw.sol";
import {Public_assignRole} from "../src/implementation/laws/Public_assignRole.sol";
import {Public_challengeRevoke} from "../src/implementation/laws/Public_challengeRevoke.sol";
import {Member_proposeCoreValue} from "../src/implementation/laws/Member_proposeCoreValue.sol";
import {Senior_acceptProposedLaw} from "../src/implementation/laws/Senior_acceptProposedLaw.sol";
import {Senior_assignRole} from "../src/implementation/laws/Senior_assignRole.sol";
import {Senior_reinstateMember} from "../src/implementation/laws/Senior_reinstateMember.sol";
import {Senior_revokeRole} from "../src/implementation/laws/Senior_revokeRole.sol";
import {Whale_acceptCoreValue} from "../src/implementation/laws/Whale_acceptCoreValue.sol";
import {Member_assignWhale} from "../src/implementation/laws/Member_assignWhale.sol";
import {Whale_proposeLaw} from "../src/implementation/laws/Whale_proposeLaw.sol";
import {Whale_revokeMember} from "../src/implementation/laws/Whale_revokeMember.sol";

contract DeployAgDao is Script {
    error DeployFactoryProgrmas__DeployedContractAtAddress(address deploymentAddress);
    
    /* Functions */
    function run() external returns (AgDao, AgCoins, address[] memory constituentLaws) { // 
        vm.startBroadcast();
            AgDao agDao = new AgDao();
            AgCoins agCoins = new AgCoins(payable(address(agDao)));
        vm.stopBroadcast();

        vm.startBroadcast();
            // setting up constituent Laws and initializing them.
            constituentLaws = _deployLaws(payable(address(agDao)), address(agCoins));
        vm.stopBroadcast();

        return(agDao, agCoins, constituentLaws); // 
    }

    /* internal functions */
function _deployLaws(address payable agDaoAddress_, address agCoinsAddress_) internal returns (address[] memory lawsArray) {
      address[] memory laws = new address[](12);

      // deploying laws //
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

      return laws; 
    }
}



