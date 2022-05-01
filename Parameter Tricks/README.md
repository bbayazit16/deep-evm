# Taking Parameters Without Function Parameters

Keep in mind that:

- 1 byte = 2 hex characters
- 1 byte = 8 bits

To take function parameters in Solidity, one would usually do:

```solidity
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
```

This function takes:

- 32 bytes \_msg
- uint8 (1 byte) v
- 32 bytes r
- 32 bytes s
- 20 bytes address

- Total: 117 bytes

So the calldata should technically be 117 bytes, right? It is 164 bytes.

## Why?

Let's examine the calldata:

```bytecode
0xaf1d06e83438e7f69dbe1b418705d87b2d75c1447939ed1a7c7eedc4ff4ba87739ed93e4000000000000000000000000000000000000000000000000000000000000001c05fd9519cf69e4cf6e9d9c456d22aceea8e67681f514dffc8836560f4bcd540a36f3572a1fde84e5e704c4c096dda84e8cf7766fa9a08067f82ec811b71d3fec0000000000000000000000000000018014a365cfc1ac5020b84b24678fc6af55
```

The first 4 bytes of Ethereum transactions are often the function signature. The remaining are function parameters, which are usually zero-padded to 32 bytes, meaning that zero's are added to the beginning if the value is less than 32 bytes. That explains the consecutive zeros in our calldata.

If the value is a byte-type (bytes8, bytes16...), zero's are added to the end and not the beginning.

```solidity
[0] = af1d06e8
4 bytes function selector, which is the first 4 bytes of keccak256 hash of validateSignature(bytes32,uint8,bytes32,bytes32,address). (so first 8 hexes excluding 0x.)

[1] = 3438e7f69dbe1b418705d87b2d75c1447939ed1a7c7eedc4ff4ba87739ed93e4
32 bytes _msg. Notice that no zeros are added to the beginning, because the value is already 32 bytes.

[2] = 000000000000000000000000000000000000000000000000000000000000001c
1 byte hex v value, (1c = 28). Because the value is less than 32 bytes, it is padded to 32 bytes.

[3] = 05fd9519cf69e4cf6e9d9c456d22aceea8e67681f514dffc8836560f4bcd540a
32 bytes r value. No zero-padding.

[4] = 36f3572a1fde84e5e704c4c096dda84e8cf7766fa9a08067f82ec811b71d3fec
32 bytes s value. Again no zero-padding.

[5] = 0000000000000000000000000000018014a365cfc1ac5020b84b24678fc6af55
20 bytes address. (0x0000018014A365Cfc1aC5020B84B24678Fc6af55). Padded to 32 bytes.
```

In total, there are 86 additional zeros, 43 bytes, that should not be a part of function parameters.

## Math Checks Up

Our variables in total were supposed to be 117 bytes. Our calldata is 164 bytes (328 hexes). 164 - 117 - 4 (function signature) = 43 bytes extra, which is equal to the number of additional zeros added to the calldata.

Currently, the calldata cost is 16 gas for each non-zero byte (0x00) and 4 gas for every zero bytes. This means 43 \* 4 = 172 gas extra calldata cost spent to zero's.

## Quick History of Calldata Costs

