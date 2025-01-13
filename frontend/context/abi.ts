import { Abi } from "viem"

import separatedPowers from "../../solidity/out/SeparatedPowers.sol/SeparatedPowers.json"
import law from "../../solidity/out/Law.sol/Law.json"

export const separatedPowersAbi: Abi = JSON.parse(JSON.stringify(separatedPowers.abi)) 
export const lawAbi: Abi = JSON.parse(JSON.stringify(law.abi)) 

