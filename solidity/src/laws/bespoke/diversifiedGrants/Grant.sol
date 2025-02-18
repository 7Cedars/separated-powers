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

// open zeppelin contracts
import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { ERC1155 } from "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";

// NB: no checks on what kind of Erc20 token is used. This is just an example.
contract Grant is Law {
    enum TokenType {
        ERC20,
        ERC1155
    }

    uint48 public expiryBlock;
    uint256 public budget;
    uint256 public spent;
    address public tokenAddress; // grants are, in this case, always funded through ERC20 contracts
    TokenType public tokenType;
    uint256 public tokenId;

    constructor(
        string memory name_,
        string memory description_,
        address payable powers_,
        uint32 allowedRole_,
        LawConfig memory config_,
        uint48 duration_,
        uint256 budget_,
        address tokenAddress_,
        TokenType tokenType_,
        uint256 tokenId_ // only used with erc1155 funded grants
    ) Law(name_, description_, powers_, allowedRole_, config_) {
        inputParams = abi.encode(
            "address Grantee", // grantee address
            "address Grant", // grant address = address(this). This is needed to make abuse of proposals across contracts impossible.
            "uint256 Quantity" // quantity to transfer
        );
        stateVars = abi.encode("uint256"); //  quantity to transfer

        expiryBlock = duration_ + uint48(block.number);
        budget = budget_;
        tokenAddress = tokenAddress_;
        tokenType = tokenType_;
        tokenId = tokenId_;
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
        // step 0: decode law calldata
        (address grantee, address grantAddress, uint256 quantity) = abi.decode(lawCalldata, (address, address, uint256));

        // step 1: run additional checks
        if (grantAddress != address(this)) {
            revert ("Incorrect grant address.");
        }
        if (quantity > budget - spent) {
            revert ("Request amount exceeds available funds."); 
        }

        // step 2: create arrays
        targets = new address[](1);
        values = new uint256[](1);
        calldatas = new bytes[](1);
        stateChange = abi.encode("");

        // step 3: fill out arrays with data
        targets[0] = tokenAddress;
        stateChange = abi.encode(quantity);
        // action: transfer tokens to grantee. Conditional on what token type is used.
        if (tokenType == TokenType.ERC20) {
            calldatas[0] = abi.encodeWithSelector(ERC20.transfer.selector, grantee, quantity);
        } else if (tokenType == TokenType.ERC1155) {
            calldatas[0] = abi.encodeWithSelector(
                ERC1155.safeTransferFrom.selector, powers, grantee, tokenId, quantity, ""
            );
        }

        // step 4: return data
        return (targets, values, calldatas, stateChange);
    }

    function _changeStateVariables(bytes memory stateChange) internal override {
        (uint256 quantity) = abi.decode(stateChange, (uint256));

        // update spent amount in law.
        spent += quantity;
    }
}
