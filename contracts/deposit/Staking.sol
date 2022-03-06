// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../interfaces/IStaking.sol";
import "../token/SLETH.sol";

contract Staking is IStaking{
    
    address public owner;
    address public devAddress;
    uint256 public fee = 75; //7.5% fees
    uint256 public rewardFee;
    uint256 public totalReward;
    address constant public ETHER = address(0);
    uint256 constant public DEPOSIT_SIZE = 32 ether;
    SLETH public slETH;
    
    //storing stakers addresses
    address[] public stakers;
    mapping(address => mapping(address=> uint256)) public stakingBalance;
    uint256 public stakedAmount;
    mapping(address=>uint256) public feeByUser;
    mapping(address => uint256) public rewardBalance;
    mapping(address => bool) public isStaking;
    mapping(address => bool) public hasStaked;
    
    //events
    event Stake(address indexed token, address indexed user, uint256 amount, uint256 balance);
    event TransferSleth(address indexed user, uint256 amount, uint timestamp);
    event Withdraw(address indexed token, address indexed user, uint256 amount, uint256 balance);
    event ClaimRewards(address indexed user, uint256 amount);

    constructor( address _owner, address _devAddress, SLETH _slETH ){
        owner = _owner;
        devAddress = _devAddress;
        slETH = _slETH;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    modifier validAddress (address _address) {
        require(_address != address(0));
        _;
    }

    function depositEth1() payable public{
        require(msg.value > 0, "Amount cannot be zero");
        if(!hasStaked[msg.sender]){
            stakers.push(msg.sender);
        }
        stakingBalance[ETHER][msg.sender] = stakingBalance[ETHER][msg.sender]+(msg.value);
        stakedAmount += msg.value;
        isStaking[msg.sender] = true;
        hasStaked[msg.sender] = true;
        emit Stake(ETHER, msg.sender, msg.value, stakingBalance[ETHER][msg.sender]);
        slETH._mint(msg.sender, msg.value);
        emit TransferSleth(msg.sender, msg.value, block.timestamp);
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
    function claimReward() public{
        require(isStaking[msg.sender]==true, "No staked Ether");
        require(msg.sender != address(0), "Invalid address");
        uint256 rewardPerUser = calculateRewards(msg.sender);
        payable(msg.sender).transfer(rewardPerUser);
        emit ClaimRewards(msg.sender, rewardPerUser);

    }

    /* calculateRewards will calculate the user reward based on eth satked by the user/ total staked eth. */
    function calculateRewards(address _user) public returns(uint256) {
        uint256 stakedEthByuser = stakingBalance[ETHER][_user];
        uint256 allocationPerUser = (stakedEthByuser/stakedAmount)*100;
        uint256 reward = (allocationPerUser*totalReward);
        feeByUser[_user] = (reward*fee)/1000;
        rewardBalance[_user] = reward - feeByUser[_user];
        totalReward -= reward; 
        return rewardBalance[_user];
    }

    /* claimFee will be called by the owner only.
       upon calling 7.5% reward fees will get transfered to dev address. Which we will set when depolying this contract  */
    function claimFee() public onlyOwner {
        require(rewardFee > 0, "No fee to claim");
        payable(devAddress).transfer(rewardFee);
    }
    //change to escrow contract

    /*WithdrawEther can be only called by owner. This function will get only called if the total staked balance is equal
      or more than discussed amount.
    */
    // function withdrawEther(uint256 _amount) public onlyOwner{
    //     payable(msg.sender).transfer(_amount);
    // }

    function setNewOwner( address _newOwner) public onlyOwner validAddress(_newOwner) {
        owner = _newOwner;
    }

    function setNewDevAddress( address _newDevAddress) public onlyOwner validAddress(_newDevAddress){
        devAddress = _newDevAddress;
    }

    function balanceOf(address _user) public view returns (uint256){
        return stakingBalance[ETHER][_user];
    }

    function stillStaking() public view returns(bool){
        return isStaking[msg.sender];
    }
}