# Lazy Loot

##### Ethan Bodzioney

## Introduction

This was my final project for CMSC430 at UMD. The goal of this project was to implement a compiler and runtime system for a lazily evaluated subset of the Racket language. Specifically, it aims to implement the technique outlined in *A New Implementation Technique for Applicative Languages* by David Turner.

## Implementation

The implementation can be viewed as three parts:

1. Conversion to SKI Form

2. Storing the resulting tree on the heap

3. The Graph Reduction Machine

## Reduction to SKI Form

Relevant files:

- `ast.rkt` Contains all related functions and structures

- `parse.rkt` Minor changes, like parsing `'if` as an `op3` structure instead of as an `If` structure

The functions `abstract` and `abstract-prog` are what convert the program into SKI-Form. `abstract-prog` takes in a `prog` struct and runs `abstract` on all expressions inside. It then stores them in place of the expression in the original struct. The benefit of this is some context is preserved (i.e. the names of global definitions). The `abstract` function is what performs the actual conversion. It recursively traverses the expressions, converting each to a form consisting of combinators, applications, functions, literals, and variables.

The rules for abstracting $x$ (denoted $[x]$) out of an expression are as follows:

- $[x](E_1\:E_2) \Rightarrow \textbf{S} ([x]E_1)([x]E_2)$

- $[x]x \Rightarrow \textbf{I}$

- $[x]y \Rightarrow \textbf{K} y$

If there are multiple variables:

- $\text{def} \:f \:x \:y = \:E \Rightarrow \text{def} \:f = [x]([y]\:E)$

For local definitions (let statements):

- $E_1 \: \text{where} \:x=E_2 \Rightarrow ([x]E_1)E_2$

These rules are what `abstract` applies to given expressions. If there is no variable bound in the expression `abstract` still converts it to an expression that is valid in the SKI-Tree. The only difference is it will not add combinators.

After this, we have the optimizations, which are similarly written in `optimize-prog` and `optimize-expr`. `optimize-prog` is essentially the same as `abstract-prog` but instead runs `optimize-expr` on the SKI-Trees now stored inside. `optimize-expr` is what applies the optimization rules, which are as follows:

- $\textbf{S}(\textbf{K} \:E_1)(\textbf{K} \:E_2) \Rightarrow \textbf{K} (E_1 \:E_2)$

- $\textbf{S}(\textbf{K} \:E_1)\:\textbf{I} \Rightarrow E_1$

- $\textbf{S}(\textbf{K} \:E_1)\:E_2 \Rightarrow \textbf{B}\:E_1 \:E_2$

- $\textbf{S}\:E_1\:(\textbf{K} \:E_2) \Rightarrow \textbf{C} \:E_1 \:E_2$

The purpose of this is to shrink the amount of expressions stored, and therefore minimize how many expressions must be reduced at runtime. The implementation of this matches all applications of $\textbf{S}$ onto two expressions as that is the form of all the optimization rules. It calls `optimize-expr` on every expression it sees as the resulting tree potentially can be optimized again.

---

## Storing the tree on the heap

Relevant files:

- `compile.rkt`

The structure now has to be stored on the heap. My way of doing this was to use three types. A type representing a function, a type representing a literal, and a type representing an application. The function and literal types are pointer-tagged boxes. The application type is a pointer-tagged cons. The application type contains two pointers to any of the three types.

The function `compile-tree` recursively generates the assembly for each tree. It is called on every tree throughout this process.

The tree structure is incrementally put on the heap. We start by taking the result of our optimization and passing it to `compile-prog`. This function then calls `compile-ds` on the definitions. `compile-ds` recursively puts each definition on the heap, updating the environment as it goes. The environment is a pointer, stored in the `rdx` register, to where the definitions are on the stack. To make recursion possible the definition's environment needs to have a pointer to itself. My solution to this was to just compute the pointer first. So the function `tree->bits` calculates the pointer offset given the struct and then the head of the struct is matched to check what tag it should have. This system has multiple downsides. First, the heap allocation happens at runtime. Second, definitions can only reference definitions above them. Third, calculating the pointers like this leaves room for error. If there was anything I would change about how I implemented this project, it would be this.

After this we put the main expression on the heap, providing it with an environment containing all the definitions. Then all the definitions are popped off the stack and the reduction machine is called.

---

## The Graph Reduction Machine

Relevant files:

- `reduction.c` Contains the function `reduce` which contains all reduction logic

- `stack.c` Contains the implementation of linked list stack structure

- `values.c` Added various helper functions to deal with new heap structure

- `types.h` Contains all typing information and values

- `compile.rkt` Adds the reduce function call to the binary

The Graph Reduction Machine at its core consists of three rules:

1. If apply, push the left side onto the stack

2. If literal, return it

3. If function, apply it

The first two are self-explanatory, the bulk of the `reduce` function is for evaluating the third step. In this step, we match the function (with a very large switch statement) and replace it with the output. This output varies depending on which function is being applied.

---

### Example:

To check laziness I wrote a short program (stored in `example.rkt`):

```racket
(define (endless x) (endless (+ x 1)))

(define (first x y) x)

(first (+ 1 2) (endless 0))
```

The function `endless` recurses forever.

The function `first` returns the first argument.

When running this program with racket it never ends, as it attempts to evaluate `(endless 0)` when it is passed into `first`.  When compiled with the lazy runtime (`$ make example.run`) the program returns 3.

### Usage

I replaced all previous commands with new implementations. This means building programs with the lazy runtime is the same as building regular loot programs. `$ make program.run` should compile the racket program `program.rkt` using the new compiler. You can also use the racket repl the same way as before.
I removed all tests in the test directory that would not work in the new implementation (if the test used features not implemented). So all remaining tests should pass.
