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
    event ExecuteFailed(uint256 indexed txIndex);

    address public owner;
    address[] public owners;
    mapping(address => bool) public isOwner;
    uint256 public required;
    uint256 public txCount;

    // mapping from tx index => owner => bool
    mapping(uint256 => mapping(address => bool)) public approved;
    mapping(uint256 => Transaction) public transactions;
    mapping(uint256 => bool) public isExecuted;

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
        require(transactions[_txIndex].to != address(0), "TX_NOT_EXIST");
        _;
    }

    modifier txApproved(uint256 _txIndex, address _owner) {
        require(approved[_txIndex][_owner]);
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
        console.log("Submit Tx: ", _txIndex); // This to be removed at the final stage
        console.log("Submit Tx: ", msg.sender); // This to be removed at the final stage
        _txIndex = addTransaction(_to, _value, _data);
        emit Submit(_txIndex);
        approveTx(_txIndex);
    }

    function approveTx(uint256 _txIndex)
        public
        onlyOwner
        txExists(_txIndex)
        notExecuted(_txIndex)
        notApproved(_txIndex)
    {
        console.log("Approve Tx: ", _txIndex); // This to be removed at the final stage
        approved[_txIndex][msg.sender] = true;
        console.log("Approved by owner: ", msg.sender); // This to be removed at the final stage
        emit Approve(msg.sender, _txIndex);
        executeTx(_txIndex);
    }

    // function revokeTx(uint256 _txIndex)
    //     public
    //     onlyOwner
    //     txExists(_txIndex)
    //     notExecuted(_txIndex)
    // {
    //     //require(isSubmitted[_txIndex], "TX_NOT_SUBMITTED");
    //     require(approved[_txIndex][msg.sender], "TX_NOT_APPROVED");
    //     isRevoked[_txIndex] = true;
    //     approved[_txIndex][msg.sender] = false;
    //     console.log("revoke Tx: ", _txIndex); // This to be removed at the final stage
    //     emit Revoke(msg.sender, _txIndex);

    //     if (!isRevoked[_txIndex]) {
    //         executeTx(_txIndex);
    //     }
    // }

    function executeTx(uint256 _txIndex)
        public
        onlyOwner
        txExists(_txIndex)
        txApproved(_txIndex, msg.sender)
        notExecuted(_txIndex)
    {
        console.log("Execute Tx: ", _txIndex); // This to be removed at the final stage
        console.log("Required approval: ", required); // This to be removed at the final stage
        console.log("Approved: ", isTxApproved(_txIndex)); // This to be removed at the final stage

        Transaction storage transaction = transactions[_txIndex];

        if (isTxApproved(_txIndex)) {
            // transaction.executed = true;
            address add = transaction.to;
            console.log("Sending to: ", add);
            console.log("Value of ether: ", transaction.value);
            console.logBytes(transaction.data);

            console.log("Tx executed before: ", transaction.executed);

            (bool success, ) = transaction.to.call{value: transaction.value}(
                transaction.data
            );
            transaction.executed = true;
            isExecuted[_txIndex] = true;

            emit Execute(msg.sender, _txIndex);
        } else {
            emit ExecuteFailed(_txIndex);
            transaction.executed = false;
        }
        console.log("Tx Executed after: ", transaction.executed);
        console.log("Tx executed by owner: ", msg.sender);
    }

    function addTransaction(
        address _to,
        uint256 _value,
        bytes memory _data
    ) internal returns (uint256 _txIndex) {
        _txIndex = txCount;
        transactions[_txIndex] = Transaction({
            to: _to,
            value: _value,
            data: _data,
            executed: false
        });
        txCount += 1;
    }

    function isTxApproved(uint256 _txIndex) public view returns (bool) {
        uint256 count = 0;
        for (uint256 i = 0; i < owners.length; i++) {
            if (approved[_txIndex][owners[i]]) {
                count += 1;
                if (count == required) return true;
            }
        }
    }

    function getOwners() public view returns (address[] memory) {
        return owners;
    }

    function getTransactionCount(uint256 _txIndex)
        public
        view
        returns (uint256 count)
    {
        for (uint256 i = 0; i < owners.length; i++)
            require(isExecuted[_txIndex], "NOT_EXECUTED");
        count += 1;
    }

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
