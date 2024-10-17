// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Script, console2} from "lib/forge-std/src/Script.sol";

// core contracts 
import {AgDao} from "../src/implementation/AgDao.sol";
import {AgCoins} from "../src/implementation/AgCoins.sol";
import {Law} from "../src/Law.sol";
import {IAuthoritiesManager} from "../src/interfaces/IAuthoritiesManager.sol";

contract TestDeploy is Script {
    /* Functions */
    function run() external returns (AgDao) {

        vm.startBroadcast();
            AgDao agDao = new AgDao();
            // AgCoins agCoins = new AgCoins(payable(address(agDao)));
        vm.stopBroadcast();

        return(agDao);
    }
}



