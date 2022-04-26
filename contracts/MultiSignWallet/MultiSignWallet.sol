// // SPDX-License-Identifier: MIT
// pragma solidity ^0.8.0;

// contract MultiSignWallet {
//     address[] public owners;

//     mapping(address => bool) public isOwner;
//     uint256 public numOfConfirmationRequired;
//     mapping(address => mapping(address => bool)) public isConfirmed;

//     Transaction[] public transaction;

//     struct Transaction {
//         address to;
//         uint256 value;
//         bytes data;
//         bool executed;
//         uint256 numOfConfirmation;
//     }

//     modifier onlyOwner() {
//         require(isOwner[msg.sender], "NOT_OWNER");
//         _;
//     }

//     constructor() public {}

//     function submitTransaction() public onlyOwner {}

//     function confirmTransaction() public onlyOwner {}

//     function executeTransaction() public onlyOwner {}

//     function revokeTransaction() public onlyOwner {}
// }
