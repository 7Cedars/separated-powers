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
        address[] testAccounts; // an array of accounts that can be used in testing. This way you can take existing accounts (+ their balances) and use them in forked tests. 
    }

    uint256 constant LOCAL_CHAIN_ID = 31_337;
    uint256 constant ETH_SEPOLIA_CHAIN_ID = 11_155_111;
    uint256 constant OPT_SEPOLIA_CHAIN_ID = 11_155_420;
    uint256 constant ARB_SEPOLIA_CHAIN_ID = 421_614;
    uint256 constant BASE_SEPOLIA_CHAIN_ID = 84_532;

    NetworkConfig public localNetworkConfig;
    NetworkConfig public networkConfig;
    mapping(uint256 chainId => NetworkConfig) public networkConfigs;

    constructor() {
        networkConfigs[ETH_SEPOLIA_CHAIN_ID] = getEthSepoliaConfig();
        networkConfigs[ARB_SEPOLIA_CHAIN_ID] = getArbSepoliaConfig();
        networkConfigs[OPT_SEPOLIA_CHAIN_ID] = getOptSepoliaConfig();
        networkConfigs[BASE_SEPOLIA_CHAIN_ID] = getBaseSepoliaConfig();
    }

    function getConfig() public returns (NetworkConfig memory) {
        return getConfigByChainId(block.chainid);
    }

    function getConfigByChainId(uint256 chainId) public returns (NetworkConfig memory) {
        if (chainId == LOCAL_CHAIN_ID) {
            return getOrCreateAnvilEthConfig();
        } else if (networkConfigs[chainId].blocksPerHour != 0) {
            return networkConfigs[chainId];
        } else {
            revert HelperConfig__InvalidChainId();
        }
    }

    function getArbSepoliaConfig() public returns (NetworkConfig memory) {
        networkConfig.erc1155Mock = address(0);
        networkConfig.erc20VotesMock = address(0);
        networkConfig.blocksPerHour = 300;

        return networkConfig;
    }

    function getEthSepoliaConfig() public returns (NetworkConfig memory) {
        networkConfig.erc1155Mock = address(0);
        networkConfig.erc20VotesMock = address(0);
        networkConfig.blocksPerHour = 300;

        return networkConfig;
    }

    function getOptSepoliaConfig() public returns (NetworkConfig memory) {
        networkConfig.erc1155Mock = address(0);
        networkConfig.erc20VotesMock = address(0);
        networkConfig.blocksPerHour = 300;

        return networkConfig;
    }

    function getBaseSepoliaConfig() public returns (NetworkConfig memory) {
        networkConfig.erc1155Mock = address(0);
        networkConfig.erc20VotesMock = address(0);
        networkConfig.blocksPerHour = 300;

        return networkConfig;
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

        localNetworkConfig.erc1155Mock = address(erc1155Mock);
        localNetworkConfig.erc20VotesMock = address(erc20VotesMock);
        localNetworkConfig.blocksPerHour = 3600;

        address[] memory community = new address[](10);
        // anvil standard addresses. 
        community[0] = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;
        community[1] = 0x70997970C51812dc3A010C7d01b50e0d17dc79C8;
        community[2] = 0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC;
        community[3] = 0x90F79bf6EB2c4f870365E785982E1f101E93b906;
        community[4] = 0x15d34AAf54267DB7D7c367839AAf71A00a2C6A65;
        community[5] = 0x9965507D1a55bcC2695C58ba16FB37d819B0A4dc;
        community[6] = 0x976EA74026E726554dB657fA54763abd0C3a0aa9;
        community[7] = 0x14dC79964da2C08b23698B3D3cc7Ca32193d9955;
        community[8] = 0x23618e81E3f5cdF7f54C3d65f7FBc0aBf5B21E8f;
        community[9] = 0xa0Ee7A142d267C1f36714E4a8F75612F20a79720;

        localNetworkConfig.testAccounts = community;
    }
}

//////////////////////////////////////////////////////////////////
//                      Acknowledgements                        //
//////////////////////////////////////////////////////////////////

/**
 * - Patrick Collins & Cyfrin: @https://updraft.cyfrin.io/courses/advanced-foundry/account-abstraction
 */
