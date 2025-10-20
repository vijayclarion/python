# Global vs Local Scope
Here are a few more examples illustrating scope in Python:
```
def declare_variable() -> None:
    inside_function_only = 10
    return

declare_variable()
print(inside_function_only) # This will raise a NameError
```

In the code above, the variable inside_function_only is declared inside the function declare_variable. This variable has a local scope and is only accessible within the function. Attempting to access it outside the function will result in a NameError.
```
n = 10

def print_global_variable() -> None:
    print(n)

print_global_variable() # This will print 10
```

In the code above, the variable n is declared outside the function print_global_variable. This variable has a global scope, since it's not within a function, and can be accessed from anywhere in the program, including inside functions.

Note: We saw earlier, that if the function has a parameter with the same name as a global variable, the function will use the local variable instead of the global variable.

### Global Scope:

* Variables declared outside of any function have a global scope.
* They can be accessed from anywhere in the program, including inside functions.

### Local Scope:

* Variables declared within a function have a local scope.
* They can only be accessed within the function in which they are defined.
* Local variables are created when the function is called and destroyed when the function exits.

### Challenge
There's a bug in the code on the right, if you try to run it you'll see a NameError. Can you fix it so that the output is:

* 100
* 100
```
n = 100

def print_local_variable(num: int) -> None:
    print(num)

print_local_variable(n)

print(num)
```