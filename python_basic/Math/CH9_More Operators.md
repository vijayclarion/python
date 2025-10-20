More Operators
There are a few more operators in Python that are commonly used in arithmetic operations:

* Floor Division //: Divides the first operand by the second and rounds down the result to an integer.
* Modulus %: Returns the remainder of the division of the first operand by the second.
* Exponentiation **: Raises the first operand to the power of the second operand.

Here is an example of each:
```
x, y = 7, 2

print(x // y) # Output: 3  (7 divided by 2 is 3.5, after rounding down we get 3)

print(x % y)  # Output: 1  (7 divided by 2 is 3, with a remainder of 1)

print(x ** y) # Output: 49 (7 raised to the power of 2 is 49, 7*7 = 49)
```

### Challenge
You are given three variables, a, b, and c. Print the following numbers in order:
```
a, b, c = 2, 8, 5
```

* The product of a and b, floor divided by c
* The remainder of the product of a and b divided by c
* The result of raising a to the power of b.
* The result of raising b to the power of c.