#ifndef TYPES_H
#define TYPES_H

// Pointer tags
#define imm_shift 3
#define ptr_type_mask ((1 << imm_shift) - 1)
#define app_type_tag 1
#define lit_type_tag 2
#define fun_type_tag 3

/*
 Values are either:
  - Integers:   end in  #b0
  - Characters: end in #b01
  - True:              #b11
  - False:            #b111
  - Eof:             #b1011
  - Void:            #b1111
*/
#define int_shift 1
#define int_type_mask ((1 << int_shift) - 1)
#define int_type_tag (0 << (int_shift - 1))
#define nonint_type_tag (1 << (int_shift - 1))
#define char_shift (int_shift + 1)
#define char_type_mask ((1 << char_shift) - 1)
#define char_type_tag ((0 << (char_shift - 1)) | nonint_type_tag)
#define nonchar_type_tag ((1 << (char_shift - 1)) | nonint_type_tag)
#define val_true ((0 << char_shift) | nonchar_type_tag)
#define val_false ((1 << char_shift) | nonchar_type_tag)
#define val_eof ((2 << char_shift) | nonchar_type_tag)
#define val_void ((3 << char_shift) | nonchar_type_tag)
#define val_empty ((4 << char_shift) | nonchar_type_tag)

// Function Values
#define val_S 1
#define val_K 2
#define val_I 3
#define val_B 4
#define val_C 5
#define val_read_byte 6
#define val_write_byte 7
#define val_peek_byte 8
#define val_add1 9
#define val_sub1 10
#define val_zero 11
#define val_char 12
#define val_char_to_int 13
#define val_int_to_char 14
#define val_plus 15
#define val_minus 16
#define val_lt 17
#define val_equals 18
#define val_eq 19
#define val_if 20
#define val_eof_obj 21

#endif
