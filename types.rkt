#lang racket
(provide (all-defined-out))

(define imm-shift          3)
(define imm-mask       #b111)
(define ptr-mask       #b111)
(define type-app       #b001)
(define type-lit       #b010)
(define type-fun       #b011)
(define int-shift          1)
(define char-shift         2)
(define type-int         #b0)
(define mask-int         #b1)
(define type-char       #b01)
(define mask-char       #b11)
(define val-true      #b0011)
(define val-false     #b0111)
(define val-eof       #b1011)
(define val-void      #b1111)

;; Completely arbitrary numerical values for primatives/combinators
;; These will be stored in boxes tagged as functions
(define val-S #b0001)
(define val-K #b0010)
(define val-I #b0011)
(define val-B #b0100)
(define val-C #b0101)
(define val-read-byte #b0110)
(define val-write-byte #b0111)
(define val-peek-byte #b1000)
(define val-add1 #b1001)
(define val-sub1 #b1010)
(define val-zero? #b1011)
(define val-char? #b1100)
(define val-char->integer #b1101)
(define val-integer->char #b1110)
(define val-plus #b1111)
(define val-minus #b10000)
(define val-lt #b10001)
(define val-equals #b10010)
(define val-eq? #b10011)
(define val-if #b10100)
(define val-eof? #b10101)


(define (bits->value b)
  (cond [(= type-int (bitwise-and b mask-int))
         (arithmetic-shift b (- int-shift))]
        [(= type-char (bitwise-and b mask-char))
         (integer->char (arithmetic-shift b (- char-shift)))]
        [(= b val-true)  #t]
        [(= b val-false) #f]
        [(= b val-eof)  eof]
        [(= b val-void) (void)]
        [else (error "invalid bits")]))

(define (value->bits v)
  (cond [(eof-object? v) val-eof]
        [(integer? v) (arithmetic-shift v int-shift)]
        [(char? v)
         (bitwise-ior type-char
                      (arithmetic-shift (char->integer v) char-shift))]
        [(eq? v #t) val-true]
        [(eq? v #f) val-false]
        [(void? v)  val-void]
        [(eq? v 'S) val-S]
        [(eq? v 'K) val-K]
        [(eq? v 'I) val-I]
        [(eq? v 'B) val-B]
        [(eq? v 'C) val-C]
        [(eq? v 'read-byte) val-read-byte]
        [(eq? v 'write-byte) val-write-byte]
        [(eq? v 'peek-byte) val-peek-byte]
        [(eq? v 'eof-object?) val-eof?]
        [(eq? v 'add1) val-add1]
        [(eq? v 'sub1) val-sub1]
        [(eq? v 'zero?) val-zero?]
        [(eq? v 'char?) val-char?]
        [(eq? v 'char->integer) val-char->integer]
        [(eq? v 'integer->char) val-integer->char]
        [(eq? v '+) val-plus]
        [(eq? v '-) val-minus]
        [(eq? v '<) val-lt]
        [(eq? v '=) val-equals]
        [(eq? v 'eq?) val-eq?]
        [(eq? v 'if) val-if]
        [else (error "not an immediate value" v)]))

(define (imm-bits? v)
  (zero? (bitwise-and v imm-mask)))

(define (int-bits? v)
  (zero? (bitwise-and v mask-int)))

(define (char-bits? v)
  (= type-char (bitwise-and v mask-char)))