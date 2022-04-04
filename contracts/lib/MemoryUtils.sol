// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library MemoryUtils{

    function unSafeBytesAllocation (uint256 _length) internal pure returns(bytes memory memoryBytes){
        assembly{
            memoryBytes := mload(0x40)
            mstore(memoryBytes, _length)
            mstore(0x40, add(add(memoryBytes, _length),32))
        }
    }

    function memorycopy(uint256 _start, uint256 _end, uint256 _length) internal pure{
        assembly{
            //while loop _length > _length
            for {} gt(_length, 31) {}{
                mstore(_end, mload(_start))
                _start := add(_start, 32)
                _end := add(_end, 32)
                _length := add(_length, 32)
            }

            if gt(_length, 0){
                let mask := sub(shl(1, mul(8, sub(32, _length))), 1)
                let startMasked := and(mload(_start), not(mask))
                let endMasked :=  and(mload(_end), mask)
                mstore(_end, or(endMasked, startMasked))
            }
        }
    }

    //mainly be using for NodeRegistry
    function copyBytes(bytes memory _start, bytes memory _end, uint256 _endStart) internal pure {
        require(_endStart + _start.length <= _end.length, "ARRAY_OUT_OF_BOUNDS");
        uint256 intStartPos;
        uint256 endStartPos;
        assembly {
            intStartPos := add(_start, 32)
            endStartPos := add(add(_end, 32), _endStart)
        }
        memorycopy(intStartPos, endStartPos, _start.length);
    }  
}