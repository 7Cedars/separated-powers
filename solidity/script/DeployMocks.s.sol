// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import { Script, console2 } from "lib/forge-std/src/Script.sol";

import { Erc1155Mock } from "../../test/mocks/Erc1155Mock.sol";
import { Erc20VotesMock } from "../../test/mocks/Erc20VotesMock.sol";

contract DeployMocks is Script {
    /* Functions */
    function run()
        external
        returns (
            Erc1155Mock erc1155Mock,
            Erc20VotesMock erc20VotesMock
        )
    {   
        vm.startBroadcast();
          erc1155Mock = new Erc1155Mock();
          erc20VotesMock = new Erc20VotesMock();
        vm.stopBroadcast();

        return (
            erc1155Mock, erc20VotesMock
        );
    }
}
