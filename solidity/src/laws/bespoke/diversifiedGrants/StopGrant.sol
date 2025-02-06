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

pragma solidity 0.8.26;

// protocol
import { Law } from "../../../Law.sol";
import { SeparatedPowers } from "../../../SeparatedPowers.sol";

import { Grant } from "./Grant.sol";

contract StopGrant is Law {
    error StopGrant__GrantHasNotExpired();

    constructor(
        string memory name_,
        string memory description_,
        address payable separatedPowers_,
        uint32 allowedRole_,
        LawConfig memory config_ // this is the configuration for creating new grants, not of the grants themselves.
    ) Law(name_, description_, separatedPowers_, allowedRole_, config_) {
        inputParams = abi.encode("address"); // address of grant
    }

    function simulateLaw(address, /*initiator*/ bytes memory lawCalldata, bytes32 descriptionHash)
        public
        view
        virtual
        override
        returns (address[] memory targets, uint256[] memory values, bytes[] memory calldatas, bytes memory stateChange)
    {
        // step 1: decode data from stateChange
        (address grantAddress) = abi.decode(lawCalldata, (address));

        // step 2: run additional checks
        if (
            Grant(grantAddress).budget() != Grant(grantAddress).spent() && 
            Grant(grantAddress).expiryBlock() > uint48(block.number)
        ) {
            revert StopGrant__GrantHasNotExpired();
        }

        // step 3: create arrays
        targets = new address[](1);
        values = new uint256[](1);
        calldatas = new bytes[](1);
        stateChange = abi.encode("");

        // step 4: fill out arrays with data
        targets[0] = separatedPowers;
        calldatas[0] = abi.encodeWithSelector(SeparatedPowers.revokeLaw.selector, grantAddress);

        // step 5: return data
        return (targets, values, calldatas, stateChange);
    }
}
