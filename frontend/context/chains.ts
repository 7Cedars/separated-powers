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
    genesisBlock: 110000000n,
    mockErc20: `0x96B8FDE7522cB57aD19478637033607732412B84`,
    mockErc1155: `0x32205ae519CdDeEFB8Cb360C628eaF8159447b65`,
    erc20s: [
      {
        name: "USD Coin",
        symbol: "USDC",
        decimals: 6,
        address: `0xf3C3351D6Bd0098EEb33ca8f830FAf2a141Ea2E1`,
      }
    ], 
  },

]