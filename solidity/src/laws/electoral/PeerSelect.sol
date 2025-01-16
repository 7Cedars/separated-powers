// SPDX-License-Identifier: MIT

///////////////////////////////////////////////////////////////////////////////
/// This program is free software: you can redistribute it and/or modify    ///
/// it under the terms of the MIT Public License.                           ///
///                                                                         ///
/// This is a Proof Of Concept and is not intended for production use.      ///
/// Tests are incomplete and it contracts have not been audited.            ///
///                                                                         ///
/// It is distributed in the hope that it will be useful and insightful,    ///
/// but WITHOUT ANY WARRANTY; without even the implied warranty of          ///
/// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.                    ///
///////////////////////////////////////////////////////////////////////////////

// note that natspecs are wip.

/// @notice This contract ....
///



pragma solidity 0.8.26;

import { Law } from "../../Law.sol";
import { SeparatedPowers } from "../../SeparatedPowers.sol";
import { NominateMe } from "./NominateMe.sol";

contract PeerSelect is Law {
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
        uint256 maxRoleHolders_,
        uint32 roleId_
    ) Law(name_, description_, separatedPowers_, allowedRole_, config_) {
        MAX_ROLE_HOLDERS = maxRoleHolders_;
        ROLE_ID = roleId_;
        string[] memory paramArray = new string[](2);
        inputParams[0] = dataType("uint256");
        inputParams[1] = dataType("bool");
    }

    function simulateLaw(address, /*initiator*/ bytes memory lawCalldata, bytes32 descriptionHash)
        public view
        override
        returns (address[] memory targets, uint256[] memory values, bytes[] memory calldatas, bytes memory stateChange)
    {
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

        return (targets, values, calldatas, '0x0');
    }
}
