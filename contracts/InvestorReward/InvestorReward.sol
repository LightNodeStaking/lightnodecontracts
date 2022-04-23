// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/access/Ownable.sol";

contract InvestoReward is Ownable {
    //uint256 admin;
    address public admin;
    mapping(address => bool) public isAdmin;
    //uint256 numberOfAdmin;

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

    function addInvestor(address newInvestor) public onlyOwner returns (bool) {
        require(!isInvestor[newInvestor], "ALREADY_INVESTOR");
        investors.push(newInvestor);
        isInvestor[newInvestor] = true;
        numberOfInvestor++;
        emit InvestorAdded(newInvestor, msg.sender);
        return true;
    }

    function removeInvestor(address existInvestor)
        public
        onlyOwner
        returns (bool)
    {
        require(isInvestor[existInvestor] == true, "ALREADY_REMOVED");
        isInvestor[existInvestor] = false;
        numberOfInvestor--;
        emit InvestorRemoved(existInvestor, msg.sender);
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

    function tranferOwnerShip(address newAdmin)
        public
        onlyOwner
        returns (bool)
    {
        require(newAdmin != address(0), "ZERO_ADDRESS");
        address oldAdmin = admin;
        oldAdmin = newAdmin;
        emit OwnershipTransferred(newAdmin, oldAdmin);
        return true;
    }
}
