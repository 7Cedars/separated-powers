// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import { Script, console2 } from "lib/forge-std/src/Script.sol";

contract Founders is Script {
  uint256 constant NUMBER_OF_FOUNDERS = 0;

  function get() external view returns (
      uint32[] memory constituentRoles,
      address[] memory constituentAccounts
    ) {
      constituentRoles = new uint32[](NUMBER_OF_FOUNDERS);
      constituentAccounts = new address[](NUMBER_OF_FOUNDERS);

      // For now no founders. Will implement later 

      //////////////////////////////////////////////////////////////
      //                    RETURN FOUNDERS                       //
      //////////////////////////////////////////////////////////////
      return (constituentRoles, constituentAccounts); 
  }
}