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

contract ChallengeRevoke is Law {
    using ShortStrings for *;

    bool private immutable _execute;

    constructor(
        string memory name_, 
        string memory description_, 
        address separatedPowers_,
        address parentLaw_
        ) Law(name_, description_, separatedPowers_) { 
            parentLaw = parentLaw_;
    }

    function executeLaw(address /*initiator */, bytes memory lawCalldata, bytes32 descriptionHash)
        external
        needsParentCompleted(lawCalldata, descriptionHash)
        override
        returns (address[] memory tar, uint256[] memory val, bytes[] memory cal)
    { 
        // retrieve the account that was revoked
        address revokedAccount = abi.decode(lawCalldata, (address));

        if (revokedAccount != msg.sender)
        {
          cal[0] = abi.encode("non-revoked account challenger".toShortString());
          return (tar, val, cal);
        }

        // send an tar[0] = address(1) back to protocol so no further action will be taken. 
        tar[0] = address(1);
        return (tar, val, cal);
    }
}
