// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IDepositContract{
    /*
    @param pubKey validator siging key - bytes48
    @param withdrawalCredentials that allows to withdraw funds - bytes32
    @param sign signature of the request - bytes96
    @param deposit_data_root The deposits Merkle tree node, used as a checksum
    */

    function deposit(
        bytes /* 48 */ memory pubkey,
        bytes /* 32 */ memory withdrawal_credentials,
        bytes /* 96 */ memory signature,
        bytes32 deposit_data_root
    )
        external payable;
}