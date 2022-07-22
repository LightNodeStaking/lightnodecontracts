// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

import "./interfaces/ILightNode.sol";

/**
 * @title A vault for temporary storage of execution layer rewards (MEV and tx priority fee)
 */
contract ExecutionLayerRewardsVault {
    using SafeERC20 for IERC20;

    address public immutable STAKING;
    address public immutable TREASURY;

    /**
      * Emitted when the ERC20 `token` recovered (i.e. transferred)
      * to the Staking treasury address by `requestedBy` sender.
      */
    event ERC20Recovered(
        address indexed requestedBy,
        address indexed token,
        uint256 amount
    );

    /**
      * Emitted when the ERC721-compatible `token` (NFT) recovered (i.e. transferred)
      * to the Staking treasury address by `requestedBy` sender.
      */
    event ERC721Recovered(
        address indexed requestedBy,
        address indexed token,
        uint256 tokenId
    );

    /**
      * Emitted when the vault received ETH
      */
    event ETHReceived(
        uint256 amount
    );

    /**
      * Ctor
      *
      * @param _staking the Staking token (stETH) address
      * @param _treasury the Staking treasury address (see ERC20/ERC721-recovery interfaces)
      */
    constructor(address _staking, address _treasury) {
        require(_staking != address(0), "STAKING_ZERO_ADDRESS");
        require(_treasury != address(0), "TREASURY_ZERO_ADDRESS");

        STAKING = _staking;
        TREASURY = _treasury;
    }

    /**
      * @notice Allows the contract to receive ETH
      * @dev execution layer rewards may be sent as plain ETH transfers
      */
    receive() external payable {
        emit ETHReceived(msg.value);
    }

    /**
      * @notice Withdraw all accumulated rewards to Staking contract
      * @dev Can be called only by the Staking contract
      * @param _maxAmount Max amount of ETH to withdraw
      * @return amount of funds received as execution layer rewards (in wei)
      */
    function withdrawRewards(uint256 _maxAmount) external returns (uint256 amount) {
        require(msg.sender == STAKING, "ONLY_STAKING_CAN_WITHDRAW");

        uint256 balance = address(this).balance;
        amount = (balance > _maxAmount) ? _maxAmount : balance;
        if (amount > 0) {
            ILightNode(STAKING).receiveELRewards{value: amount}();
        }
        return amount;
    }

    /**
      * Transfers a given `_amount` of an ERC20-token (defined by the `_token` contract address)
      * currently belonging to the burner contract address to the Staking treasury address.
      *
      * @param _token an ERC20-compatible token
      * @param _amount token amount
      */
    function recoverERC20(address _token, uint256 _amount) external {
        require(_amount > 0, "ZERO_RECOVERY_AMOUNT");

        emit ERC20Recovered(msg.sender, _token, _amount);

        IERC20(_token).safeTransfer(TREASURY, _amount);
    }

    /**
      * Transfers a given token_id of an ERC721-compatible NFT (defined by the token contract address)
      * currently belonging to the burner contract address to the Staking treasury address.
      *
      * @param _token an ERC721-compatible token
      * @param _tokenId minted token id
      */
    function recoverERC721(address _token, uint256 _tokenId) external {
        emit ERC721Recovered(msg.sender, _token, _tokenId);

        IERC721(_token).transferFrom(address(this), TREASURY, _tokenId);
    }
}
