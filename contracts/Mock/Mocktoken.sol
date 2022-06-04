// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract Mocktoken is ERC20 {
    uint256 private _totalSupply = 1000 * 1e18;

    constructor(address owner) ERC20("MockToken", "MT") {
        _mint(owner, _totalSupply);
    }
}
