// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import { Script, console2 } from "lib/forge-std/src/Script.sol";
import { Erc1155Mock } from "../test/mocks/Erc1155Mock.sol";
import { Erc20VotesMock } from "../test/mocks/Erc20VotesMock.sol";

contract HelperConfig is Script {
    error HelperConfig__InvalidChainId();

    struct NetworkConfig {
        address erc1155Mock;
        address erc20VotesMock;
        uint256 blocksPerHour; // a basic way of establishing time. As long as block times are fairly stable on a chain, this will work.
    }

    uint256 constant LOCAL_CHAIN_ID = 31_337;
    uint256 constant ETH_SEPOLIA_CHAIN_ID = 11_155_111;
    uint256 constant OPT_SEPOLIA_CHAIN_ID = 11_155_420;
    uint256 constant ARB_SEPOLIA_CHAIN_ID = 421_614;
    uint256 constant BASE_SEPOLIA_CHAIN_ID = 84_532;

    NetworkConfig public localNetworkConfig;
    mapping(uint256 chainId => NetworkConfig) public networkConfig;

    constructor() {
        networkConfig[ETH_SEPOLIA_CHAIN_ID] = getEthSepoliaConfig();
        networkConfig[ARB_SEPOLIA_CHAIN_ID] = getArbSepoliaConfig();
        networkConfig[OPT_SEPOLIA_CHAIN_ID] = getOptSepoliaConfig();
        networkConfig[BASE_SEPOLIA_CHAIN_ID] = getBaseSepoliaConfig();
    }

    function getConfig() public returns (NetworkConfig memory) {
        return getConfigByChainId(block.chainid);
    }

    function getConfigByChainId(uint256 chainId) public returns (NetworkConfig memory) {
        if (chainId == LOCAL_CHAIN_ID) {
            return getOrCreateAnvilEthConfig();
        } else if (networkConfig[chainId].blocksPerHour != 0) {
            return networkConfig[chainId];
        } else {
            revert HelperConfig__InvalidChainId();
        }
    }

    function getArbSepoliaConfig() public pure returns (NetworkConfig memory) {
        return NetworkConfig({
            erc1155Mock: address(0), // not yet deployed
            erc20VotesMock: address(0), // not yet deployed
            blocksPerHour: 300 // returns Eth mainnet block numbers.
         });
    }

    function getEthSepoliaConfig() public pure returns (NetworkConfig memory) {
        return NetworkConfig({
            erc1155Mock: address(0),
            erc20VotesMock: address(0),
            blocksPerHour: 300 // one block = 12 sec
         });
    }

    function getOptSepoliaConfig() public pure returns (NetworkConfig memory) {
        return NetworkConfig({
            erc1155Mock: address(0),
            erc20VotesMock: address(0),
            blocksPerHour: 300 // placeholder value. Have to check what block.number is actually returned.
         });
    }

    function getBaseSepoliaConfig() public pure returns (NetworkConfig memory) {
        return NetworkConfig({
            erc1155Mock: address(0),
            erc20VotesMock: address(0),
            blocksPerHour: 300 // one block = 12 sec
         });
    }

    function getOrCreateAnvilEthConfig() public returns (NetworkConfig memory) {
        // check if anvil is already deployed.
        if (localNetworkConfig.erc1155Mock != address(0) && localNetworkConfig.erc20VotesMock != address(0)) {
            return localNetworkConfig;
        }
        // if anvil is not deployed, deploy and save addresses.
        vm.startBroadcast();
        Erc1155Mock erc1155Mock = new Erc1155Mock();
        Erc20VotesMock erc20VotesMock = new Erc20VotesMock();
        vm.stopBroadcast();

        localNetworkConfig = NetworkConfig({
            erc1155Mock: address(erc1155Mock),
            erc20VotesMock: address(erc20VotesMock),
            blocksPerHour: 3600 // the anvil block time should be set to 1 second.
         });
        return localNetworkConfig;
    }
}

//////////////////////////////////////////////////////////////////
//                      Acknowledgements                        //
//////////////////////////////////////////////////////////////////

/**
 * - Patrick Collins & Cyfrin: @https://updraft.cyfrin.io/courses/advanced-foundry/account-abstraction
 */
