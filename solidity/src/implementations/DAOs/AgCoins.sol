// // SPDX-License-Identifier: MIT
// pragma solidity 0.8.26;

// import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

// /**
//  * @dev Mock ERC20 contract for use in the agDAO example implementation of the SeparatedPowers protocol.
//  *
//  */
// contract AgCoins is ERC20 {
//     error AgCoins__ZeroAmount();
//     error AgCoins__AmountExceedsMax();

//     uint256 constant MAX_AMOUNT_COINS_TO_MINT = 2_000_000;

//     constructor(address agDao_) ERC20("AgCoins", "AGC") {
//         _mint(agDao_, type(uint256).max / 2);
//     }

//     function mintCoins(uint256 amount) public {
//         if (amount == 0) {
//             revert AgCoins__ZeroAmount();
//         }
//         if (amount > MAX_AMOUNT_COINS_TO_MINT) {
//             revert AgCoins__AmountExceedsMax();
//         }

//         _mint(msg.sender, amount);
//     }
// }
// // 