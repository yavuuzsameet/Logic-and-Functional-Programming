; yavuz samet topcuoglu
; compiling: yes
; complete: yes

#lang racket
(provide (all-defined-out)) ;compiled from terminal with command: racket -it .\autodiff.rkt

;; given
(struct num (value grad)
    #:property prop:custom-write
    (lambda (num port write?)
        (fprintf port (if write? "(num ~s ~s)" "(num ~a ~a)")
            (num-value num) (num-grad num))))
;; given
(define relu (lambda (x) (if (> (num-value x) 0) x (num 0.0 0.0))))
;; given
(define mse (lambda (x y) (mul (sub x y) (sub x y))))

(define (get-value num-list) (cond  ((num? num-list) (num-value num-list))
                                    ((equal? '() num-list) '())
                                    (else (cons (num-value (eval (car num-list))) (get-value (cdr num-list))))))

(define (get-grad num-list) (cond   ((num? num-list) (num-grad num-list))
                                    ((equal? '() num-list) '())
                                    (else (cons (num-grad (eval (car num-list))) (get-grad (cdr num-list))))))

(define (list-sum lst) ( ;summation of all elements in the list.
    cond    ((null? lst) 0)
            ((pair? (car lst))
            (+(list-sum (car lst)) (list-sum (cdr lst))))
            (else (+ (car lst) (list-sum (cdr lst))))))

(define (list-sub lst) ( ;subtraction of all elements from the first in the list.
    cond    ((null? lst) 0)
            ((pair? (car lst))
            (-(list-sub (car lst)) (list-sub (cdr lst))))
            (else (- (car lst) (list-sub (cdr lst))))))

(define (list-mul lst) ( ;multiplication of all elements in the list.
    cond    ((null? lst) 1)
            ((pair? (car lst))
            (*(list-mul (car lst)) (list-mul (cdr lst))))
            (else (* (car lst) (list-mul (cdr lst))))))

(define (add . args) (num (list-sum (get-value (car(list args)))) (list-sum (get-grad (car(list args))))))

(define (sub . args) (num (list-sub (get-value (car(list args)))) (list-sub (get-grad (car(list args))))))

(define (mul . argv) (
    num (list-mul (get-value (car(list argv)))) (mult (car(list argv)) (list-mul (get-value (car(list argv)))))
))
(define (mult list tot) (
    cond ((null? list) 0)
         (else (+ (/ (* tot (num-grad(car list))) (num-value (car list))) (mult (cdr list) tot)))
))

(define (create-hash names values var)(
    make-hash (crreate-hash names values var)
))
(define (crreate-hash names values var)(
    cond ((null? names) '())
         ((equal? (car names) var) (cons (cons (car names) (num (car values) 1.0)) (crreate-hash (cdr names) (cdr values) var)))
         (else (cons (cons (car names) (num (car values) 0.0)) (crreate-hash (cdr names) (cdr values) var)))
))

(define (parse hash expr) (
    cond ((null? expr) '())
         ((list? expr) (cons (parse hash (car expr)) (parse hash (cdr expr))))
         ((equal? expr '+) 'add)
         ((equal? expr '-) 'sub)
         ((equal? expr '*) 'mul)
         ((equal? expr 'mse) 'mse)
         ((equal? expr 'relu) 'relu)
         ((number? expr) (num expr 0.0))
         (else (hash-ref hash expr))
))

(define (grad names values var expr) (num-grad (eval (parse (create-hash names values var) expr))))

(define (partial-grad names values vars expr) (map (lambda (atom) (if (list? (member atom vars)) (grad names values atom expr) 0.0)) names))

(define (mulbycons lst x) (map (lambda (n) (* x n)) lst))

(define (gradient-descent names values vars lr expr) (map - values (mulbycons (partial-grad names values vars expr) lr)))

(define (optimize names values vars lr k expr) (
    cond ((equal? k 1) (gradient-descent names values vars lr expr))
         (else (optimize names (gradient-descent names values vars lr expr) vars lr (sub1 k) expr))
))



