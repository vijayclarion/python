# Parameters

You may have noticed that when we call the print() function, we put variables and strings inside of the parentheses. That's because a function can be defined with parameters.
```
def greet(name):
    msg = "Hello, " + name
    print(msg)

greet("Alice")  # This will print "Hello, Alice"
```

In the above code, we defined a function called greet that takes a parameter called name. We call the function by passing in "Alice" as the argument. Inside the function, we concatenate the string "Hello, " with the name parameter (we can combine strings with the + operator). We then print the result.

The power of parameters is that we can pass different values to the function and get different results. This allows us to reuse code without having to type it all out from scratch each time.

When calling a function, you can pass values, variables, or expressions as arguments to the function.

### Challenge
In the code editor, define a function called farewell, which takes a single parameter. The function should print "Goodbye, " followed by the parameter. Then use this function so that the output is:

Goodbye, Bob
Goodbye, Charlie
Goodbye, NeetCode



```


# don't modify below this line
farewell("NeetCode")
```