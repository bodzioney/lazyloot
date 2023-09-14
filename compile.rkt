#lang racket

(provide (all-defined-out))
(require "ast.rkt" "types.rkt" a86/ast)

;; type CEnv = [Listof Id]

;; Registers used
(define rax 'rax) ; return
(define rbx 'rbx) ; heap
(define rdx 'rdx) ; environment
(define rsp 'rsp) ; stack
(define rdi 'rdi) ; arg
(define r15 'r15) ; stack pad (non-volatile)

;; Prog -> Asm
(define (compile p)
  (compile-prog
   (optimize-prog
    (abstract-prog p))))

;; SKI-Prog -> Asm
(define (compile-prog p)
  (match p
    [(Prog ds t)
     (let ((gls (get-globals ds)))
       (prog
        (Extern 'reduce)
        (Global 'entry)
        (Label 'entry)
        (Push rbx)    ; save callee-saved register
        (Mov rbx rdi) ; recv heap pointer
        (compile-ds ds '())
        (Mov rdx rsp)
        (compile-tree t (reverse gls))
        (Add rsp (* 8 (length gls))) ; Pop enviroment
        pad-stack
        (Mov rdi rax)
        (Call 'reduce)
        unpad-stack
        (Pop rbx)     ; restore callee-save register
        (Ret)))]))

;; [Listof Defn] -> [Listof String]
(define (get-globals ds)
  (match ds
    ['() '()]
    [(cons (Defn f _ _) ds)
     (cons f (get-globals ds))]))

;; [Listof Defn] -> Asm
(define (compile-ds ds c)
  (match ds
    ['() (seq)]
    [(cons (Defn f _ d) ds)
     (let ((env (cons f c)))
       (seq (Mov rdx rbx)
            (Add rdx (tree->bits d #t))
            (match d
              [(Apply _ _) (Or rdx type-app)]
              [(Prim _) (Or rdx type-fun)]
              [_ (Or rdx type-lit)])
            (Push rdx)
            (Mov rdx rsp)
            (compile-tree d env)
            (Add rsp 8)
            (Push rax)
            (compile-ds ds env)))]))

;; Literal -> Asm
(define (compile-lit v)
  (seq (Mov rax (value->bits v))
       (Mov (Offset rbx 0) rax)
       (Mov rax rbx)
       (Or rax type-lit)
       (Add rbx 8)))

;; Function -> Asm
(define (compile-fun v)
  (seq (Mov rax (value->bits v))
       (Mov (Offset rbx 0) rax)
       (Mov rax rbx)
       (Or rax type-fun)
       (Add rbx 8)))

;; SKI-Tree -> Asm
(define (compile-tree t c)
  (match t
    [(Int i)            (compile-lit i)]
    [(Bool b)           (compile-lit b)]
    [(Char c)           (compile-lit c)]
    [(Eof)              (compile-lit eof)]
    [(? combinator?)    (compile-fun t)]
    [(Prim p)           (compile-fun p)]
    [(Var v)            (Mov rax (Offset rdx (lookup v c)))]
    [(Apply t1 t2)
     (seq  (compile-tree t2 c)
           (Push rax)
           (compile-tree t1 c)
           (Mov (Offset rbx 0) rax)
           (Pop rax)
           (Mov (Offset rbx 8) rax)
           (Mov rax rbx)
           (Or rax type-app)
           (Add rbx 16))]))

;; Asm
;; Dynamically pad the stack to be aligned for a call
(define pad-stack
  (seq (Mov r15 rsp)
       (And r15 #b1000)
       (Sub rsp r15)))

;; Asm
;; Undo the stack alignment after a call
(define unpad-stack
  (seq (Add rsp r15)))

;; Id CEnv -> Integer
(define (lookup x cenv)
  (match cenv
    ['() (error "undefined variable:" x)]
    [(cons y rest)
     (match (eq? x y)
       [#t 0]
       [#f (+ 8 (lookup x rest))])]))

;; SKI-Tree -> Int
;; Hacky way to computer pointer befor it exists
(define (tree->bits t h?)
  (match t
    [(Apply f x) (+ (if h? 0 16) (tree->bits f #f) (tree->bits x #f))]
    [(Var _) 0]
    [_ (if h? 0 8)]))