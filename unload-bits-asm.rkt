#lang racket
(provide unload/free)
(require "types.rkt"
         ffi/unsafe)

;; Answer* -> Answer
(define (unload/free a)
  (match a
    ['err 'err]
    [(cons h v) (begin0 (bits->value v)
                        (free h))]))


(define (untag i)
  (arithmetic-shift (arithmetic-shift i (- (integer-length ptr-mask)))
                    (integer-length ptr-mask)))

(define (heap-ref i)
  (ptr-ref (cast (untag i) _int64 _pointer) _int64))

(define (char-ref i j)
  (integer->char (ptr-ref (cast (untag i) _int64 _pointer) _uint32 j)))
