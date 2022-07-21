// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
  * @title Interface defining a callback that the quorum will call on every quorum reached
  */
interface IBeaconReportReceiver {
    /**
      * @notice Callback to be called by the oracle contract upon the quorum is reached
      * @param _postTotalPooledEther total pooled ether on LightNode right after the quorum value was reported
      * @param _preTotalPooledEther total pooled ether on LightNode right before the quorum value was reported
      * @param _timeElapsed time elapsed in seconds between the last and the previous quorum
      */
    function processOracleReport(
      uint256 _postTotalPooledEther, 
      uint256 _preTotalPooledEther, 
      uint256 _timeElapsed
    ) external;
}
