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
import { ERC1155 } from "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import { ThrottlePerAccount } from "../../modules/ThrottlePerAccount.sol";

// Bespoke law 2: Request Payment  
contract RequestPayment is ThrottlePerAccount {
    address public erc1155; 
    uint256 public tokenId;
    uint256 public amount;
    uint48 public delay; 
    
    constructor(
        string memory name_,
        string memory description_,
        address payable separatedPowers_,
        uint32 allowedRole_,
        LawConfig memory config_, 

        address erc1155_,
        uint256 tokenId_, 
        uint256 amount_,
        uint48 delay_
    ) Law(name_, description_, separatedPowers_, allowedRole_, config_) {
        amount = amount_; 
        delay = delay_;
        erc1155 = erc1155_;
        tokenId = tokenId_;
    }
          /// @notice execute the law.
        /// @param lawCalldata the calldata _without function signature_ to send to the function.
        function simulateLaw(address initiator, bytes memory lawCalldata, bytes32 descriptionHash)
            public
            view
            virtual
            override
            returns (address[] memory targets, uint256[] memory values, bytes[] memory calldatas, bytes memory stateChange)
        {   
            targets = new address[](1);
            values = new uint256[](1);
            calldatas = new bytes[](1);
            targets[0] = erc1155; 
            calldatas[0] = abi.encodeWithSelector(ERC1155.safeTransferFrom.selector, separatedPowers, initiator, tokenId, amount, "");
        }

        function _delay() internal view override returns (uint48) {
            return delay; 
        }
}
