#lang racket
(provide test-runner test-runner-io)
(require rackunit)

(define (test-runner run)
  ;; Abscond examples
  (check-equal? (run 7) 7)
  (check-equal? (run -8) -8)

  ;; Blackmail examples
  (check-equal? (run '(add1 (add1 7))) 9)
  (check-equal? (run '(add1 (sub1 7))) 7)

  ;; Con examples
  (check-equal? (run '(if (zero? 0) 1 2)) 1)
  (check-equal? (run '(if (zero? 1) 1 2)) 2)
  (check-equal? (run '(if (zero? -7) 1 2)) 2)
  (check-equal? (run '(if (zero? 0)
                          (if (zero? 1) 1 2)
                          7))
                2)
  (check-equal? (run '(if (zero? (if (zero? 0) 1 0))
                          (if (zero? 1) 1 2)
                          7))
                7)

  ;; Dupe examples
  (check-equal? (run #t) #t)
  (check-equal? (run #f) #f)
  (check-equal? (run '(if #t 1 2)) 1)
  (check-equal? (run '(if #f 1 2)) 2)
  (check-equal? (run '(if 0 1 2)) 1)
  (check-equal? (run '(if #t 3 4)) 3)
  (check-equal? (run '(if #f 3 4)) 4)
  (check-equal? (run '(if  0 3 4)) 3)
  (check-equal? (run '(zero? 4)) #f)
  (check-equal? (run '(zero? 0)) #t)

  ;; Dodger examples
  (check-equal? (run #\a) #\a)
  (check-equal? (run #\b) #\b)
  (check-equal? (run '(char? #\a)) #t)
  (check-equal? (run '(char? #t)) #f)
  (check-equal? (run '(char? 8)) #f)
  (check-equal? (run '(char->integer #\a)) (char->integer #\a))
  (check-equal? (run '(integer->char 955)) #\λ)

  ;; Extort examples
  (check-equal? (run '(add1 #f)) 'err)
  (check-equal? (run '(sub1 #f)) 'err)
  (check-equal? (run '(zero? #f)) 'err)
  (check-equal? (run '(char->integer #f)) 'err)
  (check-equal? (run '(integer->char #f)) 'err)
  (check-equal? (run '(integer->char -1)) 'err)
  (check-equal? (run '(write-byte #f)) 'err)
  (check-equal? (run '(write-byte -1)) 'err)
  (check-equal? (run '(write-byte 256)) 'err)

  ;; Fraud examples
  (check-equal? (run '(let ((x 7)) x)) 7)
  (check-equal? (run '(let ((x 7)) 2)) 2)
  (check-equal? (run '(let ((x 7)) (add1 x))) 8)
  (check-equal? (run '(let ((x (add1 7))) x)) 8)
  (check-equal? (run '(let ((x 7)) (let ((y 2)) x))) 7)
  (check-equal? (run '(let ((x 7)) (let ((x 2)) x))) 2)
  (check-equal? (run '(let ((x 7)) (let ((x (add1 x))) x))) 8)

  (check-equal? (run '(let ((x 0))
                        (if (zero? x) 7 8)))
                7)
  (check-equal? (run '(let ((x 1))
                        (add1 (if (zero? x) 7 8))))
                9)
  (check-equal? (run '(+ 3 4)) 7)
  (check-equal? (run '(- 3 4)) -1)
  (check-equal? (run '(+ (+ 2 1) 4)) 7)
  (check-equal? (run '(+ (+ 2 1) (+ 2 2))) 7)
  (check-equal? (run '(let ((x (+ 1 2)))
                        (let ((z (- 4 x)))
                          (+ (+ x x) z))))
                7)
  (check-equal? (run '(= 5 5)) #t)
  (check-equal? (run '(= 4 5)) #f)
  (check-equal? (run '(= (add1 4) 5)) #t)
  (check-equal? (run '(< 5 5)) #f)
  (check-equal? (run '(< 4 5)) #t)
  (check-equal? (run '(< (add1 4) 5)) #f)

  ;; Hustle examples
  (check-equal? (run '(eq? 1 1)) #t)
  (check-equal? (run '(eq? 1 2)) #f)

  ;; Iniquity tests
  (check-equal? (run
                 '(define (f x) x)
                 '(f 5))
                5)

  (check-equal? (run
                 '(define (tri x)
                    (if (zero? x)
                        0
                        (+ x (tri (sub1 x)))))
                 '(tri 9))
                45)

  (check-equal? (run
                 '(define (f x) x)
                 '(define (g x) (f x))
                 '(g 5))
                5)
  (check-equal? (run
                 '(define (f x)
                    10)
                 '(f 1))
                10)
  (check-equal? (run
                 '(define (f x)
                    10)
                 '(let ((x 2)) (f 1)))
                10)
  (check-equal? (run
                 '(define (f x y)
                    10)
                 '(f 1 2))
                10)
  (check-equal? (run
                 '(define (f x y)
                    10)
                 '(let ((z 2)) (f 1 2)))
                10)
  (check-equal? (run '(define (f x y) y)
                     '(f 1 (add1 #f)))
                'err)
  ;; Loot examples
  (check-equal? (run '((λ (x) x) 5))
                5)

  (check-equal? (run '(let ((f (λ (x) x))) (f 5)))
                5)
  (check-equal? (run '(let ((f (λ (x y) x))) (f 5 7)))
                5)
  (check-equal? (run '(let ((f (λ (x y) y))) (f 5 7)))
                7)
  (check-equal? (run '(define (adder n)
                        (λ (x) (+ x n)))
                     '((adder 5) 10))
                15)
  (check-equal? (run '(((λ (t)
                          ((λ (f) (t (λ (z) ((f f) z))))
                           (λ (f) (t (λ (z) ((f f) z))))))
                        (λ (tri)
                          (λ (n)
                            (if (zero? n)
                                0
                                (+ n (tri (sub1 n)))))))
                       36))
                666)
  (check-equal? (run '(define (tri n)
                        (if (zero? n)
                            0
                            (+ n (tri (sub1 n)))))
                     '(tri 36))
                666)
  )

(define (test-runner-io run)
  ;; Evildoer examples
  (check-equal? (run "" 7) (cons 7 ""))
  (check-equal? (run "" '(write-byte 97)) (cons (void) "a"))
  (check-equal? (run "a" '(read-byte)) (cons 97 ""))
  (check-equal? (run "" '(read-byte)) (cons eof ""))
  (check-equal? (run "" '(eof-object? (read-byte))) (cons #t ""))
  (check-equal? (run "a" '(eof-object? (read-byte))) (cons #f ""))

  (check-equal? (run "ab" '(peek-byte)) (cons 97 ""))
  ;; Extort examples
  (check-equal? (run "" '(write-byte #t)) (cons 'err ""))

  ;; Fraud examples
  (check-equal? (run "" '(let ((x 97)) (write-byte x))) (cons (void) "a")))