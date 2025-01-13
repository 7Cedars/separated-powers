import { Abi } from "viem"

import separatedPowers from "../../solidity/out/SeparatedPowers.sol/SeparatedPowers.json"
import law from "../../solidity/out/Law.sol/Law.json"

export const separatedPowersAbi: Abi = JSON.parse(JSON.stringify(separatedPowers.abi)) 
export const lawAbi: Abi = JSON.parse(JSON.stringify(law.abi)) 

// Note: these abis only have the functions that are used in the UI
export const erc20Abi: Abi = [
  {
    "type": "function",
    "name": "balanceOf",
    "inputs": [
      { "name": "owner", "type": "address", "internalType": "address" }
    ],
    "outputs": [{ "name": "", "type": "uint256", "internalType": "uint256" }],
    "stateMutability": "view"
  }
]

export const erc721Abi: Abi = [
  {
    "type": "function",
    "name": "balanceOf",
    "inputs": [
      { "name": "owner", "type": "address", "internalType": "address" }
    ],
    "outputs": [{ "name": "", "type": "uint256", "internalType": "uint256" }],
    "stateMutability": "view"
  }
]

export const erc1155Abi: Abi = [
  {
    "type": "function",
    "name": "balanceOf",
    "inputs": [
      { "name": "account", "type": "address", "internalType": "address" },
      { "name": "id", "type": "uint256", "internalType": "uint256" }
    ],
    "outputs": [{ "name": "", "type": "uint256", "internalType": "uint256" }],
    "stateMutability": "view"
  },
]
