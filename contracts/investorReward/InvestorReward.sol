// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract InvestoReward {
    //uint256 admin;
    address[] public adminList;
    mapping(address => bool) public isAdmin;
    uint256 numberOfAdmin;

    //uint256 investorBalance;
    uint256 numberOfInvestor;
    address[] public investors;
    mapping(address => bool) public isInvestor;

    uint256 setPercentage;
    uint256 changePercentage;
    mapping(address => uint256) public investorPercentage;

    constructor(address admin) {
        admin = msg.sender;
    }

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
            "Only Admin can remove the investor"
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

    function addPercentage(address _investor) public returns (string memory) {
        require(
            isAdmin[msg.sender] == true,
            "Only Admin can add/edit the percentage"
        );
        require(
            isInvestor[_investor] == true,
            "the existing address is not an investor"
        );
        setPercentage = setPercentage / 1000;
        investorPercentage[_investor] = setPercentage;
    }

    function editPercentage(address _investor) public returns (string memory) {
        require(
            isAdmin[msg.sender] == true,
            "Only Admin can add/edit the percentage"
        );
        require(
            isInvestor[_investor] == true,
            "the existing address is not an investor"
        );
        changePercentage = changePercentage / 1000;
        investorPercentage[_investor] = changePercentage;
    }

    function addAdmin(address _admin) public returns (string memory) {
        require(
            isAdmin[msg.sender] == true,
            "Only Admin can call this function"
        );
        string memory messageAdmin = "The address is already an admin";
        if (isAdmin[_admin] = false) {
            adminList.push(_admin);
            isAdmin[_admin] = true;
            numberOfAdmin++;
        } else if (isAdmin[_admin] = true) {
            return messageAdmin;
        }
    }

    function removeAdmin(address _admin) public returns (string memory) {
        require(
            isAdmin[msg.sender] == true,
            "Only Admin can call this function"
        );
        string
            memory messageAdmin = "This address does not exist in admin directory";
        if (isAdmin[_admin] = true) {
            isAdmin[_admin] = false;
            numberOfAdmin--;
        } else if (isAdmin[_admin] = false) {
            return messageAdmin;
        }
    }
}
