import { Abi } from "viem"

import agDao from "../../solidity/out/AgDao.sol/AgDao.json"
import agCoins from "../../solidity/out/AgCoins.sol/AgCoins.json"

export const agDaoAbi: Abi = JSON.parse(JSON.stringify(agDao.abi)) 
export const agCoinsAbi: Abi = JSON.parse(JSON.stringify(agCoins.abi)) 