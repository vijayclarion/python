# Multiple Parameters

Functions can be defined to accept more than one parameter. The parameters are separated by commas in the function definition. When calling the function, the arguments are also separated by commas.

```
def greet(name, greeting):
    message = greeting + " " + name
    print(message)

greet("Alice", "Hello")  # This will print "Hello Alice"
```

Notice how we concatenate three strings together (greeting, " ", and name) using the + operator. This allows us to combine the strings into one message.

### Challenge
In the code editor, define two functions, two_sum, and three_sum. The two_sum function should take two parameters and print their sum. The three_sum function should take three parameters and print their sum.


Finally, call two_sum with the arguments 7, 10 and after that call three_sum with the arguments 3, 5, 8.

```




# do not modify below this line
two_sum(10, 9)
three_sum(5, 14, 6)

```