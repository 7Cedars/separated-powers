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

contract TokensSelect is Law {
    using ShortStrings for *;

    address private immutable ERC_1155_TOKEN;
    uint256 private immutable MAX_ROLE_HOLDERS;
    uint32 private immutable ROLE_ID;

    mapping(address => uint48) private _nominees;
    mapping(address => uint48) private _elected;
    uint48 private _lastElection;
    address[] private _nomineesSorted;

    event TokensSelect__NominationReceived(address indexed nominee);
    event TokensSelect__NominationRevoked(address indexed nominee);
    event TokensSelect__RolesAssigned(uint32 indexed roleId, address indexed roleHolder);

    constructor(
        string memory name_,
        string memory description_,
        address payable separatedPowers_,
        address payable erc1155Token_,
        uint256 maxRoleHolders_,
        uint32 roleId_
    ) Law(name_, description_, separatedPowers_) {
        ERC_1155_TOKEN = erc1155Token_;
        MAX_ROLE_HOLDERS = maxRoleHolders_;
        ROLE_ID = roleId_;
    }

    function executeLaw(address, /* initiator */ bytes memory lawCalldata, bytes32 /* descriptionHash */ )
        public
        override
        returns (address[] memory targets, uint256[] memory values, bytes[] memory calldatas)
    {
        // decode the calldata.
        (bool nominateMe, bool assignRoles) = abi.decode(lawCalldata, (bool, bool));
        uint256 actionId = _hashProposal(address(this), lawCalldata, keccak256(bytes(description)));
        address initiator = SeparatedPowers(payable(separatedPowers)).getInitiatorAction(actionId);

        // nominate if nominateMe == true
        // elected accounts are stored in a mapping and have to be accepted.
        if (nominateMe) {
            if (_nominees[initiator] != 0) {
                address[] memory tar = new address[](1);
                uint256[] memory val = new uint256[](1);
                bytes[] memory cal = new bytes[](1);
                cal[0] = abi.encode("Nominee already nominated".toShortString());
                return (tar, val, cal);
            }
            _nominees[initiator] = uint48(block.timestamp);
            _nomineesSorted.push(initiator);

            emit TokensSelect__NominationReceived(initiator);
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

            emit TokensSelect__NominationRevoked(initiator);
        }

        // elects roles if assignRoles == true
        if (assignRoles) {
            // NB! £todo: revoke roles of previously selected nominees!

            // create call data of lenght _elected + _nomineesSorted OR MAX_ROLE_HOLDERS.
            // the populate: first with calls to revoke, then with calls to assign.
            // it's not pretty. Are there more efficient ways?

            uint256 numberNominees = _nomineesSorted.length;

            if (numberNominees < MAX_ROLE_HOLDERS) {
                address[] memory tar = new address[](numberNominees);
                uint256[] memory val = new uint256[](numberNominees);
                bytes[] memory cal = new bytes[](numberNominees);

                for (uint256 i; i < numberNominees; i++) {
                    tar[i] = separatedPowers;
                    val[i] = 0;
                    cal[i] = abi.encodeWithSelector(SeparatedPowers.setRole.selector, ROLE_ID, _nomineesSorted[i], true);
                }
                return (tar, val, cal);
            } else {
                uint256[] memory _balances =
                    ERC1155(ERC_1155_TOKEN).balanceOfBatch(_nomineesSorted, new uint256[](MAX_ROLE_HOLDERS));

                address[] memory tar = new address[](MAX_ROLE_HOLDERS);
                uint256[] memory val = new uint256[](MAX_ROLE_HOLDERS);
                bytes[] memory cal = new bytes[](MAX_ROLE_HOLDERS);

                // note how this mechanism works:
                // 1. we add 1 to each nominee's position, if we found a account that holds more tokens.
                // 2. if the position is greater than MAX_ROLE_HOLDERS, we break. (it means there are more accounts that have more tokens than MAX_ROLE_HOLDERS)
                // 3. if the position is less than MAX_ROLE_HOLDERS, we assign the roles. - because loop did not break.
                for (uint256 i; i < _balances.length; i++) {
                    uint256 position;
                    uint256 index;
                    for (uint256 j; j < _balances.length; j++) {
                        if (_balances[i] < _balances[j]) {
                            position++;
                            if (position > MAX_ROLE_HOLDERS) {
                                break;
                            } else {
                                tar[index] = separatedPowers;
                                val[index] = 0;
                                cal[index] = abi.encodeWithSelector(
                                    SeparatedPowers.setRole.selector, ROLE_ID, _nomineesSorted[i], true
                                ); // selector probably wrong. check later.
                                index++;

                                emit TokensSelect__RolesAssigned(ROLE_ID, _nomineesSorted[i]);
                            }
                        }
                    }
                }
                return (tar, val, cal);
            }
        }
    }
}