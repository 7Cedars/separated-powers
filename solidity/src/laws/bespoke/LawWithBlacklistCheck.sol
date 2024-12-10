// SPDX-License-Identifier: MIT

/// @title Law.sol v.0.2
/// @notice Base implementation of a Law in the SeparatedPowers protocol. Meant to be inherited by law implementations.
///
/// @dev Laws are role restricted contracts that are executed by the core SeparatedPowers protocol. The provide the following functionality:
/// 1 - Role restricting DAO actions
/// 2 - Transforming a {lawCalldata) input into an output of targets[], values[], calldatas[] to be executed by the core protocol.
/// 3 - Adding conditions to execution of the law, such as a proposal vote, a completed parent law or a delay. Any logic can be added.  
/// 
/// A number of law settings are set through the {setLawConfig} function:
/// - a required role restriction. 
/// - optional configurations of the law, such as
///     - a vote quorum needed to execute the law.  
///     - a vote threshold. 
///     - a vote period. 
///     - a parent law that needs to be completed before the law can be executed.
///     - a parent law that needs to NOT be completed before the law can be executed.
///     - a vote delay: an amount of time in blocks that needs to have passed since the proposal vote ended before the law can be executed. 
///     - a minimum amount of blocks that need to have passed since the previous execution before the law can be executed again. 
/// It is possible to add additional checks if needed. 
///
/// @author 7Cedars, Oct-Nov 2024, RnDAO CollabTech Hackathon
pragma solidity 0.8.26;

import { Law } from "../../Law.sol";
import { BlacklistAccount } from "./BlacklistAccount.sol";

contract LawWithBlacklistCheck is Law {
  error LawWithBlacklistCheck__NoZeroAddress(); 
  error LawWithBlacklistCheck__AccountBlacklisted();

  address public blacklistAccountLaw;  

    constructor(
        string memory name_, 
        string memory description_, 
        address separatedPowers_,
        uint32 allowedRole_,
        LawConfig memory config_,  
        address blacklistAccountLaw_
        ) Law(name_, description_, separatedPowers_, allowedRole_, config_) {
          if (blacklistAccountLaw_ != address(0)) {
            revert LawWithBlacklistCheck__NoZeroAddress(); 
          }
          blacklistAccountLaw = blacklistAccountLaw_;
    }

    /// @notice overrides the default _executeChecks function. 
    /// adds a blacklist check. 
    // any blacklisted account will not be able to execute any law that uses this additional check. 
    function _executeChecks(bytes memory lawCalldata, bytes32 descriptionHash) internal override {
        super._executeChecks(lawCalldata, descriptionHash);

        bool blacklisted = BlacklistAccount(blacklistAccountLaw).blacklistedAccounts(msg.sender);

        if (blacklisted) {
          revert LawWithBlacklistCheck__AccountBlacklisted(); 
        }
    }
}
