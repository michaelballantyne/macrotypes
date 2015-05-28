#lang racket/base
(require
  (for-syntax racket/base syntax/parse)
  "typecheck.rkt")
(require "stlc.rkt")
(provide (all-from-out "stlc.rkt"))
(provide (rename-out [datum/tc #%datum]))
 
;; Simply-Typed Lambda Calculus, plus numeric literals and primitives
;; Types:
;; - types from stlc.rkt
;; - Int
;; Terms:
;; - terms from stlc.rkt
;; - numeric literals
;; - prim +

(define-base-type Int)

(define-primop + : (→ Int Int Int))

(define-syntax (datum/tc stx)
  (syntax-parse stx
    [(_ . n:integer) (⊢ (syntax/loc stx (#%datum . n)) #'Int)]
    [(_ . x)
     #:when (type-error #:src #'x #:msg "Unsupported literal: ~v" #'x)
     #'(#%datum . x)]))