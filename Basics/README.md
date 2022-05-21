# Basics of the EVM

This write-up assumes that you have a basic understanding of Solidity or any other high level language and you know what Ethereum is. If you don't know either, you should consider learning about them first.

## Hex, Byte, Bit, and Binary

If you're not familiar with the terms hex, bytes, and bits, here's a quick explanation.

There are different formats to represent numbers. In our daily lives, we use base-10 to indicate numbers, which means that numbers are composed of digits between 0 to 10. Base 2 is composed of digits 0 and 1, binary. On the other hand, base 16 is composed of digits 0 to 10 and a, b, c, d, e, f. Base 3 is composed of 0, 1, 2 and so on...

Over the history civilizations used various numeral systems. Mayans used [base-20](https://en.wikipedia.org/wiki/Maya_numerals), Sumerians used [base-60](https://en.wikipedia.org/wiki/Sexagesimal), and so on. Today, we use base-10, probably because we have ten fingers.

### Binary

As you probably know, computers use the base-2 (binary) numeral system. Before you understand how the EVM works, it is important that you know how base-16 and base-2 can be converted to base-10.

![Binary to Decimal](https://www.w3resource.com/w3r_images/javascript-math-image-exercise-2.svg)

The digit number is raised to the power of 2 and multiplied with the number in place of the digit. The rightmost digit's location is zero, and the leftmost digit's location is 7.

Actually, when you think of it, the numbers in our daily lives work with the same logic. 128, for instance, is 10 x 10^2 + 2 x 10^1 + 8 x 10^0 => 100 + 20 + 8 = 128.

Each digit in binary is called a bit, and every 8 bits are called a byte.

You can represent literally any number using the binary format. However, if you want to represent greater numbers, you have to use more digits (just like in any other numeral system). There is an easy formula to calculate the maximum number you can represent using X number of bits.

With three bits, the biggest number you can write is 111 (in binary). If you convert this to base-10, you get 7.

With four bits, the biggest number you can write is 1111. In base-10, it is 15.

The maximum number you can write using X bits is 2^x - 1, where x is the number of bits. With six bits, the maximum number you can write is 2^6 - 1, which is 63. (111111 = 63).

In Solidity and many other high-level smart contract languages, you can see the use of type uint256. It is capable of storing 256 bits (32 bytes), hence the name uint<256>. Uint256 is the biggest number you can use in the EVM. The max value of uint256 is 2^256 - 1, which is 1.1579209e+77.

### Hex

There is also another numeral system, as seen in bytecodes. It is called the hexadecimal format (base-16), or often just hex in short. Hexadecimal numbers consist of digits 0-9 and letters a, b, c, d, e, f. A is used as 10, b 11, c 12, d 13, e 14 and f 15. As you may have noticed, Ethereum addresses are formatted in hexadecimal. They only have hexadecimal digits, which means that Ethereum addresses are actually just big numbers 🤯.

Bytecodes are hex too! This means that all smart contracts are actually just HUGE numbers 🤯 (but that number is meaningless).

![Hexadecimal to Decimal](https://media.geeksforgeeks.org/wp-content/uploads/hexaTodeci.png)

Hexadecimal works just like binary, with one minor difference: Instead of raising to the power of 2, numbers ar raised to the power of 16.

You can also see some hexadecimal numbers starting with the 0x prefix. All it does is indicating that the given number is formatted in hex, nothing else. It is redundant and can be removed.

To understand hex better, you should try converting a few numbers using [this website](https://www.rapidtables.com/convert/number/hex-to-decimal.html).

## The Bytecode

The EVM (Ethereum Virtual Machine) is the computation engine of the Ethereum Blockchain. It is capable of executing EVM bytecode, which enables Ethereum to run smart contracts - unlike Bitcoin.

The EVM bytecode is a series of hex codes. It looks something like this, in hexadecimal:

```bytecode
343d52593df3
```

When you write a smart contract in Solidity, your code compiles down to a long bytecode. This bytecode is then deployed to the chain. The EVM is only capable of executing the EVM bytecode, it doesn't recognize the high level Vyper or Solidity languages.

The EVM is turing complete (with the assumption that gas is *unlimited*), which basically means you can simulate a turing machine (compute any algorithm, in simple terms).

Every byte (2 hexes) in the bytecode corresponds to one opcode (with the exception of the hard-coded push values, which we'll get into later). You don't have to memorize the corresponding operations for each byte to be a good developer. Just understanding what each operation does is enough. In order to better understand what each operation does, you should spend some time on [evm.codes](https://www.evm.codes/)! They provide explanations and a playground for each function.

Let's break down a bytecooed to opcodes. For example:

343d52593df3 => 34, 3d, 52, 59, 3d, f3 => CALLVALUE, RETURNDATASIZE, MSTORE, MSIZE, RETURNDATASIZE, RETURN.

These operations are simply functions, and their specification can all be found in the [Ethereum Yellow Paper, starting from page 30](https://ethereum.github.io/yellowpaper/paper.pdf).

Each operation does something, either manipulates the stack, the memory, or the state of the EVM. In these tutorials, I'll aim to explain every operation and how they work.

## How The Bytecode is Executed

### Storage

Storage in the EVM can be divided into four locations:

- The code, which can't be changed after deployed.
- The stack, where temporary values can be pushed / popped.
- The memory, where temporary values can be set.
- The world chain state and global state, which contains information such as the block number, sender, tx calldata...

#### The Code

The bytecode deployed to Ethereum is immmutable, it can't be changed once deployed. Although code can be destroyed with selfdestruct, there are plans to deactivate selfdestruct in [EIP-4758.](https://eips.ethereum.org/EIPS/eip-4758)

#### The Stack

The EVM has a stack-based architecture. But what is a stack?

Think of a pile of books.

<img src="https://media.wired.com/photos/5be4cd03db23f3775e466767/master/pass/books-521812297.jpg" alt="A pile of books" width="128" height="128">

If you want to take the second book from top, you would have to remove the topmost book first.
If you want to create a pile of books, the first book you put on the desk would be the last book in the pile, the one in the lowest position. The last book you put would be the topmost book.

This is basically how a stack works, except the books are variables.

This principle is called "last in, first out", or LIFO in short. The last element placed on the stack is the first element that is removed.

![The stack](https://cdn.programiz.com/sites/tutorial2program/files/stack.png)
