// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "../lib/UnStructuredData.sol";

abstract contract SLETH is IERC20, Pausable {
    using UnStructuredData for bytes32;
    mapping(address => uint256) public _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    bytes32 internal constant TOTAL_SHARES_POSITION =
        keccak256("StETH.totalShares");

    string public _name = "Lightnode staked Ether";
    string public _symbol = "slETH";
    uint8 public _decimal = 18;

    //address public tokenAccount;

    function name() public view virtual returns (string memory) {
        return _name;
    }

    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    function decimals() public view virtual returns (uint8) {
        return _decimal;
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _getTotalPooledEther();
    }

    function getTotalPooledEther() public view returns (uint256) {
        return _getTotalPooledEther();
    }

    function balanceOf(address account)
        public
        view
        virtual
        override
        returns (uint256)
    {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
        require(_balances[msg.sender] >= amount, "NOT_ENOUGH_BALANCE");
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function allowance(address owner, address spender)
        public
        view
        virtual
        override
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override whenNotPaused returns (bool) {
        uint256 currentAllowance = _allowances[sender][msg.sender];
        if (currentAllowance != type(uint256).max) {
            require(
                currentAllowance >= amount,
                "ERC20: transfer amount exceeds allowance"
            );
            unchecked {
                _approve(sender, msg.sender, currentAllowance - amount);
            }
        }

        _transfer(sender, recipient, amount);

        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue)
        public
        virtual
        returns (bool)
    {
        _approve(
            msg.sender,
            spender,
            _allowances[msg.sender][spender] + addedValue
        );
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        virtual
        returns (bool)
    {
        uint256 currentAllowance = _allowances[msg.sender][spender];
        require(
            currentAllowance >= subtractedValue,
            "ERC20: DECREASED_ALLOWANCE_BELOW_ZERO"
        );
        unchecked {
            _approve(msg.sender, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    function getTotalShares() public view returns (uint256) {
        return _getTotalShares();
    }

    function sharesOf(address _account) public view returns (uint256) {
        return _sharesOf(_account);
    }

    function getSharesByPooledEth(uint256 _ethAmount)
        public
        view
        returns (uint256)
    {
        uint256 totalPooledEther = _getTotalPooledEther();
        if (totalPooledEther == 0) {
            return 0;
        } else {
            return (_ethAmount * (_getTotalShares())) / (totalPooledEther);
        }
    }

    function getPooledEthByShares(uint256 _sharesAmount)
        public
        view
        returns (uint256)
    {
        uint256 totalShares = _getTotalShares();
        if (totalShares == 0) {
            return 0;
        } else {
            return (_sharesAmount * (_getTotalPooledEther())) / (totalShares);
        }
    }

    function _getTotalShares() internal view returns (uint256) {
        return TOTAL_SHARES_POSITION.getStorageUint256();
    }

    function _sharesOf(address _account) internal view returns (uint256) {
        return _balances[_account];
    }

    //_getTotalPooledEther() function needs tro be implemented in teh main contract.
    // further testing will be required at the master contract testing stage.

    function _getTotalPooledEther() internal view virtual returns (uint256);

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual whenNotPaused {
        uint256 _sharesToTransfer = getSharesByPooledEth(amount);
        _transferShares(sender, recipient, _sharesToTransfer);

        emit Transfer(sender, recipient, amount);
    }

    function _transferShares(
        address _sender,
        address _recipient,
        uint256 _sharesAmount
    ) internal whenNotPaused {
        require(_sender != address(0), "TRANSFER_FROM_THE_ZERO_ADDRESS");
        require(_recipient != address(0), "TRANSFER_TO_THE_ZERO_ADDRESS");

        _beforeTokenTransfer(_sender, _recipient, _sharesAmount);

        uint256 senderBalance = _balances[_sender];
        require(
            senderBalance >= _sharesAmount,
            "ERC20: transfer amount exceeds balance"
        );

        _balances[_sender] = senderBalance - _sharesAmount;

        _balances[_recipient] += _sharesAmount;

        _afterTokenTransfer(_sender, _recipient, _sharesAmount);
    }

    //mint function, mints new shares. it does not change the totalsupply

    function _mint(address account, uint256 amount)
        public
        virtual
        whenNotPaused
        returns (uint256 newTotalShares)
    {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        newTotalShares = _getTotalShares() + amount;
        TOTAL_SHARES_POSITION.setStorageUint256(newTotalShares);

        _balances[account] += amount;

        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    //burn function, burn shares. it does not change the totalsupply.

    function _burn(address account, uint256 amount)
        public
        virtual
        whenNotPaused
        returns (uint256 newTotalShares)
    {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");

        newTotalShares = _getTotalShares() - (amount);
        TOTAL_SHARES_POSITION.setStorageUint256(newTotalShares);

        unchecked {
            _balances[account] -= amount;
        }

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual whenNotPaused {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    function pause() external {
        _pause();
    }

    function unpause() external {
        _unpause();
    }
}
