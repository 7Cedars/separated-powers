// SPDX-License-Identifier: MIT

/// @notice A modifier that sets a function to be conditioned by a proposal vote.
pragma solidity 0.8.26;

import { Law } from "../../../Law.sol";
import { SeparatedPowers } from "../../../SeparatedPowers.sol";
import { AlignedGrants } from "../../../implementations/daos/aligned-grants/AlignedGrants.sol";
import "@openzeppelin/contracts/utils/ShortStrings.sol";

contract RevokeRole is Law {
    using ShortStrings for *;

    uint32 private immutable _roleId;

    constructor(
      string memory name_, 
      string memory description_, 
      address separatedPowers_, 
      uint32 roleId_
      ) Law(name_, description_, separatedPowers_) {
        _roleId = roleId_;
        params = [dataType("address")];
    } 

    function executeLaw(address, /* initiator */ bytes memory lawCalldata, bytes32 descriptionHash)
        public
        override
        returns (address[] memory tar, uint256[] memory val, bytes[] memory cal)
    {
        // step 0: do necessary optional checks. 
        super.executeLaw(address(0), lawCalldata, descriptionHash);
        
        // retrieve the account to be revoked.
        (address accountToBeRevoked) = abi.decode(lawCalldata, (address));

        tar = new address[](2);
        val = new uint256[](2);
        cal = new bytes[](2);

        // revoke member role and blacklist account
        tar[0] = separatedPowers;
        cal[0] = abi.encodeWithSignature("setRole(uint32,address,bool)" , _roleId, accountToBeRevoked, false);

        tar[1] = separatedPowers;
        cal[1] = abi.encodeWithSignature("setBlacklistAccount(address,bool)", accountToBeRevoked, true);
        return (tar, val, cal);
    }
}