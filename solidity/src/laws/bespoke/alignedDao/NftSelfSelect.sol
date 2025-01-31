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
import { NftCheck } from "../../modules/NftCheck.sol";
import { SelfSelect } from "../../electoral/SelfSelect.sol";

contract NftSelfSelect is SelfSelect, NftCheck {
    address public erc721Token;

    constructor(
        string memory name_,
        string memory description_,
        address payable separatedPowers_,
        uint32 allowedRole_,
        LawConfig memory config_,
        uint32 roleId_,
        address erc721Token_
    ) SelfSelect(name_, description_, separatedPowers_, allowedRole_, config_, roleId_) {
        erc721Token = erc721Token_;
    }

    function simulateLaw(address initiator, bytes memory lawCalldata, bytes32 descriptionHash)
        public
        view
        virtual
        override(Law, SelfSelect)
        returns (address[] memory targets, uint256[] memory values, bytes[] memory calldatas, bytes memory stateChange)
    {
        return super.simulateLaw(initiator, lawCalldata, descriptionHash);
    }

    function _executeChecks(address initiator, bytes memory lawCalldata, bytes32 descriptionHash)
        internal
        override(Law, NftCheck)
    {
        super._executeChecks(initiator, lawCalldata, descriptionHash);
    }

    function _nftCheckAddress() internal view override returns (address) {
        return erc721Token;
    }
}
