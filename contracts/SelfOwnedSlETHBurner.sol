// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";

import "./interfaces/IBeaconReportReceiver.sol";
import "./interfaces/ISelfOwnedSlETHBurner.sol";
import "./interfaces/ILightNode.sol";
import "./interfaces/IOracle.sol";

/**
  * @title A dedicated contract for enacting slETH burning requests
  * @dev Burning slETH means 'decrease total underlying shares amount to perform slETH token rebase'
  */
contract SelfOwnedSlETHBurner is ISelfOwnedSlETHBurner, IBeaconReportReceiver, ERC165 {
    using SafeERC20 for IERC20;

    uint256 private constant MAX_BASIS_POINTS = 10000;

    uint256 private coverSharesBurnRequested;
    uint256 private nonCoverSharesBurnRequested;

    uint256 private totalCoverSharesBurnt;
    uint256 private totalNonCoverSharesBurnt;

    uint256 private maxBurnAmountPerRunBasisPoints = 4; // 0.04% by default for the biggest `slETH:ETH` curve pool

    address public immutable LIGHTNODE;
    address public immutable TREASURY;
    address public immutable VOTING;

    /**
      * Emitted when a new single burn quota is set
      */
    event BurnAmountPerRunQuotaChanged(
        uint256 maxBurnAmountPerRunBasisPoints
    );

    /**
      * Emitted when a new slETH burning request is added by the `requestedBy` address.
      */
    event SlETHBurnRequested(
        bool indexed isCover,
        address indexed requestedBy,
        uint256 amount,
        uint256 sharesAmount
    );

    /**
      * Emitted when the slETH `amount` (corresponding to `sharesAmount` shares) burnt for the `isCover` reason.
      */
    event SlETHBurnt(
        bool indexed isCover,
        uint256 amount,
        uint256 sharesAmount
    );

    /**
      * Emitted when the excessive slETH `amount` (corresponding to `sharesAmount` shares) recovered (i.e. transferred)
      * to the LightNode treasure address by `requestedBy` sender.
      */
    event ExcessSlETHRecovered(
        address indexed requestedBy,
        uint256 amount,
        uint256 sharesAmount
    );

    /**
      * Emitted when the ERC20 `token` recovered (i.e. transferred)
      * to the LightNode treasure address by `requestedBy` sender.
      */
    event ERC20Recovered(
        address indexed requestedBy,
        address indexed token,
        uint256 amount
    );

    /**
      * Emitted when the ERC721-compatible `token` (NFT) recovered (i.e. transferred)
      * to the LightNode treasure address by `requestedBy` sender.
      */
    event ERC721Recovered(
        address indexed requestedBy,
        address indexed token,
        uint256 tokenId
    );

    /**
      * Ctor
      *
      * @param _treasury the LightNode treasury address (see SlETH/ERC20/ERC721-recovery interfaces)
      * @param _lightNode the LightNode token (slETH) address
      * @param _voting the LightNode Voting address
      * @param _totalCoverSharesBurnt Shares burnt counter init value (cover case)
      * @param _totalNonCoverSharesBurnt Shares burnt counter init value (non-cover case)
      * @param _maxBurnAmountPerRunBasisPoints Max burn amount per single run
      */
    constructor(
        address _treasury,
        address _lightNode,
        address _voting,
        uint256 _totalCoverSharesBurnt,
        uint256 _totalNonCoverSharesBurnt,
        uint256 _maxBurnAmountPerRunBasisPoints
    ) {
        require(_treasury != address(0), "TREASURY_ZERO_ADDRESS");
        require(_lightNode != address(0), "LIGHTNODE_ZERO_ADDRESS");
        require(_voting != address(0), "VOTING_ZERO_ADDRESS");
        require(_maxBurnAmountPerRunBasisPoints > 0, "ZERO_BURN_AMOUNT_PER_RUN");
        require(_maxBurnAmountPerRunBasisPoints <= MAX_BASIS_POINTS, "TOO_LARGE_BURN_AMOUNT_PER_RUN");

        TREASURY = _treasury;
        LIGHTNODE = _lightNode;
        VOTING = _voting;

        totalCoverSharesBurnt = _totalCoverSharesBurnt;
        totalNonCoverSharesBurnt = _totalNonCoverSharesBurnt;

        maxBurnAmountPerRunBasisPoints = _maxBurnAmountPerRunBasisPoints;
    }

    /**
      * Sets the maximum amount of shares allowed to burn per single run (quota).
      *
      * @dev only `voting` allowed to call this function.
      *
      * @param _maxBurnAmountPerRunBasisPoints a fraction expressed in basis points (taken from LightNode.totalSharesAmount)
      *
      */
    function setBurnAmountPerRunQuota(uint256 _maxBurnAmountPerRunBasisPoints) external {
        require(_maxBurnAmountPerRunBasisPoints > 0, "ZERO_BURN_AMOUNT_PER_RUN");
        require(_maxBurnAmountPerRunBasisPoints <= MAX_BASIS_POINTS, "TOO_LARGE_BURN_AMOUNT_PER_RUN");
        require(msg.sender == VOTING, "MSG_SENDER_MUST_BE_VOTING");

        emit BurnAmountPerRunQuotaChanged(_maxBurnAmountPerRunBasisPoints);

        maxBurnAmountPerRunBasisPoints = _maxBurnAmountPerRunBasisPoints;
    }

    /**
      * @notice BE CAREFUL, the provided slETH will be burnt permanently.
      * @dev only `voting` allowed to call this function.
      *
      * Transfers `_slETH2Burn` slETH tokens from the message sender and irreversibly locks these
      * on the burner contract address. Internally converts `_slETH2Burn` amount into underlying
      * shares amount (`_slETH2BurnAsShares`) and marks the converted amount for burning
      * by increasing the `coverSharesBurnRequested` counter.
      *
      * @param _slETH2Burn slETH tokens to burn
      *
      */
    function requestBurnMySlETHForCover(uint256 _slETH2Burn) external {
        _requestBurnMySlETH(_slETH2Burn, true);
    }

    /**
      * @notice BE CAREFUL, the provided slETH will be burnt permanently.
      * @dev only `voting` allowed to call this function.
      *
      * Transfers `_slETH2Burn` slETH tokens from the message sender and irreversibly locks these
      * on the burner contract address. Internally converts `_slETH2Burn` amount into underlying
      * shares amount (`_slETH2BurnAsShares`) and marks the converted amount for burning
      * by increasing the `nonCoverSharesBurnRequested` counter.
      *
      * @param _slETH2Burn slETH tokens to burn
      *
      */
    function requestBurnMySlETH(uint256 _slETH2Burn) external {
        _requestBurnMySlETH(_slETH2Burn, false);
    }

    /**
      * Transfers the excess slETH amount (e.g. belonging to the burner contract address
      * but not marked for burning) to the LightNode treasury address set upon the
      * contract construction.
      */
    function recoverExcessSlETH() external {
        uint256 excessSlETH = getExcessSlETH();

        if (excessSlETH > 0) {
            uint256 excessSharesAmount = ILightNode(LIGHTNODE).getSharesByPooledEth(excessSlETH);

            emit ExcessSlETHRecovered(msg.sender, excessSlETH, excessSharesAmount);

            require(IERC20(LIGHTNODE).transfer(TREASURY, excessSlETH));
        }
    }

    /**
      * Intentionally deny incoming ether
      */
    receive() external payable {
        revert("INCOMING_ETH_IS_FORBIDDEN");
    }

    /**
      * Transfers a given `_amount` of an ERC20-token (defined by the `_token` contract address)
      * currently belonging to the burner contract address to the LightNode treasury address.
      *
      * @param _token an ERC20-compatible token
      * @param _amount token amount
      */
    function recoverERC20(address _token, uint256 _amount) external {
        require(_amount > 0, "ZERO_RECOVERY_AMOUNT");
        require(_token != LIGHTNODE, "STETH_RECOVER_WRONG_FUNC");

        emit ERC20Recovered(msg.sender, _token, _amount);

        IERC20(_token).safeTransfer(TREASURY, _amount);
    }

    /**
      * Transfers a given token_id of an ERC721-compatible NFT (defined by the token contract address)
      * currently belonging to the burner contract address to the LightNode treasury address.
      *
      * @param _token an ERC721-compatible token
      * @param _tokenId minted token id
      */
    function recoverERC721(address _token, uint256 _tokenId) external {
        emit ERC721Recovered(msg.sender, _token, _tokenId);

        IERC721(_token).transferFrom(address(this), TREASURY, _tokenId);
    }

    /**
     * Enacts cover/non-cover burning requests and logs cover/non-cover shares amount just burnt.
     * Increments `totalCoverSharesBurnt` and `totalNonCoverSharesBurnt` counters.
     * Resets `coverSharesBurnRequested` and `nonCoverSharesBurnRequested` counters to zero.
     * Does nothing if there are no pending burning requests.
     */
    function processOracleReport(uint256, uint256, uint256) external virtual override {
        uint256 memCoverSharesBurnRequested = coverSharesBurnRequested;
        uint256 memNonCoverSharesBurnRequested = nonCoverSharesBurnRequested;

        uint256 burnAmount = memCoverSharesBurnRequested + memNonCoverSharesBurnRequested;

        if (burnAmount == 0) {
            return;
        }

        address oracle = ILightNode(LIGHTNODE).getOracle();

        /**
          * Allow invocation only from `LightNodeOracle` or previously set composite beacon report receiver.
          * The second condition provides a way to use multiple callbacks packed into a single composite container.
          */
        require(
            msg.sender == oracle
            || (msg.sender == IOracle(oracle).getBeaconReportReceiver()),
            "APP_AUTH_FAILED"
        );

        uint256 maxSharesToBurnNow = (ILightNode(LIGHTNODE).getTotalShares() * maxBurnAmountPerRunBasisPoints) / MAX_BASIS_POINTS;

        if (memCoverSharesBurnRequested > 0) {
            uint256 sharesToBurnNowForCover = Math.min(maxSharesToBurnNow, memCoverSharesBurnRequested);

            totalCoverSharesBurnt += sharesToBurnNowForCover;
            uint256 slETHToBurnNowForCover = ILightNode(LIGHTNODE).getPooledEthByShares(sharesToBurnNowForCover);
            emit SlETHBurnt(true /* isCover */, slETHToBurnNowForCover, sharesToBurnNowForCover);

            coverSharesBurnRequested -= sharesToBurnNowForCover;

            // early return if at least one of the conditions is TRUE:
            // - we have reached a capacity per single run already
            // - there are no pending non-cover requests
            if ((sharesToBurnNowForCover == maxSharesToBurnNow) || (memNonCoverSharesBurnRequested == 0)) {
                ILightNode(LIGHTNODE).burnShares(address(this), sharesToBurnNowForCover);
                return;
            }
        }

        // we're here only if memNonCoverSharesBurnRequested > 0
        uint256 sharesToBurnNowForNonCover = Math.min(
            maxSharesToBurnNow - memCoverSharesBurnRequested,
            memNonCoverSharesBurnRequested
        );

        totalNonCoverSharesBurnt += sharesToBurnNowForNonCover;
        uint256 slETHToBurnNowForNonCover = ILightNode(LIGHTNODE).getPooledEthByShares(sharesToBurnNowForNonCover);
        emit SlETHBurnt(false /* isCover */, slETHToBurnNowForNonCover, sharesToBurnNowForNonCover);
        nonCoverSharesBurnRequested -= sharesToBurnNowForNonCover;

        ILightNode(LIGHTNODE).burnShares(address(this), memCoverSharesBurnRequested + sharesToBurnNowForNonCover);
    }

    /**
      * Returns the total cover shares ever burnt.
      */
    function getCoverSharesBurnt() external view virtual override returns (uint256) {
        return totalCoverSharesBurnt;
    }

    /**
      * Returns the total non-cover shares ever burnt.
      */
    function getNonCoverSharesBurnt() external view virtual override returns (uint256) {
        return totalNonCoverSharesBurnt;
    }

    /**
      * Returns the max amount of shares allowed to burn per single run
      */
    function getBurnAmountPerRunQuota() external view returns (uint256) {
        return maxBurnAmountPerRunBasisPoints;
    }

    /**
      * Returns the slETH amount belonging to the burner contract address but not marked for burning.
      */
    function getExcessSlETH() public view returns (uint256)  {
        uint256 sharesBurnRequested = (coverSharesBurnRequested + nonCoverSharesBurnRequested);
        uint256 totalShares = ILightNode(LIGHTNODE).sharesOf(address(this));

        // sanity check, don't revert
        if (totalShares <= sharesBurnRequested) {
            return 0;
        }

        return ILightNode(LIGHTNODE).getPooledEthByShares(totalShares - sharesBurnRequested);
    }

    function supportsInterface(bytes4 _interfaceId) public view virtual override returns (bool) {
        return (
            _interfaceId == type(IBeaconReportReceiver).interfaceId
            || _interfaceId == type(ISelfOwnedSlETHBurner).interfaceId
            || super.supportsInterface(_interfaceId)
        );
    }

    function _requestBurnMySlETH(uint256 _slETH2Burn, bool _isCover) private {
        require(_slETH2Burn > 0, "ZERO_BURN_AMOUNT");
        require(msg.sender == VOTING, "MSG_SENDER_MUST_BE_VOTING");
        require(IERC20(LIGHTNODE).transferFrom(msg.sender, address(this), _slETH2Burn));

        uint256 sharesAmount = ILightNode(LIGHTNODE).getSharesByPooledEth(_slETH2Burn);

        emit SlETHBurnRequested(_isCover, msg.sender, _slETH2Burn, sharesAmount);

        if (_isCover) {
            coverSharesBurnRequested += sharesAmount;
        } else {
            nonCoverSharesBurnRequested += sharesAmount;
        }
    }
}
