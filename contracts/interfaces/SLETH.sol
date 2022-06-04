// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface SLETH {
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address owner, address spender)
        external
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    function increaseAllowance(address spender, uint256 addedValue)
        external
        returns (bool);

    function decreaseAllowance(address spender, uint256 subtractedValue)
        external
        returns (bool);

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) external;

    function _mint(address account, uint256 amount) external;

    function _burn(address account, uint256 amount) external;

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) external;
}
