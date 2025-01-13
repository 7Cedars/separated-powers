// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import "lib/forge-std/src/Script.sol";

import { Erc20VotesMock } from "../test/mocks/Erc20VotesMock.sol";
import { Erc1155Mock } from "../test/mocks/Erc1155Mock.sol";

/// @notice script to deploy mockErc20 and mockErc1155 contracts to a chain. 
/// note that each contract has its own broadcast. Foundry is a bit unstable when it comes to deploying multiple contracts in one broadcast call.
contract DeployMocks is Script {
    address[] laws;

    function run()
        external
        returns (address payable erc20VotesMock, address payable erc1155Mock)
    {
        // deploy erc20VotesMock.
        vm.startBroadcast();
        Erc20VotesMock erc20VotesMock = new Erc20VotesMock();
        vm.stopBroadcast();

        // constitute erc1155Mock.
        vm.startBroadcast();
        Erc1155Mock erc1155Mock = new Erc1155Mock();
        vm.stopBroadcast();

        return (payable(address(erc20VotesMock)), payable(address(erc1155Mock)));
    }
}