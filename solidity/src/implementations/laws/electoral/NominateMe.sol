// SPDX-License-Identifier: MIT

// note that natspecs are wip.

/// @notice This contract allows account holders to log themselves as nominated. The nomination can subsequently be used for an election process: see {DelegateSelect}, {RandomSelect} and {TokenSelect} for examples.
///
/// - The contract is meant to be open (using PUBLIC_ROLE) but can also be role restricted.
///    - anyone can nominate themselves for a role. 
/// 
/// note: the private state var that stores nominees is exposed by calling the executeLaw function. 

pragma solidity 0.8.26;

import { Law } from "../../../Law.sol";
import { SeparatedPowers } from "../../../SeparatedPowers.sol";
import { ERC20Votes } from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol";
import "@openzeppelin/contracts/utils/ShortStrings.sol";

/// ONLY FOR TESTING PURPOSES 
import "forge-std/Test.sol";

contract NominateMe is Law {
    using ShortStrings for *;

    error NominateMe__NomineeAlreadyNominated();
    error NominateMe__NomineeNotNominated();

    mapping(address => uint48) public nominees;
    address[] public nomineesSorted; 
    uint256 public nomineesCount;

    event NominateMe__NominationReceived(address indexed nominee);
    event NominateMe__NominationRevoked(address indexed nominee);

    constructor(
        string memory name_,
        string memory description_,
        address payable separatedPowers_,
        uint32 allowedRole_, 
        LawConfig memory config_
    ) Law(name_, description_, separatedPowers_, allowedRole_, config_) {
        params = [dataType("bool")]; 
    }

    function executeLaw(address initiator, bytes memory lawCalldata, bytes32 descriptionHash)
        public
        override
        returns (address[] memory targets, uint256[] memory values, bytes[] memory calldatas)
    {
        // do optional checks. 
        (targets, values, calldatas) = super.executeLaw(address(0), lawCalldata, descriptionHash);

        // decode the calldata.
        (bool nominateMe) = abi.decode(lawCalldata, (bool));

        // nominating // 
        if (nominateMe) {
            if (nominees[initiator] != 0) {
                revert NominateMe__NomineeAlreadyNominated();
            }
            nominees[initiator] = uint48(block.timestamp);
            nomineesSorted.push(initiator);
            nomineesCount++;

            emit NominateMe__NominationReceived(initiator);
        }

        // revoke nomination // 
        if (!nominateMe) {
            if (nominees[initiator] == 0) {
                revert NominateMe__NomineeNotNominated();
            }

            nominees[initiator] = 0;
            for (uint256 i; i < nomineesSorted.length; i++) {
                if (nomineesSorted[i] == initiator) {
                    nomineesSorted[i] = nomineesSorted[nomineesSorted.length - 1];
                    nomineesSorted.pop();
                    nomineesCount--;
                    break;
                }
            }
            emit NominateMe__NominationRevoked(initiator);
        }
    }
}


