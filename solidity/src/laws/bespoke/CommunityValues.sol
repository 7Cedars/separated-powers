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
        inputParams[0] = dataType("string");
        inputParams[1] = dataType("bool");
        stateVars[0] = dataType("string");
        stateVars[1] = dataType("bool");
    }

    function simulateLaw(address, /*initiator */ bytes memory lawCalldata, bytes32 descriptionHash)
        public view
        override
        returns (address[] memory tar, uint256[] memory val, bytes[] memory cal, bytes memory stateChange)
    {
        // step 1: return data
        address[] memory tar = new address[](1);
        uint256[] memory val = new uint256[](1);
        bytes[] memory cal = new bytes[](1);
        tar[0] = address(1); // signals that separatedPowers should not execute anything else.

        return (tar, val, cal, lawCalldata);
    }

    function _changeStateVariables(bytes memory stateChange) internal override {
        (string memory value, bool addValue) = abi.decode(stateChange, (string, bool)); // don't know if this is going to work...

        if (addValue) {
            values.push(value);
            numberOfValues++;

            emit CommunityValues__Added(value);
        } else {
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
}
