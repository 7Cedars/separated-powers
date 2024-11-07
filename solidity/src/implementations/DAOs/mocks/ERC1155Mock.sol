// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import { ERC1155 } from "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";

/**
 * @dev Mock ERC20 contract for use in the agDAO example implementation of the SeparatedPowers protocol.
 *
 */
contract ERC1155Mock is ERC1155 {
    error ERC20Mock__NoZeroAmount();
    error ERC20Mock__AmountExceedsMax();

    uint256 constant MAX_AMOUNT_COINS_TO_MINT = 20_000;
    uint256 constant COIN_ID = 0;

    // the dao address receives half of mintable coins. 
    constructor(address dao) ERC1155("") {
        _mint(dao, COIN_ID, type(uint256).max / 2, "");
    }

    // a public non-restricted function that allows anyone to mint coins. Only restricted by max allowed coins to mint. 
    function mintCoins(uint256 amount) public {
        if (amount == 0) {
            revert ERC20Mock__NoZeroAmount();
        }
        if (amount > MAX_AMOUNT_COINS_TO_MINT) {
            revert ERC20Mock__AmountExceedsMax();
        }

        _mint(msg.sender, COIN_ID, amount, "");
    }
}
