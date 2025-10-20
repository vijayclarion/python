# Introduction to Functions

We learned that variables can store values that can be reused later in the program. Functions are even more powerful because they can store entire blocks of code that can be reused multiple times.

Below we are defining a function.
```
def greet():
    print("Hello, world!")
```

Functions are defined using the def keyword followed by the function name and parentheses with a colon ():. The code that belongs to the function must be indented with whitespace. In this case we have just a single line of code that prints "Hello, world!". Functions can have multiple lines of code too, but they can not be empty.

After defining a function, you can use it by typing the name of it followed by parentheses (). This is called calling the function.

```
greet()  # This will print "Hello, world!"
```

This is not so different than how we use built-in functions like print(). We just need to define our own functions before we can use them.

### Challenge
In the code editor, we are calling two functions, greet() and say_goodbye().

* The greet() function is already defined but it has a bug. It should print "Hello, World!".
* The say_goodbye() function is not defined. Define it so that it prints "Goodbye, World!".

```
def greet():
print("Hello, World!")



# don't modify below this line
greet()
say_goodbye()
```

