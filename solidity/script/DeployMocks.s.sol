// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import "lib/forge-std/src/Script.sol";

import { Erc20VotesMock } from "../test/mocks/Erc20VotesMock.sol";
import { Erc721Mock } from "../test/mocks/Erc721Mock.sol";
import { Erc1155Mock } from "../test/mocks/Erc1155Mock.sol";

/// @notice script to deploy mockErc20 and mockErc1155 contracts to a chain. 
/// note that each contract has its own broadcast. Foundry is a bit unstable when it comes to deploying multiple contracts in one broadcast call.
contract DeployMocks is Script {
    address[] laws;

    function run()
        external
        returns (
            address payable erc20VotesMock, 
            address payable erc721Mock, 
            address payable erc1155Mock)
    {
        // deploy erc20VotesMock.
        vm.startBroadcast();
        Erc20VotesMock erc20Votes = new Erc20VotesMock();
        vm.stopBroadcast();

        // deploy erc721Mock.
        vm.startBroadcast();
        Erc721Mock erc721 = new Erc721Mock();
        vm.stopBroadcast();

        // deploy erc1155Mock.
        vm.startBroadcast();
        Erc1155Mock erc1155 = new Erc1155Mock();
        vm.stopBroadcast();

        return (
            payable(address(erc20Votes)), 
            payable(address(erc721)), 
            payable(address(erc1155))
        );
    }
}