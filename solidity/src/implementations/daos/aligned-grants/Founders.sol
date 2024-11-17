// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import { AlignedGrants } from "./AlignedGrants.sol";

contract Founders {
    AlignedGrants agDao; 

    uint256 constant LOCAL_CHAIN_ID = 31337;
    // uint256 constant ETH_SEPOLIA_CHAIN_ID = 11155111;
    // uint256 constant OPT_SEPOLIA_CHAIN_ID = 11155420;
    // uint256 constant ARB_SEPOLIA_CHAIN_ID = 421614;
    // uint256 constant BASE_SEPOLIA_CHAIN_ID = 84532;

    function get(
        address payable alignedGrants 
        ) external returns (
            uint32[] memory constituentRoles, 
            address[] memory constituentAccounts
            ) {
                agDao = AlignedGrants(alignedGrants);

                return getFoundersByChainId(block.chainid);
    }

    function getFoundersByChainId(uint256 chainId) internal returns (
        uint32[] memory constituentRoles, 
        address[] memory constituentAccounts
    ) {
        if (chainId == LOCAL_CHAIN_ID) {
            return getFoundersLocal();
        // } else if (chainId == ETH_SEPOLIA_CHAIN_ID) {
            // return getFoundersEthSepolia();
            // etc... 
        // }
        } else {
            revert("ChainId not supported");
        }
    }

    function getFoundersLocal() internal returns (
        uint32[] memory constituentRoles, 
        address[] memory constituentAccounts
    ) {
        address anvil_0 = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;
        address anvil_1 = 0x70997970C51812dc3A010C7d01b50e0d17dc79C8;
        address anvil_2 = 0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC;
        address anvil_3 = 0x90F79bf6EB2c4f870365E785982E1f101E93b906;
        address anvil_4 = 0x15d34AAf54267DB7D7c367839AAf71A00a2C6A65;
        address anvil_5 = 0x9965507D1a55bcC2695C58ba16FB37d819B0A4dc;

        constituentAccounts[0] = anvil_0;
        constituentRoles[0] = agDao.MEMBER_ROLE();
        constituentAccounts[1] = anvil_1;
        constituentRoles[1] = agDao.MEMBER_ROLE();
        constituentAccounts[2] = anvil_2;
        constituentRoles[2] = agDao.MEMBER_ROLE();
        constituentAccounts[3] = anvil_3;
        constituentRoles[3] = agDao.MEMBER_ROLE();
        constituentAccounts[4] = anvil_4;
        constituentRoles[4] = agDao.MEMBER_ROLE();

        constituentAccounts[5] = anvil_0;
        constituentRoles[5] = agDao.SENIOR_ROLE();
        constituentAccounts[6] = anvil_1;
        constituentRoles[6] = agDao.SENIOR_ROLE();
        constituentAccounts[7] = anvil_2;
        constituentRoles[7] = agDao.SENIOR_ROLE();
        
        constituentAccounts[8] = anvil_4;
        constituentRoles[8] = agDao.WHALE_ROLE();
        constituentAccounts[9] = anvil_5;
        constituentRoles[9] = agDao.WHALE_ROLE();

        return (constituentRoles, constituentAccounts);
    }
}
