// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Staking{
    
    //storing stakers addresses
    address[] public stakers;
    mapping(address => uint256) public stakingBalance;
    mapping(address => uint256) public rewardBalance;
    mapping(address => bool) public hasStaked;
    mapping(address => bool) public  isStaking;
    
    //events
    event Stake(address indexed from, uint256 amount);
    event UnStake(address indexed from, uint256 amount);

    constructor( address _owner ){
        _owner = msg.sender;
    }

    function stakeToken() public{

    }

    function unStake() public {

    }
}