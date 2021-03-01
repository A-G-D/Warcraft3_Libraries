require('boolexpr.src.boolexpr')

do
	local output = ''
	-- Construct a nested/tree BoolExpr
	local tree = BoolExpr.Any
	(
		BoolExpr.All
		(
			function ()
				output = output .. "1:1:true\n"
				return true
			end,
			function ()
				output = output .. "1:2:true\n"
				return true
			end,
			BoolExpr.Or
			(
				function ()
					output = output .. "1:3:1:true\n"
					return true
				end,
				function ()
					output = output .. "1:3:2:false\n"
					return false
				end
			),
			BoolExpr.Not(function ()
				output = output .. "1:4:false\n"
				return true
			end)
		),
		BoolExpr.Or
		(
			function ()
				output = output .. "2:1:false\n"
				return false
			end,
			function ()
				output = output .. "2:2:true\n"
				return true
			end
		),
		BoolExpr.And
		(
			function ()
				output = output .. "3:1:true\n"
				return true
			end,
			function ()
				output = output .. "3:2:true\n"
				return true
			end
		)
	)

	-- Evaluate BoolExpr and print result
	local program_output = tree() and output .. "Result: True" or output .. "Result: False"
	local expected_output =
		"1:1:true\n" 	..
		"1:2:true\n" 	..
		"1:3:1:true\n" 	..
		"1:4:false\n" 	..
		"2:1:false\n" 	..
		"2:2:true\n"	..
		"Result: True"

	print("expected_output:\n" .. expected_output .. "\n")
	print("program_output:\n" .. program_output .. "\n")
	print(program_output == expected_output and "Unit Test 1: Passed!" or "Unit Test 1: Failed!")
end