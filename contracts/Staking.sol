// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./SLETH.sol";

contract Staking{
    
    address public owner;
    address public devAddress;
    uint256 public fee = 75; //7.5% fees
    uint256 private rewardFee;
    uint256 private totalReward;
    address constant ETHER = address(0);
    SLETH public slETH;
    
    //storing stakers addresses
    address[] public stakers;
    mapping(address => mapping(address=> uint256)) public stakingBalance;
    uint256 public stakedAmount;
    mapping(address => uint256) public rewardBalance;
    mapping(address => bool) public isStaking;
    mapping(address => bool) public hasStaked;
    
    //events
    event Stake(address indexed token, address indexed user, uint256 amount, uint256 balance);
    event TransferSeth(address indexed user, uint256 amount, uint timestamp);
    event Withdraw(address indexed token, address indexed user, uint256 amount, uint256 balance);
    event ClaimRewards(address indexed user, uint256 amount);

    constructor( address _owner, address _devAddress/*, SLETH _slETH*/ ){
        owner = _owner;
        devAddress = _devAddress;
        //slETH = _slETH;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function stakeETHER(address _token, uint256 _amount) payable public{
        require(_token == ETHER, "Invalid Token");
        if(!hasStaked[msg.sender]){
            stakers.push(msg.sender);
        }
        stakingBalance[_token][msg.sender] = stakingBalance[_token][msg.sender]+(_amount);
        isStaking[msg.sender] = true;
        hasStaked[msg.sender] = true;
        stakedAmount += _amount;
        emit Stake(_token, msg.sender, _amount, stakingBalance[_token][msg.sender]);
        slETH.mint(msg.sender, _amount);
        emit TransferSeth(msg.sender, _amount, block.timestamp);
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
        require(msg.sender == address(0), "Invalid address");
        uint256 rewardPerUser = calculateRewards(msg.sender);
        payable(msg.sender).transfer(rewardPerUser);
        emit ClaimRewards(msg.sender, rewardPerUser);

    }

    /* calculateRewards will calculate the user reward based on eth satked by the user/ total staked eth. */
    function calculateRewards(address _user) internal returns(uint256) {
        uint256 stakedEthByuser = stakingBalance[ETHER][_user];
        rewardFee = (totalReward*fee)/1000;
        uint256 netReward = totalReward-rewardFee;
        uint256 allocationPerUser = (stakedEthByuser*100)/stakedAmount;
        rewardBalance[_user] = (allocationPerUser*netReward)/100;
        return rewardBalance[_user];
    }

    /* claimFee will be called by the owner only.
       upon calling 7.5% reward fees will get transfered to dev address. Which we will set when depolying this contract  */
    function claimFee() public onlyOwner {
        require(rewardFee > 0, "No fee to claim");
        payable(devAddress).transfer(rewardFee);
    }

    /*WithdrawEther can be only called by owner. This function will get only called if the total staked balance is equal
      or more than discussed amount.
    */
    function withdrawEther(uint256 _amount) public onlyOwner{
        payable(msg.sender).transfer(_amount);
    }

    function balanceOf(address _user) public view returns (uint256){
        return stakingBalance[ETHER][_user];
    }

    function stillStaking() public view returns(bool){
        return isStaking[msg.sender];
    }
}