# Executing a Listener Object

## Basic Execution

Executing a listener object in most cases is as simple as calling a normal function.

```Lua
do
    local listener = Listener.new()

    listener:register(
        function ()
            print("Listener object executed")
        end
    )

    listener() -- Execute listener
end
```

Output:
> Listener object executed
