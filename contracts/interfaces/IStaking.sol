// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IStaking {
    function depositEth1() external payable;

    function setOwner(address _newOwner) external;

    function setDevAddress(address _newDevAddress) external;

    function stillStaking() external view returns (bool);

    // function balanceOf(address _user) external view returns (uint256);

    function totalSupply() external view returns (uint256);

    function pushBeacon(uint256 epoch, uint256 eth2Bal) external;

    function getTotalShares() external view returns (uint256);

    function receiveELRewards() external payable;
}
