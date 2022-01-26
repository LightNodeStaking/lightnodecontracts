// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts//token/ERC20/ERC20.sol";

contract Staking{
    
    address public owner;
    address constant ETHER = address(0);
    ERC20 sEth;
    //storing stakers addresses
    address[] public stakers;
    mapping(address => mapping(address=> uint256)) public stakingBalance;
    uint256 public stakedAmount;
    mapping(address => uint256) public rewardBalance;
    mapping(address => bool) public  isStaking;
    
    //events
    event Stake(address indexed token, address indexed user, uint256 amount, uint256 balance);
    event TransferSeth(address indexed user, uint256 amount, uint timestamp);
    //event Withdraw(address indexed token, address indexed user, uint256 amount, uint256 balance);

    constructor( address _owner ){
        owner = _owner;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function stakeETHER( address _token, uint256 _amount) payable public{
        require(_token == ETHER, "Invalid Token");
        stakingBalance[_token][msg.sender] = stakingBalance[_token][msg.sender]+(_amount);
        isStaking[msg.sender] == true;
        stakedAmount += _amount;
        emit Stake(_token, msg.sender, _amount, stakingBalance[_token][msg.sender] );
    }

    function transferWeth(address _address, uint256 _amount) internal{
        require(isStaking[_address]== true);
        sEth.transfer(_address, _amount);
        emit TransferSeth(_address, _amount, block.timestamp);
    }
    // function withdrawETHER(uint256 _amount) public {
    //     require(isStaking[msg.sender] == true, "No Eth to withdraw");
    //     require(stakingBalance[ETHER][msg.sender]>=_amount);
    //     stakingBalance[ETHER][msg.sender] =stakingBalance[ETHER][msg.sender]-(_amount);
    //     payable(msg.sender).transfer(_amount);
    //     emit Withdraw(ETHER, msg.sender, _amount, stakingBalance[ETHER][msg.sender]); 

    // }

    function withdrawEther(uint256 _amount) public onlyOwner{
        payable(msg.sender).transfer(_amount);
    }
    function balanceOf(address _user) public view returns (uint256){
        return stakingBalance[ETHER][_user];
    }
}