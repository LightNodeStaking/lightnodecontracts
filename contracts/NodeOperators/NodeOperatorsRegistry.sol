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

    modifier operatorExists( uint256 _id){
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

    function setNodeOpeartorActive(uint _id, bool _active) external onlyRole(SET_NODE_OPERATOR_ACTIVE_ROLE) operatorExists(_id){
        _increaseKeysOpIndex();

        if(operators[_id].active != _active){
            uint256 activeOperator = getActiveNodeOperatorsCount();
            if(_active){
                ACTIVE_OPERATORS_COUNT_POSITION.setStorageUint256(activeOperator + 1);
            } else{
                ACTIVE_OPERATORS_COUNT_POSITION.setStorageUint256(activeOperator - 1);
            }
        }

        operators[_id].active = _active;
        emit NodeOperatorActiveSet(_id, _active);
    }

    /**
    * @notice Change human-readable name of the node operator #`_id` to `_name`
    */
    function setNodeOperatorName(uint256 _id, string memory _name) external
        onlyRole(SET_NODE_OPERATOR_NAME_ROLE)
        operatorExists(_id)
    {
        operators[_id].name = _name;
        emit NodeOperatorNameSet(_id, _name);
    }

    /**
    * @notice Change reward address of the node operator #`_id` to `_rewardAddress`
    */
    function setNodeOperatorRewardAddress(uint256 _id, address _rewardAddress) external
        onlyRole(SET_NODE_OPERATOR_ADDRESS_ROLE)
        operatorExists(_id)
        validAddress(_rewardAddress)
    {
        operators[_id].rewardAddress = _rewardAddress;
        emit NodeOperatorRewardAddressSet(_id, _rewardAddress);
    }

    /**
    * @notice Report `_stoppedIncrement` more stopped validators of the node operator #`_id`
    */
    function reportStoppedValidators(uint256 _id, uint64 _stoppedIncrement) external
        onlyRole(REPORT_STOPPED_VALIDATORS_ROLE)
        operatorExists(_id)
    {
        require(0 != _stoppedIncrement, "EMPTY_VALUE");
        operators[_id].stoppedValidators = operators[_id].stoppedValidators + (_stoppedIncrement);
        require(operators[_id].stoppedValidators <= operators[_id].usedSigningKeys, "STOPPED_MORE_THAN_LAUNCHED");

        emit NodeOperatorTotalStoppedValidatorsReported(_id, operators[_id].stoppedValidators);
    }


    /**
    * @notice Remove unused signing keys
    * @dev Function is used by the Lido contract
    */
    function trimUnusedKeys() external onlyLightNode {
        uint256 length = getNodeOperatorsCount();
        for (uint256 operatorId = 0; operatorId < length; ++operatorId) {
            uint64 totalSigningKeys = operators[operatorId].totalSigningKeys;
            uint64 usedSigningKeys = operators[operatorId].usedSigningKeys;
            if (totalSigningKeys != usedSigningKeys) { // write only if update is needed
                operators[operatorId].totalSigningKeys = usedSigningKeys;  // discard unused keys
                emit NodeOperatorTotalKeysTrimmed(operatorId, totalSigningKeys - usedSigningKeys);
            }
        }
    }

    /**
    * @notice Add `_quantity` validator signing keys of operator #`_id` to the set of usable keys. Concatenated keys are: `_pubkeys`. Can be done by the DAO in question by using the designated rewards address.
    * @dev Along with each key the DAO has to provide a signatures for the
    *      (pubkey, withdrawal_credentials, 32000000000) message.
    *      Given that information, the contract'll be able to call
    *      deposit_contract.deposit on-chain.
    * @param _operator_id Node Operator id
    * @param _quantity Number of signing keys provided
    * @param _pubkeys Several concatenated validator signing keys
    * @param _signatures Several concatenated signatures for (pubkey, withdrawal_credentials, 32000000000) messages
    */
    function addSigningKeys(uint256 _operator_id, uint256 _quantity, bytes _pubkeys, bytes _signatures) external
        onlyRole(MANAGE_SIGNING_KEYS)
    {
        _addSigningKeys(_operator_id, _quantity, _pubkeys, _signatures);
    }

    /**
    * @notice Add `_quantity` validator signing keys of operator #`_id` to the set of usable keys. Concatenated keys are: `_pubkeys`. Can be done by node operator in question by using the designated rewards address.
    * @dev Along with each key the DAO has to provide a signatures for the
    *      (pubkey, withdrawal_credentials, 32000000000) message.
    *      Given that information, the contract'll be able to call
    *      deposit_contract.deposit on-chain.
    * @param _operator_id Node Operator id
    * @param _quantity Number of signing keys provided
    * @param _pubkeys Several concatenated validator signing keys
    * @param _signatures Several concatenated signatures for (pubkey, withdrawal_credentials, 32000000000) messages
    */
    function addSigningKeysOperatorBH(
        uint256 _operator_id,
        uint256 _quantity,
        bytes _pubkeys,
        bytes _signatures
    )
        external
    {
        require(msg.sender == operators[_operator_id].rewardAddress, "APP_AUTH_FAILED");
        _addSigningKeys(_operator_id, _quantity, _pubkeys, _signatures);
    }

    /**
    * @notice Removes a validator signing key #`_index` of operator #`_id` from the set of usable keys. Executed on behalf of DAO.
    * @param _operator_id Node Operator id
    * @param _index Index of the key, starting with 0
    */
    function removeSigningKey(uint256 _operator_id, uint256 _index)
        external
        onlyRole(MANAGE_SIGNING_KEYS)
    {
        _removeSigningKey(_operator_id, _index);
    }

    /**
    * @notice Removes an #`_amount` of validator signing keys starting from #`_index` of operator #`_id` usable keys. Executed on behalf of DAO.
    * @param _operator_id Node Operator id
    * @param _index Index of the key, starting with 0
    * @param _amount Number of keys to remove
    */
    function removeSigningKeys(uint256 _operator_id, uint256 _index, uint256 _amount)
        external
        onlyRole(MANAGE_SIGNING_KEYS)
    {
        // removing from the last index to the highest one, so we won't get outside the array
        for (uint256 i = _index + _amount; i > _index ; --i) {
            _removeSigningKey(_operator_id, i - 1);
        }
    }

    /**
    * @notice Removes a validator signing key #`_index` of operator #`_id` from the set of usable keys. Executed on behalf of Node Operator.
    * @param _operator_id Node Operator id
    * @param _index Index of the key, starting with 0
    */
    function removeSigningKeyOperatorBH(uint256 _operator_id, uint256 _index) external {
        require(msg.sender == operators[_operator_id].rewardAddress, "APP_AUTH_FAILED");
        _removeSigningKey(_operator_id, _index);
    }

    /**
    * @notice Removes an #`_amount` of validator signing keys starting from #`_index` of operator #`_id` usable keys. Executed on behalf of Node Operator.
    * @param _operator_id Node Operator id
    * @param _index Index of the key, starting with 0
    * @param _amount Number of keys to remove
    */
    function removeSigningKeysOperatorBH(uint256 _operator_id, uint256 _index, uint256 _amount) external {
        require(msg.sender == operators[_operator_id].rewardAddress, "APP_AUTH_FAILED");
        // removing from the last index to the highest one, so we won't get outside the array
        for (uint256 i = _index + _amount; i > _index ; --i) {
            _removeSigningKey(_operator_id, i - 1);
        }
    }

    /**
     * @notice Selects and returns at most `_numKeys` signing keys (as well as the corresponding
     *         signatures) from the set of active keys and marks the selected keys as used.
     *         May only be called by the Lido contract.
     *
     * @param _numKeys The number of keys to select. The actual number of selected keys may be less
     *        due to the lack of active keys.
     */
    function assignNextSigningKeys(uint256 _numKeys) external onlyLightNode returns (bytes memory pubkeys, bytes memory signatures) {
        // Memory is very cheap, although you don't want to grow it too much
        DepositLookupCacheEntry[] memory cache = _loadOperatorCache();
        if (0 == cache.length)
            return (new bytes(0), new bytes(0));

        uint256 numAssignedKeys = 0;
        DepositLookupCacheEntry memory entry;

        while (numAssignedKeys < _numKeys) {
            // Finding the best suitable operator
            uint256 bestOperatorIdx = cache.length;   // 'not found' flag
            uint256 smallestStake;
            // The loop is ligthweight comparing to an ether transfer and .deposit invocation
            for (uint256 idx = 0; idx < cache.length; ++idx) {
                entry = cache[idx];

                assert(entry.usedSigningKeys <= entry.totalSigningKeys);
                if (entry.usedSigningKeys == entry.totalSigningKeys)
                    continue;

                uint256 stake = entry.usedSigningKeys.sub(entry.stoppedValidators);
                if (stake + 1 > entry.stakingLimit)
                    continue;

                if (bestOperatorIdx == cache.length || stake < smallestStake) {
                    bestOperatorIdx = idx;
                    smallestStake = stake;
                }
            }

            if (bestOperatorIdx == cache.length)  // not found
                break;

            entry = cache[bestOperatorIdx];
            assert(entry.usedSigningKeys < UINT64_MAX);

            ++entry.usedSigningKeys;
            ++numAssignedKeys;
        }

        if (numAssignedKeys == 0) {
            return (new bytes(0), new bytes(0));
        }

        if (numAssignedKeys > 1) {
            // we can allocate without zeroing out since we're going to rewrite the whole array
            pubkeys = MemUtils.unsafeAllocateBytes(numAssignedKeys * PUBKEY_LENGTH);
            signatures = MemUtils.unsafeAllocateBytes(numAssignedKeys * SIGNATURE_LENGTH);
        }

        uint256 numLoadedKeys = 0;

        for (uint256 i = 0; i < cache.length; ++i) {
            entry = cache[i];

            if (entry.usedSigningKeys == entry.initialUsedSigningKeys) {
                continue;
            }

            operators[entry.id].usedSigningKeys = uint64(entry.usedSigningKeys);

            for (uint256 keyIndex = entry.initialUsedSigningKeys; keyIndex < entry.usedSigningKeys; ++keyIndex) {
                (bytes memory pubkey, bytes memory signature) = _loadSigningKey(entry.id, keyIndex);
                if (numAssignedKeys == 1) {
                    return (pubkey, signature);
                } else {
                    MemUtils.copyBytes(pubkey, pubkeys, numLoadedKeys * PUBKEY_LENGTH);
                    MemUtils.copyBytes(signature, signatures, numLoadedKeys * SIGNATURE_LENGTH);
                    ++numLoadedKeys;
                }
            }

            if (numLoadedKeys == numAssignedKeys) {
                break;
            }
        }

        assert(numLoadedKeys == numAssignedKeys);
        return (pubkeys, signatures);
    }






    /**
    * @notice Set the maximum number of validators to stake for the node operator #`_id` to `_stakingLimit`
    */
    function setNodeOperatorStakingLimit(uint256 _id, uint64 _stakingLimit) external
        onlyRole(SET_NODE_OPERATOR_LIMIT_ROLE)
        operatorExists(_id)
    {
        _increaseKeysOpIndex();
        operators[_id].stakingLimit = _stakingLimit;
        emit NodeOperatorStakingLimitSet(_id, _stakingLimit);
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

