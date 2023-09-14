#lang racket
(provide (all-defined-out))

;; type Prog = (Prog (Listof Defn) Expr)
(struct Prog (ds e) #:prefab)

;; type Defn = (Defn Id (Listof Id) Expr)
(struct Defn (f xs e) #:prefab)

;; type Expr = (Eof)
;;           | (Empty)
;;           | (Int Integer)
;;           | (Bool Boolean)
;;           | (Char Character)
;;           | (Prim0 Op0)
;;           | (Prim1 Op1 Expr)
;;           | (Prim2 Op2 Expr Expr)
;;           | (Prim3 Op3 Expr Expr Expr)
;;           | (Let Id Expr Expr)
;;           | (Var Id)
;;           | (App Expr (Listof Expr))
;;           | (Lam Id (Listof Id) Expr)
;; type Id   = Symbol
;; type Op0  = 'read-byte
;; type Op1  = 'add1 | 'sub1 | 'zero?
;;           | 'char? | 'integer->char | 'char->integer
;;           | 'write-byte | 'eof-object?
;; type Op2  = '+ | '- | '< | '=
;; type Op3  = 'if

(struct Eof   ()           #:prefab)
(struct Int   (i)          #:prefab)
(struct Bool  (b)          #:prefab)
(struct Char  (c)          #:prefab)
(struct Prim0 (p)          #:prefab)
(struct Prim1 (p e)        #:prefab)
(struct Prim2 (p e1 e2)    #:prefab)
(struct Prim3 (p e1 e2 e3) #:prefab)

(struct Let   (x e1 e2)    #:prefab)
(struct Var   (x)          #:prefab)
(struct App   (e es)       #:prefab)
(struct Lam   (f xs e)     #:prefab)

;; type SKI-Tree = (Apply (SKI-Tree) (SKI-Tree))
;;               | 'S
;;               | 'K
;;               | 'I
;;               | 'B
;;               | 'C
;;               | (Prim Op)
;;               | (Var Id)
;;               | (Eof)
;;               | (Int Integer)
;;               | (Bool Boolean)
;;               | (Char Character)
;; type Id       = Symbol
;; type Op       = 'read-byte \ 'write-byte
;;               | 'peek-byte | eof-object?
;;               | 'add1 | 'sub1 | 'zero?
;;               | 'char? | 'integer->char | 'char->integer
;;               '+ | '- | '< | '= | 'if
(struct Prim (p)    #:prefab)
(struct Apply (f x) #:prefab)

;; Combinators
(define S 'S)
(define K 'K)
(define I 'I)
(define B 'B)
(define C 'C)

;; Value -> Bool
(define (combinator? x)
  (and (symbol? x)
       (memq x '(S K I B C))))

;; Prog -> SKI-Prog
(define (abstract-prog p)
  (match p
    [(Prog ds es) (Prog (map abstract-prog ds) (abstract es #f))]
    [(Defn f '() e) (Defn f '() (abstract e #f))]
    [(Defn f (list x) e) (Defn f '() (abstract e x))]
    [(Defn f (list hd ... tl) e) (abstract-prog (Defn f hd (abstract e tl)))]))

;; Expr -> SKI-Tree
(define (abstract e v)
  (match e
    ;; Constants
    [(Eof) (Eof)]
    [(? combinator?)
     (if v
         (Apply K e)
         e)]
    [(Prim p)
     (if v
         (Apply K (Prim p))
         (Prim p))]
    [(Int i)
     (if v
         (Apply K (Int i))
         (Int i))]
    [(Bool b)
     (if v
         (Apply K (Bool b))
         (Bool b))]
    [(Char c)
     (if v
         (Apply K (Char c))
         (Char c))]
    ;; Variables
    [(Let x e1 e2) (abstract (Apply (abstract e2 x) e1) v)]
    [(Var x)
     (match v
       [#f (Var x)]
       [(== x) I]
       [_ (Apply K (Var x))])]
    ;; Functions + Applications
    [(Prim0 p)
     (if v
         (Apply K (Prim p))
         (Prim p))]
    [(Prim1 p e)
     (if v
         (Apply (Apply S (abstract (Prim0 p) v)) (abstract e v))
         (Apply (abstract (Prim0 p) v) (abstract e v)))]
    [(Prim2 p e1 e2)
     (if v
         (Apply (Apply S (abstract (Prim1 p e1) v)) (abstract e2 v))
         (Apply (abstract (Prim1 p e1) v) (abstract e2 v)))]
    [(Prim3 p e1 e2 e3)
     (if v
         (Apply (Apply S (abstract (Prim2 p e1 e2) v)) (abstract e3 v))
         (Apply (abstract (Prim2 p e1 e2) v) (abstract e3 v)))]
    [(App e '()) (abstract e v)]
    [(App e (list hd ... tl))
     (if v
         (Apply (Apply S (abstract (App e hd) v)) (abstract tl v))
         (Apply (abstract (App e hd) v) (abstract tl v)))]
    [(Lam _ '() e) (abstract e v)]
    [(Lam f (list hd ... tl) e) (abstract (Lam f hd (abstract e tl)) v)]
    [(Apply e1 e2)
     (if v
         (Apply (Apply S (abstract e1 v)) (abstract e2 v))
         (Apply (abstract e1 v) (abstract e2 v)))]))

;; SKI-Prog -> SKI-Prog
(define (optimize-prog p)
  (match p
    [(Prog ds es) (Prog (map optimize-prog ds) (optimize-expr es))]
    [(Defn f _ e) (Defn f '() (optimize-expr e))]))

;; SKI-Tree -> SKI-Tree
(define (optimize-expr e)
  (match e
    [(Apply (Apply 'S e1) e2)
     (match (Apply (Apply 'S (optimize-expr e1)) (optimize-expr e2))
       [(Apply (Apply 'S (Apply 'K e1)) (Apply 'K e2)) (optimize-expr (Apply K (Apply e1 e2)))]
       [(Apply (Apply 'S (Apply 'K e)) 'I) (optimize-expr e)]
       [(Apply (Apply 'S (Apply 'K e1)) e2) (Apply (Apply B (optimize-expr e1)) (optimize-expr e2))]
       [(Apply (Apply 'S e1) (Apply 'K e2)) (Apply (Apply C (optimize-expr e1)) (optimize-expr e2))]
       [e e])]
    [(Apply e1 e2) (Apply (optimize-expr e1) (optimize-expr e2))]
    [e e]))
