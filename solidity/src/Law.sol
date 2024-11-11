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
    address public separatedPowers; // the address of the core governance protocol
    uint48[] public executions; // timeslot at which law has been executed.  

    /// @dev Constructor function for Law contract.
    constructor(string memory name_, string memory description_) {
        separatedPowers = msg.sender;
        name = name_.toShortString();
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
        // if implementation of law does not override this function, returns empty arrays.  

        address[] memory tar = new address[](0);
        uint256[] memory val = new uint256[](0);
        bytes[] memory cal = new bytes[](0);
        return (tar, val, cal);
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
