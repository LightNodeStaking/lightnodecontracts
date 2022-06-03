// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface INodeOperatorsRegistry {

    /*
        * @notice Add node operator named `name` with reward address `rewardAddress` and staking limit = 0 validators
        * @param _name Human-readable name
        * @param _rewardAddress Ethereum 1 address which receives stETH rewards for this operator
        * @return a unique key of the added operator
    */
    function addNodeOperator(string memory _name, address _rewardAddress) external returns (uint256 id);

    /**
        * @notice `_active ? 'Enable' : 'Disable'` the node operator #`_id`
    */
    function setNodeOperatorActive(uint256 _id, bool _active) external;

    /**
      * @notice Change human-readable name of the node operator #`_id` to `_name`
      */
    function setNodeOperatorName(uint256 _id, string memory _name) external;

    /**
      * @notice Change reward address of the node operator #`_id` to `_rewardAddress`
      */
    function setNodeOperatorRewardAddress(uint256 _id, address _rewardAddress) external;

    /**
        * @notice Set the maximum number of validators to stake for the node operator #`_id` to `_stakingLimit`
    */
    function setNodeOperatorStakingLimit(uint256 _id, uint64 _stakingLimit) external;

    /**
        * @notice Report `_stoppedIncrement` more stopped validators of the node operator #`_id`
    */
    function reportStoppedValidators(uint256 _id, uint64 _stoppedIncrement) external;

    /**
        * @notice Remove unused signing keys
        * @dev Function is used by the pool
    */
    function trimUnusedKeys() external;

    /**
        * @notice Returns total number of node operators
    */
    function getNodeOperatorsCount() external view returns (uint256);

    /**
        * @notice Returns the n-th node operator
        * @param _id Node Operator id
        * @param _fullInfo If true, name will be returned as well
     */
    function getNodeOperator(uint256 _id, bool _fullInfo) external view returns (
        bool active,
        string memory name,
        address rewardAddress,
        uint64 stakingLimit,
        uint64 stoppedValidators,
        uint64 totalSigningKeys,
        uint64 usedSigningKeys);

    /**
        * @notice Returns the rewards distribution proportional to the effective stake for each node operator.
        * @param _totalRewardShares Total amount of reward shares to distribute.
    */
    function getRewardsDistribution(uint256 _totalRewardShares) external view returns (
        address[] memory recipients,
        uint256[] memory shares
    );

    event NodeOperatorAdded(uint256 id, string name, address rewardAddress, uint64 stakingLimit);
    event NodeOperatorActiveSet(uint256 indexed id, bool active);
    event NodeOperatorNameSet(uint256 indexed id, string name);
    event NodeOperatorRewardAddressSet(uint256 indexed id, address rewardAddress);
    event NodeOperatorStakingLimitSet(uint256 indexed id, uint64 stakingLimit);
    event NodeOperatorTotalStoppedValidatorsReported(uint256 indexed id, uint64 totalStopped);
    event NodeOperatorTotalKeysTrimmed(uint256 indexed id, uint64 totalKeysTrimmed);

    /**
        * @notice Add `_quantity` validator signing keys to the keys of the node operator #`_operator_id`. Concatenated keys are: `_pubkeys`
        * @dev Along with each key the DAO has to provide a signatures for the
        *      (pubkey, withdrawal_credentials, 32000000000) message.
        *      Given that information, the contract'll be able to call
        *      deposit_contract.deposit on-chain.
        * @param _operator_id Node Operator id
        * @param _quantity Number of signing keys provided
        * @param _pubkeys Several concatenated validator signing keys
        * @param _signatures Several concatenated signatures for (pubkey, withdrawal_credentials, 32000000000) messages
      */
    function addSigningKeys(uint256 _operator_id, uint256 _quantity, bytes memory _pubkeys, bytes memory _signatures) external;

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
    function addSigningKeysOperatorBH(uint256 _operator_id, uint256 _quantity, bytes memory _pubkeys, bytes memory _signatures) external;

    /**
        * @notice Removes a validator signing key #`_index` from the keys of the node operator #`_operator_id`
        * @param _operator_id Node Operator id
        * @param _index Index of the key, starting with 0
    */
    function removeSigningKey(uint256 _operator_id, uint256 _index) external;

    /**
        * @notice Removes a validator signing key #`_index` of operator #`_id` from the set of usable keys. Executed on behalf of Node Operator.
        * @param _operator_id Node Operator id
        * @param _index Index of the key, starting with 0
    */
    function removeSigningKeyOperatorBH(uint256 _operator_id, uint256 _index) external;

    /**
        * @notice Returns total number of signing keys of the node operator #`_operator_id`
    */
    function getTotalSigningKeyCount(uint256 _operator_id) external view returns (uint256);

    /**
        * @notice Returns number of usable signing keys of the node operator #`_operator_id`
    */
    function getUnusedSigningKeyCount(uint256 _operator_id) external view returns (uint256);

    /**
        * @notice Returns n-th signing key of the node operator #`_operator_id`
        * @param _operator_id Node Operator id
        * @param _index Index of the key, starting with 0
        * @return key Key
        * @return depositSignature Signature needed for a deposit_contract.deposit call
        * @return used Flag indication if the key was used in the staking
    */
    function getSigningKey(uint256 _operator_id, uint256 _index) external view returns
            (bytes memory key, bytes memory depositSignature, bool used);

    /**
        * @notice Returns a monotonically increasing counter that gets incremented when any of the following happens:
        *   1. a node operator's key(s) is added;
        *   2. a node operator's key(s) is removed;
        *   3. a node operator's approved keys limit is changed.
        *   4. a node operator was activated/deactivated. Activation or deactivation of node operator
        *      might lead to usage of unvalidated keys in the assignNextSigningKeys method.
    */
    function getKeysOpIndex() external view returns (uint256);

    event SigningKeyAdded(uint256 indexed operatorId, bytes pubkey);
    event SigningKeyRemoved(uint256 indexed operatorId, bytes pubkey);
    event KeysOpIndexSet(uint256 keysOpIndex);

}