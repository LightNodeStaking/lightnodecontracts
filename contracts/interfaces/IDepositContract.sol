// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title Deposit contract interface
interface IDepositContract{
    /**
     * @notice Top-ups deposit of a validator on the ETH 2.0 side
     * @param pubkey Validator signing key
     * @param withdrawal_credentials Credentials that allows to withdraw funds
     * @param signature Signature of the request
     * @param deposit_data_root The deposits Merkle tree node, used as a checksum
     */
    function deposit(
        bytes /* 48 */ memory pubkey,
        bytes /* 32 */ memory withdrawal_credentials,
        bytes /* 96 */ memory signature,
        bytes32 deposit_data_root
    ) external payable;
}
