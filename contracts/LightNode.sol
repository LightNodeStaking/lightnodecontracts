// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./token/SlETH.sol";
import "./lib/UnstructuredStorage.sol";

contract LightNode {
    using UnstructuredStorage for bytes32;

    bytes32 constant public PAUSE_ROLE = keccak256("PAUSE_ROLE");
    bytes32 constant public RESUME_ROLE = keccak256("RESUME_ROLE");
    bytes32 constant public STAKING_PAUSE_ROLE = keccak256("STAKING_PAUSE_ROLE");
    bytes32 constant public STAKING_CONTROL_ROLE = keccak256("STAKING_CONTROL_ROLE");
    bytes32 constant public MANAGE_FEE = keccak256("MANAGE_FEE");
    bytes32 constant public MANAGE_WITHDRAWAL_KEY = keccak256("MANAGE_WITHDRAWAL_KEY");
    bytes32 constant public MANAGE_PROTOCOL_CONTRACTS_ROLE = keccak256("MANAGE_PROTOCOL_CONTRACTS_ROLE");
    bytes32 constant public BURN_ROLE = keccak256("BURN_ROLE");
    bytes32 constant public DEPOSIT_ROLE = keccak256("DEPOSIT_ROLE");
    bytes32 constant public SET_EL_REWARDS_VAULT_ROLE = keccak256("SET_EL_REWARDS_VAULT_ROLE");
    bytes32 constant public SET_EL_REWARDS_WITHDRAWAL_LIMIT_ROLE = keccak256(
        "SET_EL_REWARDS_WITHDRAWAL_LIMIT_ROLE"
    );

    uint256 constant public PUBKEY_LENGTH = 48;
    uint256 constant public WITHDRAWAL_CREDENTIALS_LENGTH = 32;
    uint256 constant public SIGNATURE_LENGTH = 96;

    uint256 constant public DEPOSIT_SIZE = 32 ether;

    uint256 internal constant DEPOSIT_AMOUNT_UNIT = 1000000000 wei;
    uint256 internal constant TOTAL_BASIS_POINTS = 10000;

    /// @dev default value for maximum number of Ethereum 2.0 validators 
    /// registered in a single depositBufferedEther call
    uint256 internal constant DEFAULT_MAX_DEPOSITS_PER_CALL = 150;

    bytes32 internal constant FEE_POSITION = keccak256("lightnode.Lightnode.fee");
    bytes32 internal constant TREASURY_FEE_POSITION = keccak256("lightnode.Lightnode.treasuryFee");
    bytes32 internal constant INSURANCE_FEE_POSITION = keccak256("lightnode.Lightnode.insuranceFee");
    bytes32 internal constant NODE_OPERATORS_FEE_POSITION = keccak256("lightnode.Lightnode.nodeOperatorsFee");

    bytes32 internal constant DEPOSIT_CONTRACT_POSITION = keccak256("lightnode.Lightnode.depositContract");
    bytes32 internal constant ORACLE_POSITION = keccak256("lightnode.Lightnode.oracle");
    bytes32 internal constant NODE_OPERATORS_REGISTRY_POSITION = keccak256("lightnode.Lightnode.nodeOperatorsRegistry");
    bytes32 internal constant TREASURY_POSITION = keccak256("lightnode.Lightnode.treasury");
    bytes32 internal constant INSURANCE_FUND_POSITION = keccak256("lightnode.Lightnode.insuranceFund");
    bytes32 internal constant EL_REWARDS_VAULT_POSITION = keccak256("lightnode.Lightnode.executionLayerRewardsVault");

    /// @dev storage slot position of the staking rate limit structure
    bytes32 internal constant STAKING_STATE_POSITION = keccak256("lightnode.Lightnode.stakeLimit");
    /// @dev amount of Ether (on the current Ethereum side) buffered on this smart contract balance
    bytes32 internal constant BUFFERED_ETHER_POSITION = keccak256("lightnode.Lightnode.bufferedEther");
    /// @dev number of deposited validators (incrementing counter of deposit operations).
    bytes32 internal constant DEPOSITED_VALIDATORS_POSITION = keccak256("lightnode.Lightnode.depositedValidators");
    /// @dev total amount of Beacon-side Ether (sum of all the balances of LightNode validators)
    bytes32 internal constant BEACON_BALANCE_POSITION = keccak256("lightnode.Lightnode.beaconBalance");
    /// @dev number of LightNode's validators available in the Beacon state
    bytes32 internal constant BEACON_VALIDATORS_POSITION = keccak256("lightnode.Lightnode.beaconValidators");

    /// @dev percent in basis points of total pooled ether allowed to withdraw from ExecutionLayerRewardsVault per Oracle report
    bytes32 internal constant EL_REWARDS_WITHDRAWAL_LIMIT_POSITION = keccak256("lightnode.Lightnode.ELRewardsWithdrawalLimit");

    /// @dev Just a counter of total amount of execution layer rewards received by LightNode contract
    /// Not used in the logic
    bytes32 internal constant TOTAL_EL_REWARDS_COLLECTED_POSITION = keccak256("lightnode.Lightnode.totalELRewardsCollected");

    /// @dev Credentials which allows the DAO to withdraw Ether on the 2.0 side
    bytes32 internal constant WITHDRAWAL_CREDENTIALS_POSITION = keccak256("lightnode.Lightnode.withdrawalCredentials");
}
