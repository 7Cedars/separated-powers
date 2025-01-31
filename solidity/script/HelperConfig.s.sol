// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import "lib/forge-std/src/Script.sol";
import { Erc1155Mock } from "../test/mocks/Erc1155Mock.sol";
import { Erc20VotesMock } from "../test/mocks/Erc20VotesMock.sol";
import { ERC1155 } from "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import { ERC20Votes } from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol";
import { Erc721Mock } from "../test/mocks/Erc721Mock.sol";

contract HelperConfig is Script {
    error HelperConfig__InvalidChainId();

    struct NetworkConfig {
        address erc20VotesMock;
        address erc721Mock;
        address erc1155Mock;
        uint256 blocksPerHour; // a basic way of establishing time. As long as block times are fairly stable on a chain, this will work.
        address[] testAccounts; // an array of accounts that can be used in testing. This way you can take existing accounts (+ their balances) and use them in forked tests.
    }

    uint256 constant LOCAL_CHAIN_ID = 31_337;
    uint256 constant ETH_SEPOLIA_CHAIN_ID = 11_155_111;
    uint256 constant OPT_SEPOLIA_CHAIN_ID = 11_155_420;
    uint256 constant ARB_SEPOLIA_CHAIN_ID = 421_614;
    uint256 constant BASE_SEPOLIA_CHAIN_ID = 84_532;

    NetworkConfig public networkConfig;
    mapping(uint256 chainId => NetworkConfig) public networkConfigs;

    constructor() {
        networkConfigs[LOCAL_CHAIN_ID] = getOrCreateAnvilEthConfig();
        networkConfigs[ETH_SEPOLIA_CHAIN_ID] = getEthSepoliaConfig();
        networkConfigs[ARB_SEPOLIA_CHAIN_ID] = getArbSepoliaConfig();
        networkConfigs[OPT_SEPOLIA_CHAIN_ID] = getOptSepoliaConfig();
        networkConfigs[BASE_SEPOLIA_CHAIN_ID] = getBaseSepoliaConfig();
    }

    function getConfig() public returns (NetworkConfig memory) {
        return getConfigByChainId(block.chainid);
    }

    function getConfigByChainId(uint256 chainId) public returns (NetworkConfig memory) {
        if (networkConfigs[chainId].blocksPerHour != 0) {
            return networkConfigs[chainId];
        } else {
            revert HelperConfig__InvalidChainId();
        }
    }

    function getArbSepoliaConfig() public returns (NetworkConfig memory) {
        networkConfig.erc1155Mock = 0x32205ae519CdDeEFB8Cb360C628eaF8159447b65;
        networkConfig.erc20VotesMock = 0x96B8FDE7522cB57aD19478637033607732412B84;
        networkConfig.blocksPerHour = 300;

        return networkConfig;
    }

    function getEthSepoliaConfig() public returns (NetworkConfig memory) {
        networkConfig.blocksPerHour = 300;

        return networkConfig;
    }

    function getOptSepoliaConfig() public returns (NetworkConfig memory) {
        networkConfig.blocksPerHour = 300;

        return networkConfig;
    }

    function getBaseSepoliaConfig() public returns (NetworkConfig memory) {
        networkConfig.blocksPerHour = 300;

        return networkConfig;
    }

    function getOrCreateAnvilEthConfig() public returns (NetworkConfig memory) {
        // check if anvil is already deployed.
        if (networkConfig.erc1155Mock != address(0) && networkConfig.erc20VotesMock != address(0)) {
            return networkConfig;
        }
        // if anvil is not deployed, deploy and save addresses.
        vm.startBroadcast();
        ERC20Votes erc20VotesMock = new Erc20VotesMock();
        Erc721Mock erc721Mock = new Erc721Mock();
        Erc1155Mock erc1155Mock = new Erc1155Mock();
        vm.stopBroadcast();

        networkConfig.erc20VotesMock = address(erc20VotesMock);
        networkConfig.erc721Mock = address(erc721Mock);
        networkConfig.erc1155Mock = address(erc1155Mock);
        networkConfig.blocksPerHour = 3600;

        address[] memory community = new address[](10);
        community[0] = makeAddr("alice");
        community[1] = makeAddr("bob");
        community[2] = makeAddr("charlotte");
        community[3] = makeAddr("david");
        community[4] = makeAddr("eve");
        community[5] = makeAddr("frank");
        community[6] = makeAddr("gary");
        community[7] = makeAddr("helen");
        community[8] = makeAddr("ian");
        community[9] = makeAddr("janice");

        networkConfig.testAccounts = community;

        return networkConfig;
    }
}

//////////////////////////////////////////////////////////////////
//                      Acknowledgements                        //
//////////////////////////////////////////////////////////////////

/**
 * - Patrick Collins & Cyfrin: @https://updraft.cyfrin.io/courses/advanced-foundry/account-abstraction
 */
