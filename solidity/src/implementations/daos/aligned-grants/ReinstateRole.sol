// SPDX-License-Identifier: MIT

/// @notice A bespoke law to reinstate a revoked role.
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

    constructor(string memory name_, string memory description_, address separatedPowers_, uint32 roleId_)
        Law(name_, description_, separatedPowers_)
    {
         _roleId = roleId_;
    }

    function executeLaw(address, /*initiator */ bytes memory lawCalldata, bytes32 descriptionHash)
        public
        override
        needsParentCompleted(lawCalldata, descriptionHash)
        needsProposalVote(lawCalldata, descriptionHash)
        returns (address[] memory tar, uint256[] memory val, bytes[] memory cal)
    {
        // do necessary optional checks. 
        super.executeLaw(address(0), lawCalldata, descriptionHash);

        tar = new address[](2);
        val = new uint256[](2);
        cal = new bytes[](2);

        // retrieve the account that was revoked
        address revokedAccount = abi.decode(lawCalldata, (address));

        // send data to reinstate account to the member role and deblacklist..
        tar[0] = separatedPowers;
        cal[0] = abi.encodeWithSignature(SeparatedPowers.assignRole.selector, MEMBER_ROLE, revokedAccount);

        tar[1] = separatedPowers;
        cal[1] = abi.encodeWithSignature(AlignedGrants.setBlacklistAccount.selector, revokedAccount, false);
        return (tar, val, cal);
    }
}