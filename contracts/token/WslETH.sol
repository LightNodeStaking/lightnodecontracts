// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/extensions/draft-ERC20Permit.sol";
import "../interfaces/ISlETH.sol";

/**
 * @title SlETH token wrapper with static balances.
 * @dev It's an ERC20 token that represents the account's share of the total
 * supply of slETH tokens. WslETH token's balance only changes on transfers,
 * unlike SlETH that is also changed when oracles report staking rewards and
 * penalties. It's a "power user" token for DeFi protocols which don't
 * support rebasable tokens.
 *
 * The contract is also a trustless wrapper that accepts slETH tokens and mints
 * wslETH in return. Then the user unwraps, the contract burns user's wslETH
 * and sends user locked slETH in return.
 *
 * The contract provides the staking shortcut: user can send ETH with regular
 * transfer and get wslETH in return. The contract will send ETH to LightNode submit
 * method, staking it and wrapping the received slETH.
 *
 */
contract WslETH is ERC20Permit {
    ISlETH public slETH;

    /**
     * @param _slETH address of the SlETH token to wrap
     */
    constructor(ISlETH _slETH)
        ERC20Permit("Wrapped lightnode staked Ether 2.0")
        ERC20("Wrapped lightnode staked Ether 2.0", "wslETH")
    {
        slETH = _slETH;
    }

    /**
     * @notice Exchanges slETH to wslETH
     * @param _slETHAmount amount of slETH to wrap in exchange for wslETH
     * @dev Requirements:
     *  - `_slETHAmount` must be non-zero
     *  - msg.sender must approve at least `_slETHAmount` slETH to this
     *    contract.
     *  - msg.sender must have at least `_slETHAmount` of slETH.
     * User should first approve _slETHAmount to the WslETH contract
     * @return Amount of wslETH user receives after wrap
     */
    function wrap(uint256 _slETHAmount) external returns (uint256) {
        require(_slETHAmount > 0, "wslETH: can't wrap zero slETH");
        uint256 wslETHAmount = slETH.getSharesByPooledEth(_slETHAmount);
        _mint(msg.sender, wslETHAmount);
        slETH.transferFrom(msg.sender, address(this), _slETHAmount);
        return wslETHAmount;
    }

    /**
     * @notice Exchanges wslETH to slETH
     * @param _wslETHAmount amount of wslETH to uwrap in exchange for slETH
     * @dev Requirements:
     *  - `_wslETHAmount` must be non-zero
     *  - msg.sender must have at least `_wslETHAmount` wslETH.
     * @return Amount of slETH user receives after unwrap
     */
    function unwrap(uint256 _wslETHAmount) external returns (uint256) {
        require(_wslETHAmount > 0, "wslETH: zero amount unwrap not allowed");
        uint256 slETHAmount = slETH.getPooledEthByShares(_wslETHAmount);
        _burn(msg.sender, _wslETHAmount);
        slETH.transfer(msg.sender, slETHAmount);
        return slETHAmount;
    }

    /**
    * @notice Shortcut to stake ETH and auto-wrap returned slETH
    */
    receive() external payable {
        uint256 shares = slETH.submit{value: msg.value}(address(0));
        _mint(msg.sender, shares);
    }

    /**
     * @notice Get amount of wslETH for a given amount of slETH
     * @param _slETHAmount amount of slETH
     * @return Amount of wslETH for a given slETH amount
     */
    function getWslETHBySlETH(uint256 _slETHAmount) external view returns (uint256) {
        return slETH.getSharesByPooledEth(_slETHAmount);
    }

    /**
     * @notice Get amount of slETH for a given amount of wslETH
     * @param _wslETHAmount amount of wslETH
     * @return Amount of slETH for a given wslETH amount
     */
    function getSlETHByWslETH(uint256 _wslETHAmount) external view returns (uint256) {
        return slETH.getPooledEthByShares(_wslETHAmount);
    }

    /**
     * @notice Get amount of slETH for a one wslETH
     * @return Amount of slETH for 1 wslETH
     */
    function slEthPerToken() external view returns (uint256) {
        return slETH.getPooledEthByShares(1 ether);
    }

    /**
     * @notice Get amount of wslETH for a one slETH
     * @return Amount of wslETH for a 1 slETH
     */
    function tokensPerSlEth() external view returns (uint256) {
        return slETH.getSharesByPooledEth(1 ether);
    }
}
