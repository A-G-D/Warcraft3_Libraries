# Compiling Boolean Expressions

## About Compilation

Compiling boolean expressions returns a new and simplified version of that expresion. This can be done using the ```BoolExpr:compile()``` function.

<br/>

## Pros and Cons

Simplifying expressions can reduce a fair amount of overhead during evaluation. This is especially true when the leaf expresions - meaning the function - only does light operations and the overall level of nesting of boolean operators are deep. On the other hand, the process of [compilation](5_glossary.md) itself is a complex process and creates a new boolean expression which further takes up memory. Therefore, it is often enough to only compile really complex expressions that are often evaluated in a performance sensitive parts of the script, and leave the seldom used or simple boolean expressions as is.

<br/>

## Cases for Simplifications

These are a list of all cases for simplification currently supported by the library. The following are written in a simplified tree representation. Each line (except for the braces) represents an element, which is either an operator - written with words in capital letters, or an expression - written in numbers - which also represents the order in which each expression is evaluated within the boolean expression tree.

<br/>

### Chained AND Operations:

```Lua
{
    AND
    {
        AND
        {
            AND
            {
                1
            }
            2
        }
        3
    }
    4
}
```

->

```Lua
{
    ALL
    1
    2
    3
    4
}
```

<br/>

### Chained OR Operations

```Lua
{
    OR
    {
        OR
        {
            OR
            {
                1
            }
            2
        }
        3
    }
    4
}
```

->

```Lua
{
    ANY
    1
    2
    3
    4
}
```

<br/>

### Chained ALL-AND Operations (and Vice-Versa)

```Lua
{
    ALL
    {
        AND
        {
            ALL
            1
            2
            3
        }
        {
            ALL
            4
            5
            6
        }
    }
    {
        AND
        7
        8
    }
    {
        AND
        9
        10
    }
}
```

->

```Lua
{
    ALL
    1
    2
    3
    4
    5
    6
    7
    8
    9
    10
}
```

<br/>

### Chained ANY-OR Operations (and Vice-Versa)

```Lua
{
    ANY
    {
        OR
        {
            ANY
            1
            2
            3
        }
        {
            4
            5
            6
        }
    }
    {
        OR
        7
        8
    }
    {
        OR
        9
        10
    }
}
```

->

```Lua
{
    ANY
    1
    2
    3
    4
    5
    6
    7
    8
    9
    10
}
```

<br/>

### Operator Negation

- NOT-AND -> NAND

```Lua
{
    NOT
    {
        AND
        1
        2
    }
}
```

->

```Lua
{
    NAND
    1
    2
}
```

- NOT-OR -> NOR

```Lua
{
    NOT
    {
        OR
        1
        2
    }
}
```

->

```Lua
{
    NOR
    1
    2
}
```

- NOT-XAND -> XOR

```Lua
{
    NOT
    {
        XAND
        1
        2
    }
}
```

->

```Lua
{
    XOR
    1
    2
}
```

- NOT-XOR -> XAND

```Lua
{
    NOT
    {
        XOR
        1
        2
    }
}
```

->

```Lua
{
    XAND
    1
    2
}
```

- NOT-NAND -> AND

```Lua
{
    NOT
    {
        NAND
        1
        2
    }
}
```

->

```Lua
{
    AND
    1
    2
}
```

- NOT-NOR -> OR

```Lua
{
    NOT
    {
        NOR
        1
        2
    }
}
```

->

```Lua
{
    OR
    1
    2
}
```
