// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface SLETHInterface {
    function balanceOf(address owner) external view returns (uint256);

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

    function getTotalPooledEther() external view returns (uint256);

    function getTotalShares() external view returns (uint256);

    function getPooledEthByShares(uint256 _sharesAmount)
        external
        view
        returns (uint256);

    function getSharesByPooledEth(uint256 _pooledEthAmount)
        external
        view
        returns (uint256);
}
