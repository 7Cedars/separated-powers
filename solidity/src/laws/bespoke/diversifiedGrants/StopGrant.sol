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
import { Powers} from "../../../Powers.sol";

import { Grant } from "./Grant.sol";

contract StopGrant is Law { 
    constructor(
        string memory name_,
        string memory description_,
        address payable powers_,
        uint32 allowedRole_,
        LawConfig memory config_ // this is the configuration for creating new grants, not of the grants themselves.
    ) Law(name_, description_, powers_, allowedRole_, config_) {
        inputParams = abi.encode(
            "string Name", // name
            "string Description", // description
            "uint48 Duration", // duration
            "uint256 Budget", // budget
            "address Erc20Token", // tokenAddress
            "uint32 GrantCouncil", // allowedRole
            "address Proposals" // proposals
        );
        stateVars = inputParams; // Note: stateVars == inputParams.
    }

    function simulateLaw(address, /*initiator*/ bytes memory lawCalldata, bytes32 descriptionHash)
        public
        view
        virtual
        override
        returns (address[] memory targets, uint256[] memory values, bytes[] memory calldatas, bytes memory stateChange)
    {
        // step 0: decode data from stateChange
        (
            string memory name,
            string memory description,
            uint48 duration,
            uint256 budget,
            address tokenAddress,
            uint32 grantCouncil, 
            address proposals 
        ) = abi.decode(lawCalldata, (string, string, uint48, uint256, address, uint32, address));

        // step 1: calculate address at which grant will be created.
        address grantAddress = _getGrantAddress(name, description, duration, budget, tokenAddress, grantCouncil, proposals);

        // step 2: run additional checks
        if (
            Grant(grantAddress).budget() != Grant(grantAddress).spent() && 
            Grant(grantAddress).expiryBlock() > uint48(block.number)
        ) {
            revert ("Grant not expired."); 
        }

        // step 3: create arrays
        targets = new address[](1);
        values = new uint256[](1);
        calldatas = new bytes[](1);
        stateChange = abi.encode("");

        // step 4: fill out arrays with data
        targets[0] = powers;
        calldatas[0] = abi.encodeWithSelector(Powers.revokeLaw.selector, grantAddress);

        // step 5: return data
        return (targets, values, calldatas, stateChange);
    }

     /**
     * calculate the counterfactual address of this account as it would be returned by createAccount()
     * exact copy from SimpleAccountFactory.sol, except it takes loyaltyProgram as param
     */
    function _getGrantAddress(
        string memory name,
        string memory description,
        uint48 duration,
        uint256 budget,
        address tokenAddress,
        uint32 grantCouncil, 
        address proposals
    ) internal view returns (address) {
        address grantAddress = Create2.computeAddress(
            bytes32(keccak256(abi.encodePacked(name, description))),
            keccak256(
                abi.encodePacked(
                    type(Grant).creationCode,
                    abi.encode(
                        // standard params
                        name,
                        description,
                        powers,
                        allowedRole,
                        configNewGrants,
                        // remaining params
                        duration,
                        budget,
                        tokenAddress,
                        grantCouncil,
                        proposals
                    )
                )
            )
        );

        return grantAddress;
    }
}
