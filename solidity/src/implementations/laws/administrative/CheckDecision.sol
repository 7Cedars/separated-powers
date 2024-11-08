// // SPDX-License-Identifier: MIT
// pragma solidity 0.8.26;

// import { Law } from "../../../Law.sol";
// import { SeparatedPowers } from "../../../SeparatedPowers.sol";
// import { ISeparatedPowers } from "../../../interfaces/ISeparatedPowers.sol";
// import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
// import { SeparatedPowersTypes } from "../../../interfaces/SeparatedPowersTypes.sol";

// /**
//  * @notice This contract allows whales to propose laws to be included or excluded from the whitelisted active laws of agDAO.
//  *
//  * @dev The contract is an example of a law that
//  * - has access control and needs a proposal to be voted through.
//  * - starts a chain of proposals. See {Senior_acceptProposedLaw} and {Admin_setLaw} for other laws in the chain.
//  *
//  */
// contract Whale_proposeLaw is Law {
//     error Whale_proposeLaw__ProposalVoteNotSucceeded(uint256 proposalId);

//     address public agCoins;
//     address public agDao;
//     uint256 agCoinsReward = 33_000;

//     constructor(
//         address payable agDao_,
//         address agCoins_ // can take a address parentLaw param.
//     )
//         Law(
//             "Whale_proposeLaw", // = name
//             "A whale can propose laws to be included or excluded from the whitelisted active laws of agDAO.", // = description
//             2, // = access roleId = whale
//             agDao_, // = SeparatedPower.sol derived contract. Core of protocol.
//             20, // = quorum in percent
//             51, // = succeedAt in percent
//             75, // votingPeriod_ in blocks,  Note: these are L1 ethereum blocks!
//             address(0) // = parent Law
//         )
//     {
//         agDao = agDao_;
//         agCoins = agCoins_;
//     }

//     function executeLaw(address executioner, bytes memory lawCalldata, bytes32 descriptionHash)
//         external
//         override
//         returns (address[] memory targets, uint256[] memory values, bytes[] memory calldatas)
//     {
//         // step 0: check if caller is the SeparatedPowers protocol.
//         if (msg.sender != daoCore) {
//             revert Law__AccessNotAuthorized(msg.sender);
//         }

//         // step 1: decode the calldata. Note: no need to decode lawCalldata here.

//         // step 2: check if proposal passed vote.
//         uint256 proposalId = hashProposal(address(this), lawCalldata, descriptionHash);
//         if (SeparatedPowers(payable(agDao)).state(proposalId) != SeparatedPowersTypes.ProposalState.Succeeded) {
//             revert Whale_proposeLaw__ProposalVoteNotSucceeded(proposalId);
//         }

//         // step 3: set proposal to completed.
//         SeparatedPowers(payable(agDao)).complete(lawCalldata, descriptionHash);

//         // step 4: creating data to send to the execute function of agDAO's SepearatedPowers contract.
//         // action 1: send coins to whale that executes the law.
//         address[] memory tar = new address[](1);
//         uint256[] memory val = new uint256[](1);
//         bytes[] memory cal = new bytes[](1);

//         tar[0] = agCoins;
//         val[0] = 0;
//         cal[0] = abi.encodeWithSelector(IERC20.transfer.selector, msg.sender, agCoinsReward);

//         // step 6: return data
//         return (tar, val, cal);
//     }
// }
