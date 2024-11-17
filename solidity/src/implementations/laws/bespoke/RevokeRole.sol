// SPDX-License-Identifier: MIT

/// Note natspecs are still WIP.
///
/// @notice A modifier that sets a function to be conditioned by a proposal vote.
/// This modifier ensures that the function is only callable if a proposal has passed a vote.
pragma solidity 0.8.26;

import { Law } from "../../../Law.sol";
import { SeparatedPowers } from "../../../SeparatedPowers.sol";
import { AlignedGrants } from "../../../implementations/daos/aligned-grants/AlignedGrants.sol";
import "@openzeppelin/contracts/utils/ShortStrings.sol";

contract RevokeRole is Law {
    using ShortStrings for *;

    uint32 private immutable _roleId;

    constructor(string memory name_, string memory description_, address separatedPowers_, uint32 roleId_)
        Law(name_, description_, separatedPowers_)
    { 
        _roleId = roleId_;
    }

    function  executeLaw(bytes memory lawCalldata, bytes32 descriptionHash)
        external
        needsProposalVote(lawCalldata, descriptionHash)
        override
        returns (address[] memory tar, uint256[] memory val, bytes[] memory cal)
    { 
        // retrieve the account to be revoked.
        address accountToBeRevoked = abi.decode(lawCalldata, (address));

        tar = new address[](2);
        val = new uint256[](2);
        cal = new bytes[](2);

        // revoke member role and blacklist account
        tar[0] = separatedPowers;
        cal[0] = abi.encodeWithSignature("setRole(uint32,address,bool)", _roleId, accountToBeRevoked, true);

        tar[1] = separatedPowers;
        cal[1] = abi.encodeWithSignature("setBlacklisted(address,bool)", accountToBeRevoked, false);
        return (tar, val, cal);
    }
}
