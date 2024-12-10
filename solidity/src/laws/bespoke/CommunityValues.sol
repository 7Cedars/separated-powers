// SPDX-License-Identifier: MIT

// note that natspecs are wip.

/// @notice This contract ...
///
pragma solidity 0.8.26;

import { Law } from "../../Law.sol";

// ONLY FOR DEVELOPMENT.
import "forge-std/Test.sol";

contract CommunityValues is Law {
    error CommunityValues__ValueNotFound();

    // the state vars that this law manages: community values.
    string[] public values; // array of strings: values
    uint256 public numberOfValues;

    event CommunityValues__Added(string value);
    event CommunityValues__Removed(string value);

    constructor(
        string memory name_,
        string memory description_,
        address separatedPowers_,
        uint32 allowedRole_,
        LawConfig memory config_
    ) Law(name_, description_, separatedPowers_, allowedRole_, config_) {
        params = [dataType("string"), dataType("bool")];
    }

    function executeLaw(address, /*initiator */ bytes memory lawCalldata, bytes32 descriptionHash)
        public
        override
        returns (address[] memory tar, uint256[] memory val, bytes[] memory cal)
    {
        // step 0: do necessary optional checks.
        super.executeLaw(address(0), lawCalldata, descriptionHash);

        // retrieve the account that was revoked
        (string memory value, bool addValue) = abi.decode(lawCalldata, (string, bool)); // don't know if this is going to work...

        if (addValue) {
            console.log("adding value");
            _addCommunityValue(value);
        } else {
            console.log("removing value");
            _removeCommunityValue(value);
        }

        // step 2: return data
        address[] memory tar = new address[](1);
        uint256[] memory val = new uint256[](1);
        bytes[] memory cal = new bytes[](1);
        tar[0] = address(1); // signals that separatedPowers should not execute anything else.

        return (tar, val, cal);
    }

    // add value
    function _addCommunityValue(string memory value) internal {
        values.push(value);
        numberOfValues++;

        emit CommunityValues__Added(value);
    }

    // remove value
    // note: it works by searching for value. Not by index.
    // because this way executeLaw always needs the short string + low chance on accidentally removing wrong value.
    function _removeCommunityValue(string memory value) internal {
        for (uint256 index; index < numberOfValues; index++) {
            if (keccak256(bytes(values[index])) == keccak256(bytes(value))) {
                values[index] = values[numberOfValues - 1];
                values.pop();
                numberOfValues--;
                break;
            }

            if (index == numberOfValues - 1) {
                revert CommunityValues__ValueNotFound();
            }
        }

        emit CommunityValues__Removed(value);
    }
}
