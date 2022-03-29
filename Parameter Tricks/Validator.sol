// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

contract Validator {
    event Validation(bytes32 _msg, uint8 v, bytes32 r, bytes32 s, address addr);

    function validateSignature(
        bytes32 _msg,
        uint8 v,
        bytes32 r,
        bytes32 s,
        address _addr
    ) external returns (bool) {
        emit Validation(_msg, v, r, s, _addr);
        return ecrecover(_msg, v, r, s) == _addr;
    }

    function validateSignature() external returns (bool) {
        bytes32 _msg;
        uint8 v;
        bytes32 r;
        bytes32 s;
        address addr;

        assembly {
            _msg := calldataload(4) // Load 32 bytes skipping the function selector (4 bytes).
            v := shr(248, calldataload(36)) // Load calldata skipping the first 32 bytes, shift right by 256 - 8 = 248 bits.
            r := calldataload(37) // We know that uint8 is 1 byte, so load calldata starting from position 4 + 32 + 1 = 37.
            s := calldataload(69) // Skip 32 bytes of the previously loaded data, 37 + 32 = 69.
            addr := shr(96, calldataload(101)) // Shift right by 256 - 160 = 96 bits. (Addresses are 20 bytes, 160 bits).
        }

        require(
            addr != address(0),
            "Validator::validateSignature: Invalid params!"
        );

        emit Validation(_msg, v, r, s, addr);

        return ecrecover(_msg, v, r, s) == addr;
    }

    fallback() external {
        bytes32 _msg;
        uint8 v;
        bytes32 r;
        bytes32 s;
        address addr;

        assembly {
            _msg := calldataload(0x00) // Load the first 32 bytes. No need to skip function selector, because there shouldn't be any.
            v := shr(248, calldataload(32)) // Load calldata skipping the first 32 bytes, shift right by 256 - 8 = 248 bits.
            r := calldataload(33) // We know that uint8 is 1 byte, so load calldata starting from position 32 + 1 = 33.
            s := calldataload(65) // Skip 32 bytes of the previously loaded data, 33 + 32 = 65.
            addr := shr(96, calldataload(97)) // Shift right by 256 - 160 = 96 bits. (Addresses are 20 bytes, 160 bits).
        }

        require(
            addr != address(0),
            "Validator::validateSignature: Invalid params!"
        );

        emit Validation(_msg, v, r, s, addr);

        bool result = ecrecover(_msg, v, r, s) == addr;

        // Can't return directly using return, because:
        // Fallback function either has to have the signature "fallback()" or "fallback(bytes calldata) returns (bytes memory)".
        assembly {
            mstore(0x00, result)
            return(0x00, 32)
        }
    }

    // This exists in case someone wants to call directly from somewhere like Etherscan.
    function callutil(bytes memory _data) external returns (bool) {
        (bool success, bytes memory result) = address(this).call(_data);
        require(success, "Validator:callutil:: Invalid params");
        return abi.decode(result, (bool));
    }
}
