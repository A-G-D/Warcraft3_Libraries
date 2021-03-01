# Registering Listener Functions

## Listener Functions Without Parameters

```lua
do
    local function C()
        print('C')
    end

    do
        local listener = Listener.new()
        listener:register(
            function ()
                print('A')
            end
        )
        listener:register(
            function ()
                print('B')
            end
        )
        listener:register(C)
    end
end
```

## Listener Functions With Parameters

A listener function can have any number of parameters.

```Lua
do
    local function Assert(condition, message)
        if condition then
            print('[ERROR!]: ' .. message)
        end
    end

    do
        local listener = Listener.new()
        listener:register(
            function (message)
                print(message)
            end
        )
        listener:register(PrintError)
    end
end
```