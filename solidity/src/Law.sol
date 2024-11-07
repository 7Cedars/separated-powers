// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import { SeparatedPowers } from "./SeparatedPowers.sol";
import { ILaw } from "./interfaces/ILaw.sol";
import { ERC165 } from "lib/openzeppelin-contracts/contracts/utils/introspection/ERC165.sol";
import { IERC165 } from "lib/openzeppelin-contracts/contracts/utils/introspection/IERC165.sol";
import "../lib/openzeppelin-contracts/contracts/utils/ShortStrings.sol";

/**
 * @notice Base implementation of a Law in the SeparatedPowers protocol. It is meant to be inherited by law implementations.
 *
 * @dev A law has the following characteristics:
 * - They are role restricted. 
 * - Gives privileges to call external contracts and functions.
 * - Constrains these privileges through specific conditions 
 *      - These constrains can be internal: a proposal to this law needs to have passed. (this needs to be implemented in the excuteLaw function)
 *      - These constrains can also be external: a proposal to _another_ law needs to have passed. (these dependences needs to be implemented in the checkDependencies function)
 *
 * @author 7Cedars
 *
 */
contract Law is IERC165, ERC165, ILaw {
    using ShortStrings for *;

    ShortString public immutable name; // name of the law
    address private _separatedPowers; // the address of the core governance protocol
    address[] private _dependencies; // law dependencies 
    string public description; // description of the law

    /// @dev Constructor function for Law contract.
    constructor(string memory name_, string memory description_, address[] memory dependencies_) {
        name = name_.toShortString();
        _separatedPowers = msg.sender;
        _dependencies = dependencies_;
        description = description_;
    }

    /**
     * @dev See {ILaw-executeLaw}.
     *
     * @dev this function needs to be overwritten with the custom logic of the law.
     *
     */
    function executeLaw(address executioner, bytes memory lawCalldata, bytes32 descriptionHash)
        external
        virtual
        returns (address[] memory targets, uint256[] memory values, bytes[] memory calldatas)
    {
        // Normal work flow of a law: 
        // 0 check if law was called from core protocol. 
        if (msg.sender != _separatedPowers) {
            revert ILaw__AccessNotAuthorized(msg.sender);
        }

        // 1: check if conditions among dependencies have been met. 
        (bool passed) = checkDependencies(executioner, lawCalldata, descriptionHash);
        
        if (passed) {
            // 1: if relevant, check if related proposal passed (if applicable)
            // 2: set proposal to complete
            // 3: create executeCallData
            // 4: call execute at {SeparatedPowers} with the executeCallData.  
        }
        
        // That said, this flow is optional. Any logic can be build into a law. See examples in the `implementations/laws` folder 
    }

    /**
     * @dev See {ILaw-executeLaw}.
     *
     * @dev this function can be used to check if dependencies have been met before a proposal is proposed. See {SeparataedPowers::_propose}.
     *
     */
    function checkDependencies(address /* executioner */, bytes memory /* lawCalldata */, bytes32 /* descriptionHash */ )
        public
        virtual
        returns (bool passed)
    {
        return true; // default
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(ILaw).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev see {ISeperatedPowers.hashProposal}.. Use underscore here?
     * A helper function for hashing proposals.
     * Needed often to implement custom law logics.
     */
    function _hashProposal(address targetLaw, bytes memory lawCalldata, bytes32 descriptionHash)
        internal
        pure
        virtual
        returns (uint256)
    {
        return uint256(keccak256(abi.encode(targetLaw, lawCalldata, descriptionHash)));
    }
}
