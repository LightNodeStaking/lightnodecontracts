// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../Oracle/Oracle.sol";

/**
  * @dev Only for testing purposes!
  */
contract OracleMock is Oracle {
    uint256 private time;

    function setTime(uint256 _time) public {
        time = _time;
    }

    function _getTime() internal view override returns (uint256) {
        return time;
    }
}
