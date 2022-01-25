// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Staking{
    
    address public owner;
    address constant ETHER = address(0);
    //storing stakers addresses
    address[] public stakers;
    mapping(address => mapping(address=> uint256)) public stakingBalance;
    //mapping(address => uint256) public stakingBalance;
    mapping(address => uint256) public rewardBalance;
    mapping(address => bool) public  isStaking;
    
    //events
    event Stake(address indexed token, address indexed user, uint256 amount, uint256 balance);
    event Withdraw(address indexed token, address indexed user, uint256 amount, uint256 balance);

    constructor( address _owner ){
        owner = _owner;
    }

    function stakeETHER( address _token, uint256 _amount) payable public{
        require(_token == ETHER, "Invalid Token");
        stakingBalance[_token][msg.sender] = stakingBalance[_token][msg.sender]+(_amount);
        isStaking[msg.sender] == true; 
        emit Stake(_token, msg.sender, _amount, stakingBalance[_token][msg.sender] );
    }

    function withdrawETHER(uint256 _amount) public {
        require(isStaking[msg.sender] == true, "No Eth to withdraw");
        require(stakingBalance[ETHER][msg.sender]>=_amount);
        stakingBalance[ETHER][msg.sender] =stakingBalance[ETHER][msg.sender]-(_amount);
        payable(msg.sender).transfer(_amount);
        emit Withdraw(ETHER, msg.sender, _amount, stakingBalance[ETHER][msg.sender]); 

    }

    function balanceOf(address _user) public view returns (uint256){
        return stakingBalance[ETHER][_user];
    }
}