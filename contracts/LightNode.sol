// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "solidity-bytes-utils/contracts/BytesLib.sol";

import "./interfaces/ILightNode.sol";
import "./interfaces/IDepositContract.sol";
import "./interfaces/INodeOperatorsRegistry.sol";
import "./token/SlETH.sol";
import "./lib/UnstructuredStorage.sol";

contract LightNode is ILightNode, SlETH, AccessControl {
    using UnstructuredStorage for bytes32;

    bytes32 constant public PAUSE_ROLE = keccak256("PAUSE_ROLE");
    bytes32 constant public RESUME_ROLE = keccak256("RESUME_ROLE");
    bytes32 constant public STAKING_PAUSE_ROLE = keccak256("STAKING_PAUSE_ROLE");
    bytes32 constant public STAKING_CONTROL_ROLE = keccak256("STAKING_CONTROL_ROLE");
    bytes32 constant public MANAGE_FEE = keccak256("MANAGE_FEE");
    bytes32 constant public MANAGE_WITHDRAWAL_KEY = keccak256("MANAGE_WITHDRAWAL_KEY");
    bytes32 constant public MANAGE_PROTOCOL_CONTRACTS_ROLE = keccak256("MANAGE_PROTOCOL_CONTRACTS_ROLE");
    bytes32 constant public BURN_ROLE = keccak256("BURN_ROLE");
    bytes32 constant public DEPOSIT_ROLE = keccak256("DEPOSIT_ROLE");
    bytes32 constant public SET_EL_REWARDS_VAULT_ROLE = keccak256("SET_EL_REWARDS_VAULT_ROLE");
    bytes32 constant public SET_EL_REWARDS_WITHDRAWAL_LIMIT_ROLE = keccak256(
        "SET_EL_REWARDS_WITHDRAWAL_LIMIT_ROLE"
    );

    uint256 constant public PUBKEY_LENGTH = 48;
    uint256 constant public WITHDRAWAL_CREDENTIALS_LENGTH = 32;
    uint256 constant public SIGNATURE_LENGTH = 96;

    uint256 constant public DEPOSIT_SIZE = 32 ether;

    uint256 internal constant DEPOSIT_AMOUNT_UNIT = 1000000000 wei;
    uint256 internal constant TOTAL_BASIS_POINTS = 10000;

    /// @dev default value for maximum number of Ethereum 2.0 validators 
    /// registered in a single depositBufferedEther call
    uint256 internal constant DEFAULT_MAX_DEPOSITS_PER_CALL = 150;

    bytes32 internal constant FEE_POSITION = keccak256("lightnode.Lightnode.fee");
    bytes32 internal constant TREASURY_FEE_POSITION = keccak256("lightnode.Lightnode.treasuryFee");
    bytes32 internal constant INSURANCE_FEE_POSITION = keccak256("lightnode.Lightnode.insuranceFee");
    bytes32 internal constant NODE_OPERATORS_FEE_POSITION = keccak256("lightnode.Lightnode.nodeOperatorsFee");

    bytes32 internal constant DEPOSIT_CONTRACT_POSITION = keccak256("lightnode.Lightnode.depositContract");
    bytes32 internal constant ORACLE_POSITION = keccak256("lightnode.Lightnode.oracle");
    bytes32 internal constant NODE_OPERATORS_REGISTRY_POSITION = keccak256("lightnode.Lightnode.nodeOperatorsRegistry");
    bytes32 internal constant TREASURY_POSITION = keccak256("lightnode.Lightnode.treasury");
    bytes32 internal constant INSURANCE_FUND_POSITION = keccak256("lightnode.Lightnode.insuranceFund");
    bytes32 internal constant EL_REWARDS_VAULT_POSITION = keccak256("lightnode.Lightnode.executionLayerRewardsVault");

    /// @dev storage slot position of the staking rate limit structure
    bytes32 internal constant STAKING_STATE_POSITION = keccak256("lightnode.Lightnode.stakeLimit");
    /// @dev amount of Ether (on the current Ethereum side) buffered on this smart contract balance
    bytes32 internal constant BUFFERED_ETHER_POSITION = keccak256("lightnode.Lightnode.bufferedEther");
    /// @dev number of deposited validators (incrementing counter of deposit operations).
    bytes32 internal constant DEPOSITED_VALIDATORS_POSITION = keccak256("lightnode.Lightnode.depositedValidators");
    /// @dev total amount of Beacon-side Ether (sum of all the balances of LightNode validators)
    bytes32 internal constant BEACON_BALANCE_POSITION = keccak256("lightnode.Lightnode.beaconBalance");
    /// @dev number of LightNode's validators available in the Beacon state
    bytes32 internal constant BEACON_VALIDATORS_POSITION = keccak256("lightnode.Lightnode.beaconValidators");

    /// @dev percent in basis points of total pooled ether allowed to withdraw from ExecutionLayerRewardsVault per Oracle report
    bytes32 internal constant EL_REWARDS_WITHDRAWAL_LIMIT_POSITION = keccak256("lightnode.Lightnode.ELRewardsWithdrawalLimit");

    /// @dev Just a counter of total amount of execution layer rewards received by LightNode contract
    /// Not used in the logic
    bytes32 internal constant TOTAL_EL_REWARDS_COLLECTED_POSITION = keccak256("lightnode.Lightnode.totalELRewardsCollected");

    /// @dev Credentials which allows the DAO to withdraw Ether on the 2.0 side
    bytes32 internal constant WITHDRAWAL_CREDENTIALS_POSITION = keccak256("lightnode.Lightnode.withdrawalCredentials");

    constructor(
        IDepositContract _depositContract,
        address _oracle,
        INodeOperatorsRegistry _operators,
        address _treasury,
        address _insuranceFund
    ) {
        NODE_OPERATORS_REGISTRY_POSITION.setStorageAddress(address(_operators));
        DEPOSIT_CONTRACT_POSITION.setStorageAddress(address(_depositContract));

        _setProtocolContracts(_oracle, _treasury, _insuranceFund);
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    /**
    * @notice Send funds to the pool
    * @dev Users are able to submit their funds by transacting to the fallback function.
    * Unlike vanilla Eth2.0 Deposit contract, accepting only 32-Ether transactions, LightNode
    * accepts payments of any size. Submitted Ethers are stored in Buffer until someone calls
    * depositBufferedEther() and pushes them to the ETH2 Deposit contract.
    */
    fallback() external payable {
        // protection against accidental submissions by calling non-existent function
        require(msg.data.length == 0, "NON_EMPTY_DATA");
        _submit(address(0)); // why _submit(0)
    }

    /**
    * @notice Send funds to the pool with optional _referral parameter
    * @dev This function is alternative way to submit funds. Supports optional referral address.
    * @return Amount of SlETH shares generated
    */
    function submit(address _referral) external payable returns (uint256) {
        return _submit(_referral);
    }

    /**
    * @notice Set LightNode protocol contracts (oracle, treasury, insurance fund).
    *
    * @dev Oracle contract specified here is allowed to make
    * periodical updates of beacon stats
    * by calling pushBeacon. Treasury contract specified here is used
    * to accumulate the protocol treasury fee. Insurance fund contract
    * specified here is used to accumulate the protocol insurance fee.
    *
    * @param _oracle oracle contract
    * @param _treasury treasury contract
    * @param _insuranceFund insurance fund contract
    */
    function setProtocolContracts(
        address _oracle,
        address _treasury,
        address _insuranceFund
    ) external onlyRole(MANAGE_PROTOCOL_CONTRACTS_ROLE) {
        _setProtocolContracts(_oracle, _treasury, _insuranceFund);
    }

    /**
    * @notice A payable function for execution layer rewards. Can be called only by ExecutionLayerRewardsVault contract
    * @dev We need a dedicated function because funds received by the default payable function
    * are treated as a user deposit
    */
    function receiveELRewards() external payable {
        require(msg.sender == EL_REWARDS_VAULT_POSITION.getStorageAddress());

        TOTAL_EL_REWARDS_COLLECTED_POSITION.setStorageUint256(
            TOTAL_EL_REWARDS_COLLECTED_POSITION.getStorageUint256() + msg.value);

        emit ELRewardsReceived(msg.value);
    }

    /**
    * @notice Deposits buffered ethers to the official DepositContract.
    * @dev This function is separated from submit() to reduce the cost of sending funds.
    */
    function depositBufferedEther() external onlyRole(DEPOSIT_ROLE) {
        return _depositBufferedEther(DEFAULT_MAX_DEPOSITS_PER_CALL);
    }

    /**
    * @notice Deposits buffered ethers to the official DepositContract, making no more than `_maxDeposits` deposit calls.
    * @dev This function is separated from submit() to reduce the cost of sending funds.
    */
    function depositBufferedEther(uint256 _maxDeposits) external onlyRole(DEPOSIT_ROLE) {
        return _depositBufferedEther(_maxDeposits);
    }

    /**
    * @notice Pause pool routine operations
    */
    function pause() external onlyRole(PAUSE_ROLE) {
        _pause();
        // _pauseStaking();
    }

    /**
    * @notice Resume pool routine operations
    * @dev Staking should be resumed manually after this call using the desired limits
    */
    function resume() external onlyRole(RESUME_ROLE) {
        _unpause();
        // _resumeStaking();
    }

    /**
    * @notice Set fee rate to `_feeBasisPoints` basis points.
    * The fees are accrued when:
    * - oracles report staking results (beacon chain balance increase)
    * - validators gain execution layer rewards (priority fees and MEV)
    * @param _feeBasisPoints Fee rate, in basis points
    */
    function setFee(uint16 _feeBasisPoints) external onlyRole(MANAGE_FEE) {
        _setBPValue(FEE_POSITION, _feeBasisPoints);
        emit FeeSet(_feeBasisPoints);
    }

    /**
    * @notice Set fee distribution
    * @param _treasuryFeeBasisPoints basis points go to the treasury,
    * @param _insuranceFeeBasisPoints basis points go to the insurance fund,
    * @param _operatorsFeeBasisPoints basis points go to node operators.
    * @dev The sum has to be 10 000.
    */
    function setFeeDistribution(
        uint16 _treasuryFeeBasisPoints,
        uint16 _insuranceFeeBasisPoints,
        uint16 _operatorsFeeBasisPoints
    )
        external onlyRole(MANAGE_FEE)
    {
        require(
            TOTAL_BASIS_POINTS == uint256(_treasuryFeeBasisPoints)
            + uint256(_insuranceFeeBasisPoints)
            + uint256(_operatorsFeeBasisPoints),
            "FEES_DONT_ADD_UP"
        );

        _setBPValue(TREASURY_FEE_POSITION, _treasuryFeeBasisPoints);
        _setBPValue(INSURANCE_FEE_POSITION, _insuranceFeeBasisPoints);
        _setBPValue(NODE_OPERATORS_FEE_POSITION, _operatorsFeeBasisPoints);

        emit FeeDistributionSet(_treasuryFeeBasisPoints, _insuranceFeeBasisPoints, _operatorsFeeBasisPoints);
    }

    /**
    * @notice Gets node operators registry interface handle
    */
    function getOperators() public view returns (INodeOperatorsRegistry) {
        return INodeOperatorsRegistry(NODE_OPERATORS_REGISTRY_POSITION.getStorageAddress());
    }

    /**
    * @dev Write a value nominated in basis points
    */
    function _setBPValue(bytes32 _slot, uint16 _value) internal {
        require(_value <= TOTAL_BASIS_POINTS, "VALUE_OVER_100_PERCENT");
        _slot.setStorageUint256(uint256(_value));
    }

    /**
    * @dev Deposits buffered eth to the DepositContract and assigns chunked deposits to node operators
    */
    function _depositBufferedEther(uint256 _maxDeposits) internal whenNotPaused {
        uint256 buffered = _getBufferedEther();
        if (buffered >= DEPOSIT_SIZE) {
            uint256 unaccounted = _getUnaccountedEther();
            uint256 numDeposits = buffered / DEPOSIT_SIZE;
            _markAsUnbuffered(_ETH2Deposit(numDeposits < _maxDeposits ? numDeposits : _maxDeposits));
            assert(_getUnaccountedEther() == unaccounted);
        }
    }

    /**
    * @dev Performs deposits to the ETH 2.0 side
    * @param _numDeposits Number of deposits to perform
    * @return actually deposited Ether amount
    */
    function _ETH2Deposit(uint256 _numDeposits) internal returns (uint256) {
        (bytes memory pubkeys, bytes memory signatures) = getOperators().assignNextSigningKeys(_numDeposits);

        if (pubkeys.length == 0) {
            return 0;
        }

        require(pubkeys.length % PUBKEY_LENGTH == 0, "REGISTRY_INCONSISTENT_PUBKEYS_LEN");
        require(signatures.length % SIGNATURE_LENGTH == 0, "REGISTRY_INCONSISTENT_SIG_LEN");

        uint256 numKeys = pubkeys.length / PUBKEY_LENGTH;
        require(numKeys == signatures.length / SIGNATURE_LENGTH, "REGISTRY_INCONSISTENT_SIG_COUNT");

        for (uint256 i = 0; i < numKeys; ++i) {
            bytes memory pubkey = BytesLib.slice(pubkeys, i * PUBKEY_LENGTH, PUBKEY_LENGTH);
            bytes memory signature = BytesLib.slice(signatures, i * SIGNATURE_LENGTH, SIGNATURE_LENGTH);
            _stake(pubkey, signature);
        }

        DEPOSITED_VALIDATORS_POSITION.setStorageUint256(
            DEPOSITED_VALIDATORS_POSITION.getStorageUint256() + numKeys
        );

        return numKeys * DEPOSIT_SIZE;
    }

    /**
    * @dev Invokes a deposit call to the official Deposit contract
    * @param _pubkey Validator to stake for
    * @param _signature Signature of the deposit call
    */
    function _stake(bytes memory _pubkey, bytes memory _signature) internal {
        bytes32 withdrawalCredentials = getWithdrawalCredentials();
        require(withdrawalCredentials != 0, "EMPTY_WITHDRAWAL_CREDENTIALS");

        uint256 value = DEPOSIT_SIZE;

        // The following computations and Merkle tree-ization will make official Deposit contract happy
        uint256 depositAmount = value / DEPOSIT_AMOUNT_UNIT;
        assert(depositAmount * DEPOSIT_AMOUNT_UNIT == value);    // properly rounded

        // Compute deposit data root (`DepositData` hash tree root) according to deposit_contract.sol
        bytes32 pubkeyRoot = sha256(_pad64(_pubkey));
        bytes32 signatureRoot = sha256(
            abi.encodePacked(
                sha256(BytesLib.slice(_signature, 0, 64)),
                sha256(_pad64(BytesLib.slice(_signature, 64, SIGNATURE_LENGTH - 64)))
            )
        );

        bytes32 depositDataRoot = sha256(
            abi.encodePacked(
                sha256(abi.encodePacked(pubkeyRoot, withdrawalCredentials)),
                sha256(abi.encodePacked(_toLittleEndian64(depositAmount), signatureRoot))
            )
        );

        uint256 targetBalance = address(this).balance - value;

        getDepositContract().deposit{value: value}(
            _pubkey, abi.encodePacked(withdrawalCredentials), _signature, depositDataRoot);
        require(address(this).balance == targetBalance, "EXPECTING_DEPOSIT_TO_HAPPEN");
    }

    /**
    * @notice Returns current credentials to withdraw ETH on ETH 2.0 side after the phase 2 is launched
    */
    function getWithdrawalCredentials() public view returns (bytes32) {
        return WITHDRAWAL_CREDENTIALS_POSITION.getStorageBytes32();
    }

    /**
    * @notice Gets deposit contract handle
    */
    function getDepositContract() public view returns (IDepositContract) {
        return IDepositContract(DEPOSIT_CONTRACT_POSITION.getStorageAddress());
    }

    /**
    * @dev Padding memory array with zeroes up to 64 bytes on the right
    * @param _b Memory array of size 32 .. 64
    */
    function _pad64(bytes memory _b) internal pure returns (bytes memory) {
        assert(_b.length >= 32 && _b.length <= 64);
        if (64 == _b.length)
            return _b;

        bytes memory zero32 = new bytes(32);
        assembly { mstore(add(zero32, 0x20), 0) }

        if (32 == _b.length)
            return BytesLib.concat(_b, zero32);
        else
            return BytesLib.concat(_b, BytesLib.slice(zero32, 0, uint256(64) - _b.length));
    }

    /**
    * @dev Converting value to little endian bytes and padding up to 32 bytes on the right
    * @param _value Number less than `2**64` for compatibility reasons
    */
    function _toLittleEndian64(uint256 _value) internal pure returns (uint256 result) {
        result = 0;
        uint256 temp_value = _value;
        for (uint256 i = 0; i < 8; ++i) {
            result = (result << 8) | (temp_value & 0xFF);
            temp_value >>= 8;
        }

        assert(0 == temp_value);    // fully converted
        result <<= (24 * 8);
    }

    /**
    * @dev Records a deposit to the deposit_contract.deposit function
    * @param _amount Total amount deposited to the ETH 2.0 side
    */
    function _markAsUnbuffered(uint256 _amount) internal {
        BUFFERED_ETHER_POSITION.setStorageUint256(
            BUFFERED_ETHER_POSITION.getStorageUint256() - _amount
        );

        emit Unbuffered(_amount);
    }

    /**
    * @dev Gets unaccounted (excess) Ether on this contract balance
    */
    function _getUnaccountedEther() internal view returns (uint256) {
        return address(this).balance - _getBufferedEther();
    }

    /**
    * @dev Internal function to set authorized oracle address
    * @param _oracle oracle contract
    */
    function _setProtocolContracts(address _oracle, address _treasury, address _insuranceFund) internal {
        require(_oracle != address(0), "ORACLE_ZERO_ADDRESS");
        require(_treasury != address(0), "TREASURY_ZERO_ADDRESS");
        require(_insuranceFund != address(0), "INSURANCE_FUND_ZERO_ADDRESS");

        ORACLE_POSITION.setStorageAddress(_oracle);
        TREASURY_POSITION.setStorageAddress(_treasury);
        INSURANCE_FUND_POSITION.setStorageAddress(_insuranceFund);

        emit ProtocolContactsSet(_oracle, _treasury, _insuranceFund);
    }

    /**
    * @dev Gets the amount of Ether temporary buffered on this contract balance
    */
    function _getBufferedEther() internal view returns (uint256) {
        uint256 buffered = BUFFERED_ETHER_POSITION.getStorageUint256();
        assert(address(this).balance >= buffered);

        return buffered;
    }

    /**
    * @dev Process user deposit, mints liquid tokens and increase the pool buffer
    * @param _referral address of referral.
    * @return amount of SlETH shares generated
    */
    function _submit(address _referral) internal returns (uint256) {
        require(msg.value != 0, "ZERO_DEPOSIT");

        /* StakeLimitState.Data memory stakeLimitData = STAKING_STATE_POSITION.getStorageStakeLimitStruct();
        require(!stakeLimitData.isStakingPaused(), "STAKING_PAUSED");

        if (stakeLimitData.isStakingLimitSet()) {
            uint256 currentStakeLimit = stakeLimitData.calculateCurrentStakeLimit();

            require(msg.value <= currentStakeLimit, "STAKE_LIMIT");

            STAKING_STATE_POSITION.setStorageStakeLimitStruct(
                stakeLimitData.updatePrevStakeLimit(currentStakeLimit - msg.value)
            );
        } */

        uint256 sharesAmount = getSharesByPooledEth(msg.value);
        if (sharesAmount == 0) {
            // totalControlledEther is 0: either the first-ever deposit or complete slashing
            // assume that shares correspond to Ether 1-to-1
            sharesAmount = msg.value;
        }

        _mintShares(msg.sender, sharesAmount);

        BUFFERED_ETHER_POSITION.setStorageUint256(_getBufferedEther() + msg.value);
        emit Submitted(msg.sender, msg.value, _referral);

        _emitTransferAfterMintingShares(msg.sender, sharesAmount);
        return sharesAmount;
    }

    /**
    * @dev Emits {Transfer} and {TransferShares} events where `from` is 0 address. Indicates mint events.
    */
    function _emitTransferAfterMintingShares(address _to, uint256 _sharesAmount) internal {
        emit Transfer(address(0), _to, getPooledEthByShares(_sharesAmount));
        emit TransferShares(address(0), _to, _sharesAmount);
    }
}
