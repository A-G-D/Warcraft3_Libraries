BoolExpr = setmetatable({}, {})

do
	local boolexpr = getmetatable(BoolExpr)
	boolexpr.__index = boolexpr

	local DEF = 1	---@type integer
	local NOT = 2	---@type integer
	local AND = 3	---@type integer
	local OR = 4	---@type integer
	local ALL = 5	---@type integer
	local ANY = 6	---@type integer

	BoolExpr.DEF = DEF
	BoolExpr.NOT = NOT
	BoolExpr.AND = AND
	BoolExpr.OR = OR
	BoolExpr.ALL = ALL
	BoolExpr.ANY = ANY

	local function is_expression(o)
		-- Check if <o> is a function. If so, return true.
		if type(o) == 'function' then return true
		-- Check if <o> is a table
		elseif type(o) == 'table' then
			local mt = getmetatable(o)
			-- If <o> is callable table, return true
			if mt and mt.__call then return true end
			-- If <o> is a boolean expression table, return true.
			for _, v in pairs(o) do
				if not is_expression(v) then return false end
			end
			return true
		end
		-- Return false if <o> is neither a callable nor a boolean expression table
		return false
	end

	local function assert_expression(...)
		for i = 1, select("#", ...) do
			local expr = select(i, ...)
			assert(is_expression(expr), "[ERROR]: Passed expression is not callable!")
		end
	end

	---@param expr function|table
	function BoolExpr.New(expr)
		assert_expression(expr)
		return setmetatable({DEF, expr}, boolexpr)
	end
	---@param expr function|table
	function boolexpr.Not(expr)
		assert_expression(expr)
		return setmetatable({NOT, expr}, boolexpr)
	end
	---@param left_expr function|table
	---@param right_expr function|table
	function boolexpr.And(left_expr, right_expr)
		assert_expression(left_expr, right_expr)
		return setmetatable({AND, left_expr, right_expr}, boolexpr)
	end
	---@param left_expr function|table
	---@param right_expr function|table
	function boolexpr.Or(left_expr, right_expr)
		assert_expression(left_expr, right_expr)
		return setmetatable({OR, left_expr, right_expr}, boolexpr)
	end
	function boolexpr.All(...)
		assert_expression(...)
		return setmetatable({ALL, ...}, boolexpr)
	end
	function boolexpr.Any(...)
		assert_expression(...)
		return setmetatable({ANY, ...}, boolexpr)
	end

	function boolexpr:__gc()
		for i = 1, #self do self[i] = nil end
	end

	local function get_for_loop_params(first, last, reverse)
		if reverse then return last, first, -1 end return first, last, 1
	end

	local operator = {
		function (expr_t, reverse, ...)
			return boolexpr.__call(expr_t[2], reverse, ...)
		end,
		function (expr_t, reverse, ...)
			return not boolexpr.__call(expr_t[2], reverse, ...)
		end,
		function (expr_t, reverse, ...)
			return
 				boolexpr.__call(expr_t[reverse and 3 or 2], reverse, ...) and
 				boolexpr.__call(expr_t[reverse and 2 or 3], reverse, ...)
		end,
		function (expr_t, reverse, ...)
			return
 				boolexpr.__call(expr_t[reverse and 3 or 2], reverse, ...) or
 				boolexpr.__call(expr_t[reverse and 2 or 3], reverse, ...)
		end,
		function (expr_t, reverse, ...)
 			local first, last, step = get_for_loop_params(2, #expr_t, reverse)
			for i = first, last, step do
				if not boolexpr.__call(expr_t[i], reverse, ...) then return false end
			end
			return true
		end,
		function (expr_t, reverse, ...)
 			local first, last, step = get_for_loop_params(2, #expr_t, reverse)
			for i = first, last, step do
				if boolexpr.__call(expr_t[i], reverse, ...) then return true end
			end
			return false
		end
	}

	---@param reverse boolean
	function boolexpr:__call(reverse, ...)
		if type(self) == 'table' then
			local mt = getmetatable(self)
			if mt and mt.__call and mt ~= boolexpr then
				return self(self, reverse, ...)
			end
			return operator[self[1]](self, reverse, ...)
		end
		return self(self, reverse, ...)
	end
	boolexpr.evaluate = boolexpr.__call

end