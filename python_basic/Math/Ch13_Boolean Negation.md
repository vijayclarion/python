# Boolean Negation

There is yet another keyword in Python, called not, that is used to perform a logical NOT operation, also known as negation.

It's the simplest of the three logical operators. It simply inverts the value of the operand. If the operand is True, the result is False. If the operand is False, the result is True.
```
a = True
b = False
print(not a)  # Output: False
print(not b)  # Output: True
```

We can also use the operators in combination. For example, we can negate the result of an AND operation:

```
a, b = True, False
print(not (a and b))  # Output: True
```

First the AND operation is performed, which results in False. Then the NOT operation is performed on the result, which results in True.

### Challenge
In the code editor, there are 3 variables, a, b, and c. 
```
a, b, c = False, False, True
```

Print the following:

The negation of a.
The negation of c.
The negation of the logical AND of a and b.
The negation of the logical OR of b and c.

### What are the order of operations?
All logical operators have a specific order of operations. The order of operations for logical operators is NOT, AND, OR. This means that NOT is always performed first, then AND, and finally OR.

That said, as expressions grow larger, it's best to use parentheses to make the order of operations clear. This prevents unintended bugs and makes code more readable for others.