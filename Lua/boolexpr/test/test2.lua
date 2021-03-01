require('boolexpr.src.boolexpr')

do
	local output = ''
	-- Create a BoolExpr from two expressions with AND
	local sub_expr_1 =
	{
		BoolExpr.AND,
		function ()
			output = output .. '1:1:false\n'
			return false
		end,
		function ()
			output = output .. '1:2:true\n'
			return true
		end
	}
	-- Create a BoolExpr from multiple expressions with ANY
	local sub_expr_2 =
	{
		BoolExpr.ANY,
		function ()
			output = output .. '2:1:false\n'
			return false
		end,
		function ()
			output = output .. '2:2:true\n'
			return true
		end,
		function ()
			output = output .. '2:3:false\n'
			return false
		end
	}
	-- Combine the previous two BoolExpr with OR
	local parent_expr =
	{
		BoolExpr.OR,
		sub_expr_1,
		sub_expr_2
	}

	-- Evaluate <parent_expr> and compare output
	local program_output = (BoolExpr.evaluate(parent_expr) and output ..
		'Result: True' or output .. 'Result: False')
	local expected_output =
		"1:1:false\n" ..
		"2:1:false\n" ..
		"2:2:true\n" ..
		"Result: True"

	print("expected_output:\n" .. expected_output .. "\n")
	print("program_output:\n" .. program_output .. "\n")
	print(
		program_output == expected_output and
		"Unit Test 2: Passed!" or
		"Unit Test 2: Failed!"
	)
end