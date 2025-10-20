#Reassigning Variables
We mentioned earlier that two variables can not have the same name. So what do you think the following code will do?
```
message = "The first message"
message = "The second message"
print(message)
```
The output is:
```
The second message
```
This is because variables can change their value. This is called reassigning a variable. message was first assigned the value "The first message", but then it was reassigned the value "The second message".

If we had reordered the statements like this:
```
message = "The first message"
print(message)
message = "The second message"
```
The output would be:
```
The first message
```
This is because the value of message was printed before it was reassigned.

Challenge
Can you add a single line of code on below to print the following output:
```
message = "The first message"

print(message)

print(message)

message = "The third message"

print(message)
```
Output 

```
The first message
The second message
The third message
```
