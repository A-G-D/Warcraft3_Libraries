# Overview

## Background

```BoolExpr``` is a library for ```Bool```ean ```Expr```ession. A boolean expression is an expression that evaluates to a single boolean value. When thinking of boolean expressions, you often immediately think of simple conditional statements. Though also applicable, this script was made for so much more than this simple usage. Unlike in ordinary expressions where you are only concerned with the returned value, this script specifically puts emphasis to the execution of the expressions themselves and thus, provides useful utilities related to these.

The main class of this library is ```BoolExpr```, which is a list of operands operated by a single boolean operator. These operands though, could themselves be another ```BoolExpr```s such as in the case of nested boolean expressions. As such, it is easier to visualize a ```BoolExpr``` object as a boolean expression tree where each node (from root to leaves) is a boolean expression, not necessarily a ```BoolExpr``` since other things can also be considered boolean expressions, namely, functions, callable tables, and [custom-constructed tables](0_api-reference.md/#interface).

<br/>

## Main Features

- Dynamic boolean expressions
- Reversed boolean expression evaluation
- Propagation of arguments to the expression operands upon evaluation of a boolean expression
