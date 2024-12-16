// SPDX-License-Identifier: MIT

/// @notice A base contract that executes a bespoke action.
///
/// Note 1: as of now, it only allows for a single function to be called.
/// Note 2: as of now, it does not allow sending of ether values to the target function.
///
/// @author 7Cedars, Oct-Nov 2024, RnDAO CollabTech Hackathon

pragma solidity 0.8.26;

import { Law } from "../../Law.sol";
import { Erc1155Mock } from "../../../test/mocks/Erc1155Mock.sol";
import { ERC1155 } from "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";

contract RequestPayment is Law {
    error RequestPayment__DelayNotPassed();
    error RequestPayment__IncompleteConstructionParams();

    address public erc1155Contract;
    uint256 public tokenId;
    uint256 public amount;
    uint48 public personalDelay;

    mapping(address initiator => uint48 blockNumber) public lastPayment;

    /// @notice constructor of the law
    /// @param name_ the name of the law.
    /// @param description_ the description of the law.
    /// @param separatedPowers_ the address of the core governance protocol
    /// @param allowedRole_ the role that is allowed to execute this law
    /// @param config_ the configuration of the law
    /// @param erc1155Contract_ the address of the erc1155 contract
    /// @param tokenId_ the tokenId of the erc1155 contract
    /// @param amount_ the amount of the erc1155 contract
    /// @param personalDelay_ the personal delay of the erc1155 contract
    constructor(
        string memory name_,
        string memory description_,
        address separatedPowers_,
        uint32 allowedRole_,
        LawConfig memory config_,
        address erc1155Contract_,
        uint256 tokenId_,
        uint256 amount_,
        uint48 personalDelay_
    ) Law(name_, description_, separatedPowers_, allowedRole_, config_) {
        params = new bytes4[](0);

        if (erc1155Contract_ == address(0) || amount_ == 0) {
            revert RequestPayment__IncompleteConstructionParams();
        }
        erc1155Contract = erc1155Contract_; // should this be checked on being an actual erc 1155 contract £todo
        tokenId = tokenId_;
        amount = amount_;
        personalDelay = personalDelay_;
    }

    /// @notice execute the law.
    /// @param initiator the address of the initiator.
    /// @param lawCalldata the calldata _without function signature_ to send to the function.
    /// @param descriptionHash the hash of the description of the law.
    function executeLaw(address initiator, bytes memory lawCalldata, bytes32 descriptionHash)
        public
        virtual
        override
        returns (address[] memory targets, uint256[] memory values, bytes[] memory calldatas)
    {
        // do necessary checks.
        super.executeLaw(address(0), lawCalldata, descriptionHash);

        // check if initiator is not requesting payment too early.
        if (uint48(block.number) - lastPayment[initiator] < personalDelay) {
            revert RequestPayment__DelayNotPassed();
        }

        // if check passes: have core Dao pay the request.
        lastPayment[initiator] = uint48(block.number);

        targets = new address[](1);
        values = new uint256[](1);
        calldatas = new bytes[](1);

        targets[0] = erc1155Contract;
        calldatas[0] =
            abi.encodeWithSelector(ERC1155.safeTransferFrom.selector, separatedPowers, initiator, amount, tokenId, "");
    }
}
