// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract MultiSignWallet {
    address[] public owners;

    mapping(address => bool) public isOwner;
    uint256 public numOfConfirmationRequired;
    mapping(address => mapping(address => bool)) public isConfirmed;

    Transaction[] public transactions;

    struct Transaction {
        address to;
        uint256 value;
        bytes data;
        bool executed;
        uint256 numOfConfirmations;
    }

    constructor() public {}

    modifier onlyOwner() {
        require(isOwner[msg.sender], "NOT_OWNER");
        _;
    }

    modifier transExist(uint256 _txIndex) {
        require(_txIndex < transactions.length, "TRANSACTION_NOT_EXIST");
        _;
    }

    modifier notExceuted(uint256 _txIndex) {
        require(!transactions[_txIndex].executed, "ALREADY_EXECUTED");
        _;
    }

    modifier notConfirmed(uint256 _txIndex) {
        require(!isConfirmed[_txIndex][msg.sender], "ALREADY_CONFIRMED");
        _;
    }

    event SubmitTransaction(
        address indexed owner,
        uint256 indexed txIndex,
        address indexed to,
        uint256 value,
        bytes data
    );
    event ConfirmTransaction();
    event ExecuteTransaction();
    event RevokeTransaction();

    function submitTransaction(
        address _to,
        uint256 _value,
        bytes memory _data
    ) public onlyOwner {
        uint256 txIndex = transactions.length;

        transactions.push(
            Transaction({
                to: _to,
                value: _value,
                data: _data,
                executed: false,
                numOfConfirmations: 0
            })
        );

        emit SubmitTransaction(msg.sender, txIndex, _to, _value, _data);
    }

    function confirmTransaction(uint256 _txIndex)
        public
        onlyOwner
        transExist(_txIndex)
        notExceuted(_txIndex)
        notConfirmed(_txIndex)
    {
        emit ConfirmTransaction();
    }

    function executeTransaction() public onlyOwner {
        emit ExecuteTransaction();
    }

    function revokeTransaction() public onlyOwner {
        emit RevokeTransaction();
    }
}
