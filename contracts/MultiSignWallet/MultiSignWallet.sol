// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "hardhat/console.sol";

contract MultiSignWallet {
    event AddOwner(address indexed owner, address indexed NewOwner);
    event RemoveOwner(address indexed owner, address indexed removedOwner);
    event Deposit(address indexed sender, uint256 amount, uint256 balance);
    event Submit(uint256 indexed txIndex);
    event Approve(address indexed owner, uint256 indexed txIndex);
    event Revoke(address indexed owner, uint256 indexed txIndex);
    event Execute(address indexed owner, uint256 indexed txIndex);

    address public owner;
    address[] public owners;
    mapping(address => bool) public isOwner;
    uint256 public required;

    // mapping from tx index => owner => bool
    mapping(uint256 => mapping(address => bool)) public approved;
    mapping(uint256 => Transaction) public transactions;
    //Transaction[] public transactions;

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

    modifier txExists(uint256 _txIndex) {
        require(transactions[_txIndex]._to != 0, "TX_NOT_EXIST");
        _;
    }

    modifier txApproved(uint256 _txIndex, address owner) {
        require(approved[_txIndex][owner])
    }

    modifier notExecuted(uint256 _txIndex) {
        require(!transactions[_txIndex].executed, "ALREADY_EXCEUTED");
        _;
    }

    modifier notApproved(uint256 _txIndex) {
        require(!approved[_txIndex][msg.sender], "ALREADY_CONFIRMED");
        _;
    }

    constructor(address[] memory _owners, uint256 _required) {
        addOwner(_owners, _required);
    }

    function addOwner(address[] memory _owners, uint256 _required) public {
        require(_owners.length > 0, "NO_OWNER");
        require(
            _required > 0 && _required <= _owners.length,
            "INVALID_CONFIRMATIONS_REQUIRED"
        );

        for (uint256 i = 0; i < _owners.length; i++) {
            owner = _owners[i];

            require(owner != address(0), "INVALID_OWNER");
            require(!isOwner[owner], "ALREADY_EXIST");

            isOwner[owner] = true;
            owners.push(owner);
        }

        required = _required;

        emit AddOwner(msg.sender, owner);
    }

    receive() external payable {
        emit Deposit(msg.sender, msg.value, address(this).balance);
    }

    function removeOwner(address _owner) public onlyOwner {
        require(isOwner[_owner], "ADDRESS_NOT_OWNER");
        isOwner[_owner] = false;

        emit RemoveOwner(msg.sender, _owner);
    }

    function submitTx(
        address _to,
        uint256 _value,
        bytes calldata _data
    ) public onlyOwner returns (uint256 _txIndex) {
        //console.log(txIndex);
        txIndex = addTransaction[_to,_value, _data];
        approve(_txIndex);
        emit Submit(_txIndex);
    }

    function addTransaction(
        address _to,
        uint256 _value,
        bytes _data
    ) internal returns (uint256 txIndex) {
        transactionId = transactionCount;
        transactions[txIndex] = Transaction({
            to: _to,
            value: _value,
            data: _data,
            executed: false
        });
    }

    function approve(uint256 _txIndex)
        external
        onlyOwner
        txExists(_txIndex)
        notExecuted(_txIndex)
        notApproved(_txIndex)
    {
        approved[_txIndex][msg.sender] = true;
        execute(uint256 _txIndex);
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
        txApproved(_txIndex, msg.sender)
        notExecuted(_txIndex)
    {
        require(_getApprovalCount(_txIndex) >= required, "NOT_ENOUGH_APPROVAL");

        Transaction storage transaction = transactions[_txIndex];
        console.log("Transaction Index: ", _txIndex);
        console.log("Transaction value: ", transaction.value);

        transaction.executed = true;
        (bool success, ) = transaction.to.call{value: transaction.value}(
            transaction.data
        );
        require(success, "TX_FAILED");

        emit Execute(msg.sender, _txIndex);
    }


    function revoke(uint256 _txIndex) external onlyOwner txExists(_txIndex) notExecuted(_txIndex) {
        require(approved[_txIndex][msg.sender], "TX_NOT_CONFIRMED");

        approved[_txIndex][msg.sender] = false;

        emit Revoke(msg.sender, _txIndex);
    }

    function getOwners() public view returns (address[] memory) {
        return owners;
    }

    /*function getTransactionCount() public view returns (uint256) {
        return transactions.length;
    }*/

    function getTransaction(uint256 _txIndex)
        public
        view
        returns (
            address to,
            uint256 value,
            bytes memory data,
            bool executed
        )
    {
        Transaction storage transaction = transactions[_txIndex];

        return (
            transaction.to,
            transaction.value,
            transaction.data,
            transaction.executed
        );
    }
}
