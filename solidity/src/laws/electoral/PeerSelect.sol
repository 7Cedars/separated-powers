// SPDX-License-Identifier: MIT

// note that natspecs are wip.

/// @notice This contract ....
///

pragma solidity 0.8.26;

import { Law } from "../../Law.sol";
import { SeparatedPowers } from "../../SeparatedPowers.sol";
import { ERC20Votes } from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol";
import { NominateMe } from "./NominateMe.sol";
import "@openzeppelin/contracts/utils/ShortStrings.sol";

/// ONLY FOR TESTING PURPOSES
import "forge-std/Test.sol";

contract PeerSelect is Law {
    using ShortStrings for *;

    error PeerSelect__MaxRoleHoldersReached();

    uint256 public immutable MAX_ROLE_HOLDERS;
    uint32 public immutable ROLE_ID;
    address public immutable NOMINEES;

    mapping(address => uint48) public _elected;
    address[] public _electedSorted;

    constructor(
        string memory name_,
        string memory description_,
        address payable separatedPowers_,
        uint32 allowedRole_,
        LawConfig memory config_,
        address nominees_,
        uint256 maxRoleHolders_,
        uint32 roleId_
    ) Law(name_, description_, separatedPowers_, allowedRole_, config_) {
        MAX_ROLE_HOLDERS = maxRoleHolders_;
        ROLE_ID = roleId_;
        NOMINEES = nominees_;
        params = [dataType("uint256"), dataType("bool")];
    }

    function executeLaw(address, /*initiator*/ bytes memory lawCalldata, bytes32 descriptionHash)
        public
        override
        returns (address[] memory targets, uint256[] memory values, bytes[] memory calldatas)
    {
        // do optional checks.
        super.executeLaw(address(0), lawCalldata, descriptionHash);

        (uint256 index, bool revoke) = abi.decode(lawCalldata, (uint256, bool));

        targets = new address[](1);
        values = new uint256[](1);
        calldatas = new bytes[](1);
        targets[0] = separatedPowers;

        if (revoke) {
            calldatas[0] = abi.encodeWithSelector(SeparatedPowers.revokeRole.selector, ROLE_ID, _electedSorted[index]);
        }

        if (!revoke) {
          if (_electedSorted.length >= MAX_ROLE_HOLDERS) {
            revert PeerSelect__MaxRoleHoldersReached();
          }
            calldatas[0] = abi.encodeWithSelector(SeparatedPowers.assignRole.selector, ROLE_ID, _electedSorted[index]);
        }

        return (targets, values, calldatas);
    }
}
