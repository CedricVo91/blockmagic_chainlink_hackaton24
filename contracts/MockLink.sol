// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;


import "../node_modules/@openzeppelin/contracts/token/ERC20/ERC20.sol";


contract MockLINK is ERC20 {
    constructor() ERC20("Mock LINK", "LINK") {
        _mint(msg.sender, 1000000 * 10 ** decimals());
    }
}