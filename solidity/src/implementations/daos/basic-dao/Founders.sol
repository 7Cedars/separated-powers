// SPDX-License-Identifier: MIT
/// @notice Example Founders contract used for initiation of a DAO based on the SeparatedPowers protocol.
/// 
/// Note {Founders.sol} assigns roles to accounts through a one-time callable {SeparatedPowers::constitute} function. 
/// In this case, it is important to assign at least one account to a SENIOR_ROLE as seniors, elect seniors.  
///
/// Note. IMPORTANT: This is a work in progress. Do not use in production. It does not come with any guarantees, warranties of any kind. 
/// 
/// @author 7Cedars, Oct-Nov 2024, RnDAO CollabTech Hackathon
pragma solidity 0.8.26;

import { BasicDao } from "./BasicDao.sol";

contract Founders {
    BasicDao basicDao;

    uint256 constant LOCAL_CHAIN_ID = 31_337;
    // uint256 constant ETH_SEPOLIA_CHAIN_ID = 11155111;
    // uint256 constant OPT_SEPOLIA_CHAIN_ID = 11155420;
    // uint256 constant ARB_SEPOLIA_CHAIN_ID = 421614;
    // uint256 constant BASE_SEPOLIA_CHAIN_ID = 84532;

    function get(address payable basicDao_)
        external
        returns (uint32[] memory constituentRoles, address[] memory constituentAccounts)
    {
        basicDao = BasicDao(basicDao_);
        return getFoundersByChainId(block.chainid);
    }

    function getFoundersByChainId(uint256 chainId)
        internal
        returns (uint32[] memory constituentRoles, address[] memory constituentAccounts)
    {
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

    function getFoundersLocal()
        internal
        returns (uint32[] memory constituentRoles, address[] memory constituentAccounts)
    {
        constituentRoles = new uint32[](3);
        constituentAccounts = new address[](3);

        address anvil_0 = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;
        address anvil_1 = 0x70997970C51812dc3A010C7d01b50e0d17dc79C8;
        address anvil_2 = 0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC;

        constituentAccounts[0] = anvil_0;
        constituentRoles[0] = basicDao.SENIOR_ROLE();
        constituentAccounts[1] = anvil_1;
        constituentRoles[1] = basicDao.SENIOR_ROLE();
        constituentAccounts[2] = anvil_2;
        constituentRoles[2] = basicDao.SENIOR_ROLE();

        return (constituentRoles, constituentAccounts);
    }
}
