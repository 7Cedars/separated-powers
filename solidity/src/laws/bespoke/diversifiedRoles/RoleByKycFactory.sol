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

import { Law } from "../../../Law.sol";
import { SeparatedPowers } from "../../../SeparatedPowers.sol";
import { RoleByKyc } from "./RoleByKyc.sol";
import { Create2 } from "@openzeppelin/contracts/utils/Create2.sol";

contract RoleByKycFactory is Law {
    error RoleByKycFactory__AddressOccupied();
    error RoleByKycFactory__RequestAmountExceedsAvailableFunds();

    LawConfig public configNewGrants; // config for new grants. 
    address public members;
    
    constructor(
        string memory name_,
        string memory description_,
        address payable separatedPowers_,
        uint32 allowedRole_,
        LawConfig memory config_, // this is the configuration for creating new grants, not of the grants themselves. 
        address members_ // the address where account kyc are stored. - note: all on public blockchain..  
    ) Law(name_, description_, separatedPowers_, allowedRole_, config_) {
        inputParams[0] = _dataType("string"); // name
        inputParams[1] = _dataType("string"); // description
        inputParams[2] = _dataType("uint32"); // role to be assigned
        inputParams[3] = _dataType("uint16[]"); // nationalities
        inputParams[4] = _dataType("uint16[]"); // countries of residence
        inputParams[5] = _dataType("int64"); // olderThan
        inputParams[6] = _dataType("int64"); // youngerThan
        
        members = members_;
        stateVars = inputParams; // Note: stateVars == inputParams.
      }
   
    /// @notice execute the law.
    /// @param lawCalldata the calldata _without function signature_ to send to the function.
    function simulateLaw(address, /*initiator*/ bytes memory lawCalldata, bytes32 descriptionHash)
        public
        view 
        virtual
        override
        returns (address[] memory targets, uint256[] memory values, bytes[] memory calldatas, bytes memory stateChange)
    {   
        (
            string memory name, 
            string memory description, 
            uint32 role,
            uint16[] memory nationalities,
            uint16[] memory countryOfResidences, 
            int64 olderThan, // in seconds 
            int64 youngerThan // in seconds
            ) = abi.decode(lawCalldata, (
                string, string, uint32, uint16[], uint16[], int64, int64
                ));

        // step 0: calculate address at which grant will be created. 
        address contractAddress = _getContractAddress(name, description, role, nationalities, countryOfResidences, olderThan, youngerThan);

        // step 1: if address is already in use, revert.
        uint256 codeSize = contractAddress.code.length;
        if (codeSize > 0) {
            revert RoleByKycFactory__AddressOccupied();
        }

        // step 3: create arrays
        targets = new address[](1);
        values = new uint256[](1);
        calldatas = new bytes[](1);
        stateChange = abi.encode("");

        // step 4: fill out arrays with data
        targets[0] = separatedPowers;
        calldatas[0] = abi.encodeWithSelector(SeparatedPowers.adoptLaw.selector, contractAddress);
        stateChange = lawCalldata;

        // step 5: return data
        return (targets, values, calldatas, stateChange);
    }

    function _changeStateVariables(bytes memory stateChange) internal override {

        // step 0: decode data from stateChange
        (
            string memory name, 
            string memory description, 
            uint32 role,
            uint16[] memory nationalities,
            uint16[] memory countryOfResidences, 
            int64 olderThan, // in seconds 
            int64 youngerThan // in seconds
            ) = abi.decode(stateChange, (
                string, string, uint32, uint16[], uint16[], int64, int64
                ));

        // stp 1: deploy new grant
        _deployContract(name, description, role, nationalities, countryOfResidences, olderThan, youngerThan);      
    }

    /**
     * calculate the counterfactual address of this account as it would be returned by createAccount()
     * exact copy from SimpleAccountFactory.sol, except it takes loyaltyProgram as param
     */
    function _getContractAddress(
        string memory name, 
        string memory description, 
        uint32 roleId,
        uint16[] memory nationalities,
        uint16[] memory countryOfResidences, 
        int64 olderThan, // in seconds 
        int64 youngerThan // in seconds
        ) internal view returns (address) {
            Create2.computeAddress(bytes32(keccak256(abi.encodePacked(name, description))), keccak256(abi.encodePacked(
                type(RoleByKyc).creationCode,
                abi.encode(
                    // standard params
                    name,
                    description,
                    separatedPowers,
                    allowedRole,
                    configNewGrants,
                    // self select
                    roleId, 
                    // remaining params
                    nationalities,
                    countryOfResidences,
                    olderThan,
                    youngerThan,
                    members
                )
            )));
        }

    function _deployContract(
        string memory name, 
        string memory description, 
        uint32 roleId,
        uint16[] memory nationalities,
        uint16[] memory countryOfResidences, 
        int64 olderThan, // in seconds 
        int64 youngerThan // in seconds
        ) internal {
            RoleByKyc newFilter = new RoleByKyc{salt: bytes32(keccak256(abi.encodePacked(name, description)))}(
                // standard params
                name,
                description,
                separatedPowers,
                allowedRole,
                configNewGrants,
                // self select
                roleId,
                // remaining params
                nationalities,
                countryOfResidences,
                olderThan,
                youngerThan,
                members
            );
    }
}
