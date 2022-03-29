// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract InvestoReward {
    //uint256 admin;
    address[] public adminList;
    mapping(address => bool) public isAdmin;
    uint256 numberOfAdmin;

    uint256 investorBalance;
    uint256 numberOfInvestor;
    address[] public investors;
    mapping(address => bool) public isInvestor;

    constructor(address admin) {
        admin = msg.sender;
    }

    /*modifier adminOnly(address _admin) {
        require(
            isAdmin[msg.sender] == true,
            "Only Admin can call this function"

        );
    }*/

    function addInvestor(address _AddInvestor) public returns (string memory) {
        require(
            isAdmin[msg.sender] == true,
            "Only Admin can call this function"
        );
        string memory messageInvestor = "The address is already an investor";
        if (isInvestor[_AddInvestor] = false) {
            investors.push(_AddInvestor);
            isInvestor[_AddInvestor] = true;
            numberOfInvestor++;
        } else if (isInvestor[_AddInvestor] = true) {
            return messageInvestor;
        }
    }

    function removeInvestor(address _AddInvestor)
        public
        returns (string memory)
    {
        require(
            isAdmin[msg.sender] == true,
            "Only Admin can call this function"
        );
        string
            memory errorMessage = "The address is not an investor, please check";
        if (isInvestor[_AddInvestor] = true) {
            isInvestor[_AddInvestor] = false;
            numberOfInvestor--;
        } else if (isInvestor[_AddInvestor] = false) {
            return errorMessage;
        }
    }

    function addAdmin(address _additionalAdmin) public returns (string memory) {
        require(
            isAdmin[msg.sender] == true,
            "Only Admin can call this function"
        );
        string memory messageAdmin = "The address is already an admin";
        if (isAdmin[_additionalAdmin] = false) {
            adminList.push(_additionalAdmin);
            isAdmin[_additionalAdmin] = true;
            numberOfAdmin++;
        } else if (isAdmin[_additionalAdmin] = true) {
            return messageAdmin;
        }
    }

    function removeAdmin(address _additionalAdmin)
        public
        returns (string memory)
    {
        require(
            isAdmin[msg.sender] == true,
            "Only Admin can call this function"
        );
        string
            memory messageAdmin = "This address does not exist in admin directory";
        if (isAdmin[_additionalAdmin] = true) {
            isAdmin[_additionalAdmin] = false;
            numberOfAdmin--;
        } else if (isAdmin[_additionalAdmin] = false) {
            return messageAdmin;
        }
    }
}
