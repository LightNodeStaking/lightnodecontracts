// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "../interfaces/IStaking.sol";
import "../token/SlETH.sol";
import "../lib/UnstructuredStorage.sol";
import "../interfaces/IExecutionLayerRewardsVault.sol";
import "../interfaces/INodeOperatorsRegistry.sol";

contract Staking is IStaking, SlETH {
    using SafeMath for uint256;
    using UnstructuredStorage for bytes32;

    address public owner;
    address public devAddress;
    uint256 public fee = 75; //7.5% fees
    uint256 public rewardFee;
    uint256 public totalReward;
    address public constant ETHER = address(0);
    uint256 public constant DEPOSIT_SIZE = 32 ether;
    SlETH public slETH;

    //storing stakers addresses
    address[] public stakers;
    mapping(address => mapping(address => uint256)) public stakingBalance;
    uint256 public stakedAmount;
    mapping(address => uint256) public feeByUser;
    mapping(address => uint256) public rewardBalance;
    mapping(address => bool) public isStaking;
    mapping(address => bool) public hasStaked;

    uint256 internal constant TOTAL_BASIS_POINTS = 10000;

    bytes32 internal constant ORACLE_POSITION =
        keccak256("lightnode.lightnode.oracle");

    bytes32 internal constant DEPOSITED_VALIDATORS_POSITION =
        keccak256("lightnode.lightnode.depositedValidators");

    bytes32 internal constant BEACON_VALIDATORS_POSITION =
        keccak256("lightnode.lightnode.beaconValidators");

    bytes32 internal constant BEACON_BALANCE_POSITION =
        keccak256("lightnode.lightnode.beaconBalance");

    bytes32 internal constant EL_REWARDS_VAULT_POSITION =
        keccak256("lightnode.lightnode.executionLayerRewardsVault");

    bytes32 internal constant EL_REWARDS_WITHDRAWAL_LIMIT_POSITION =
        keccak256("lightnode.lightnode.ELRewardsWithdrawalLimit");

    bytes32 internal constant BUFFERED_ETHER_POSITION =
        keccak256("lightnode.lightnode.bufferedEther");

    bytes32 internal constant FEE_POSITION = keccak256("lightnode.lightnode.fee");

    bytes32 internal constant TREASURY_FEE_POSITION =
        keccak256("lightnode.lightnode.treasuryFee");

    bytes32 internal constant INSURANCE_FEE_POSITION =
        keccak256("lightnode.lightnode.insuranceFee");

    bytes32 internal constant NODE_OPERATORS_FEE_POSITION =
        keccak256("lightnode.lightnode.nodeOperatorsFee");

    bytes32 internal constant INSURANCE_FUND_POSITION =
        keccak256("lightnode.lightnode.insuranceFund");

    bytes32 internal constant TREASURY_POSITION =
        keccak256("lightnode.lightnode.treasury");

    bytes32 internal constant NODE_OPERATORS_REGISTRY_POSITION =
        keccak256("lightnode.lightnode.nodeOperatorsRegistry");

    /// @dev Just a counter of total amount of execution layer rewards received by Staking contract
    bytes32 internal constant TOTAL_EL_REWARDS_COLLECTED_POSITION = keccak256("lightnode.lightnode.totalELRewardsCollected");

    //events
    event Stake(
        address indexed token,
        address indexed user,
        uint256 amount,
        uint256 balance
    );
    event TransferSleth(
        address indexed user,
        uint256 amount,
        uint256 timestamp
    );
    event Withdraw(
        address indexed token,
        address indexed user,
        uint256 amount,
        uint256 balance
    );
    event ClaimRewards(address indexed user, uint256 amount);

    /// @notice The amount of ETH withdrawn from ExecutionLayerRewardsVault contract to Staking contract
    event ELRewardsReceived(uint256 amount);

    constructor(
        address _owner,
        address _devAddress,
        SlETH _slETH
    ) {
        owner = _owner;
        devAddress = _devAddress;
        slETH = _slETH;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    modifier validAddress(address _address) {
        require(msg.sender != address(0));
        _;
    }

    modifier checkAmount(uint256 _amount) {
        require(_amount > 0, "Invalid Input");
        _;
    }

    function depositEth1() public payable override checkAmount(msg.value) {
        //require(msg.value > 0, "Amount cannot be zero");
        if (!hasStaked[msg.sender]) {
            stakers.push(msg.sender);
        }
        stakingBalance[ETHER][msg.sender] =
            stakingBalance[ETHER][msg.sender] +
            (msg.value);
        stakedAmount += msg.value;
        isStaking[msg.sender] = true;
        hasStaked[msg.sender] = true;
        emit Stake(
            ETHER,
            msg.sender,
            msg.value,
            stakingBalance[ETHER][msg.sender]
        );
        slETH._mint(msg.sender, msg.value);
        emit TransferSleth(msg.sender, msg.value, block.timestamp);
    }

    function totalSupply() public view override(IStaking, SlETH) returns (uint256) {
        return SlETH.totalSupply();
    }

    /*This is for users only. Users can call this function to withdraw their staked eth.
      Commenting out this function for now. We would have to decide whether we want to give user slETH or just give them options to withdraw. 
      We can not have both these options. Otherwise, user will be able to trade their slETH to eth and claim the eth they staked as well.
    */
    // function userWithdraw(uint256 _amount) public {
    //     require(isStaking[msg.sender] == true, "No Eth to withdraw");
    //     require(stakingBalance[ETHER][msg.sender]>=_amount);
    //     stakingBalance[ETHER][msg.sender] =stakingBalance[ETHER][msg.sender]-(_amount);
    //     payable(msg.sender).transfer(_amount);
    //     isStaking[msg.sender] == false;
    //     emit Withdraw(ETHER, msg.sender, _amount, stakingBalance[ETHER][msg.sender]);
    // }

    /* setReward will be called by the owner only once a day to update the total reward */
    function setReward(uint256 _reward) public onlyOwner {
        totalReward = _reward;
    }

    /* claimReward will be called by the user. We can set the condition where owner are not able to call this function.
        further info is needed by the client*/
    function claimReward() external validAddress(msg.sender) {
        require(isStaking[msg.sender] == true, "No staked Ether");
        uint256 rewardPerUser = calculateRewards(msg.sender);
        payable(msg.sender).transfer(rewardPerUser);
        emit ClaimRewards(msg.sender, rewardPerUser);
    }

    // function pushBeacon(uint256 epoch, uint256 eth2Bal) external;

    /* calculateRewards will calculate the user reward based on eth satked by the user/ total staked eth. */
    function calculateRewards(address _user) internal returns (uint256) {
        uint256 stakedEthByuser = stakingBalance[ETHER][_user];
        uint256 allocationPerUser = (stakedEthByuser / stakedAmount) * 100;
        uint256 reward = (allocationPerUser * totalReward);
        feeByUser[_user] = (reward * fee) / 1000;
        rewardBalance[_user] = reward - feeByUser[_user];
        totalReward -= reward;
        return rewardBalance[_user];
    }

    /* claimFee will be called by the owner only.
       upon calling 7.5% reward fees will get transfered to dev address. Which we will set when depolying this contract  */
    function claimFee(uint256 _amount) public onlyOwner checkAmount(_amount) {
        require(_amount <= rewardFee, "No fee to claim");
        rewardFee -= _amount;
        payable(devAddress).transfer(_amount);
    }

    //change to escrow contract

    /*WithdrawEther can be only called by owner. This function will get only called if the total staked balance is equal
      or more than discussed amount.
    */
    // function withdrawEther(uint256 _amount) public onlyOwner{
    //     payable(msg.sender).transfer(_amount);
    // }

    function setOwner(address _newOwner)
        public
        override
        onlyOwner
        validAddress(_newOwner)
    {
        owner = _newOwner;
    }

    function setDevAddress(address _newDevAddress)
        public
        override
        onlyOwner
        validAddress(_newDevAddress)
    {
        devAddress = _newDevAddress;
    }

    /*function balanceOf(address _user) public view returns (uint256) {
        return stakingBalance[ETHER][_user];
    }*/

    function stillStaking() public view override returns (bool) {
        return isStaking[msg.sender];
    }

    function getTotalShares() public view override(IStaking, SlETH) returns (uint256) {
       return SlETH.getTotalShares();
    }

    function getOracle() public view returns (address) {
        return ORACLE_POSITION.getStorageAddress();
    }

    function getBufferedEther() external view returns (uint256) {
        return _getBufferedEther();
    }

    /**
    * @dev Gets the total amount of Ether controlled by the system
    * @return total balance in wei
    */
    function _getTotalPooledEther() internal view override returns (uint256) {
        return _getBufferedEther() + BEACON_BALANCE_POSITION.getStorageUint256();
    }

    function pushBeacon(uint256 _beaconValidators, uint256 _beaconBalance)
        external
    {
        require(msg.sender == getOracle(), "APP_AUTH_FAILED");

        uint256 depositedValidators = DEPOSITED_VALIDATORS_POSITION
            .getStorageUint256();
        require(
            _beaconValidators <= depositedValidators,
            "REPORTED_MORE_DEPOSITED"
        );

        uint256 beaconValidators = BEACON_VALIDATORS_POSITION
            .getStorageUint256();

        require(
            _beaconValidators >= beaconValidators,
            "REPORTED_LESS_VALIDATORS"
        );
        uint256 appearedValidators = _beaconValidators - beaconValidators;

        uint256 rewardBase = (appearedValidators * DEPOSIT_SIZE) + (
            BEACON_BALANCE_POSITION.getStorageUint256()
        );

        BEACON_BALANCE_POSITION.setStorageUint256(_beaconBalance);
        BEACON_VALIDATORS_POSITION.setStorageUint256(_beaconValidators);

        uint256 executionLayerRewards;
        address executionLayerRewardsVaultAddress = getELRewardsVault();

        if (executionLayerRewardsVaultAddress != address(0)) {
            executionLayerRewards = IExecutionLayerRewardsVault(
                executionLayerRewardsVaultAddress
            ).withdrawRewards(
                    (_getTotalPooledEther() *
                        EL_REWARDS_WITHDRAWAL_LIMIT_POSITION
                            .getStorageUint256()) / TOTAL_BASIS_POINTS
                );

            if (executionLayerRewards != 0) {
                BUFFERED_ETHER_POSITION.setStorageUint256(
                    _getBufferedEther() + executionLayerRewards
                );
            }
        }

        if (_beaconBalance > rewardBase) {
            uint256 rewards = _beaconBalance - rewardBase;
            distributeFee(rewards + executionLayerRewards);
        }
    }

    /**
    * @notice A payable function for execution layer rewards. Can be called only by ExecutionLayerRewardsVault contract
    * @dev We need a dedicated function because funds received by the default payable function
    * are treated as a user deposit
    */
    function receiveELRewards() external payable {
        require(msg.sender == EL_REWARDS_VAULT_POSITION.getStorageAddress());

        TOTAL_EL_REWARDS_COLLECTED_POSITION.setStorageUint256(
            TOTAL_EL_REWARDS_COLLECTED_POSITION.getStorageUint256().add(msg.value));

        emit ELRewardsReceived(msg.value);
    }

    function getELRewardsVault() public view returns (address) {
        return EL_REWARDS_VAULT_POSITION.getStorageAddress();
    }

    function _getBufferedEther() internal view returns (uint256) {
        uint256 buffered = BUFFERED_ETHER_POSITION.getStorageUint256();
        assert(address(this).balance >= buffered);

        return buffered;
    }

    function distributeFee(uint256 _totalRewards) internal {
        // We need to take a defined percentage of the reported reward as a fee, and we do
        // this by minting new token shares and assigning them to the fee recipients (see
        // StETH docs for the explanation of the shares mechanics). The staking rewards fee
        // is defined in basis points (1 basis point is equal to 0.01%, 10000 (TOTAL_BASIS_POINTS) is 100%).
        //
        // Since we've increased totalPooledEther by _totalRewards (which is already
        // performed by the time this function is called), the combined cost of all holders'
        // shares has became _totalRewards StETH tokens more, effectively splitting the reward
        // between each token holder proportionally to their token share.
        //
        // Now we want to mint new shares to the fee recipient, so that the total cost of the
        // newly-minted shares exactly corresponds to the fee taken:
        //
        // shares2mint * newShareCost = (_totalRewards * feeBasis) / TOTAL_BASIS_POINTS
        // newShareCost = newTotalPooledEther / (prevTotalShares + shares2mint)
        //
        // which follows to:
        //
        //                        _totalRewards * feeBasis * prevTotalShares
        // shares2mint = --------------------------------------------------------------
        //                 (newTotalPooledEther * TOTAL_BASIS_POINTS) - (feeBasis * _totalRewards)
        //
        // The effect is that the given percentage of the reward goes to the fee recipient, and
        // the rest of the reward is distributed between token holders proportionally to their
        // token shares.
        uint256 feeBasis = getFee();
        uint256 shares2mint = (
            _totalRewards.mul(feeBasis).mul(_getTotalShares()).div(
                _getTotalPooledEther().mul(TOTAL_BASIS_POINTS).sub(
                    feeBasis.mul(_totalRewards)
                )
            )
        );

        // Mint the calculated amount of shares to this contract address. This will reduce the
        // balances of the holders, as if the fee was taken in parts from each of them.
        // _mintShares(address(this), shares2mint);

        (
            ,
            uint16 insuranceFeeBasisPoints,
            uint16 operatorsFeeBasisPoints
        ) = getFeeDistribution();

        uint256 toInsuranceFund = shares2mint.mul(insuranceFeeBasisPoints).div(
            TOTAL_BASIS_POINTS
        );
        address insuranceFund = getInsuranceFund();
        _transferShares(address(this), insuranceFund, toInsuranceFund);
        _emitTransferAfterMintingShares(insuranceFund, toInsuranceFund);

        uint256 distributedToOperatorsShares = _distributeNodeOperatorsReward(
            shares2mint.mul(operatorsFeeBasisPoints).div(TOTAL_BASIS_POINTS)
        );

        // Transfer the rest of the fee to treasury
        uint256 toTreasury = shares2mint.sub(toInsuranceFund).sub(
            distributedToOperatorsShares
        );

        address treasury = getTreasury();
        _transferShares(address(this), treasury, toTreasury);
        _emitTransferAfterMintingShares(treasury, toTreasury);
    }

    function getFee() public view returns (uint16 feeBasisPoints) {
        return uint16(FEE_POSITION.getStorageUint256());
    }

    function getFeeDistribution()
        public
        view
        returns (
            uint16 treasuryFeeBasisPoints,
            uint16 insuranceFeeBasisPoints,
            uint16 operatorsFeeBasisPoints
        )
    {
        treasuryFeeBasisPoints = uint16(
            TREASURY_FEE_POSITION.getStorageUint256()
        );
        insuranceFeeBasisPoints = uint16(
            INSURANCE_FEE_POSITION.getStorageUint256()
        );
        operatorsFeeBasisPoints = uint16(
            NODE_OPERATORS_FEE_POSITION.getStorageUint256()
        );
    }

    function getInsuranceFund() public view returns (address) {
        return INSURANCE_FUND_POSITION.getStorageAddress();
    }

    function _emitTransferAfterMintingShares(address _to, uint256 _sharesAmount)
        internal
    {
        emit Transfer(address(0), _to, getPooledEthByShares(_sharesAmount));
        // emit TransferShares(address(0), _to, _sharesAmount);
    }

    function getOperators() public view returns (INodeOperatorsRegistry) {
        return
            INodeOperatorsRegistry(
                NODE_OPERATORS_REGISTRY_POSITION.getStorageAddress()
            );
    }

    function _distributeNodeOperatorsReward(uint256 _sharesToDistribute)
        internal
        returns (uint256 distributed)
    {
        (address[] memory recipients, uint256[] memory shares) = getOperators()
            .getRewardsDistribution(_sharesToDistribute);

        assert(recipients.length == shares.length);

        distributed = 0;
        for (uint256 idx = 0; idx < recipients.length; ++idx) {
            _transferShares(address(this), recipients[idx], shares[idx]);
            _emitTransferAfterMintingShares(recipients[idx], shares[idx]);
            distributed = distributed.add(shares[idx]);
        }
    }

    function getTreasury() public view returns (address) {
        return TREASURY_POSITION.getStorageAddress();
    }

    /* function _submit(address _referral) internal returns (uint256) {
        require(msg.value != 0, "ZERO_DEPOSIT");

        StakeLimitState.Data memory stakeLimitData = STAKING_STATE_POSITION
            .getStorageStakeLimitStruct();
        require(!stakeLimitData.isStakingPaused(), "STAKING_PAUSED");

        if (stakeLimitData.isStakingLimitSet()) {
            uint256 currentStakeLimit = stakeLimitData
                .calculateCurrentStakeLimit();

            require(msg.value <= currentStakeLimit, "STAKE_LIMIT");

            STAKING_STATE_POSITION.setStorageStakeLimitStruct(
                stakeLimitData.updatePrevStakeLimit(
                    currentStakeLimit - msg.value
                )
            );
        }

        uint256 sharesAmount = getSharesByPooledEth(msg.value);
        if (sharesAmount == 0) {
            // totalControlledEther is 0: either the first-ever deposit or complete slashing
            // assume that shares correspond to Ether 1-to-1
            sharesAmount = msg.value;
        }

        _mintShares(msg.sender, sharesAmount);

        BUFFERED_ETHER_POSITION.setStorageUint256(
            _getBufferedEther().add(msg.value)
        );
        emit Submitted(msg.sender, msg.value, _referral);

        _emitTransferAfterMintingShares(msg.sender, sharesAmount);
        return sharesAmount;
    } */
}
