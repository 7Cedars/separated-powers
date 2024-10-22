import { Abi } from "viem"

import agDao from "../../solidity/out/AgDao.sol/AgDao.json"

export const agDaoAbi: Abi = JSON.parse(JSON.stringify(agDao.abi)) 