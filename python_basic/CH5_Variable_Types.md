# Variable Types
So far we've only learned about strings. But variables in Python can hold different types of data, such as integers, decimal numbers (aka floating-point numbers), strings, booleans, lists, and more. You will learn more about these later.
```
age = 25             # integer
temperature = 98.6   # floating-point number
is_true = True       # boolean
name = "Alice"       # string
my_list = [1, 2, 3]  # list
To briefly explain the code above:
```
* A variable is an integer type when it holds a whole number value.
* A variable is a floating-point number type when it holds a decimal number value.
* A variable is a boolean type when it holds a True or False value.
* A variable is a string type when it holds a sequence of characters, inside quotes.
* A variable is a list type when it holds a collection of comma separated values, inside square brackets.

We can print the type of a variable or value using the type() function in Python. For example:
```
print(type(10))
```
This will output:

```
<class 'int'>
```

Challenge
Update the code on the below so that the output is:

```
print(type(integer_type))
print(type(float_type))
print(type(bool_type))
print(type(string_type))
print(type(list_type))

```
```
<class 'int'>
<class 'float'>
<class 'bool'>
<class 'str'>
<class 'list'>
```

Hint: The values themselves don't matter, only the types.

