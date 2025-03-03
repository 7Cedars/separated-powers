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
    genesisBlock: 0n, 
    erc20s: [], 
    erc721s: [], 
    erc1155s: []
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
      "0x19c74F72de42701c6726Fc5780771f274fE804BB", // basicDao 
      "0xB0D3356A729a88A64B1055B0798a10A35127621a", // alignedDao
      "0xb14ADAc058013e4b4b9fDe3A129Cd2F034069325", // govern Your Tax
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
      `0x620bB56C119BDaab6BB9E25866c06Fed6dF489EE`, // ERC20TaxedMock - govern your tax 
      `0xa42eBa397054882F651457E7816035A466A28756`, // ERC20VotesMock - basic DAO
      `0xA334A98A6c20B07fc50e5D4D90f5dec310a11D89`, // ERC20VotesMock - aligned DAO
      `0xD23F8ce01e2004765EA92C071e0BB1CB99ed3D1e`, // ERC20TaxedMock - aligned DAO
    ], 
    erc721s: [
      `0x535a7772dC1e3B3a5Fe25b7727546110468AbCf3`, // Mock
      `0x1799C697503Ca5B8f71b80b187078CDF06BAB6d7` // Erc721Mock - aligned DAO 
    ], 
    erc1155s: [
      `0x5818B5aeE55696900479eCd410DEC1114c63E430` // Mock 
    ]
  },

]

