// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../interfaces/INodeOperatorsRegistry.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "../lib/UnStructuredData.sol";
import "../lib/";

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
}

