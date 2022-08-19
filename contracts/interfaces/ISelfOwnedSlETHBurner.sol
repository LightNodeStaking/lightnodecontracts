// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
  * @title Interface defining a "client-side" of the `SelfOwnedSlETHBurner` contract.
  */
interface ISelfOwnedSlETHBurner {
    /**
      * Returns the total cover shares ever burnt.
      */
    function getCoverSharesBurnt() external view returns (uint256);

    /**
      * Returns the total non-cover shares ever burnt.
      */
    function getNonCoverSharesBurnt() external view returns (uint256);
}
