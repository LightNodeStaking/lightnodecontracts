//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "hardhat/console.sol";

//Sole purpose of testing lp manager
contract Defo is ERC20, Ownable{
    mapping(address => uint256) private _balances;
    uint256 public _totalSupply = 200000*1e18;
    uint256 MAXSELLLIMIT = _totalSupply / 1000;

    
    constructor() ERC20("MDAI Token","MDAI"){
        _mint(owner(), _totalSupply);
    }


}