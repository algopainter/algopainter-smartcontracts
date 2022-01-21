// SPDX-License-Identifier: MIT
pragma solidity ^0.7.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract AlgoPainterTokenMOCK is ERC20 {
    string public SYMBOL;
    string public NAME;
    uint8 public DECIMALS = 18;
    uint256 public INITIAL_SUPPLY = 1000000000 * 10**18;

    constructor(string memory name, string memory symbol) ERC20(name, symbol) {
        NAME = name;
        SYMBOL = symbol;

        _mint(msg.sender, INITIAL_SUPPLY);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override(ERC20) {}
}
