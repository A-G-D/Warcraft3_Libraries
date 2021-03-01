require('listener.src.listener')

do
    local function A(self, reverse, exec_data, data) print(exec_data .. 'A:' .. (data and tostring(data) or 'nil')) end
    local function B(self, reverse, exec_data, data) print(exec_data .. 'B:' .. (data and tostring(data) or 'nil')) end
    local function C(self, reverse, exec_data, data) print(exec_data .. 'C:' .. (data and tostring(data) or 'nil')) end

    local listener = Listener.new()
    listener:register(A, 1)
    listener:register(B, 2)
    listener:register(C, 3)
    listener:register(A, 4)
    listener:register(B, 5)
    listener:register(C, 6)
    listener:register(C, 7)
    listener:register(B, 8)
    listener:register(A, 9)
    listener:register(C, 10)
    listener:register(B, 11)
    listener:register(A, 12)

    listener:deregister(B)
    listener:deregister(C)
    listener:deregister(C)
    listener:unregister(C, true)

    listener(false, "[Execution 1]: ") -- call/execute

    print('|')

    listener:register(
        {
            BoolExpr.ANY,
            A,
            B,
            A
        }
    )

    listener(true, "[Execution 2]: ")

    print('|')

    listener:clear()

    listener(false, "[Execution 3]: ")

    local function Recursive(self, reverse, exec_data, data)
        print(exec_data .. "Recursive function called")
        return listener(reverse, exec_data, data)
    end
    listener:register(Recursive, nil, 3)

    local better_listener = Listener.new()
    better_listener:register(function () print("Start") end)
    better_listener:register(listener)
    better_listener:register(function () print("End") end)

    if better_listener(false, "[Execution 4]: ") then
        print(better_listener.EXCEPTION_MSG)
    end
end