// uint256 constant LOCAL_CHAIN_ID = 31_337;
// uint256 constant ETH_SEPOLIA_CHAIN_ID = 11_155_111;
// uint256 constant OPT_SEPOLIA_CHAIN_ID = 11_155_420;
// uint256 constant ARB_SEPOLIA_CHAIN_ID = 421_614;
// uint256 constant BASE_SEPOLIA_CHAIN_ID = 84_532;

import { ChainProps } from "./types"

export const supportedChains: ChainProps[] = [
  {
    id: 31337,
    name: "Anvil",
    network: "anvil",
    genesisBlock: 0n 
  },
  {
    id: 421614,
    name: "Arbitrum Sepolia",
    network: "arbitrumSepolia",
    blockExplorerUrl: "https://sepolia.arbiscan.io/",
    genesisBlock: 110000000n,
    mockErc20: 
      {
        name: "Mock Erc20 Vote Coin",
        symbol: "MOCK",
        decimals: 6,
        address: `0x96B8FDE7522cB57aD19478637033607732412B84`,
      },
    mockErc1155: {
      name: "Mock Erc1155 Coin",
      symbol: "MOCK",
      address: `0x32205ae519CdDeEFB8Cb360C628eaF8159447b65`,
      }, 
  },

]