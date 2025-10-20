# Arithmetic Operators
Arithmetic operators are used to perform mathematical operations like addition, subtraction, multiplication, division, and more.

* Addition +: Adds two operands together.
* Subtraction -: Subtracts the second operand from the first.
* Multiplication *: Multiplies two operands.
* Division /: Divides the first operand by the second. The result is always a float.
x, y = 3, 6
```
print(x + y) # Output: 9

print(x - y) # Output: -3

print(x * y) # Output: 18

print(x / y) # Output: 0.5
```

If we divide y by x, the result will be 2.0 and not 2. This is because the result of division is always a float in Python.

For the other arithmetic operators, the result will be an integer if both operands are integers. If one of the operands is a float, the result will be a float.

## What about order of operations?
The order of operations in Python is the same as in mathematics. The acronym PEMDAS can help you remember the order:

* Parentheses
* Exponents
* Multiplication and Division (from left to right)
* Addition and Subtraction (from left to right)

For example, in the expression 2 + 3 * 4, the multiplication is done first, then the addition. The result is 14.

To specify the order of operations, you can use parentheses. For example, (2 + 3) * 4 will result in 20.

Challenge
In the code editor, there are some integers and floats declared. Print the following in order:
```
a, b, c = 2, 2, 0.5
```
* The sum of the values (addition)
* 0 minus the sum of the values
* The product of the values (multiplication)
* The sum of the values divided by the product of the values

Hint: You are free to declare additional variables if it's helpful.