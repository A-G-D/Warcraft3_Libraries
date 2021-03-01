# Glossary

## Abbreviations

1. EF
    - Expression Function

<br/>

## Definitions

1. Expression Function
    - A function being passed as argument when creating a new BoolExpr using its constructors, and also follows the interface as specified [here](0_api-reference.md/#interface)

2. Boolean Expression
    - A BoolExpr instance. They are similar to Expressions but semantically different in that the latter does not neccessary have to be a product of a BoolExpr constructor.

3. BoolExpr Table
    - An table whose metatable is not ```BoolExpr``` and whose contents follow the specifications stated [here](0_api-reference.md/#interface) 

4. Expressions
    - The individual operands that together, compose a Boolean Expression. Note that BoolExpr Tables and Boolean Expressions qualifies for this definition too, since they can also be used to form much larger Boolean Expressions themselves. 