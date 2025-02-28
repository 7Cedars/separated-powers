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
    // alternativeBlockNumbers: sepolia
    blockTimeInSeconds: 12, // NB: this is the block time of mainnet because on arbitrum One & Arbitrum sepolia 'block.number' returns the block number of L1 *mainnet* not of the L2! . 
    // ps. when using wagmi's 'getBlock' or 'useBlock' you DO get timestamps based on the L2 blocks. That's just to make thinks simpler :/  
    organisations: [
      "0xE0E4241d127C301B1c60eB77c4e81E0Dd0D2E22b", // basicDao 
      "0xD54D38587694cb9E6Cfd59ba4c3e7f607A088b63", // alignedDao
      "0x08Bb4F590170Da2A3613a5446BCdc960B560ED16", // govern Your Tax
      // "0x0181A03C24183eA8F6469C88362B0958ACc474Ce" // diversified roles
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
      `0xCd5261356706Fd4D8f417F9BffB9dBE575CaE996`, // stEth 
      // what follows or mock token contracts used by the example organisations
      `0x10Bf1c1cCe9A0DfE02ad908c462C24f67B2e7DA6`, // ERC20TaxedMock - govern your tax 
      `0xd3b6aed9eB51F2457E51783F66c4fBFA1687557C`, // ERC20VotesMock - basic DAO
    ], 
    erc721s: [
      `0x535a7772dC1e3B3a5Fe25b7727546110468AbCf3` // Mock 
    ], 
    erc1155s: [
      `0x5818B5aeE55696900479eCd410DEC1114c63E430` // Mock 
    ]
  },

]

