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
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { ERC1155 } from "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import { Erc721Mock } from "../../../test/mocks/Erc721Mock.sol";
import { Erc1155Mock } from "../../../test/mocks/Erc1155Mock.sol";
import { Create2 } from "lib/openzeppelin-contracts/contracts/utils/Create2.sol";

// possible to add more types later on. 
enum TokenType {
    ERC20,
    ERC1155
}

// NB: no checks on what kind of Erc20 token is used. This is just an example. 
contract Grant is Law {
    error Grant__IncorrectGrantAddress();
    error Grant__RequestAmountExceedsAvailableFunds();

    uint48 public expiryBlock;
    uint256 public budget;
    uint256 public spent;
    address public tokenAddress; // grants are, in this case, always funded through ERC20 contracts
    TokenType public tokenType;
    uint256 public tokenId;
    
    constructor(
        string memory name_,
        string memory description_,
        address payable separatedPowers_,
        uint32 allowedRole_,
        LawConfig memory config_,

        uint48 duration_, 
        uint256 budget_,
        address tokenAddress_, 
        TokenType tokenType_,
        uint256 tokenId_ // only used with erc1155 funded grants
    ) Law(name_, description_, separatedPowers_, allowedRole_, config_) {
        inputParams[0] = _dataType("address");  // grantee address
        inputParams[1] = _dataType("address");  // grant address = address(this). This is needed to make abuse of proposals across contracts impossible.
        inputParams[2] = _dataType("uint256"); // quantity to transfer
        stateVars[0] = _dataType("uint256"); //  quantity to transfer

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
          revert Grant__IncorrectGrantAddress();
        }
        if (quantity > budget - spent) {
          revert Grant__RequestAmountExceedsAvailableFunds();
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
            calldatas[0] = abi.encodeWithSelector(ERC1155.safeTransferFrom.selector, separatedPowers, grantee, quantity, tokenId, "");
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

contract StartGrant is Law {
    error StartGrant__GrantAddressAlreadyExists();
    error Grant__RequestAmountExceedsAvailableFunds();

    LawConfig public configNewGrants; // config for new grants. 
    
    constructor(
        string memory name_,
        string memory description_,
        address payable separatedPowers_,
        uint32 allowedRole_,
        LawConfig memory config_ // this is the configuration for creating new grants, not of the grants themselves. 
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
        if (TokenType(tokenType) == TokenType.ERC20 && budget >  ERC20(tokenAddress).balanceOf(separatedPowers)) {
            revert Grant__RequestAmountExceedsAvailableFunds();
        } else if (TokenType(tokenType) == TokenType.ERC1155 && budget > ERC1155(tokenAddress).balanceOf(separatedPowers, tokenId)) {
            revert Grant__RequestAmountExceedsAvailableFunds();
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
        ) public view returns (address) {
            Create2.computeAddress(bytes32(keccak256(abi.encodePacked(name, description))), keccak256(abi.encodePacked(
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
                    TokenType(tokenType),
                    tokenId
                )
            )));
        }
    

        //     string memory name_,
        // string memory description_,
        // address payable separatedPowers_,
        // uint32 allowedRole_,
        // LawConfig memory config_,

        // uint48 duration_, 
        // uint256 budget_,
        // address tokenAddress_, 
        // TokenType tokenType_,
        // uint256 tokenId_ // only used with erc1155 funded grants


    function _deployGrant(
        string memory name, 
        string memory description, 
        uint48 duration,
        uint256 budget,
        address tokenAddress,   
        uint256 tokenType,
        uint256 tokenId,
        uint32 allowedRole
        ) internal returns (address grantAddress) {
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
                TokenType(tokenType),
                tokenId
            );

        return address(newGrant);
    }
}

contract stopGrant is Law {
    error StopGrant__GrantHasNotExpired();

     constructor(
        string memory name_,
        string memory description_,
        address payable separatedPowers_,
        uint32 allowedRole_,
        LawConfig memory config_ // this is the configuration for creating new grants, not of the grants themselves. 
    ) Law(name_, description_, separatedPowers_, allowedRole_, config_) {
        inputParams[0] = _dataType("address"); // address of grant
    }
    
    function simulateLaw(address, /*initiator*/ bytes memory lawCalldata, bytes32 descriptionHash)
        public
        view 
        virtual
        override
        returns (address[] memory targets, uint256[] memory values, bytes[] memory calldatas, bytes memory stateChange)
    {
        // step 1: decode data from stateChange
        (address grantAddress) = abi.decode(lawCalldata, (address));

        // step 2: run additional checks 
        if (Grant(grantAddress).budget() - Grant(grantAddress).spent() != 0 && Grant(grantAddress).expiryBlock() > uint48(block.number)) {
            revert StopGrant__GrantHasNotExpired();
        }

        // step 3: create arrays
        targets = new address[](1);
        values = new uint256[](1);
        calldatas = new bytes[](1);
        stateChange = abi.encode("");

        // step 4: fill out arrays with data
        targets[0] = separatedPowers;
        calldatas[0] = abi.encodeWithSelector(SeparatedPowers.revokeLaw.selector, grantAddress);

        // step 5: return data
        return (targets, values, calldatas, stateChange); 
    }
}