#ifndef VALUES_H
#define VALUES_H

#include <stdint.h>

/* any abstract value */
typedef int64_t val_t;

typedef enum type_t {
  T_INVALID = -1,
  /* immediates */
  T_INT,
  T_BOOL,
  T_CHAR,
  T_EOF,  
  T_VOID,
  T_EMPTY,
  /* pointers */
  T_APP,
  T_LIT,
  T_FUN,
  T_STR,
  T_PROC,
} type_t;

typedef uint32_t val_char_t;
typedef struct val_lit_t {
  val_t val;
} val_lit_t;
typedef struct val_app_t {
  val_t fst;
  val_t snd;
} val_app_t;
typedef struct val_fun_t {
  val_t val;
} val_fun_t;

/* return the type of x */
type_t val_typeof_lit(val_t x);
type_t val_typeof_ptr(val_t x);

/**
 * Wrap/unwrap values
 *
 * The behavior of unwrap functions are undefined on type mismatch.
 */
int64_t val_unwrap_int(val_t x);
val_t val_wrap_int(int64_t i);

int val_unwrap_bool(val_t x);
val_t val_wrap_bool(int b);

val_char_t val_unwrap_char(val_t x);
val_t val_wrap_char(val_char_t b);

val_t val_wrap_eof();

val_t val_wrap_void();

val_lit_t* val_unwrap_lit(val_t x);
val_t val_wrap_lit(val_lit_t* l);

val_app_t* val_unwrap_app(val_t x);
val_t val_wrap_app(val_app_t* a);

val_fun_t* val_unwrap_fun(val_t x);
val_t val_wrap_fun(val_fun_t* f);

/**
 * Create nodes on heap
*/
val_t new_fun(val_t f);
val_t new_lit(val_t x);
val_t new_app(val_t fst, val_t snd);

#endif
