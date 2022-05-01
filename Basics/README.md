# Basics of EVM

This write-up assumes that you have a basic understanding of Solidity or any other high level language and you know what Ethereum is. If you don't know either, you should consider learning about them first.

## The EVM Environment

The EVM (Ethereum Virtual Machine) is the computation engine of the Ethereum Blockchain. It is capable of executing EVM bytecode, which enables Ethereum to run smart contracts - unlike Bitcoin.

The EVM bytecode is a series of hex codes. It looks something like this:

```bytecode
343d52593df3 // You may also see bytecodes starting with 0x
```

### Hex, Byte, Bit, and Binary

If you're not familiar with the terms hex, bytes, and bits, here's a quick explanation.

There are different formats to represent numbers. In our daily lives, we use base-10 to indicate numbers, which means that numbers are composed of digits between 0 to 10. Base 2 is composed of digits 0 and 1, binary. On the other hand, base 16 is composed of digits 0 to 10 and a, b, c, d, e, f.

Throughout the course of history, civilizations used different numeral systems. Mayans used [base-20](https://en.wikipedia.org/wiki/Maya_numerals), Sumerians used [base-60](https://en.wikipedia.org/wiki/Sexagesimal), and so on. Today, we use base-10, probably because we have ten fingers.

As you probably know, computers use the base-2 (binary) numeral system. Before you understand how the EVM works, it is important that you know how base-16 and base-2 can be converted to base-10.

![Binary to Decimal](https://www.w3resource.com/w3r_images/javascript-math-image-exercise-2.svg)

The digit number is raised to the power of 2 and multiplied with the number in place of the digit. The rightmost digit's location is zero, and the leftmost digit's location is 7.

You can represent literally any number using the binary format. However, if you want to represent greater numbers, you have to use more digits (just like in any other numeral system). There is an easy formula to calculate the maximum number you can represent using X number of digits. 

With three binary digits, the biggest number you can write is 111 (in base 2). If you convert this to decimals, you get 7.

With four binary digits, the biggest number you can write is 1111. In decimals, it is 15.

The maximum number you can write using X digits is 2^x - 1. With six digits, the maximum number you can write is 2 ^ 6 - 1, which is 63. (111111 = 63).


### The EVM Environment

The EVM is only capable of executing the EVM bytecode. It doesn't recognize Solidity, Vyper, or any other high-level language. So how do developers write smart contracts in Solidity?
