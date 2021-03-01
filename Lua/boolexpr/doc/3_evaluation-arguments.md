# Expression Evaluation Arguments

## Evaluation Arguments

```Lua
do
    local expression = BoolExpr.Any(
        function ()
            return nil
        end
    )

    expression(1, 2, 3)
end
```

## Expression Parameters

```Lua
do
    local function is_even(n)
        return int(n) % 2 == 0
    end

    do
        local expression = BoolExpr.Any(is_even)

        expression(1, 2, 3)
    end
end
```