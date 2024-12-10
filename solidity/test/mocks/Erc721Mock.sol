// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import { ERC721 } from "@openzeppelin/contracts/token/ERC721/ERC721.sol";

/**
 * @dev Mock ERC721 contract for use in DAO example implementations of the SeparatedPowers protocol.
 *
 */
contract Erc721Mock is ERC721 {
    // the dao address receives half of mintable coins.
    constructor() ERC721("mock", "MOCK") { }

    // a public non-restricted function that allows anyone to mint coins. Only restricted by max allowed coins to mint.
    function mintNFT(uint256 tokenId) public {
        _mint(msg.sender, tokenId);
    }
}
