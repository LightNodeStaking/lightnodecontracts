// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../interfaces/INodeOperatorsRegistry.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "../lib/UnStructuredData.sol";
import "../lib/Memoryutils.sol";
import "solidity-bytes-utils/contracts/BytesLib.sol";

contract NodeOperatorsRegistry is INodeOperatorsRegistry, AccessControl{
    using SafeMath for uint256;
    using UnStructuredData for bytes32;

    //Account control List
    bytes32 constant public MANAGE_SIGNING_KEYS = keccak256("MANAGE_SIGNING_KEYS");
    bytes32 constant public ADD_NODE_OPERATOR_ROLE = keccak256("ADD_NODE_OPERATOR_ROLE");
    bytes32 constant public SET_NODE_OPERATOR_ACTIVE_ROLE = keccak256("SET_NODE_OPERATOR_ACTIVE_ROLE");
    bytes32 constant public SET_NODE_OPERATOR_NAME_ROLE = keccak256("SET_NODE_OPERATOR_NAME_ROLE");
    bytes32 constant public SET_NODE_OPERATOR_ADDRESS_ROLE = keccak256("SET_NODE_OPERATOR_ADDRESS_ROLE");
    bytes32 constant public SET_NODE_OPERATOR_LIMIT_ROLE = keccak256("SET_NODE_OPERATOR_LIMIT_ROLE");
    bytes32 constant public REPORT_STOPPED_VALIDATORS_ROLE = keccak256("REPORT_STOPPED_VALIDATORS_ROLE");

    uint256 constant public PUBKEY_LENGTH = 48;
    uint256 constant public SIGNATURE_LENGTH = 96;

    uint256 internal constant UINT64_MAX = uint256(uint64(-1));
    bytes32 internal constant SIGNING_KEYS_MAPPING_NAME = keccak256("lightNode.NodeOperatorsRegistry.signingKeysMappingName");


    // @dev Node Operator parameters and internal state
    struct NodeOperator {
        bool active;    // a flag indicating if the operator can participate in further staking and reward distribution
        address rewardAddress;  // Ethereum 1 address which receives steth rewards for this operator
        string name;    // human-readable name
        uint64 stakingLimit;    // the maximum number of validators to stake for this operator
        uint64 stoppedValidators;   // number of signing keys which stopped validation (e.g. were slashed)

        uint64 totalSigningKeys;    // total amount of signing keys of this operator
        uint64 usedSigningKeys;     // number of signing keys of this operator which were used in deposits to the Ethereum 2
    }

    // @dev Memory cache entry used in the assignNextKeys function
    struct DepositLookupCacheEntry {
        // Makes no sense to pack types since reading memory is as fast as any op
        uint256 id;
        uint256 stakingLimit;
        uint256 stoppedValidators;
        uint256 totalSigningKeys;
        uint256 usedSigningKeys;
        uint256 initialUsedSigningKeys;
    }
    // @dev Mapping of all node operators. Mapping is used to be able to extend the struct.
    mapping(uint256 => NodeOperator) internal operators;

    // @dev Total number of operators
    bytes32 internal constant TOTAL_OPERATORS_COUNT_POSITION = keccak256("lightNode.NodeOperatorsRegistry.totalOperatorsCount");

    // @dev Cached number of active operators
    bytes32 internal constant ACTIVE_OPERATORS_COUNT_POSITION = keccak256("lightNode.NodeOperatorsRegistry.activeOperatorsCount");

    /// @dev link to the Lido contract
    bytes32 internal constant LIGHT_NODE_POSITION = keccak256("lightNode.NodeOperatorsRegistry.lightNode");

    /// @dev link to the index of operations with keys
    bytes32 internal constant KEYS_OP_INDEX_POSITION = keccak256("lightNode.NodeOperatorsRegistry.keysOpIndex");

    modifier onlyLightNode() {
        require(msg.sender == LIGHT_NODE_POSITION.getStorageAddress(), "APP_AUTH_FAILED");
        _;
    }

    modifier validAddress(address _a) {
        require(_a != address(0), "INVALID_ADDRESS");
        _;
    }

    modifier operatorExist( uint256 _id){
        require(_id < getNodeOperatorsCount(), "NODE_OPERATOT_DOESN'T EXTIST");
        _;
    }

    function initialize(address _slEth) public {
        TOTAL_OPERATORS_COUNT_POSITION.setStorageUint256(0);
        ACTIVE_OPERATORS_COUNT_POSITION.setStorageUint256(0);
        KEYS_OP_INDEX_POSITION.setStorageUint256(0);
        LIGHT_NODE_POSITION.setStorageAddress(_slEth);
    }

    function addNodeOperator(string memory _name, address _rewardAdd) external onlyRole(ADD_NODE_OPERATOR_ROLE) validAddress(_rewardAdd) returns(uint256 id){
        id = getNodeOperatorsCount();
        TOTAL_OPERATORS_COUNT_POSITION.setStorageUint256(id + 1);

        NodeOperator storage operator = operators[id];
        //update active operator count
        uint256 activeOperator = getActiveNodeOperatorsCount();
        ACTIVE_OPERATORS_COUNT_POSITION.setStorageUint256(activeOperator+1);

        operator.active = true;
        operator.name = _name;
        operator.rewardAddress = _rewardAdd;
        operator.stakingLimit = 0;

        emit NodeOperatorAdded(id, _name, _rewardAdd, 0);

        return id;

    }

    function setNodeOpeartorActive(uint _id, bool _bool) external onlyRole(SET_NODE_OPERATOR_ACTIVE_ROLE) operatorExist(_id){
        _increaseKeysOpIndex();



    }

    

    function _increaseKeysOpIndex() internal {
        uint256 keysOpIndex = getKeysOpIndex();
        KEYS_OP_INDEX_POSITION.setStorageUint256(keysOpIndex + 1);
        emit KeysOpIndexSet(keysOpIndex + 1);
    }

    //view functions
    
    /**
    * @notice Returns a monotonically increasing counter that gets incremented when any of the following happens:
    *   1. a node operator's key(s) is added;
    *   2. a node operator's key(s) is removed;
    *   3. a node operator's approved keys limit is changed.
    *   4. a node operator was activated/deactivated. Activation or deactivation of node operator
    *      might lead to usage of unvalidated keys in the assignNextSigningKeys method.
    */
    function getKeysOpIndex() public view returns (uint256) {
        return KEYS_OP_INDEX_POSITION.getStorageUint256();
    }

   /**
      * @notice Returns total number of node operators
      */
    function getNodeOperatorsCount() public view returns (uint256) {
        return TOTAL_OPERATORS_COUNT_POSITION.getStorageUint256();
    }

    function getActiveNodeOperatorsCount() public view returns(uint256){
        return ACTIVE_OPERATORS_COUNT_POSITION.getStorageUint256();

    }
}

