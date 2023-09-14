#include "values.h"
#include "types.h"
#include <stdlib.h>

type_t val_typeof_ptr(val_t x)
{

    switch (x & ptr_type_mask) {

    case lit_type_tag:
        return T_LIT;
    case app_type_tag:
        return T_APP;
    case fun_type_tag:
        return T_FUN;
    }
}
type_t val_typeof_lit(val_t x)
{
    if ((int_type_mask & x) == int_type_tag)
        return T_INT;
    if ((char_type_mask & x) == char_type_tag)
        return T_CHAR;

    switch (x) {
    case val_true:
    case val_false:
        return T_BOOL;
    case val_eof:
        return T_EOF;
    case val_void:
        return T_VOID;
    case val_empty:
        return T_EMPTY;
    }

    return T_INVALID;
}

int64_t val_unwrap_int(val_t x)
{
    return x >> int_shift;
}
val_t val_wrap_int(int64_t i)
{
    return (i << int_shift) | int_type_tag;
}

int val_unwrap_bool(val_t x)
{
    return x == val_true;
}
val_t val_wrap_bool(int b)
{
    return b ? val_true : val_false;
}

val_char_t val_unwrap_char(val_t x)
{
    return (val_char_t)(x >> char_shift);
}
val_t val_wrap_char(val_char_t c)
{
    return (((val_t)c) << char_shift) | char_type_tag;
}

val_t val_wrap_eof(void)
{
    return val_eof;
}

val_t val_wrap_void(void)
{
    return val_void;
}

val_lit_t* val_unwrap_lit(val_t x)
{
    return (val_lit_t*)(x ^ lit_type_tag);
}
val_t val_wrap_lit(val_lit_t* v)
{
    return ((val_t)v) | lit_type_tag;
}

val_app_t* val_unwrap_app(val_t x)
{
    return (val_app_t*)(x ^ app_type_tag);
}

val_t val_wrap_app(val_app_t* a)
{
    return ((val_t)a) | app_type_tag;
}

val_fun_t* val_unwrap_fun(val_t x)
{
    return (val_fun_t*)(x ^ fun_type_tag);
}
val_t val_wrap_fun(val_fun_t* f)
{
    return ((val_t)f) | fun_type_tag;
}

val_t new_lit(val_t x)
{
    val_lit_t* lit = (val_lit_t*)malloc(sizeof(val_lit_t));
    lit->val = x;

    return val_wrap_lit(lit);
}

val_t new_app(val_t fst, val_t snd)
{
    val_app_t* app = (val_app_t*)malloc(sizeof(val_app_t));
    app->fst = fst;
    app->snd = snd;

    return val_wrap_app(app);
}

val_t new_fun(val_t f)
{
    val_fun_t* fun = (val_fun_t*)malloc(sizeof(val_fun_t));
    fun->val = f;

    return val_wrap_fun(fun);
}