# Printing Text
Earlier we printed Hello, world! to the console.
```
print("Hello, world!")
```

You may have noticed that we used double quotes "" around the text. This is known as a string in programming. Most languages use double quotes to define a string.

A string is just a sequence of characters between the opening and closing quotes.

But what if we wanted to print a string that also contains quote characters? For example, how would the Python interpreter know where the following string ends?

```
print("They said, "Hello, world!"")
```

This code will cause an error. Python thinks we have a string "They said, ", followed by Hello, world!, which is outside of the quotes (not apart of the string).

One possible solution to this is to use a backslash \, aka the escape character, before each quote character inside the string.

print("They said, \"Hello, world!\"")
This tells Python we want to interpret the quote " as a character inside the string, not as a quote that ends the string.

Challenge
Your task is to correct the code in the code editor to print the following text to the console:

```
My favorite quote is "To be or not to be."
```