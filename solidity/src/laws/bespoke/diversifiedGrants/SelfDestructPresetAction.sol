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
import { Law } from "../../Law.sol";
import { SeparatedPowers } from "../../SeparatedPowers.sol";

// mocks 
import { Erc721Mock } from "../../../test/mocks/Erc721Mock.sol";
import { Erc1155Mock } from "../../../test/mocks/Erc1155Mock.sol";

// laws 
import { PresetAction } from "../executive/PresetAction.sol";
import { SelfDestruct } from "../modules/SelfDestruct.sol";
import { ThrottlePerAccount } from "../modules/ThrottlePerAccount.sol";
import { NftCheck } from "../modules/NftCheck.sol";
import { SelfSelect } from "../electoral/SelfSelect.sol";

// open zeppelin contracts
import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { ERC1155 } from "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import { Create2 } from "@openzeppelin/contracts/utils/Create2.sol";

contract SelfDestructPresetAction is PresetAction, SelfDestruct {
    constructor(
        string memory name_,
        string memory description_,
        address payable separatedPowers_,
        uint32 allowedRole_,
        LawConfig memory config_,
        address[] memory targets_,
        uint256[] memory values_,
        bytes[] memory calldatas_
    ) PresetAction(
        name_, description_, separatedPowers_, allowedRole_, config_, targets_, values_, calldatas_
    ) SelfDestruct() { }

    function simulateLaw(address initiator, bytes memory lawCalldata, bytes32 descriptionHash)
        public view
        override (PresetAction, SelfDestruct)
        virtual
        returns (address[] memory targets, uint256[] memory values, bytes[] memory calldatas, bytes memory stateChange)
    {
        return super.simulateLaw(initiator, lawCalldata, descriptionHash);
    }
}