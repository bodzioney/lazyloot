#lang racket

;; Infinite Function
(define (endless x) (endless (+ x 1)))

;; Just return first argument
(define (first x y) x)

;; Passing two arguments into first
(first (+ 1 2) (endless 0))
