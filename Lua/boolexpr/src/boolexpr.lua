---@class BoolExpr
BoolExpr = setmetatable({}, {})

do
	---@type BoolExpr
	local boolexpr = getmetatable(BoolExpr)
	boolexpr.__index = boolexpr

	local DEF 		= 1		---@type integer
	local NOT 		= 2		---@type integer
	local AND 		= 3		---@type integer
	local OR 		= 4		---@type integer
	local XAND 		= 5		---@type integer
	local XOR 		= 6		---@type integer
	local NAND 		= 7		---@type integer
	local NOR 		= 8		---@type integer
	local ALL 		= 9		---@type integer
	local ANY 		= 10	---@type integer

	BoolExpr.DEF 	= DEF
	BoolExpr.NOT 	= NOT
	BoolExpr.AND 	= AND
	BoolExpr.OR 	= OR
	BoolExpr.XAND 	= XAND
	BoolExpr.XOR 	= XOR
	BoolExpr.NAND 	= NAND
	BoolExpr.NOR 	= NOR
	BoolExpr.ALL 	= ALL
	BoolExpr.ANY 	= ANY

	local op_neg = {
		[DEF] 	= NOT	, [NOT] = DEF,
		[AND] 	= NAND	, [OR] 	= NOR,
		[XAND] 	= XOR	, [XOR] = XAND,
		[NAND] 	= AND	, [NOR] = OR
	}
	local op_str = {
		[DEF] 	= 'DEF'	, [NOT] = 'NOT',
		[AND] 	= 'AND'	, [OR] 	= 'OR',
		[XAND] 	= 'XAND', [XOR] = 'XOR',
		[NAND] 	= 'NAND', [NOR] = 'NOR',
		[ALL] 	= 'ALL'	, [ANY] = 'ANY'
	}
	local op_up = {
		[AND] 	= ALL	, [OR] = ANY,
		[ALL] 	= AND	, [ANY] = OR,
	}

	local function assert_expression(...)
		for i = 1, select("#", ...) do
			assert(select(i, ...), "[ERROR]: Passed expression is nil!")
		end
	end

	---@param expr function|table|BoolExpr
	---@return BoolExpr
	function boolexpr.New(expr)
		assert_expression(expr)
		return setmetatable({DEF, expr}, boolexpr)
	end
	---@param expr function|table|BoolExpr
	---@return BoolExpr
	function boolexpr.Not(expr)
		assert_expression(expr)
		return setmetatable({NOT, expr}, boolexpr)
	end
	---@param left_expr function|table|BoolExpr
	---@param right_expr function|table|BoolExpr
	---@return BoolExpr
	function boolexpr.And(left_expr, right_expr)
		assert_expression(left_expr, right_expr)
		return setmetatable({AND, left_expr, right_expr}, boolexpr)
	end
	---@param left_expr function|table|BoolExpr
	---@param right_expr function|table|BoolExpr
	---@return BoolExpr
	function boolexpr.Or(left_expr, right_expr)
		assert_expression(left_expr, right_expr)
		return setmetatable({OR, left_expr, right_expr}, boolexpr)
	end
	---@param left_expr function|table|BoolExpr
	---@param right_expr function|table|BoolExpr
	---@return BoolExpr
	function boolexpr.Xand(left_expr, right_expr)
		assert_expression(left_expr, right_expr)
		return setmetatable({XAND, left_expr, right_expr}, boolexpr)
	end
	---@param left_expr function|table|BoolExpr
	---@param right_expr function|table|BoolExpr
	---@return BoolExpr
	function boolexpr.Xor(left_expr, right_expr)
		assert_expression(left_expr, right_expr)
		return setmetatable({XOR, left_expr, right_expr}, boolexpr)
	end
	---@param left_expr function|table|BoolExpr
	---@param right_expr function|table|BoolExpr
	---@return BoolExpr
	function boolexpr.Nand(left_expr, right_expr)
		assert_expression(left_expr, right_expr)
		return setmetatable({NAND, left_expr, right_expr}, boolexpr)
	end
	---@param left_expr function|table|BoolExpr
	---@param right_expr function|table|BoolExpr
	---@return BoolExpr
	function boolexpr.Nor(left_expr, right_expr)
		assert_expression(left_expr, right_expr)
		return setmetatable({NOR, left_expr, right_expr}, boolexpr)
	end
	---@return BoolExpr
	function boolexpr.All(...)
		assert_expression(...)
		return setmetatable({ALL, ...}, boolexpr)
	end
	---@return BoolExpr
	function boolexpr.Any(...)
		assert_expression(...)
		return setmetatable({ANY, ...}, boolexpr)
	end

	function boolexpr:__gc()
		for i = 1, #self do self[i] = nil end
	end

	local first, last, step
	local operator = {
		-- Operator: DEF (Default)
		function (expr_t, reverse, ...)
			return boolexpr.__call(expr_t[2], reverse, ...)
		end,
		-- Operator: NOT (Not)
		function (expr_t, reverse, ...)
			return not boolexpr.__call(expr_t[2], reverse, ...)
		end,
		-- Operator: AND (And)
		function (expr_t, reverse, ...)
			return
 				boolexpr.__call(expr_t[reverse and 3 or 2], reverse, ...) and
 				boolexpr.__call(expr_t[reverse and 2 or 3], reverse, ...)
		end,
		-- Operator: OR (Or)
		function (expr_t, reverse, ...)
			return
 				boolexpr.__call(expr_t[reverse and 3 or 2], reverse, ...) or
 				boolexpr.__call(expr_t[reverse and 2 or 3], reverse, ...)
		end,
		-- Operator: XAND (Exclusive-And)
		function (expr_t, reverse, ...)
			return
				boolexpr.__call(expr_t[reverse and 3 or 2], reverse, ...) ==
				boolexpr.__call(expr_t[reverse and 2 or 3], reverse, ...)
		end,
		-- Operator: XOR (Exclusive-Or)
		function (expr_t, reverse, ...)
			return
				boolexpr.__call(expr_t[reverse and 3 or 2], reverse, ...) ~=
				boolexpr.__call(expr_t[reverse and 2 or 3], reverse, ...)
		end,
		-- Operator: NAND (Not-And)
		function (expr_t, reverse, ...)
			return not (
				boolexpr.__call(expr_t[reverse and 3 or 2], reverse, ...) and
				boolexpr.__call(expr_t[reverse and 2 or 3], reverse, ...)
			)
		end,
		-- Operator: NOR (Not-Or)
		function (expr_t, reverse, ...)
			return not (
				boolexpr.__call(expr_t[reverse and 3 or 2], reverse, ...) or
				boolexpr.__call(expr_t[reverse and 2 or 3], reverse, ...)
			)
		end,
		-- Operator: ALL (All)
		function (expr_t, reverse, ...)
			if reverse then
				first, last, step = #expr_t, 2, -1
			else
				first, last, step = 2, #expr_t, 1
			end
			for i = first, last, step do
				if not boolexpr.__call(expr_t[i], reverse, ...) then return false end
			end
			return true
		end,
		-- Operator: ANY (Any)
		function (expr_t, reverse, ...)
			if reverse then
				first, last, step = #expr_t, 2, -1
			else
				first, last, step = 2, #expr_t, 1
			end
			for i = first, last, step do
				if boolexpr.__call(expr_t[i], reverse, ...) then return true end
			end
			return false
		end
	}

	---@param self BoolExpr
	---@param reverse boolean
	---@return boolean
	function boolexpr.__call(self, reverse, ...)
		local t = type(self)
		if t == 'table' then
			local mt = getmetatable(self)
			if mt and mt.__call and mt.__call ~= boolexpr.__call then
				return self(self, reverse, ...)
			end
			return operator[self[1]](self, reverse, ...)
		elseif t == 'function' then
			return self(self, reverse, ...)
		end
		return self and true or false
	end
	boolexpr.evaluate = boolexpr.__call

	---to-do
	local function callable_status(o)
		if type(o) == 'table' then
			local mt = getmetatable(o)
			if mt and mt.__call then
				if mt.__call ~= boolexpr.__call then
					return 2 -- table is inherently callable
				end
				return 3 -- a BoolExpr or extends BoolExpr
			end
			return 0 -- non-callable table
		elseif type(o) == 'function' then
			return 1 -- a function
		end
		return nil -- non-table and non-callable
	end

	local function is_table_expr(o)
		local op = o[1]
		return
			op == DEF 	or op == NOT 	or
			op == AND 	or op == OR 	or
			op == XAND 	or op == XOR 	or
			op == NAND 	or op == NOR 	or
			op == ALL 	or op == ANY
	end

	local function is_expr_table(o)
		local call_stat = callable_status(o)
		return call_stat == 3 or (call_stat == 0 and is_table_expr(o))
	end

	local function copy_table(o)
		if type(o) == 'table' then
			local t = {}
			for i = 1, #o do t[i] = copy_table(o[i]) end
			return t
		end
		return o
	end

	local ex_count
	---@return string
	function boolexpr:__tostring(tab, start)
		tab = tab or ""
		ex_count = start or 0
		if type(self) == 'table' then
			local s = tab .. "{\n"
			local op = self[1]
			s = s .. tab .. "\t" .. op_str[op] .. "\n"
			for i = 2, #self do
				s = s .. boolexpr.__tostring(self[i], tab .. "\t", ex_count)
			end
			return s .. tab .. "}\n"
		end
		ex_count = ex_count + 1
		return tab .. tostring(ex_count) .. "\n"
	end
	function boolexpr:print()
		print(tostring(self))
	end

	---@return BoolExpr
	function boolexpr:compile()
		if #self > 0 then

			local copy = copy_table(self) -- deep copy array table
			local compile = boolexpr.compile
			local op = copy[1]

			if op == DEF then
				local expr = copy[2]

				if is_expr_table(expr) then
					expr = compile(expr)
					-- if an expression table, collapse one level
					for i = 1, #expr do copy[i] = expr[i] end
				end

			elseif op == NOT then
				-- Simplify expression by one level if possible
				local expr = copy[2]

				if is_expr_table(expr) then
					-- is an expression table
					expr = compile(expr)
					local eop = expr[1]

					if eop == DEF then
						copy[2] = expr[2]
					elseif eop == NOT then
						copy[1] = DEF
						copy[2] = expr[2]
					elseif eop ~= ALL and eop ~= ANY then
						-- invert operator and collapse one level
						copy[1] = op_neg[eop]
						copy[2] = expr[2]
						copy[3] = expr[3]
					end
				end

			elseif op == AND or op == OR then
				-- Convert AND to ALL and OR to ANY when possible
				local le, re = copy[2], copy[3]
				local let, ret = is_expr_table(le), is_expr_table(re)
				local uop = op_up[op]

				if let or ret then
					local lop, rop, upl, upr

					if let then
						le = compile(le)
						lop = le[1]
						upl = lop == op or lop == uop
					end
					if ret then
						re = compile(re)
						rop = re[1]
						upr = rop == op or rop == uop
					end

					if upl or upr then
						copy[1] = uop

						if upl then
							for i = 2, #le do copy[i] = le[i] end
						else
							copy[2] = le
						end

						if upr then
							for i = 2, #re do copy[#le + i - 1] = re[i] end
						else
							copy[#le + 1] = re
						end

					elseif lop == DEF or rop == DEF then
						-- collapse one level
						if lop == DEF then copy[2] = le[2] end
						if rop == DEF then copy[3] = re[2] end
					else
						-- reload compiled children
						copy[2] = le
						copy[3] = re
					end
				end

			elseif op == ALL or op == ANY then
				-- Combine ALL and AND to ALL or ANY and OR to ANY
				local ref = {}
				local uop = op_up[op]

				for i = 1, #copy do ref[i] = copy[i] end

				local j = 2
				for i = 2, #ref do
					local expr = ref[i]

					if is_expr_table(expr) then
						-- is expression table
						expr = compile(expr)
						local eop = expr[1]

						if eop == op or eop == uop or eop == DEF then
							-- collapsable/combinable
							for k = 2, #expr do
								copy[j] = expr[k]
								j = j + 1
							end
						else
							-- not collapsable, add expression as-is
							copy[j] = expr
							j = j + 1
						end
					else
						-- not an expression table, add expression as-is
						copy[j] = expr
						j = j + 1
					end
				end
			end

			-- return compiled expression as a new BoolExpr
			return setmetatable(copy, boolexpr)
		end

		return nil
	end

end
