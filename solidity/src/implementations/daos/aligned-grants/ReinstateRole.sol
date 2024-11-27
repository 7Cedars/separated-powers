// SPDX-License-Identifier: MIT

/// Note natspecs are still WIP.
///
/// @notice A modifier that sets a function to be conditioned by a proposal vote.
/// This modifier ensures that the function is only callable if a proposal has passed a vote.
pragma solidity 0.8.26;

import { Law } from "../../../Law.sol";
import { SeparatedPowers } from "../../../SeparatedPowers.sol";
import { SeparatedPowersTypes } from "../../../interfaces/SeparatedPowersTypes.sol";
import { AlignedGrants } from "../../../implementations/daos/aligned-grants/AlignedGrants.sol";
import { RevokeRole } from "./RevokeRole.sol";
import "@openzeppelin/contracts/utils/ShortStrings.sol";

contract ReinstateRole is Law {
    using ShortStrings for *;

    uint32 private immutable _roleId;

    constructor(
      string memory name_, 
      string memory description_, 
      address separatedPowers_,
      uint32 roleId_
      )
        Law(name_, description_, separatedPowers_)
    {
        _roleId = roleId_;
        params = [dataType("address")];
    }

    function executeLaw(address, /*initiator */ bytes memory lawCalldata, bytes32 descriptionHash)
        public
        override
        returns (address[] memory tar, uint256[] memory val, bytes[] memory cal) {
        // step 0: do necessary optional checks. 
        super.executeLaw(address(0), lawCalldata, descriptionHash);

        // retrieve the account that was revoked
        (address revokedAccount) = abi.decode(lawCalldata, (address));

        // step 1: create & send return calldata conditional if it is an assign or revoke action.
        tar = new address[](2);
        val = new uint256[](2);
        cal = new bytes[](2);

        // send data to reinstate account to the member role and deblacklist..
        tar[0] = separatedPowers;
        cal[0] = abi.encodeWithSignature("setRole(uint32,address,bool)" , _roleId, revokedAccount, true);

        tar[1] = separatedPowers;
        cal[1] = abi.encodeWithSignature("setBlacklistAccount(address,bool)", revokedAccount, false);
        return (tar, val, cal);
    }
}