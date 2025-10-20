# Function Declaration

Similar to how variables must be declared before they can be used, functions must also be defined before they can be called.
```
print(n) # error because n is not defined yet
n = 10 


print_number(5) # error because the function print_number is not defined yet

def print_number(n):
    print(n)
```

### Challenge

There is a bug in the code on the below. 
```
print_number(10)
print_number(20)

def print_number(n):
    print(n)
```

Can you fix it so that the output is:

* 10
* 20
