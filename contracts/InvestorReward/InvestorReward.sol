// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/access/Ownable.sol";

contract InvestoReward is Ownable {
    address public admin;

    uint256 numberOfInvestor;
    address[] public investors;
    mapping(address => bool) public isInvestor;

    mapping(address => uint256) public investorPercentage;

    event InvestorAdded(address investor, address admin);
    event InvestorRemoved(address investor, address admin);

    constructor() {
        admin = _msgSender();
    }

    function addInvestor(address newInvestor) public onlyOwner returns (bool) {
        require(newInvestor != address(0), "INVALID_ADDRESS");
        require(newInvestor != admin, "ADMIN_ADDRESS");
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
        require(isInvestor[existInvestor], "INVALID_ADDRESS");
        isInvestor[existInvestor] = false;
        numberOfInvestor--;
        emit InvestorRemoved(existInvestor, msg.sender);
        return true;
    }

    function addPercentage(address investor, uint256 setPercentage)
        public
        onlyOwner
        returns (uint256)
    {
        require(isInvestor[investor], "NOT_INVESTOR");
        setPercentage = setPercentage / 1000;
        investorPercentage[investor] = setPercentage;
        return setPercentage;
    }

    function editPercentage(address investor, uint256 changePercentage)
        public
        onlyOwner
        returns (uint256)
    {
        require(isInvestor[investor], "NOT_INVESTOR");
        changePercentage = changePercentage / 1000;
        investorPercentage[investor] = changePercentage;
        return changePercentage;
    }
}