Previously before the Istanbul hard fork, calldata cost for non-zero bytes was 68 gas. It was reduced to 16 with [EIP-2028](https://eips.ethereum.org/EIPS/eip-2028).

One cool proposal yet to be integrated is [EIP-4488](https://eips.ethereum.org/EIPS/eip-4488), which plans to reduce calldata cost from 16 gas to 3 gas regardless of whether the byte is zero or nonzero. This would make calldata costs around 5x cheaper while increasing the [maximum block size](https://etherscan.io/chart/blocksize) (not a good thing).

## Reducing Calldata Size

One thing MEV bots and L2 Ethereum contracts do is take inputs directly using assembly. By doing this, they avoid leading and trailing zeros, thus reducing calldata costs.

To understand how they do it, we should first understand two opcodes:

```CALLDATALOAD(offset)```: Load 32 bytes from calldata starting from `offset`.  
```SHR(shift, value)```: Shift `value` right by amount `shift`. Simply put, logical right shift operation.
```SHL(shift, value)```: Shift `value` left by amount `shift`. Simply put, left shift operation.

## Theory

Suppose we have the following calldata:
`aaaaaaaa22bd44f12d37856d0414f143bee7668e1ac3bedec297d1d321451c6b2efd6b13aaaaaaaaaaaaaaaaaaaaaaaa`

```solidity
calldataload(0x4)
```

would load the first 32 bytes from calldata into memory, skipping the first 4 bytes:
`22bd44f12d37856d0414f143bee7668e1ac3bedec297d1d321451c6b2efd6b13`

This leaves us with a value that is 32 bytes, 64 hexes, 256 bits.

If we want to extract, let's say `22bd44f12d37856d` (8 bytes, 16 hexes, 32 bits) from the calldata, we can right-shift the loaded calldata by 256 - 32 = 224 bits.

```solidity
shr(224, calldataload(4))
```

which leaves us with:
`0x0000000000000000000000000000000000000000000000000000000022bd44f1`, which is 582829297.

On the other hand, if we want to extract the last 32 bits, we can do:

```solidity
shl(224, calldataload(4))
```

which results in:
`0x2efd6b1300000000000000000000000000000000000000000000000000000000`, which is something along the lines of 2.12e29. Although in most cases, you would want to use logical right shift to extract the parameters.

Using this method, we can extract the parameters from the calldata manually, removing the need for zero-padding thus creating more efficient contracts (while reducing readability).

## Implementation

```solidity
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
```

The check for

```solidity
addr != address(0)
```

is crucial. This check prevents empty variables from being passed into ecrecover(), which would result in true.

Using this method, we can add our parameters consecutively to calldata, without any zero padding.

```bytecode
0x146368693438e7f69dbe1b418705d87b2d75c1447939ed1a7c7eedc4ff4ba87739ed93e41c05fd9519cf69e4cf6e9d9c456d22aceea8e67681f514dffc8836560f4bcd540a36f3572a1fde84e5e704c4c096dda84e8cf7766fa9a08067f82ec811b71d3fec0000018014A365Cfc1aC5020B84B24678Fc6af55
```

Now our calldata is 121 bytes. Keep in mind that we still have to add the 4-byte function selector (14636869) but there's a way to remove that.

## Fallback Function

By using the fallback function, we can omit the first 4 bytes (function selector) and return the result using assembly.

```solidity
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
```

If you remove the 4-byte function selector from calldata and call this contract, you'll see that you get the exact same output, but slightly cheaper.

If you want to implement more than one function inside fallback, you have to add an extra function selector of your choice and detect it using a switch statement.

## Going Even Further

Now that we have almost coded the entire thing in assembly, we might as well write it in pure opcodes.

If you want to dive deep into EVM bytecode, or EVM in general, [evm.codes](https://evm.codes/) is just the right website. In addition to summarizing each EVM opcode, [evm.codes](https://evm.codes/) also provides a playground.

Remember: stack machines follow LIFO principle. Last in, first out. The item on top of the stack is passed as the first argument to the opcode. So, if you want to do ```div(9, 3)``` your stack should look like this:

```solidity
9    <---- Correct  Incorrect ---->    3
3                                      9
```

This means that we should PUSH the last parameters first.

```solidity
PUSH1 3
PUSH1 9
DIV
// 3 on stack.
```

Before we start coding, I want to explain a few opcodes:

- ```PUSH1 0x40``` Pushes 1 byte on the stack. PUSH2 pushes 2 bytes, PUSH3 pushes 3 bytes and so on. Each PUSH opcode costs 3 gas.
- ```CALLVALUE``` Pushes the value of Ether sent to the contract on top of the stack. This opcode costs 2 gas.

One trick is using CALLVALUE to push 0 on top of the stack. This will be 1 gas cheaper, and will be the same thing as long as there is no Ether sent to the contract. In our case, we don't verify function to be paid anyways, so we're good to go. You may also use ```RETURNDATASIZE``` instead of CALLVALUE. (Keep in mind that RETURNDATASIZE changes after your contract makes an external call. Our contract uses ecrecover, which is technically a call to another contract, hence why I used CALLVALUE. I'll be explaining why ecreover is an external call later.)

I recommend you follow along with the upcoming opcodes using run & step button [here.](https://tinyurl.com/29r9aps2)

Lets start:

```solidity
CALLVALUE // Push 0 on stack.
CALLDATALOAD // Load calldata onto stack.
CALLVALUE // Push 0 on to stack.
MSTORE // Store calldata on memory.

// Identical to: mstore(0x00, calldataload(0x00)).
```

Next:

```solidity
PUSH1 32
CALLDATALOAD
PUSH1 248    // mstore(32, shr(248, calldataload(32)))
SHR
PUSH1 32
MSTORE

PUSH1 33
CALLDATALOAD    // mstore(64, calldataload(33)))
PUSH1 64
MSTORE

PUSH1 65
CALLDATALOAD   // mstore(96, calldataload(65)))
PUSH1 96
MSTORE
```

Next comes ecrecover(). The EVM offers advanced functionalities using precompiled contracts. Each precompiled contract has a specific address along with a specific functionality. Ecrecover lies on address 0x01, which means calling 0x01 will perform ecrecover() operation. The whole list of precompiled contracts with their addresses can be found [here.](https://www.evm.codes/precompiled)

```solidity
PUSH1 0x20 // Return size (32 bytes). Returned value is actually an address (20 bytes), but ecrecover returns "address right-aligned to 32 bytes".
CALLVALUE // Return offset in memory (0x00).
MSIZE // Arguments size (128). 
CALLVALUE // From which place in memory our args begin. (0x00).
PUSH1 1 // Address of ecreover(). If you're deploying on Ethereum mainnet, you can use CHAINID.
PUSH2 3000 // ECRECOVER() costs 3000 gas.
STATICCALL // Call without modifying data. This is similar to calling a view/pure function from a different contract in Solidity.

// Identical to: staticcall(3000, 0x01, 0x00, 0x80, 0x00, 0x20).
```

```solidity
POP // If the input data sent to the contract was valid, the call should be successful hence 1 is pushed on top of the stack. Pop removes staticcall() return value.
CALLVALUE // Push 0x00.
MLOAD // mload(0x00).
```

```solidity
PUSH1 97
CALLDATALOAD // shr(96, calldataload(97)) to extract input address from calldata.
PUSH1 96
SHR
````

Finally:

```solidity
EQ // == (equals). Pushes 1 on stack if inputs are equal else 0.
RETURNDATASIZE // Push 0x20 on stack.
MSTORE
// mstore(0x20, eq(ecrecover_result, input_address)).

RETURNDATASIZE // PUSH1 0x20.
RETURNDATASIZE // PUSH1 0x20.
RETURN // return(0x20, 0x20)
```

This contract is written in pure bytecode. It can also take inputs without zero-padding. However it is possible to shorten the byte-size of this contract (at the cost of extra gas). [Here](https://tinyurl.com/ycyhy7ep) I have prepared a differrent version of the bytecode which uses calldatacopy to reduce the contract bytecode size. This version however requires input data to be zero-padded which means it costs 141 more gas compared to the former bytecode despite being smaller in size.

## Gas Costs (With Events Removed)

- With Function Parameters: 27,002 gas.
- Without Function Parameters: 26,590 gas.
- Callback: 26,470 gas.
- Bytecode Not-Zero-Padded: 26,058 gas.
- Bytecode (Zero-Padded): 26,199 gas.

Is it worth it? You decide!

## Applications

[Libevm - Subway](https://github.com/libevm/subway/blob/8ea4e86c65ad76801c72c681138b0a150f7e2dbd/contracts/src/Sandwich.sol#L67) A gas efficient MEV sandwich bot that directly reads from the calldata in fallback.

[Optimism - appendSequencerBatch()](https://github.com/ethereum-optimism/optimism/blob/6a839b186701a6821cad1da630504b71d08b9956/packages/contracts/contracts/L1/rollup/CanonicalTransactionChain.sol#L290) Optimism (previously Optimistic Ethereum) L2 Canonical Transaction Chain contract.  
[Example transaction](https://etherscan.io/tx/0x540facb7543b8f20839eccb9f68f62714e3e45104a3fc64985e82f111b54e9ac)
