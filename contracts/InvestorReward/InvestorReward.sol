// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/access/Ownable.sol";

contract InvestoReward is Ownable {
    //uint256 admin;
    address public admin;
    mapping(address => bool) public isAdmin;
    uint256 numberOfAdmin;

    //uint256 investorBalance;
    uint256 numberOfInvestor;
    address[] public investors;
    mapping(address => bool) public isInvestor;

    uint256 setPercentage;
    uint256 changePercentage;
    mapping(address => uint256) public investorPercentage;

    event InvestorAdded(address investor, address owner);
    event InvestorRemoved(address investor, address owner);
    event AdminSet(address admin, address owner);

    //event AdminRemoved(address admin, address owner);

    constructor() {
        admin == _msgSender();
    }

    function addInvestor(address addInvestor) public onlyOwner returns (bool) {
        require(!isInvestor[addInvestor], "ALREADY_INVESTOR");
        investors.push(addInvestor);
        isInvestor[addInvestor] = true;
        numberOfInvestor++;
        emit InvestorAdded(addInvestor, msg.sender);
        return true;
    }

    function removeInvestor(address addInvestor)
        public
        onlyOwner
        returns (bool)
    {
        require(isInvestor[addInvestor] == true, "ALREADY_REMOVED");
        isInvestor[addInvestor] = false;
        numberOfInvestor--;
        emit InvestorRemoved(addInvestor, msg.sender);
        return true;
    }

    function addPercentage(address investor)
        public
        onlyOwner
        returns (uint256)
    {
        require(isInvestor[investor] == true, "NOT_INVESTOR");
        setPercentage = setPercentage / 1000;
        investorPercentage[investor] = setPercentage;
        return setPercentage;
    }

    function editPercentage(address investor)
        public
        onlyOwner
        returns (uint256)
    {
        require(isInvestor[investor] == true, "NOT_INVESTOR");
        changePercentage = changePercentage / 1000;
        investorPercentage[investor] = changePercentage;
        return changePercentage;
    }

    /*function SetAdmin(address newAdmin) public onlyOwner returns (bool) {
        require(newAdmin != address(0), "ZERO_ADDRESS");
        //adminList.push(newAdmin);
        isAdmin[newAdmin] = true;
        numberOfAdmin++;
        emit AdminSet(newAdmin, msg.sender);
        return true;
    }*/
}
