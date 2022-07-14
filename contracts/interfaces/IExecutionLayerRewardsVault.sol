// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IExecutionLayerRewardsVault {

    /**
    * @notice Withdraw all accumulated execution layer rewards to Staking contract
    * @param _maxAmount Max amount of ETH to withdraw
    * @return amount of funds received as execution layer rewards (in wei)
    */
    function withdrawRewards(uint256 _maxAmount) external returns (uint256 amount);
}
