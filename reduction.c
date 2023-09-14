#include "io.h"
#include "runtime.h"
#include "stack.h"
#include "types.h"
#include "values.h"
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>

val_t reduce(val_t root)
{
    // Get stopping point
    node* breakpoint = head;
    // Push head onto stack
    push(root);

    // Loop until stack is empty
    while (head != breakpoint) {

        // Check first args types
        val_t curr = peek();
        switch (curr & ptr_type_mask) {
        case lit_type_tag:
            pop();
            return val_unwrap_lit(curr)->val;
        case app_type_tag: {
            // Unwrap and push left most node
            val_app_t* a = val_unwrap_app(curr);

            push(a->fst);
            continue;
        }
        case fun_type_tag: {
            val_fun_t* f = val_unwrap_fun(curr);
            // If function, apply it
            switch (f->val) {
            case val_S: {
                val_app_t* app;

                pop(); // Remove S literal

                app = val_unwrap_app(peek());
                val_t f = app->snd; // Get f
                pop();

                app = val_unwrap_app(peek());
                val_t g = app->snd; // Get g
                pop();

                app = val_unwrap_app(peek());
                val_t x = app->snd; // Get x
                pop();

                // Replace final node with new one
                val_t f_x = new_app(f, x);
                val_t g_x = new_app(g, x);

                push(new_app(f_x, g_x));
                continue;
            }
            case val_K: {
                val_app_t* app;

                pop(); // Pop off K literal

                app = val_unwrap_app(peek());
                val_t x = app->snd;
                pop(); // Get x

                pop(); // Pop y

                // Push (Apply I x)
                val_t fun_I = new_fun(val_I);
                push(new_app(fun_I, x));
                continue;
            }
            case val_I: {
                pop(); // Pop I literal off

                // Get and push x
                val_app_t* app = val_unwrap_app(peek());
                val_t new = app->snd;
                pop();
                push(new);
                continue;
            }
            case val_B: {
                val_app_t* app;

                pop(); // Pop off B literal

                app = val_unwrap_app(peek());
                val_t f = app->snd; // Get f
                pop();

                app = val_unwrap_app(peek());
                val_t g = app->snd; // Get g
                pop();

                app = val_unwrap_app(peek());
                val_t x = app->snd; // Get x
                pop();

                val_t g_x = new_app(g, x);
                push(new_app(f, g_x));
                continue;
            }
            case val_C: {
                val_app_t* app;

                pop(); // Pop off B literal

                app = val_unwrap_app(peek());
                val_t f = app->snd; // Get f
                pop();

                app = val_unwrap_app(peek());
                val_t g = app->snd; // Get g
                pop();

                app = val_unwrap_app(peek());
                val_t x = app->snd; // Get x
                pop();

                val_t f_x = new_app(f, x);
                push(new_app(f_x, g)); // Push new node
                continue;
            }
            case val_read_byte: {
                pop(); // Pop off literal
                val_t input = new_lit(read_byte());
                push(input);
                continue;
            }
            case val_write_byte: {
                pop(); // Pop off literal

                val_app_t* app = val_unwrap_app(peek());
                val_t byte = reduce(app->snd); // Get reduced arg
                pop();

                // Check if byte
                if (val_typeof_lit(byte) != T_INT) {
                    error_handler();
                }
                if (byte > 255 || byte < 0) {
                    error_handler();
                }
                val_t v = write_byte(byte);

                push(new_lit(v)); // Push result
                continue;
            }
            case val_peek_byte: {
                pop(); // Pop off literal
                val_t input = new_lit(peek_byte());
                push(input);
                continue;
            }
            case val_eof_obj: {
                pop(); // Pop off literal

                val_app_t* app = val_unwrap_app(peek());
                val_t x = reduce(app->snd); // Get reduced arg
                pop();

                // If eof true else false
                val_t bool;
                val_t fun_I = new_fun(val_I);
                if (val_typeof_lit(x) == T_EOF) {
                    bool = new_lit(val_true);
                } else {
                    bool = new_lit(val_false);
                }

                push(new_app(fun_I, bool));
                continue;
            }
            case val_add1: {
                pop(); // Pop off literal

                val_app_t* app = val_unwrap_app(peek());
                val_t x = reduce(app->snd); // Get reduced arg
                pop();

                // Type check
                if (val_typeof_lit(x) != T_INT) {
                    error_handler();
                }

                // Add 1 to x and push
                val_t fun_I = new_fun(val_I);
                val_t diff = new_lit(x + (val_wrap_int(1)));
                push(new_app(fun_I, diff));
                continue;
            }
            case val_sub1: {
                pop(); // Pop off literal

                val_app_t* app = val_unwrap_app(peek());
                val_t x = reduce(app->snd); // Get reduced arg
                pop();

                // Type check
                if (val_typeof_lit(x) != T_INT) {
                    error_handler();
                }

                // Sub 1 from x and push
                val_t fun_I = new_fun(val_I);
                val_t diff = new_lit(x - (val_wrap_int(1)));
                push(new_app(fun_I, diff));
                continue;
            }
            case val_zero: {
                pop(); // Pop off literal

                val_app_t* app = val_unwrap_app(peek());
                val_t x = reduce(app->snd); // Get reduced arg
                pop();

                // Type check
                if (val_typeof_lit(x) != T_INT) {
                    error_handler();
                }

                // Compare
                val_t fun_I = new_fun(val_I);
                val_t bool;
                if (x == 0) {
                    bool = new_lit(val_true);
                } else {
                    bool = new_lit(val_false);
                }

                push(new_app(fun_I, bool)); // Push new node
                continue;
            }
            case val_char: {
                pop(); // Pop off literal

                val_app_t* app = val_unwrap_app(peek());
                val_t x = reduce(app->snd); // Get reduced arg
                pop();

                // Check type and push bool
                val_t fun_I = new_fun(val_I);
                val_t bool;
                if (val_typeof_lit(x) == T_CHAR) {
                    bool = new_lit(val_true);
                } else {
                    bool = new_lit(val_false);
                }
                push(new_app(fun_I, bool));
                continue;
            }
            case val_char_to_int: {
                pop(); // Pop off the literal

                val_app_t* app = val_unwrap_app(peek());
                val_t x = reduce(app->snd); // Get reduced arg
                pop();

                // Type check
                if (val_typeof_lit(x) != T_CHAR) {
                    error_handler();
                }

                // Perform shifts and push
                val_t fun_I = new_fun(val_I);
                x = val_unwrap_char(x);
                x = val_wrap_int(x);

                push(new_app(fun_I, new_lit(x)));
                continue;
            }
            case val_int_to_char: {
                pop(); // Pop off the literal

                val_app_t* app = val_unwrap_app(peek());
                val_t x = reduce(app->snd); // Get reduced arg
                pop();

                // Type check
                if (val_typeof_lit(x) != T_INT) {
                    error_handler();
                }

                // Assert codepoint
                if (x > 1114111 || 0 > x) {
                    error_handler();
                }
                if (55295 >= x && x >= 57344) {
                    error_handler();
                }

                // Perform shifts and push
                val_t fun_I = new_fun(val_I);
                x = val_unwrap_int(x);
                x = val_wrap_char(x);

                push(new_app(fun_I, new_lit(x)));
                continue;
            }
            case val_lt: {
                val_app_t* app;

                pop(); // Pop off literal

                // Get first apply and reduce
                app = val_unwrap_app(peek());
                val_t x = reduce(app->snd);
                pop();

                // Get second apply and reduce
                app = val_unwrap_app(peek());
                val_t y = reduce(app->snd);
                pop();

                // Check type of the literals
                if (val_typeof_lit(x) != T_INT || val_typeof_lit(y) != T_INT) {
                    error_handler();
                }

                // Compare and push new node
                val_t fun_I = new_fun(val_I);
                val_t bool;
                if (x < y) {
                    bool = new_lit(val_true);
                } else {
                    bool = new_lit(val_false);
                }

                push(new_app(fun_I, bool));
                continue;
            }
            case val_equals: {
                val_app_t* app;

                pop(); // Pop off literal

                // Get first apply and reduce
                app = val_unwrap_app(peek());
                val_t x = reduce(app->snd);
                pop();

                // Get second apply and reduce
                app = val_unwrap_app(peek());
                val_t y = reduce(app->snd);
                pop();

                // Check type of the literals
                if (val_typeof_lit(x) != T_INT || val_typeof_lit(y) != T_INT) {
                    error_handler();
                }

                // Compare and push new node
                val_t fun_I = new_fun(val_I);
                val_t bool;
                if (x == y) {
                    bool = new_lit(val_true);
                } else {
                    bool = new_lit(val_false);
                }

                push(new_app(fun_I, bool));
                continue;
            }
            case val_plus: {
                val_app_t* app;

                pop(); // Pop off literal

                // Get first apply and reduce
                app = val_unwrap_app(peek());
                val_t x = reduce(app->snd);
                pop();

                // Get second apply and reduce
                app = val_unwrap_app(peek());
                val_t y = reduce(app->snd);
                pop();

                // Check type of the literals
                if (val_typeof_lit(x) != T_INT || val_typeof_lit(y) != T_INT) {
                    error_handler();
                }

                // Replace node with (Apply 'I (+ first second)):
                val_t fun_I = new_fun(val_I);
                val_t sum = new_lit(x + y);
                push(new_app(fun_I, sum));
                continue;
            }
            case val_minus: {
                val_app_t* app;

                pop(); // Pop off literal

                // Get first apply and reduce
                app = val_unwrap_app(peek());
                val_t x = reduce(app->snd);
                pop();

                // Get second apply and reduce
                app = val_unwrap_app(peek());
                val_t y = reduce(app->snd);
                pop();

                // Check type of the literals
                if (val_typeof_lit(x) != T_INT || val_typeof_lit(y) != T_INT) {
                    error_handler();
                }

                // Replace node with (Apply 'I (- first second)):
                val_t fun_I = new_fun(val_I);
                val_t diff = new_lit(x - y);
                push(new_app(fun_I, diff));
                continue;
            }
            case val_eq: {
                val_app_t* app;

                pop(); // Pop off literal

                app = val_unwrap_app(peek());
                val_t x = reduce(app->snd); // Get x
                pop();

                app = val_unwrap_app(peek());
                val_t y = reduce(app->snd); // Get y
                pop();

                val_t fun_I = new_fun(val_I);
                val_t bool;
                if (x == y) {
                    bool = new_lit(val_true);
                } else {
                    bool = new_lit(val_false);
                }

                push(new_app(fun_I, bool));

                continue;
            }
            case val_if: {
                val_app_t* app;

                // Pop if literal off
                pop();

                // Get, reduce, then pop bool
                app = val_unwrap_app(peek());
                val_t bool = reduce(app->snd);
                pop();

                val_t fun_I = new_fun(val_I);
                val_t branch;
                if (bool == val_false) {
                    pop(); // Pop off x
                    app = val_unwrap_app(peek());
                    branch = new_app(fun_I, app->snd); // Get and make (Apply I y)
                    pop(); // Pop y
                } else {
                    app = val_unwrap_app(peek());
                    branch = new_app(fun_I, app->snd); // Get and make (Apply I x)
                    pop();
                    pop(); // Pop off x and y
                }
                push(branch); // Push resulting branch
                continue;
            }
            }
            error_handler();
        }
        }
    }
}