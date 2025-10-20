# Shorthand Operators

It's very common to increment or decrement a variable by a certain value. Consider the following code:
```
count = 0
count = count + 1
count = count + 2
print(count)  # Output: 3
```

It will run how we would expect. First it will add 1 to the count, and next add 2 to the count.

However, Python has shorthand operators that allow you to perform the same operation in a more concise way. These are called in-place operators. Here is the same code using the shorthand:
```
count = 0
count += 1
count += 2
print(count)  # Output: 3
```

The += operator is shorthand for count = count + . The other arithmetic operators have similar shorthand operators:

* -= is shorthand for count = count -
* *= is shorthand for count = count *
* /= is shorthand for count = count /
* %= is shorthand for count = count %
* //= is shorthand for count = count //
* *= is shorthand for count = count **

You are not necessarily required to use these shorthand operators, but you will almost certainly see += and -= in Python code that you come across.

### Challenge
In the code editor there is a variable called number. Use the shorthand operators to:

```
number = 0
```

* Add 5 to number and print the result.
* Subtract 2 from number and print the result.
* Add number to itself and print the result. (Yes, you can add a variable to itself.)