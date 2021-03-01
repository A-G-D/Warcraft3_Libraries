# Execution Parameters

## Passing Execution Arguments

You can optionally pass arguments to the listener object being executed. In which case, all the listener functions are passed that argument upon execution.

```Lua
do
    local listener = Listener.new()

    listener:register(
        function (...)
            print("Name: " .. select(3, ...))
        end
    )
    listener:register(
        function (...)
            print("Pseudonym: " .. select(4, ...))
        end
    )
    listener:register(
        function (...)
            print("Status: " .. select(5, ...))
        end
    )

    listener:execute("Victor Hugo Soliz Kunkar", "Vexorian", "Retired")
end
```

Output:
> Name: Victor Hugo Soliz Kuncar
> 
> Pseudonym: Vexorian
> 
> Status: Retired

## Listener Parameters

You might wonder based on the above example, why the passed arguments are accessed from the listener functions starting at index 3 and not 1. Well that is because the system also passes what are called the 'default arguments' into the function. That means, even if you do not pass any argument during the execution, the listeners still receive arguments.

There are 2 default arguments being passed to the listeners. The first one is the listener object itself, i.e., the current executing function.