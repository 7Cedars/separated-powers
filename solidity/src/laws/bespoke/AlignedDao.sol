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
import { Erc721Mock } from "../../../test/mocks/Erc721Mock.sol";
import { Erc1155Mock } from "../../../test/mocks/Erc1155Mock.sol";

// Bespoke law 0: RevokeMembership  
contract RevokeMembership is Law {
    error RevokeMembership__IsNotMember();
    uint32 constant ROLE_ID = 1; 

    address public erc721Token;

    constructor(
        string memory name_,
        string memory description_,
        address payable separatedPowers_,
        uint32 allowedRole_,
        LawConfig memory config_,
        address erc721Token_
    ) Law(name_, description_, separatedPowers_, allowedRole_, config_) {
        inputParams[0] = _dataType("uint256");
        inputParams[1] = _dataType("address");

        erc721Token = erc721Token_;
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

        (uint256 tokenId, address account) = abi.decode(lawCalldata, (uint256, address));
        targets = new address[](2);
        values = new uint256[](2);
        calldatas = new bytes[](2);
        stateChange = abi.encode("");

        // action 0: revoke role member in Separated powers 
        targets[0] = separatedPowers;
        calldatas[0] = abi.encodeWithSelector(SeparatedPowers.revokeRole.selector, ROLE_ID, account);

        // action 1: burn the access token of the member, so they cannot become member again.
        targets[1] = erc721Token;
        calldatas[1] = abi.encodeWithSelector(Erc721Mock.burnNFT.selector, tokenId, account);

        return (targets, values, calldatas, stateChange);
    }
}

// Bespoke law 1: ReinstateRole  
contract ReinstateRole is Law {
    error ReinstateRole__IsAlreadyMember();
    uint32 constant ROLE_ID = 1; 

    address public erc721Token;

    constructor(
        string memory name_,
        string memory description_,
        address payable separatedPowers_,
        uint32 allowedRole_,
        LawConfig memory config_,
        address erc721Token_
    ) Law(name_, description_, separatedPowers_, allowedRole_, config_) {
        inputParams[0] = _dataType("uint256");
        inputParams[1] = _dataType("address");

        erc721Token = erc721Token_;
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

        (uint256 tokenId, address account) = abi.decode(lawCalldata, (uint256, address));
        targets = new address[](2);
        values = new uint256[](2);
        calldatas = new bytes[](2);
        stateChange = abi.encode("");

        // action 0: revoke role member in Separated powers 
        targets[0] = separatedPowers;
        calldatas[0] = abi.encodeWithSelector(SeparatedPowers.assignRole.selector, ROLE_ID, account);

        // action 1: burn the access token of the member, so they cannot become member again.
        targets[1] = erc721Token;
        calldatas[1] = abi.encodeWithSelector(Erc721Mock.mintNFT.selector, account);

        return (targets, values, calldatas, stateChange);
    }
}

// Bespoke law 2: Request Payment  
contract RequestPayment is ThrottlePerAccount {
    address public erc1155; 
    uint256 public amount;
    uint48 public delay; 
    
    constructor(
        string memory name_,
        string memory description_,
        address payable separatedPowers_,
        uint32 allowedRole_,
        LawConfig memory config_, 

        address erc1155_,
        uint256 amount_,
        uint48 delay_
    ) Law(name_, description_, separatedPowers_, allowedRole_, config_) {
        amount = amount_; 
        delay = delay_;
        erc1155 = erc1155_;
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
            calldatas[0] = abi.encodeWithSelector(ERC1155.safeTransferFrom.selector, separatedPowers, initiator, 0, amount, "");
        }

        function _delay() internal view override returns (uint48) {
            return delay; 
        }
}

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
        public view
        override (Law, SelfSelect)
        virtual
        returns (address[] memory targets, uint256[] memory values, bytes[] memory calldatas, bytes memory stateChange)
    {
        return super.simulateLaw(initiator, lawCalldata, descriptionHash);
    }

    function _executeChecks(address initiator, bytes memory lawCalldata, bytes32 descriptionHash) internal override (Law, NftCheck) {
        super._executeChecks(initiator, lawCalldata, descriptionHash);
    }

    function _nftCheckAddress() internal view override returns (address) {
        return erc721Token;
    }

} 