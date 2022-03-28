// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

//import "../token/SLETH.sol";

contract InvestoReward {
    uint256 admin;
    address[] public adminList;
    mapping(address => bool) public isAdmin;

    uint256 numberOfInvestor;
    address[] public investors;
    mapping(address => bool) public isInvestor;

    constructor(address _admin) {
        admin = _admin;
        addAdmin();
    }

    /*modifier adminOnly(address _admin) {
        require(
            isAdmin[msg.sender] == true,
            "Only Admin can call this function"
        );
    }*/

    function addInvestor(address _newInvestor) public {
        require(
            isAdmin[msg.sender] == true,
            "Only Admin can call this function"
        );
        if (isInvestor[_newInvestor] = false) {
            investors.push(_newInvestor);
            isInvestor[_newInvestor] = true;
            numberOfInvestor++;
        } else if (isInvestor[_newInvestor] = true) returns (bool) {
            return "User is already an Investor";
        }
    }

    function removeInvestor() public {
        require(
            isAdmin[msg.sender] == true,
            "Only Admin can call this function"
        );
    }

    function addAdmin(address _newAdmin) public {
        require(
            isAdmin[msg.sender] == true,
            "Only Admin can call this function"
        );
        if(isAdmin[_newAdmin] = false) {
            adminlist.push(_newAdmin);
            isAdmin[_newAdmin] = true;
        } else if (isAdmin[_user] = true){

        }

    }

    function removeAdmin(address _existingAdmin) public {
        require(
            isAdmin[msg.sender] == true,
            "Only Admin can call this function"
        );
    }
}
