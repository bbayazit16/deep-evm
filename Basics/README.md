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

In Solidity and many other high-level smart contract languages, you can see the use of type uint256. Uint256 is the biggest number you can use in the EVM. It is capable of storing 256 bits (32 bytes). Uint256's max value is 2^256 - 1, which is 1.1579209e+77.

### Hex

There is also another numeral system, as seen in bytecodes. It is called the hexadecimal format (base-16), or often just hex in short. Hexadecimal numbers consist of digits 0-9 and letters a, b, c, d, e, f. A is used as 10, b 11, c 12, d 13, e 14 and f 15. As you may have noticed, Ethereum addresses are formatted in hexadecimal. They only have hexadecimal digits, which means that Ethereum addresses are actually just big numbers 🤯.

Bytecodes are hex too! This means that all smart contracts are actually just HUGE numbers 🤯 (but they don't work that way).

![Hexadecimal to Decimal](https://media.geeksforgeeks.org/wp-content/uploads/hexaTodeci.png)

Hexadecimal works just like binary, with one minor difference: Instead of raising to the power of 2, numbers ar raised to the power of 16.

## The Use Of Bytecode in the EVM

The EVM is only capable of executing the EVM bytecode. It doesn't recognize Solidity, Vyper, or any other high-level language. So how do developers write smart contracts in Solidity?
