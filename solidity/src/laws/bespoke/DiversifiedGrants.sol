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

import { Law } from "../../Law.sol";
import { ERC1155 } from "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import { SeparatedPowers } from "../../SeparatedPowers.sol";
import { ThrottlePerAccount } from "../modules/ThrottlePerAccount.sol";
import { NftCheck } from "../modules/NftCheck.sol";
import { SelfSelect } from "../electoral/SelfSelect.sol";
import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { ERC1155 } from "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import { Erc721Mock } from "../../../test/mocks/Erc721Mock.sol";
import { Erc1155Mock } from "../../../test/mocks/Erc1155Mock.sol";

// Bespoke law 0: Grant20  
// NB: no checks on what kind of Erc20 token is used. This is just an example. 
contract Grant20 is Law {
    error Grant20__IncorrectGrantAddress();
    error Grant20__RequestAmountExceedsAvailableFunds();

    uint48 public duration;
    uint256 public budget;
    uint256 public spent;
    address public erc20Address; // grants are, in this case, always funded through ERC20 contracts
    
    constructor(
        string memory name_,
        string memory description_,
        address payable separatedPowers_,
        uint32 allowedRole_,
        LawConfig memory config_,

        uint48 duration_, 
        uint256 budget_,
        address erc20Address_
    ) Law(name_, description_, separatedPowers_, allowedRole_, config_) {
        inputParams[0] = _dataType("address");
        inputParams[1] = _dataType("address");
        inputParams[2] = _dataType("uint256");
        stateVars[0] = _dataType("uint256");

        duration = duration_;
        budget = budget_;
        erc20Address = erc20Address_;
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
        (address grantee, address grantAddress, uint256 amount) = abi.decode(lawCalldata, (address, address, uint256));
        
        if (grantAddress != address(this)) {
          revert Grant20__IncorrectGrantAddress();
        }
        if (amount > budget - spent) {
          revert Grant20__RequestAmountExceedsAvailableFunds();
        }
        targets = new address[](1);
        values = new uint256[](1);
        calldatas = new bytes[](1);
        stateChange = abi.encode("");

        // action 0: revoke role member in Separated powers 
        targets[0] = erc20Address;
        calldatas[0] = abi.encodeWithSelector(ERC20.transfer.selector, grantee, amount);
        stateChange = abi.encode(amount);

        return (targets, values, calldatas, stateChange);
    }

    function _changeStateVariables(bytes memory stateChange) internal override {
        (uint256 amount) = abi.decode(stateChange, (uint256));

        spent += amount;
    }
}


// Bespoke law 1: Grant1155  
contract Grant1155 is Law {
    error Grant1155__IncorrectGrantAddress();
    error Grant1155__RequestAmountExceedsAvailableFunds();

    uint48 public duration;
    uint256 public budget;
    uint256 public spent;
    address public erc1155Address; // grants are, in this case, always funded through ERC1155 contracts
    
    constructor(
        string memory name_,
        string memory description_,
        address payable separatedPowers_,
        uint32 allowedRole_,
        LawConfig memory config_,

        uint48 duration_, 
        uint256 budget_,
        address erc20Address_
    ) Law(name_, description_, separatedPowers_, allowedRole_, config_) {
        inputParams[0] = _dataType("address");
        inputParams[1] = _dataType("address");
        inputParams[2] = _dataType("uint256");
        stateVars[0] = _dataType("uint256");

        duration = duration_;
        budget = budget_;
        erc20Address = erc20Address_;
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
        (address grantee, address grantAddress, uint256 amount) = abi.decode(lawCalldata, (address, address, uint256));
        
        if (grantAddress != address(this)) {
          revert Grant1155__IncorrectGrantAddress();
        }
        if (amount > budget - spent) {
          revert Grant1155__RequestAmountExceedsAvailableFunds();
        }
        targets = new address[](1);
        values = new uint256[](1);
        calldatas = new bytes[](1);
        stateChange = abi.encode("");

        // action 0: revoke role member in Separated powers 
        targets[0] = erc20Address;
        calldatas[0] = abi.encodeWithSelector(ERC1155.safeTransferFrom.selector, separatedPowers, grantee, 0, amount, "");
        stateChange = abi.encode(amount);

        return (targets, values, calldatas, stateChange);
    }

    function _changeStateVariables(bytes memory stateChange) internal override {
        (uint256 amount) = abi.decode(stateChange, (uint256));

        spent += amount;
    }
}

// Helper Contract: Grants Factory 
// NB! Note that this is NOT a law. It is a helper contract to create grant law contracts.
// In Separated Powers, by design, laws CANNOT create laws. They have to be deployed separately and then set as an active law in the core protocol.   
contract GrantsFactory { 
    error StartGrant__NotErc20Contract();
    error StartGrant__NotErc1155Contract();
    error GrantsFactory__NotSeparatedPowers();

    address[] public grants;
    uint256 public numberOfGrants;
    address separatedPowers; 

    constructor(
        address payable separatedPowers_ 
    ) {
        separatedPowers = separatedPowers_;
    }

    startGrant20(address grantAddress) external {
        if (grantAddress == address(0)) {
            revert StartGrant__NotErc20Contract();
        }
    }

    startGrant1155(address grantAddress) external {
        if (grantAddress == address(0)) {
            revert StartGrant__NotErc1155Contract();
        }
    }

    stopGrant(address grantAddress) external {
        if (grantAddress == address(0)) {
            revert StartGrant__NotErc1155Contract();
        }
    }

    /// CONTINUE HERE ///

    
}