// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../token/SlETH.sol";

contract SlethMock is SlETH {
    address public tokenAccount;

    uint256 public totalPooledEther;

    constructor(address _owner) {
        tokenAccount = _owner;
    }

    /**
     * @dev Gets the total amount of Ether controlled by the system
     * @return total balance in wei
     */
    function _getTotalPooledEther() internal view override returns (uint256) {
        return totalPooledEther;
    }

    function setTotalPooledEther(uint256 _totalPooledEther) public {
        totalPooledEther = _totalPooledEther;
    }

    function mintShares(address _to, uint256 _sharesAmount)
        public
        returns (uint256 newTotalShares)
    {
        newTotalShares = _mintShares(_to, _sharesAmount);
        //_emitTransferAfterMintingShares(_to, _sharesAmount);
    }

    function burnShares(address _account, uint256 _sharesAmount)
        public
        returns (uint256 newTotalShares)
    {
        return _burnShares(_account, _sharesAmount);
    }
}
