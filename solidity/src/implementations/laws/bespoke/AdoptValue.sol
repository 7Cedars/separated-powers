// SPDX-License-Identifier: MIT

/// Note natspecs are still WIP.
///
/// @notice A modifier that sets a function to be conditioned by a proposal vote.
/// This modifier ensures that the function is only callable if a proposal has passed a vote.
pragma solidity 0.8.26;

import { Law } from "../../../Law.sol";
import { AlignedGrants } from "../../../implementations/daos/AlignedGrants.sol";
import { SeparatedPowers } from "../../../SeparatedPowers.sol";
import "@openzeppelin/contracts/utils/ShortStrings.sol";

contract AdoptValue is Law {
    using ShortStrings for *;

    constructor(
        string memory name_, 
        string memory description_, 
        address separatedPowers_,
        address parentLaw_
        ) Law(name_, description_, separatedPowers_) { 
            parentLaw = parentLaw_;
    }

    function executeLaw(bytes memory lawCalldata, bytes32 descriptionHash)
        external
        needsParentCompleted(lawCalldata, descriptionHash)
        override
        // needsVote() include here a modifier?  
        returns (address[] memory tar, uint256[] memory val, bytes[] memory cal)
    { 
        bytes32 newValue = abi.decode(lawCalldata, (bytes32));

        tar = new address[](1);
        val = new uint256[](1);
        cal = new bytes[](1);

        tar[0] = separatedPowers;
        cal[0] = abi.encodeWithSignature("addCoreValue(string)", newValue);
        return (tar, val, cal);
    }
}
