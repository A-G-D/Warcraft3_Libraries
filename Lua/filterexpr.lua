--[[ filterexpr.lua v1.0.0 by AGD


    Description:

        Overrides the native boolexpr functions Or(), And(), and Not() with
        a lighter version. The deeper the nesting of expressions, the more
        significant this script becomes.
        With the native functions, creating a nested boolexpr such as:
        And(Or(Filter(FuncA), Filter(FuncB)), Or(Filter(FuncC), Filter(FuncD)))


    Requirements:

        - BoolExpr
			Link: https://www.hiveworkshop.com/threads/330817

]]--
--[[

    API:

        - N/A, Simply import or copy-paste the script in your map.
]]--
do
	-- Override native boolexpr functions
	local expr_data = {}

	local old_filter = Filter
	function Filter(filter_func)
		local filter_expr = old_filter(filter_func)
		expr_data[filter_expr] = filter_func
		return filter_expr
	end

	function Not(filter_expr)
		return old_filter(function ()
			return BoolExpr.Not(expr_data[filter_expr])()
		end)
	end

	function And(left_filter_expr, right_filter_expr)
		return old_filter(function ()
			return BoolExpr.And(expr_data[left_filter_expr], expr_data[right_filter_expr])()
		end)
	end

	function Or(left_filter_expr, right_filter_expr)
		return old_filter(function ()
			return BoolExpr.Or(expr_data[left_filter_expr], expr_data[right_filter_expr])()
		end)
	end

end