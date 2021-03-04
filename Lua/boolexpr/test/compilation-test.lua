require('boolexpr.src.boolexpr')

do
    local boolexpr = {}
    local i

    i = #boolexpr + 1
    boolexpr[i] = {}
    boolexpr[i][1] = BoolExpr.New
        (
            {
                BoolExpr.AND,
                {
                    BoolExpr.AND,
                    function () end,
                    {
                        BoolExpr.NOT,
                        {
                            BoolExpr.XOR,
                            function () end,
                            function () end
                        }
                    }
                },
                {
                    BoolExpr.OR,
                    function () end,
                    {
                        BoolExpr.DEF,
                        function () end
                    }
                }
            }
        )
    boolexpr[i][2] =
"{\
\tALL\
\t1\
\t{\
\t\tXAND\
\t\t2\
\t\t3\
\t}\
\t{\
\t\tOR\
\t\t4\
\t\t5\
\t}\
}\
"

    i = #boolexpr + 1
    boolexpr[i] = {}
    boolexpr[i][1] = BoolExpr.Any
        (
            {
                BoolExpr.OR,
                {
                    BoolExpr.OR,
                    function () end,
                    function () end
                },
                {
                    BoolExpr.OR,
                    function () end,
                    {
                        BoolExpr.NOT,
                        function () end
                    }
                }
            },
            function () end,
            BoolExpr.All
            (
                function () end,
                function () end,
                BoolExpr.All
                (
                    function () end
                )
            )
        )
    boolexpr[i][2] =
"{\
\tANY\
\t1\
\t2\
\t3\
\t{\
\t\tNOT\
\t\t4\
\t}\
\t5\
\t{\
\t\tALL\
\t\t6\
\t\t7\
\t\t8\
\t}\
}\
"

    i = #boolexpr + 1
    boolexpr[i] = {}
    boolexpr[i][1] = BoolExpr.Not
        (
            {
                BoolExpr.NOT,
                {
                    BoolExpr.NOT,
                    {
                        BoolExpr.NOT,
                        function () end
                    }
                }
            }
        )
    boolexpr[i][2] =
"{\
\tDEF\
\t1\
}\
"

    i = #boolexpr + 1
    boolexpr[i] = {}
    boolexpr[i][1] =
        {
            BoolExpr.NOT,
            {
                BoolExpr.XOR,
                function () end,
                function () end
            }
        }
    boolexpr[i][2] =
"{\
\tXAND\
\t1\
\t2\
}\
"

    i = #boolexpr + 1
    boolexpr[i] = {}
    boolexpr[i][1] =
        {
            BoolExpr.AND,
            {
                BoolExpr.NOT,
                {
                    BoolExpr.XOR,
                    function () end,
                    function () end
                }
            },
            function () end
        }
    boolexpr[i][2] =
"{\
\tAND\
\t{\
\t\tXAND\
\t\t1\
\t\t2\
\t}\
\t3\
}\
"

    do
        local passed = true

        for i = 1, #boolexpr do
            local expression = boolexpr[i][1]
            local program_output = tostring(BoolExpr.compile(expression))
            local expected_output = boolexpr[i][2]
            local ex_passed = (program_output == expected_output)
            passed = passed and ex_passed

            print("Original Boolean Expression:\n" .. BoolExpr.__tostring(expression) .. "\n")
            print("Expected Output:\n" .. expected_output .. "\n")
            print("Program Output:\n" .. program_output .. "\n")
            print("Boolean Expression " .. tostring(i) .. ": " ..
                (ex_passed and "Passed" or "Failed") .. "\n")
            print("----------------------------------------------------------\n")
        end

        print("Compilation Test Result: " .. (passed and "PASSED" or "FAILED"))
    end
end