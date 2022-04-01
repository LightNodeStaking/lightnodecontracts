// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface INodeOperatords{

    function addNodeOperator(string memory _name, address _rewardAddress) external returns (uint256 id);

    function setNodeOperatorActive(uint256 _id, bool _active) external;

    function setNodeOperatorName(uint256 _id, string memory _name) external;

    function setNodeOperatorRewardAddress(uint256 _id, address _rewardAddress) external;

    function setNodeOperatorStakingLimit(uint256 _id, uint64 _stakingLimit) external;

    function reportStoppedValidators(uint256 _id, uint64 _stoppedIncrement) external;

    function trimUnusedKeys() external;

    function getNodeOperatorsCount() external view returns (uint256);

    function getActiveNodeOperatorsCount() external view returns (uint256);

    function getNodeOperator(uint256 _id, bool _fullInfo) external view returns (
        bool active,
        string memory name,
        address rewardAddress, 
        uint64 stakingLimit,
        uint64 stoppedValidators,
        uint64 totalSigningKeys,
        uint64 usedSigningKeys);

    function getRewardsDistribution(uint256 _totalRewardShares) external view returns (
        address[] memory recipients,
        uint256[] memory shares
    );

    function assignNextSigningKeys(uint256 _numKeys) external returns (bytes memory pubkeys, bytes memory signatures);
    
    function addSigningKeys(uint256 _operator_id, uint256 _quantity, bytes memory _pubkeys, bytes memory _signatures) external;

    function addSigningKeysOperatorBH(uint256 _operator_id, uint256 _quantity, bytes memory _pubkeys, bytes memory _signatures) external;

    function removeSigningKey(uint256 _operator_id, uint256 _index) external;

    function removeSigningKeyOperatorBH(uint256 _operator_id, uint256 _index) external;

    function removeSigningKeys(uint256 _operator_id, uint256 _index, uint256 _amount) external;

    function removeSigningKeysOperatorBH(uint256 _operator_id, uint256 _index, uint256 _amount) external;

    function getTotalSigningKeyCount(uint256 _operator_id) external view returns (uint256);

    function getUnusedSigningKeyCount(uint256 _operator_id) external view returns (uint256);

    function getSigningKey(uint256 _operator_id, uint256 _index) external view returns(bytes memory key, bytes memory depositSignature, bool used);

    function getKeysOpIndex() external view returns (uint256);

} 