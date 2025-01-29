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

// open zeppelin contracts
import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { ERC1155 } from "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import { Create2 } from "@openzeppelin/contracts/utils/Create2.sol";

contract StartGrant is Law {
    error StartGrant__GrantAddressAlreadyExists();
    error StartGrant__RequestAmountExceedsAvailableFunds();

    LawConfig public configNewGrants; // config for new grants. 
    
    constructor(
        string memory name_,
        string memory description_,
        address payable separatedPowers_,
        uint32 allowedRole_,
        LawConfig memory config_, // this is the configuration for creating new grants, not of the grants themselves. 
        address proposals // the address where proposals should be made to proposals. 
    ) Law(name_, description_, separatedPowers_, allowedRole_, config_) {
        inputParams[0] = _dataType("string"); // name
        inputParams[1] = _dataType("string"); // description
        inputParams[2] = _dataType("uint48"); // duration
        inputParams[3] = _dataType("uint256"); // budget
        inputParams[4] = _dataType("address"); // tokenAddress
        inputParams[5] = _dataType("uint256"); // tokenType
        inputParams[6] = _dataType("uint256"); // tokenId   
        inputParams[7] = _dataType("uint32"); // allowedRole
        stateVars = inputParams; // Note: stateVars == inputParams.

        configNewGrants.quorum = 80; 
        configNewGrants.succeedAt = 66; 
        configNewGrants.votingPeriod = 1200; 
        configNewGrants.needCompleted = proposals; 
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
            uint48 duration,
            uint256 budget,
            address tokenAddress,   
            uint256 tokenType,
            uint256 tokenId,
            uint32 allowedRole
            ) = abi.decode(lawCalldata, (
                string, string, uint48, uint256, address, uint256, uint256, uint32
                ));

        // step 0: run additional checks
        // - if budget of grant does not exceed available funds. 
        if (Grant.TokenType(tokenType) == Grant.TokenType.ERC20 && budget >  ERC20(tokenAddress).balanceOf(separatedPowers)) {
            revert StartGrant__RequestAmountExceedsAvailableFunds();
        } else if (Grant.TokenType(tokenType) == Grant.TokenType.ERC1155 && budget > ERC1155(tokenAddress).balanceOf(separatedPowers, tokenId)) {
            revert StartGrant__RequestAmountExceedsAvailableFunds();
        }

        // step 1: calculate address at which grant will be created. 
        address grantAddress = _getGrantAddress(name, description, duration, budget, tokenAddress, tokenType, tokenId, allowedRole);

        // step 2: if address is already in use, revert.
        uint256 codeSize = grantAddress.code.length;
        if (codeSize > 0) {
            revert StartGrant__GrantAddressAlreadyExists();
        }

        // step 3: create arrays
        targets = new address[](1);
        values = new uint256[](1);
        calldatas = new bytes[](1);
        stateChange = abi.encode("");

        // step 4: fill out arrays with data
        targets[0] = separatedPowers;
        calldatas[0] = abi.encodeWithSelector(SeparatedPowers.adoptLaw.selector, grantAddress);
        stateChange = lawCalldata;

        // step 5: return data
        return (targets, values, calldatas, stateChange);
    }

    function _changeStateVariables(bytes memory stateChange) internal override {

        // step 0: decode data from stateChange
        (
        string memory name, 
        string memory description, 
        uint48 duration,
        uint256 budget,
        address tokenAddress,   
        uint256 tokenType,
        uint256 tokenId,
        uint32 allowedRole
        ) = abi.decode(stateChange, (
            string, string, uint48, uint256, address, uint256, uint256, uint32
            ));

        // stp 1: deploy new grant
        _deployGrant(name, description, duration, budget, tokenAddress, tokenType, tokenId, allowedRole);      
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
        uint256 tokenType,
        uint256 tokenId,
        uint32 allowedRole
        ) internal view returns (address) {
            address grantAddress = Create2.computeAddress(bytes32(keccak256(abi.encodePacked(name, description))), keccak256(abi.encodePacked(
                type(Grant).creationCode,
                abi.encode(
                    // standard params
                    name,
                    description,
                    separatedPowers,
                    allowedRole,
                    configNewGrants,
                    // remaining params
                    duration,
                    budget,
                    tokenAddress,
                    Grant.TokenType(tokenType),
                    tokenId
                )
            )));

            return grantAddress;
        }

    function _deployGrant(
        string memory name, 
        string memory description, 
        uint48 duration,
        uint256 budget,
        address tokenAddress,   
        uint256 tokenType,
        uint256 tokenId,
        uint32 allowedRole
        ) internal {
            Grant newGrant = new Grant{salt: bytes32(keccak256(abi.encodePacked(name, description)))}(
                // standard params
                name,
                description,
                separatedPowers,
                allowedRole,
                configNewGrants,
                // remaining params
                duration,
                budget,
                tokenAddress,
                Grant.TokenType(tokenType),
                tokenId
            );
    }
}