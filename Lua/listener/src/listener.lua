require('boolexpr.src.boolexpr')

Listener = setmetatable({}, {})

do
    local listener = getmetatable(Listener)
    listener.__index = listener

    local data_table = {}
    local recur_table = {}

    function listener.create()
        local self = setmetatable(BoolExpr.Any(), listener)
        self.index_table = {}
        return self
    end
    function listener.new() return listener.create() end

    function listener:__gc()
        self:clear()
        self.index_table = nil
    end

    local evaluate = BoolExpr.evaluate
    function listener:register(handler, data, max_recursion_depth)
        max_recursion_depth = (max_recursion_depth and max_recursion_depth > 0) and
            max_recursion_depth or 1
        local index_t = self.index_table[handler] or {}
        self.index_table[handler] = index_t
        local handler_closure = function (func, reverse, ...)
            local result
            local recur_count = recur_table[func] + 1
            recur_table[func] = recur_count
            if recur_count <= max_recursion_depth then
                result = evaluate(handler, reverse, ..., data_table[func])
                self.EXCEPTION_MSG = (self.EXCEPTION_MSG or '') .. (type(handler) == 'table' and handler.EXCEPTION_MSG or '')
            else
                result = true
                self.EXCEPTION_MSG = (self.EXCEPTION_MSG or '') .. "[Recursion Error] Recursion Level: " .. tostring(recur_count) .. '\n'
            end
            recur_table[func] = recur_count - 1
            return result
        end
        self[#self + 1] = handler_closure
        index_t[#index_t + 1] = #self
        data_table[handler_closure] = data
        recur_table[handler_closure] = 0
    end

    local min = math.min
    function listener:deregister(handler, deregister_all)
        local index_t = self.index_table[handler]
        if deregister_all then
            local index = index_t and index_t[1]
            if index then
                local n = #self
                local i = 1
                data_table[self[index]] = nil
                index_t[i] = nil
                for j = index, n do
                    if j + i == index_t[i + 1] then
                        i = i + 1
                        data_table[self[index_t[i]]] = nil
                        index_t[i] = nil
                    end
                    self[j] = self[j + i]
                end
            end
        else
            local index = index_t and index_t[#index_t]
            index_t[#index_t] = nil
            if index then
                data_table[self[index]] = nil
                for i = index, #self do
                    self[i] = self[i + 1]
                end
            end
        end
    end
    listener.unregister = listener.deregister

    function listener:clear()
        for i = 2, #self do
            data_table[self[i]] = nil
            self[i] = nil
        end
        self.index_table = {}
    end

    function listener:__call(reverse, ...) return evaluate(self, reverse, ...) end
    listener.execute = listener.__call

end