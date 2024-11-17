// SPDX-License-Identifier: MIT

// note that natspecs are wip.

/// @notice This contract assigns accounts to roles by the tokens that they hold.
/// - At construction time, the following is set:
///    - the amount of role holders {N}
///    - the roleId {R} to be assigned
///    - the ERC20 token {T} address to be assessed.
///
/// - The contract is meant to be open (using PUBLIC_ROLE at SeperatedPowers protocol), but can also be role restricted.
///    - anyone can nominate themselves for the role.
///    - anyone can call the law to have it (re)assign accounts to the law.
///
/// - The logic:
///    - If fewer than N accounts are nominated, all will be assigne roleId R.
///    - If more than N accounts are nominated, the accounts that hold most ERC20 T will be assigned roleId R.
///
/// @dev The contract is an example of a law that
/// - has does not need a proposal to be voted through. It can be called directly.
/// - has two internal mechanisms: nominate or elect. Which one is run depends on calldata input.
/// - doess not have to role restricted.
/// - translates a simple token based voting system to separated powers.
/// - Note this logic can also be applied with a delegation logic added. Not only taking simple token holdings into account, but also delegated tokens.

pragma solidity 0.8.26;

import { Law } from "../../../Law.sol";
import { SeparatedPowers } from "../../../SeparatedPowers.sol";
import { ERC1155 } from "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/utils/ShortStrings.sol";

contract Randomly is Law {
    using ShortStrings for *;

    error RandomlySelect__NomineeAlreadyNominated();

    uint256 private immutable MAX_ROLE_HOLDERS;
    uint32 private immutable ROLE_ID;

    mapping(address => uint48) private _nominees;
    address[] private _nomineesSorted;
    mapping(address => uint48) private _elected;
    address[] private _electedSorted;
    uint48 private _lastElection;

    event Randomly__NominationReceived(address indexed nominee);
    event Randomly__NominationRevoked(address indexed nominee);
    event Randomly__RolesAssigned(uint32 indexed roleId, address indexed roleHolder);

    constructor(
        string memory name_,
        string memory description_,
        address payable separatedPowers_,
        uint256 maxRoleHolders_,
        uint32 roleId_
    ) Law(name_, description_, separatedPowers_) {
        MAX_ROLE_HOLDERS = maxRoleHolders_;
        ROLE_ID = roleId_;
    }

    function executeLaw(bytes memory lawCalldata, bytes32 descriptionHash)
        external
        override
        returns (address[] memory targets, uint256[] memory values, bytes[] memory calldatas)
    {
        // decode the calldata.
        (bool nominateMe, bool assignRoles) = abi.decode(lawCalldata, (bool, bool));
        uint256 actionId = _hashExecutiveAction(address(this), lawCalldata, keccak256(bytes(description())));
        address initiator = SeparatedPowers(payable(separatedPowers)).getInitiatorAction(actionId);  

        // nominate if nominateMe == true
        // elected accounts are stored in a mapping and have to be accepted.
        if (nominateMe) {
            if (_nominees[initiator] != 0) {
              revert RandomlySelect__NomineeAlreadyNominated();
            }

            _nominees[initiator] = uint48(block.timestamp);
            _nomineesSorted.push(initiator);

            emit Randomly__NominationReceived(initiator);
        }

        // revoke nomination if executionar is nominated and nominateMe == false
        if (!nominateMe && _nominees[initiator] != 0) {
            _nominees[initiator] = 0;
            for (uint256 i; i < _nomineesSorted.length; i++) {
                if (_nomineesSorted[i] == initiator) {
                    _nomineesSorted[i] = _nomineesSorted[_nomineesSorted.length - 1];
                    _nomineesSorted.pop();
                    break;
                }
            }

            emit Randomly__NominationRevoked(initiator);
        }

        // elects roles if assignRoles == true
        if (assignRoles) {
            for (uint256 i = 0; i < _nomineesSorted.length; i++) {
                // £todo here have to revoke roles first.
            }

            uint256 numberNominees = _nomineesSorted.length;

            if (numberNominees < MAX_ROLE_HOLDERS) {
                address[] memory tar = new address[](numberNominees);
                uint256[] memory val = new uint256[](numberNominees);
                bytes[] memory cal = new bytes[](numberNominees);

                for (uint256 i; i < numberNominees; i++) {
                    tar[i] = separatedPowers;
                    val[i] = 0;
                    cal[i] = abi.encodeWithSelector(0x446b340f, ROLE_ID, _nomineesSorted[i]);
                }
                return (tar, val, cal);
            } else {
                address[] memory tar = new address[](MAX_ROLE_HOLDERS);
                uint256[] memory val = new uint256[](MAX_ROLE_HOLDERS);
                bytes[] memory cal = new bytes[](MAX_ROLE_HOLDERS);

                uint256 index;
                while (index < MAX_ROLE_HOLDERS) {
                    // computionally expensive, and pseudo random. But easy to understand as example.
                    // £todo, mechanism here should be improved.
                    for (uint256 i; i < numberNominees; i++) {
                        uint256 psuedoRandomValue =
                            uint256(keccak256(abi.encodePacked(block.number, descriptionHash, i)));
                        if (psuedoRandomValue % numberNominees == 0 && _elected[_nomineesSorted[i]] == 0) {
                            tar[index] = separatedPowers;
                            val[index] = 0;
                            cal[index] = abi.encodeWithSelector(0x446b340f, ROLE_ID, _nomineesSorted[i]); // selector probably wrong. check later.
                            _elected[_nomineesSorted[i]] = uint48(block.timestamp);
                            _electedSorted.push(_nomineesSorted[i]);
                            index++;
                        }
                    }
                }
                return (tar, val, cal);
            }
        }
    }
}
