// SPDX-License-Identifier: MIT

/// Note natspecs are still WIP.
///
/// @notice A modifier that sets a function to be conditioned by a proposal vote.
/// This modifier ensures that the function is only callable if a proposal has passed a vote.
pragma solidity 0.8.26;

import { Law } from "../../../Law.sol";
import { AlignedGrantsDao } from "../../../AlignedGrantsDao.sol";
import { SeparatedPowers } from "../../../SeparatedPowers.sol";
import "@openzeppelin/contracts/utils/ShortStrings.sol";

contract AdoptValue is Law {
    using ShortStrings for *;

    constructor(string memory name_, string memory description_, address separatedPowers_)
        Law(name_, description_, separatedPowers_)
    { }

    function executeLaw(address proposer, bytes memory lawCalldata, bytes32 descriptionHash)
        external
        override
        returns (address[] memory tar, uint256[] memory val, bytes[] memory cal)
    { 
        string memory newValue = abi.decode(lawCalldata, (string newValue));

        tar = new address[](1);
        val = new uint256[](1);
        cal = new bytes[](1);

        tar[0] = separatedPowers;
        cal[0] = abi.encodeWithSignature(AlignedGrantsDao.setBlacklistAccount, revokedAccount, false);
        return (tar, val, cal);
    }
}
