# Evaluating Boolean Expressions

## Evaluating a ```BoolExpr```

Evaluating a ```BoolExpr``` is as simple as calling a function.

```Lua
do
    local expression = BoolExpr.Xor(
        function ()
            print("true")
            return true
        end,
        function ()
            print("false")
            return false
        end
    )

    print("XOR Result: " .. (expression() and "true" or "false")) -- evaluate expression
end
```

Output:
> true
>
> false
>
> XOR Result: true

<br/>

## Evaluating a BoolExpr Table

A BoolExpr Table does not have ```BoolExpr``` as its metatable so you cannot call the table directly as done above. It's also ugly to call ```__call``` with a dot notation either so you can instead use ```evaluate()```.

```Lua
do
    local expression =
    {
        BoolExpr.XOR,
        function ()
            print("true")
            return true
        end,
        function ()
            print("false")
            return false
        end
    }

    print("XOR Result: " .. (BoolExpr.evaluate(expression) and "true" or "false")) -- evaluate expression
end
```

Output:
> true
>
> false
>
> XOR Result: true
