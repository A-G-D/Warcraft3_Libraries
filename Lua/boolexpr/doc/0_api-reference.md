# API

## Variables

The following variables are used for manual BoolExpr construction (see [Manually Constructed BoolExpr](1_creating-expressions)).

| Name | Type | Description |
|---|---|---|
| ```BoolExpr.DEF``` | integer | Constructed BoolExpr evaluates to true when EF returns true |
| ```BoolExpr.NOT``` | integer | Constructed BoolExpr evaluates to true when EF returns false |
| ```BoolExpr.AND``` | integer | Constructed BoolExpr evaluates to true when both the left EF and right EF both return true |
| ```BoolExpr.OR``` | integer | Constructed BoolExpr evaluates to true when either the left EF or right EF returns true |
| ```BoolExpr.ALL``` | integer | Constructed BoolExpr evaluates to true when all the EFs return true |
| ```BoolExpr.ANY``` | integer | Constructed BoolExpr evaluates to true when at least one EF returns true |

<br/>

## Interface

This is the interface for functions passed to the constructors:
```Lua
function ([self [, reverse [, ...]]))
```

| Parameters: |||
|---|---|---|
| **Name** | **Type** | **Description** |
| *self* | function \| table | The function currently being evaluated |
| *reverse* | boolean | ```true``` if the BoolExpr object the function belongs to was evaluated in reverse order |
| *...* | any | The arguments passed to the ```evaluate()``` call |

| Return value: |||
|---|---|---|
| **#** | **Type** | **Description** |
| *1* | table | A newly constructed boolean expression |

<br/>

## Constructors

```Lua
function BoolExpr.New(expr)
```

Constructs a new BoolExpr object, which evaluates to true when *expr* returns true.

| Parameters: |||
|---|---|---|
| **Name** | **Type** | **Description** |
| *expr* | function \| table | An EF, or another BoolExpr |

| Return value: |||
|---|---|---|
| **#** | **Type** | **Description** |
| *1* | table | A newly constructed boolean expression |

<br/>

```Lua
function BoolExpr.Not(expr)
```

Constructs a new BoolExpr object, which evaluates to true when *expr* returns false.

| Parameters: |||
|---|---|---|
| **Name** | **Type** | **Description** |
| *expr* | function \| table | An EF, or another BoolExpr |

| Return value: |||
|---|---|---|
| **#** | **Type** | **Description** |
| *1* | table | A newly constructed boolean expression |

<br/>

```Lua
function BoolExpr.And(left_expr, right_expr)
```

Constructs a new BoolExpr object, which evaluates to true when both *left_expr* and *right_expr* return true.

| Parameters: |||
|---|---|---|
| **Name** | **Type** | **Description** |
| *left_expr* | function \| table | An EF, or another BoolExpr, serving as the left expression |
| *right_expr* | function \| table | An EF, or another BoolExpr, serving as the right expression |

| Return value: |||
|---|---|---|
| **#** | **Type** | **Description** |
| *1* | table | A newly constructed boolean expression |

<br/>

```Lua
function BoolExpr.Or(left_expr, right_expr)
```

Constructs a new BoolExpr object, which evaluates to true when either *left_expr* or *right_expr* returns true.

| Parameters: |||
|---|---|---|
| **Name** | **Type** | **Description** |
| *left_expr* | function \| table | An EF, or another BoolExpr, serving as the left expression |
| *right_expr* | function \| table | An EF, or another BoolExpr, serving as the right expression |

| Return value: |||
|---|---|---|
| **#** | **Type** | **Description** |
| *1* | table | A newly constructed boolean expression |

<br/>

```Lua
function BoolExpr.All(...)
```

Constructs a new BoolExpr object, which evaluates to true when all the EFs in ... return true.

| Parameters: |||
|---|---|---|
| **Name** | **Type** | **Description** |
| *...* | function \| table | A list of EF, or BoolExprs, serving as expressions |

| Return value: |||
|---|---|---|
| **#** | **Type** | **Description** |
| *1* | table | A newly constructed boolean expression |

<br/>

```Lua
function BoolExpr.Any(...)
```

Constructs a new BoolExpr object, which evaluates to true when all the EFs in ... return true.

| Parameters: |||
|---|---|---|
| **Name** | **Type** | **Description** |
| *...* | function \| table | A list of EF, or BoolExprs, serving as expressions |

| Return value: |||
|---|---|---|
| **#** | **Type** | **Description** |
| *1* | table | A newly constructed boolean expression |

<br/>

- Boolean expression constructors
- Expressions can take arguments
- Expressions MUST be callable
- Can construct nested boolean expressions

<br/>

## Functions

```Lua
function BoolExpr:__call([reverse [, ...]])
```

Evaluates a BoolExpr

| Parameters: |||
|---|---|---|
| **Name** | **Type** | **Description** |
| *reverse* | boolean | If true, the boolean expression is evaluated in reversed order |
| *...* | Any \| table | Arguments passed into all the evaluated expressions |

| Return value: |||
|---|---|---|
| **#** | **Type** | **Description** |
| *1* | boolean | Boolean result of the evaluation |

<br/>

```Lua
function BoolExpr.evaluate(expr, [reverse [, ...]])
```

- Similar to the function above, but can be used for manually constructed BoolExprs using ordinary table (see [Creating Boolean Expressions](1_creating-expressions.md) for a sample of manual construction using ordinary table)

| Parameters: |||
|---|---|---|
| **Name** | **Type** | **Description** |
| *expr* | function \| table | BoolExpr or BoolExpr table to be evaluated |
| *reverse* | boolean | If true, the expressions are evaluated in reversed order |
| *...* | Any \| table | Arguments passed into all the evaluated expressions |

| Return value: |||
|---|---|---|
| **#** | **Type** | **Description** |
| *1* | boolean | Boolean result of the evaluation |
