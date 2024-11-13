// SPDX-License-Identifier: MIT

/// @notice Base implementation of a Law in the SeparatedPowers protocol. Meant to be inherited by law implementations.
/// See ./laws/Readme.md for more details. 
///
/// @dev Law contracts only encode the base logic of the law: 
/// - how an input is transformed into an output.
/// - under what conditions the law can be executed .
/// 
/// Configuration of the law is handled in the core SeparatedPowers contract.
/// - what role restriction applies to the law
/// - quorum 
/// - vote threshold 
/// - voting period
///
/// The base contract does not have any logic: it only returns empty arrays. 
/// - See the ./laws folder for example implementations. 
///
/// @author 7Cedars, Oct-Nov 2024, RnDAO CollabTech Hackathon
pragma solidity 0.8.26;

import { ILaw } from "./interfaces/ILaw.sol";
import { ERC165 } from "lib/openzeppelin-contracts/contracts/utils/introspection/ERC165.sol";
import { IERC165 } from "lib/openzeppelin-contracts/contracts/utils/introspection/IERC165.sol";
import "@openzeppelin/contracts/utils/ShortStrings.sol";


contract Law is IERC165, ERC165, ILaw {
    using ShortStrings for *; 

    error Law__NoZeroAddress();

    ShortString public immutable name; // name of the law
    address public separatedPowers; // the address of the core governance protocol
    address public parentLaw; // optional slot to save a parentLaw. 
    string public description;
    uint48[] public executions; // log of block numbers at which the law was executed.  

    /// @dev Constructor function for Law contract.
    constructor(string memory name_, string memory description_, address separatedPowers_) {
        separatedPowers = separatedPowers_;
        name = name_.toShortString();
        description = description_;
    }
    
    /// @inheritdoc ILaw
    function executeLaw(address /* proposer */, bytes memory /* lawCalldata */ , bytes32 /* descriptionHash */)
        external
        virtual
        returns (address[] memory targets, uint256[] memory values, bytes[] memory calldatas)
    {
        address[] memory tar = new address[](0);
        uint256[] memory val = new uint256[](0);
        bytes[] memory cal = new bytes[](0);
        return (tar, val, cal);
    }

    /// @inheritdoc ILaw
    function getExecutions() public view returns (uint48[] memory) {
        return executions;
    }

    /// @notice implements ERC165
    function supportsInterface(bytes4 interfaceId) public view override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(ILaw).interfaceId || super.supportsInterface(interfaceId);
    }

    /// @notice an internal helper function for hashing proposals. 
    function _hashProposal( 
        address proposer, 
        address targetLaw, 
        bytes memory lawCalldata, 
        bytes32 descriptionHash
        ) internal pure returns (uint256) {
        return uint256(keccak256(abi.encode(proposer, targetLaw, lawCalldata, descriptionHash)));
    }
}
