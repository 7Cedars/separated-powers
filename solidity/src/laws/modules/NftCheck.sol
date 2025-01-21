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

/// @notice Natspecs WIP 
/// 
pragma solidity 0.8.26;

import { Law } from "../../Law.sol";
import { ERC721 } from "lib/openzeppelin-contracts/contracts/token/ERC721/ERC721.sol";

abstract contract NftCheck is Law {
    error Erc721Check__DoesNotOwnToken(); 

    /// @notice overrides the default simulateLaw function.
    function _executeChecks(address initiator, bytes memory lawCalldata, bytes32 descriptionHash) internal override {
        bool hasToken = ERC721(nftAddress()).balanceOf(initiator) > 0;
        if (!hasToken) {
            revert Erc721Check__DoesNotOwnToken();
        }
        super._executeChecks(initiator, lawCalldata, descriptionHash);
    }

    function nftAddress() internal view virtual returns (address) {
        return address(0);
    }
}
