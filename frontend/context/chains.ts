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
    blockExplorerUrl: "https://sepolia.arbiscan.io",
    genesisBlock: 111800000n,
    organisations: [
      "0xc70A1A95157Ba7cB7e9fC24F9f91a3B9414ba8a6", // alignedDao ?
      "0x7d4cA83bF92655CF6Ea3fe534765428CBA3E6a55" // basicDao ? 
    ],
    nativeCurrency: {
      name: "Ether", 
      symbol: "ETH", 
      decimals: 18n
    }, 
    erc20s: [
      `0x96B8FDE7522cB57aD19478637033607732412B84`, // Mock 
      `0xe97A5e6C4670DD6fDeA0B5C3E304110eB0e599d9`, // USDC contract
      `0xA977E34e4B8583C6928453CC9572Ae032Cc3200a`, // USDS
      `0xCd5261356706Fd4D8f417F9BffB9dBE575CaE996` // stEth 
    ], 
    erc721s: [
      `0x535a7772dC1e3B3a5Fe25b7727546110468AbCf3` // Mock 
    ], 
    erc1155s: [
      `0x5818B5aeE55696900479eCd410DEC1114c63E430` // Mock 
    ]
  },

]

