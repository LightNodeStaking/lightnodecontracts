// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract MultiSignWallet {
    event AddOwner(address indexed owner, address indexed NewOwner);
    event RemoveOwner(address indexed owner, address indexed removedOwner);
    event ConfirmationRequired(uint256 required);

    event Deposit(address indexed sender, uint256 amount, uint256 balance);
    event Submit(uint256 indexed txIndex);
    event Approve(address indexed owner, uint256 indexed txIndex);
    event Revoke(address indexed owner, uint256 indexed txIndex);
    event Execute(uint256 indexed txIndex);

    address public owner;
    address[] public owners; // to be private
    mapping(address => bool) public isOwner;
    uint256 public required;

    // mapping from tx index => owner => bool
    mapping(uint256 => mapping(address => bool)) public approved;

    Transaction[] public transactions;

    struct Transaction {
        address to;
        uint256 value;
        bytes data;
        bool executed;
    }

    modifier onlyOwner() {
        require(isOwner[msg.sender], "NOT_OWNER");
        _;
    }
    modifier validAddress(address _address) {
        require(_address != address(0), "INVALID_ADDRESS");
        _;
    }

    modifier txExists(uint256 _txIndex) {
        require(_txIndex < transactions.length, "TX_NOT_EXIST");
        _;
    }

    modifier notExecuted(uint256 _txIndex) {
        require(!transactions[_txIndex].executed, "ALREADY_EXCEUTED");
        _;
    }

    modifier notApproved(uint256 _txIndex) {
        require(!approved[_txIndex][msg.sender], "ALREADY_CONFIRMED");
        _;
    }

    constructor(address _owner) validAddress(_owner) {
        //addOwner(_owners);
        owner = _owner;

        isOwner[_owner] = true;
    }

    function addOwner(address _owner, bool status)
        public
        onlyOwner
        validAddress(_owner)
    {
        require(!isOwner[_owner], "ALREADY_EXIST");
        owners.push(_owner);
        isOwner[_owner] = true;

        emit AddOwner(msg.sender, _owner);
    }

    receive() external payable {
        emit Deposit(msg.sender, msg.value, address(this).balance);
    }

    function removeOwner(address _owner, bool status) public onlyOwner {
        require(isOwner[_owner], "ADDRESS_NOT_OWNER");
        isOwner[_owner] = false;

        emit RemoveOwner(msg.sender, _owner);
    }

    function numOfConfirmation(uint256 _required) public {
        require(
            _required > 0 && _required <= owners.length,
            "INVALID_CONFIRMATIONS_REQUIRED"
        );
        required = _required;

        emit ConfirmationRequired(_required);
    }

    function submitTx(
        address _to,
        uint256 _value,
        bytes calldata _data
    ) public onlyOwner {
        transactions.push(
            Transaction({to: _to, value: _value, data: _data, executed: false})
        );
        //for loop to send transaction to all the owners.

        emit Submit(transactions.length - 1);
    }

    function approve(uint256 _txIndex)
        external
        onlyOwner
        txExists(_txIndex)
        notExecuted(_txIndex)
        notApproved(_txIndex)
    {
        approved[_txIndex][msg.sender] = true;
        emit Approve(msg.sender, _txIndex);
    }

    function _getApprovalCount(uint256 _txIndex)
        private
        view
        returns (uint256 count)
    {
        for (uint256 i; i < owners.length; i++) {
            if (approved[_txIndex][owners[i]]) {
                count += 1;
            }
        }
    }

    function execute(uint256 _txIndex)
        external
        onlyOwner
        txExists(_txIndex)
        notExecuted(_txIndex)
    {
        require(_getApprovalCount(_txIndex) >= required, "NOT_ENOUGH_APPROVAL");

        Transaction storage transaction = transactions[_txIndex];

        transaction.executed = true;

        (bool success, ) = transaction.to.call{value: transaction.value}(
            transaction.data
        );
        require(success, "TX_FAILED");

        emit Execute(_txIndex);
    }

    function revoke(uint256 _txIndex)
        external
        onlyOwner
        txExists(_txIndex)
        notExecuted(_txIndex)
    {
        require(approved[_txIndex][msg.sender], "TX_NOT_CONFIRMED");

        approved[_txIndex][msg.sender] = false;

        emit Revoke(msg.sender, _txIndex);
    }

    function getOwners() public view returns (address[] memory) {
        return owners;
    }

    function getTransactionCount() public view returns (uint256) {
        return transactions.length;
    }
}
