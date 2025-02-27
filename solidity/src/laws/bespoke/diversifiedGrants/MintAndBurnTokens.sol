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
import { Erc20TaxedMock } from "../../../../test/mocks/Erc20TaxedMock.sol";

contract MintAndBurnTokens is Law {
    /// the targets, values and calldatas to be used in the calls: set at construction.
    address public targetToken;

    /// @notice constructor of the law
    /// @param name_ the name of the law.
    /// @param description_ the description of the law.
    /// @param powers_ the address of the core governance protocol
    /// @param allowedRole_ the role that is allowed to execute this law
    /// @param config_ the configuration of the law
    /// @param targetToken_ the address of the token to mint or burn.
    constructor(
        string memory name_,
        string memory description_,
        address payable powers_,
        uint32 allowedRole_,
        LawConfig memory config_,
        // bespoke options 
        address targetToken_
    ) Law(name_, description_, powers_, allowedRole_, config_) {
        targetToken = targetToken_;
        inputParams = abi.encode("boolean Mint(orBurn)", "uint256 Quantity");
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

        // decode the calldata
        (bool mint, uint256 quantity) = abi.decode(lawCalldata, (bool, uint256));

        if (quantity == 0) {
            revert ("No zero amount.");
        } 

        targets = new address[](1);
        values = new uint256[](1);
        calldatas = new bytes[](1); 

        // send the calldata to the target function
        targets[0] = targetToken;
        if (mint) {
            calldatas[0] = abi.encodePacked(Erc20TaxedMock.mint.selector, quantity);
        } else {
            calldatas[0] = abi.encodePacked(Erc20TaxedMock.burn.selector, quantity);
        }
    }
}