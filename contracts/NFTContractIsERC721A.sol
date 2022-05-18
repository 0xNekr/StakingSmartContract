// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./ERC721AContracts/ERC721A.sol";
import "./ERC721AContracts/ERC721AQueryable.sol";

contract NFTContractIsERC721A is ERC721A, ERC721AQueryable {

    constructor() ERC721A("NFsTaking", "STK") {}

    function mint(uint256 _quantity) external payable {
        _safeMint(msg.sender, _quantity);
    }
}