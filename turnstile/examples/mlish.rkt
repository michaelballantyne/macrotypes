#lang turnstile/lang
(require
 (postfix-in - racket/fixnum)
 (postfix-in - racket/flonum)
 (postfix-in - racket/match)
 (for-syntax macrotypes/type-constraints macrotypes/variance-constraints))

(extends
 "ext-stlc.rkt"
 #:except → define #%app λ #%datum begin
          + - * void = zero? sub1 add1 not let let* and
 #:rename [~→ ~ext-stlc:→])
(reuse inst #:from "sysf.rkt")
(require (only-in "ext-stlc.rkt" → →?))
(require (only-in "sysf.rkt" ~∀ ∀ ∀? Λ))
(reuse × tup proj define-type-alias #:from "stlc+rec-iso.rkt")
(require (only-in "stlc+rec-iso.rkt" ~× ×?))
(provide (rename-out [ext-stlc:and and] [ext-stlc:#%datum #%datum]))
(reuse member length reverse list-ref cons nil isnil head tail list
       #:from "stlc+cons.rkt")
(require (prefix-in stlc+cons: (only-in "stlc+cons.rkt" list cons nil)))
(require (only-in "stlc+cons.rkt" ~List List? List))
(reuse ref deref := Ref #:from "stlc+box.rkt")
(require (rename-in (only-in "stlc+reco+var.rkt" tup proj ×)
           [tup rec] [proj get] [× ××]))
(provide rec get ××)
;; for pattern matching
(require (prefix-in stlc+cons: (only-in "stlc+cons.rkt" list)))
(require (prefix-in stlc+tup: (only-in "stlc+tup.rkt" tup)))

;; ML-like language
;; - top level recursive functions
;; - user-definable algebraic datatypes
;; - pattern matching
;; - (local) type inference

(provide define-type define-types
         → →/test
         (typed-out [+ : (→ Int Int Int)]
                    [- : (→ Int Int Int)]
                    [* : (→ Int Int Int)]
                    [max : (→ Int Int Int)]
                    [min : (→ Int Int Int)]
                    [= : (→ Int Int Bool)]
                    [<= : (→ Int Int Bool)]
                    [< : (→ Int Int Bool)]
                    [> : (→ Int Int Bool)]
                    [modulo : (→ Int Int Int)]
                    [zero? : (→ Int Bool)]
                    [sub1 : (→ Int Int)]
                    [add1 : (→ Int Int)]
                    [abs : (→ Int Int)]
                    [even? : (→ Int Bool)]
                    [odd? : (→ Int Bool)]
                    [random : (→ Int Int)]
                    [integer->char : (→ Int Char)]
                    [string->list : (→ String (List Char))]
                    [string->number : (→ String Int)]
                    [string : (→ Char String)]
                    [sleep : (→ Int Unit)]
                    [string=? : (→ String String Bool)]
                    [string<=? : (→ String String Bool)]
                    [newline : (→ Unit)]
                    [open-output-string : (→ String-Port)]
                    [get-output-string : (→ String-Port String)]
                    [string-upcase : (→ String String)]
                    [make-string : (→ Int String)]
                    [string-set! : (→ String Int Char Unit)]
                    [string-ref : (→ String Int Char)]
                    [fl+ : (→ Float Float Float)]
                    [fl- : (→ Float Float Float)]
                    [fl* : (→ Float Float Float)]
                    [fl/ : (→ Float Float Float)]
                    [flsqrt : (→ Float Float)]
                    [flceiling : (→ Float Float)]
                    [inexact->exact : (→ Float Int)]
                    [exact->inexact : (→ Int Float)]
                    [char->integer : (→ Char Int)]
                    [real->decimal-string : (→ Float Int String)]
                    [fx->fl : (→ Int Float)]
                    [quotient : (→ Int Int Int)]
                    [regexp-match : (→ Regexp String (List String))]
                    [regexp : (→ String Regexp)]
                    [channel-get : (∀ (X) (→ (Channel X) X))]
                    [channel-put : (∀ (X) (→ (Channel X) X Unit))]
                    [thread : (∀ (X) (→ (→ X) Thread))]
                    [vector-length : (∀ (X) (→ (Vector X) Int))]
                    [vector-ref : (∀ (X) (→ (Vector X) Int X))]
                    [vector-set! : (∀ (X) (→ (Vector X) Int X Unit))]
                    [vector-copy! : (∀ (X) (→ (Vector X) Int (Vector X) Unit))]
                    [in-vector : (∀ (X) (→ (Vector X) (Sequence X)))]
                    [in-list : (∀ (X) (→ (List X) (Sequence X)))]
                    [display : (∀ (X) (→ X Unit))]
                    [displayln : (∀ (X) (→ X Unit))]
                    [list->vector : (∀ (X) (→ (List X) (Vector X)))]
                    [in-hash : (∀ (K V) (→ (Hash K V) (Sequence (stlc+rec-iso:× K V))))]
                    [hash-set! : (∀ (K V) (→ (Hash K V) K V Unit))]
                    [hash-has-key? : (∀ (K V) (→ (Hash K V) K Bool))]
                    [hash-count : (∀ (K V) (→ (Hash K V) Int))]
                    [equal? : (∀ (X) (→ X X Bool))]
                    )
         not void
         define match match2 λ
         (rename-out [mlish:#%app #%app])
         cond when unless
         Channel make-channel
         Thread
         List Vector
         vector make-vector
         Sequence in-range in-naturals in-lines
         for for*
         for/list for/vector for*/vector for*/list for/fold for/hash for/sum
         printf format
         let let* begin
         Hash hash hash-ref
         String-Port Input-Port
         write-string string-length string-copy!
         number->string string-append
         quotient+remainder
         set!
         provide-type
         (rename-out [mlish-provide provide])
         require-typed
         Regexp
         read)

;; for demonstrating user ability to extend the type system, see fasta.mlish
(provide (for-syntax ~seq ...))

(module+ test
  (require (for-syntax rackunit)))

;; creating possibly polymorphic types
;; ?∀ only wraps a type in a forall if there's at least one type variable
(define-syntax ?∀
  (lambda (stx)
    (syntax-case stx ()
      [(?∀ () body)
       #'body]
      [(?∀ (X ...) body)
       #'(∀ (X ...) body)])))

;; ?Λ only wraps an expression in a Λ if there's at least one type variable
(define-syntax ?Λ
  (lambda (stx)
    (syntax-case stx ()
      [(?Λ () body)
       #'body]
      [(?Λ (X ...) body)
       #'(Λ (X ...) body)])))

(begin-for-syntax 
  ;; matching possibly polymorphic types
  (define-syntax ~?∀
    (pattern-expander
     (lambda (stx)
       (syntax-case stx ()
         [(?∀ vars-pat body-pat)
          #'(~or (~∀ vars-pat body-pat)
                 (~and (~not (~∀ _ _))
                       (~parse vars-pat #'())
                       body-pat))]))))

  ;; find-free-Xs : (Stx-Listof Id) Type -> (Listof Id)
  ;; finds the free Xs in the type
  (define (find-free-Xs Xs ty)
    (for/list ([X (in-stx-list Xs)]
               #:when (stx-contains-id? ty X))
      X))

  ;; solve for Xs by unifying quantified fn type with the concrete types of stx's args
  ;;   stx = the application stx = (#%app e_fn e_arg ...)
  ;;   tyXs = input and output types from fn type
  ;;          ie (typeof e_fn) = (-> . tyXs)
  ;; It infers the types of arguments from left-to-right,
  ;; and it expands and returns all of the arguments.
  ;; It returns list of 3 values if successful, else throws a type error
  ;;  - a list of all the arguments, expanded
  ;;  - a list of all the type variables
  ;;  - the constraints for substituting the types
  (define (solve Xs tyXs stx)
    (syntax-parse tyXs
      [(τ_inX ... τ_outX)
       ;; generate initial constraints with expected type and τ_outX
       #:with (~?∀ Vs expected-ty)
              (and (get-expected-type stx)
                   ((current-type-eval) (get-expected-type stx)))
       (define initial-cs
         (if (and (syntax-e #'expected-ty) (stx-null? #'Vs))
             (add-constraints Xs '() (list (list #'expected-ty #'τ_outX)))
             '()))
       (syntax-parse stx
         [(_ e_fn . args)
          (define-values (as- cs)
              (for/fold ([as- null] [cs initial-cs])
                        ([a (in-stx-list #'args)]
                         [tyXin (in-stx-list #'(τ_inX ...))])
                (define ty_in (inst-type/cs/orig Xs cs tyXin datum=?))
                (define/with-syntax [a- ty_a]
                  (infer+erase (if (empty? (find-free-Xs Xs ty_in))
                                   (add-expected-ty a ty_in)
                                   a)))
                (values
                 (cons #'a- as-)
                 (add-constraints Xs cs (list (list ty_in #'ty_a))
                                  (list (list (inst-type/cs/orig
                                               Xs cs ty_in
                                               datum=?)
                                              #'ty_a))))))

         (list (reverse as-) Xs cs)])]))

  (define (mk-app-poly-infer-error stx expected-tys given-tys e_fn)
    (format (string-append
             "Could not infer instantiation of polymorphic function ~s.\n"
             "  expected: ~a\n"
             "  given:    ~a")
            (syntax->datum (get-orig e_fn))
            (string-join (stx-map type->str expected-tys) ", ")
            (string-join (stx-map type->str given-tys) ", ")))

  ;; covariant-Xs? : Type -> Bool
  ;; Takes a possibly polymorphic type, and returns true if all of the
  ;; type variables are in covariant positions within the type, false
  ;; otherwise.
  (define (covariant-Xs? ty)
    (syntax-parse ((current-type-eval) ty)
      [(~?∀ Xs ty)
       (for/and ([X (in-stx-list #'Xs)])
         (covariant-X? X #'ty))]))

  ;; find-X-variance : Id Type [Variance] -> Variance
  ;; Returns the variance of X within the type ty
  (define (find-X-variance X ty [ctxt-variance covariant])
    (match (find-variances (list X) ty ctxt-variance)
      [(list variance) variance]))

  ;; covariant-X? : Id Type -> Bool
  ;; Returns true if every place X appears in ty is a covariant position, false otherwise.
  (define (covariant-X? X ty)
    (variance-covariant? (find-X-variance X ty covariant)))

  ;; contravariant-X? : Id Type -> Bool
  ;; Returns true if every place X appears in ty is a contravariant position, false otherwise.
  (define (contravariant-X? X ty)
    (variance-contravariant? (find-X-variance X ty covariant)))

  ;; find-variances : (Listof Id) Type [Variance] -> (Listof Variance)
  ;; Returns the variances of each of the Xs within the type ty,
  ;; where it's already within a context represented by ctxt-variance.
  (define (find-variances Xs ty [ctxt-variance covariant])
    (syntax-parse ty
      [A:id
       (for/list ([X (in-list Xs)])
         (cond [(free-identifier=? X #'A) ctxt-variance]
               [else irrelevant]))]
      [(~Any tycons)
       (make-list (length Xs) irrelevant)]
      [(~?∀ () (~Any tycons τ ...))
       #:when (get-arg-variances #'tycons)
       #:when (stx-length=? #'[τ ...] (get-arg-variances #'tycons))
       (define τ-ctxt-variances
         (for/list ([arg-variance (in-list (get-arg-variances #'tycons))])
           (variance-compose ctxt-variance arg-variance)))
       (for/fold ([acc (make-list (length Xs) irrelevant)])
                 ([τ (in-stx-list #'[τ ...])]
                  [τ-ctxt-variance (in-list τ-ctxt-variances)])
         (map variance-join
              acc
              (find-variances Xs τ τ-ctxt-variance)))]
      [ty
       #:when (not (for/or ([X (in-list Xs)])
                     (stx-contains-id? #'ty X)))
       (make-list (length Xs) irrelevant)]
      [_ (make-list (length Xs) invariant)]))

  ;; find-variances/exprs : (Listof Id) Type [Variance-Expr] -> (Listof Variance-Expr)
  ;; Like find-variances, but works with Variance-Exprs instead of
  ;; concrete variance values.
  (define (find-variances/exprs Xs ty [ctxt-variance covariant])
    (syntax-parse ty
      [A:id
       (for/list ([X (in-list Xs)])
         (cond [(free-identifier=? X #'A) ctxt-variance]
               [else irrelevant]))]
      [(~Any tycons)
       (make-list (length Xs) irrelevant)]
      [(~?∀ () (~Any tycons τ ...))
       #:when (get-arg-variances #'tycons)
       #:when (stx-length=? #'[τ ...] (get-arg-variances #'tycons))
       (define τ-ctxt-variances
         (for/list ([arg-variance (in-list (get-arg-variances #'tycons))])
           (variance-compose/expr ctxt-variance arg-variance)))
       (for/fold ([acc (make-list (length Xs) irrelevant)])
                 ([τ (in-list (syntax->list #'[τ ...]))]
                  [τ-ctxt-variance (in-list τ-ctxt-variances)])
         (map variance-join/expr
              acc
              (find-variances/exprs Xs τ τ-ctxt-variance)))]
      [ty
       #:when (not (for/or ([X (in-list Xs)])
                     (stx-contains-id? #'ty X)))
       (make-list (length Xs) irrelevant)]
      [_ (make-list (length Xs) invariant)]))

  ;; current-variance-constraints : (U False (Mutable-Setof Variance-Constraint))
  ;; If this is false, that means that infer-variances should return concrete Variance values.
  ;; If it's a mutable set, that means that infer-variances should mutate it and return false,
  ;; and type constructors should return the list of variance vars.
  (define current-variance-constraints (make-parameter #false))

  ;; infer-variances :
  ;; ((-> Stx) -> Stx) (Listof Variance-Var) (Listof Id) (Listof Type-Stx)
  ;; -> (U False (Listof Variance))
  (define (infer-variances with-variance-vars-okay variance-vars Xs τs)
    (cond
      [(current-variance-constraints)
       (define variance-constraints (current-variance-constraints))
       (define variance-exprs
         (for/fold ([exprs (make-list (length variance-vars) irrelevant)])
                   ([τ (in-list τs)])
           (define/syntax-parse (~?∀ Xs* τ*)
             ;; This can mutate variance-constraints!
             ;; This avoids causing an infinite loop by having the type
             ;; constructors provide with-variance-vars-okay so that within
             ;; this call they declare variance-vars for their variances.
             (with-variance-vars-okay
              (λ () ((current-type-eval) #`(∀ #,Xs #,τ)))))
           (map variance-join/expr
                exprs
                (find-variances/exprs (syntax->list #'Xs*) #'τ* covariant))))
       (for ([var (in-list variance-vars)]
             [expr (in-list variance-exprs)])
         (set-add! variance-constraints (variance= var expr)))
       #f]
      [else
       (define variance-constraints (mutable-set))
       ;; This will mutate variance-constraints!
       (parameterize ([current-variance-constraints variance-constraints])
         (infer-variances with-variance-vars-okay variance-vars Xs τs))
       (define mapping
         (solve-variance-constraints variance-vars
                                     (set->list variance-constraints)
                                     (variance-mapping)))
       (for/list ([var (in-list variance-vars)])
         (variance-mapping-ref mapping var))]))

  ;; make-arg-variances-proc :
  ;; (Listof Variance-Var) (Listof Id) (Listof Type-Stx) -> (Stx -> (U (Listof Variance)
  ;;                                                                   (Listof Variance-Var)))
  (define (make-arg-variances-proc arg-variance-vars Xs τs)
    ;; variance-vars-okay? : (Parameterof Boolean)
    ;; A parameter that determines whether or not it's okay for
    ;; this type constructor to return a list of Variance-Vars
    ;; for the variances.
    (define variance-vars-okay? (make-parameter #false))
    ;; with-variance-vars-okay : (-> A) -> A
    (define (with-variance-vars-okay f)
      (parameterize ([variance-vars-okay? #true])
        (f)))
    ;; arg-variances : (Boxof (U False (List Variance ...)))
    ;; If false, means that the arg variances have not been
    ;; computed yet. Otherwise, stores the complete computed
    ;; variances for the arguments to this type constructor.
    (define arg-variances (box #f))
    ;; arg-variances-proc : Stx -> (U (Listof Variance) (Listof Variance-Var))
    (define (arg-variance-proc stx)
      (or (unbox arg-variances)
          (cond
            [(variance-vars-okay?)
             arg-variance-vars]
            [else
             (define inferred-variances
               (infer-variances
                with-variance-vars-okay
                arg-variance-vars
                Xs
                τs))
             (cond [inferred-variances
                    (set-box! arg-variances inferred-variances)
                    inferred-variances]
                   [else
                    arg-variance-vars])])))
    arg-variance-proc)

  ;; compute unbound tyvars in one unexpanded type ty
  (define (compute-tyvar1 ty)
    (syntax-parse ty
      [X:id #'(X)]
      [() #'()]
      [(C t ...) (stx-appendmap compute-tyvar1 #'(t ...))]))
  ;; computes unbound ids in (unexpanded) tys, to be used as tyvars
  (define (compute-tyvars tys)
    (define Xs (stx-appendmap compute-tyvar1 tys))
    (filter 
     (lambda (X) 
       (with-handlers
        ([exn:fail:syntax:unbound? (lambda (e) #t)]
         [exn:fail:type:infer? (lambda (e) #t)])
        (let ([X+ ((current-type-eval) X)])
          (not (or (tyvar? X+) (type? X+))))))
     (stx-remove-dups Xs))))

;; define --------------------------------------------------
;; for function defs, define infers type variables
;; - since the order of the inferred type variables depends on expansion order,
;;   which is not known to programmers, to make the result slightly more
;;   intuitive, we arbitrarily sort the inferred tyvars lexicographically
(define-typed-syntax define
  [(_ x:id e) ≫
   [⊢ e ≫ e- ⇒ τ]
   #:with x- (generate-temporary)
   --------
   [≻ (begin-
        (define-typed-variable-rename x ≫ x- : τ)
        (define- x- e-))]]
  ; explicit "forall"
  [(_ Ys (f:id [x:id (~datum :) τ] ... (~or (~datum ->) (~datum →)) τ_out) 
     e_body ... e) ≫
   #:when (brace? #'Ys)
   ;; TODO; remove this code duplication
   #:with f- (add-orig (generate-temporary #'f) #'f)
   #:with e_ann #'(add-expected e τ_out)
   #:with (τ+orig ...) (stx-map (λ (t) (add-orig t t)) #'(τ ... τ_out))
   #:with (~and ty_fn_expected (~?∀ _ (~ext-stlc:→ _ ... out_expected)))
          (set-stx-prop/preserved
            ((current-type-eval) #'(?∀ Ys (ext-stlc:→ τ+orig ...)))
            'orig
            (list #'(→ τ+orig ...)))
   --------
   [≻ (begin-
        (define-typed-variable-rename f ≫ f- : ty_fn_expected)
        (define- f-
          (Λ Ys (ext-stlc:λ ([x : τ] ...) (ext-stlc:begin e_body ... e_ann)))))]]
  ;; alternate type sig syntax, after parameter names
  [(_ (f:id x:id ...) (~datum :) ty ... (~or (~datum ->) (~datum →)) ty_out . b) ≫
   --------
   [≻ (define (f [x : ty] ... -> ty_out) . b)]]
  [(_ (f:id [x:id (~datum :) τ] ... (~or (~datum ->) (~datum →)) τ_out) 
     e_body ... e) ≫
   #:with (Y ...) (compute-tyvars #'(τ ... τ_out))
   ---------------
   [≻ (define {Y ...} (f [x : τ] ... -> τ_out)
        e_body ... e)]])

;; define-type -----------------------------------------------

(define-for-syntax (make-type-constructor-transformer
                     name           ; Name of type constructor we're defining
                     internal-name  ; Identifier used for internal rep of type
                     key2           ; Syntax property to attach kind of type
                     op             ; numeric operator to compare expected arg count
                     n              ; Expected arity, relative to op
                    )
  (define/syntax-parse τ- internal-name)
  (syntax-parser
    [(_ . args)
     #:fail-unless (op (stx-length #'args) n)
     (format
       "wrong number of arguments, expected ~a ~a"
       (object-name op) n)
     #:with ([arg- _] ...) (infers+erase #'args #:tag key2 #:stop-list? #f)
     ;; args are validated on the next line rather than above
     ;; to ensure enough stx-parse progress for proper err msg,
     ;; ie, "invalid type" instead of "improper tycon usage"
     #:with (~! _:type ...) #'(arg- ...)
     (add-orig (mk-type (syntax/loc this-syntax (τ- arg- ...))) this-syntax)]
    [_ ;; else fail with err msg
      (type-error #:src this-syntax
                  #:msg
                  (string-append
                    "Improper usage of type constructor ~a: ~a, expected ~a ~a arguments")
                  #`#,name this-syntax #`#,(object-name op) #`#,n)]))


(begin-for-syntax
  (define-syntax-class constructor
    (pattern
      ;; constructors must have the form (Cons τ ...)
      ;; but the first ~or clause accepts 0-arg constructors as ids;
      ;; the ~and is a workaround to bind the duplicate Cons ids (see Ryan's email)
      (~and C (~or
                ; Nullary constructor, without parens. Like `Nil`.
                ; Ensure fld, τ are bound though empty.
                (~and IdCons:id
                      (~parse (Cons [fld (~datum :) τ] ...) #'(IdCons)))
                ; With named fields
                (Cons [fld (~datum :) τ] ...)
                ; Fields not named; generate internal names
                (~and (Cons τ ...)
                      (~parse (fld ...) (generate-temporaries #'(τ ...)))))))))

;; defines a set of mutually recursive datatypes
(define-syntax (define-types stx)
  (syntax-parse stx
    [(_ [(Name:id X:id ...)
         c:constructor ...]
        ...)
     ;; validate tys
     #:with ((ty_flat ...) ...) (stx-map (λ (tss) (stx-flatten tss)) #'(((c.τ ...) ...) ...))
     #:with ((_ _ (_ _ (_ _ (_ _ ty+ ...)))) ...)
            (stx-map expand/df
              #`((lambda (X ...)
                   (let-syntax
                       ([X (make-rename-transformer (mk-type #'X))] ...
                        ; Temporary binding of the type we are now defining,
                        ; so that we can expand the types of constructor arguments
                        ; that refer to it. This binding is the reason we can't use infer
                        ; here; infer is specifically about attaching types, not binding
                        ; general transformers.
                        [Name
                         (make-type-constructor-transformer
                           #'Name #'void ':: = (stx-length #'(X ...)))] ...)
                     (void ty_flat ...))) ...))
     #:when (stx-map
             (λ (ts+ ts)
               (stx-map
                (lambda (t+ t) (unless (type? t+)
                                 (type-error #:src t
                                             #:msg "~a is not a valid type" t)))
                ts+ ts))
             #'((ty+ ...) ...) #'((ty_flat ...) ...))
     #:with (NameExtraInfo ...) (stx-map (λ (n) (format-id n "~a-extra-info" n)) #'(Name ...))
     #:with (n ...) (stx-map (λ (Xs) #`#,(stx-length Xs)) #'((X ...) ...))
     #:with (arg-variance-vars ...) (generate-temporaries #'(Name ...))
     #`(begin-
         (begin-for-syntax
           ;; arg-variance-vars : (List Variance-Var ...)
           (define arg-variance-vars
             (list (variance-var (syntax-e (generate-temporary 'X))) ...)) ...)
         (define-type-constructor Name
           #:arity = n
           #:arg-variances (make-arg-variances-proc arg-variance-vars
                                                    (list #'X ...)
                                                    (list #'c.τ ... ...))
           #:extra-info 'NameExtraInfo) ...
         (define-type-rest (Name X ...) c.C ...) ...
         )]))

;; defines the runtime components of a define-datatype
(define-syntax (define-type-rest stx)
  (syntax-parse stx
    [(_ (Name:id X:id ...)
        c:constructor ...)
     #:with Name? (mk-? #'Name)
     #:with NameExtraInfo (format-id #'Name "~a-extra-info" #'Name)
     #:with (StructName ...) (generate-temporaries #'(c.Cons ...))
     #:with ((exposed-acc ...) ...)
            (stx-map 
             (λ (C fs) (stx-map (λ (f) (format-id C "~a-~a" C f)) fs))
             #'(c.Cons ...) #'((c.fld ...) ...))
     #:with ((acc ...) ...)
            (stx-map
             (λ (S fs) (stx-map (λ (f) (format-id S "~a-~a" S f)) fs))
             #'(StructName ...) #'((c.fld ...) ...))
     #:with (Cons? ...) (stx-map mk-? #'(StructName ...))
     #:with (exposed-Cons? ...) (stx-map mk-? #'(c.Cons ...))
     #`(begin-
         (define-syntax NameExtraInfo
           (make-extra-info-transformer #'(X ...) #'(('c.Cons 'StructName Cons? [acc c.τ] ...) ...)))
         (struct- StructName (c.fld ...) #:reflection-name 'c.Cons #:transparent) ...
         (define-syntax exposed-acc ; accessor for records
           (make-variable-like-transformer
             (assign-type #'acc #'(?∀ (X ...) (ext-stlc:→ (Name X ...) c.τ)))))
         ... ...
         (define-syntax exposed-Cons? ; predicates for each variant
           (make-variable-like-transformer
             (assign-type #'Cons? #'(?∀ (X ...) (ext-stlc:→ (Name X ...) Bool))))) ...
         (define-syntax c.Cons
           (make-constructor-transformer #'((X ...) (c.τ ...) Name StructName)))
         ...)]))

;; defines a single datatype; dispatches to define-types
(define-syntax (define-type stx)
  (syntax-parse stx
    [(_ Name:id . rst)
     #:with NewName (generate-temporary #'Name)
     #:with Name2 (add-orig #'(NewName) #'Name)
     #`(begin-
         (define-type Name2 . #,(subst #'Name2 #'Name #'rst))
         (stlc+rec-iso:define-type-alias Name Name2))]
    [(_ Name . Cs) #'(define-types [Name . Cs])]))

(begin-for-syntax
  (define (make-extra-info-transformer Xs stuff)
    (syntax-parser
      [(_ Y ...)
       (substs #'(Y ...) Xs stuff)]))

  (define make-constructor-transformer
    (syntax-parser
      [((X ...) (τ ...) Name StructName)
       #:with fn-ty-body #'(ext-stlc:→ τ ... (Name X ...))
       #:with fn-ty #'(?∀ (X ...) fn-ty-body)
       #:with StructName/ty (assign-type #'StructName #'fn-ty)
       ;; stx/loc transfers expected-type (mlish:#%app needs for inference)
    (lambda (stx)
      (syntax-parse/typecheck stx
         [C:id ≫ #:when (stx-null? #'(τ ...)) ; id, as unary constructor applied w/o parens
          --------
          [≻ #,(syntax/loc this-syntax (C))]]
         [_:id ≫
          ----
          [≻ StructName/ty]]             ; id, as HO fn
         [(C τs . args) ≫ ; explicit instantiation
          #:when (brace? #'τs) ; commit to this clause
          #:with fn-ty-inst (inst-type #'τs #'(X ...) #'fn-ty-body)
          #:with StructName/inst/orig (add-orig (assign-type #'StructName #'fn-ty-inst) #'C)
          -----------------
          [≻ #,(syntax/loc this-syntax (mlish:#%app StructName/inst/orig . args))]]
         [(C . args) ≫   ; no explicit instantiation, defer inference to mlish:#%app
          #:with StructName/orig (add-orig #'StructName/ty #'C)
          ---------------
          [≻ #,(syntax/loc this-syntax (mlish:#%app StructName/orig . args))]]))])))


;; match --------------------------------------------------
(begin-for-syntax
  (define (get-ctx pat ty)
    (unify-pat+ty (list pat ty)))
  (define (unify-pat+ty pat+ty)
    (syntax-parse pat+ty
     [(pat ty) #:when (brace? #'pat) ; handle root pattern specially (to avoid some parens)
      (syntax-parse #'pat
        [{(~datum _)} #'()]
        [{(~literal stlc+cons:nil)}  #'()]
        [{A:id} ; disambiguate 0-arity constructors (that don't need parens)
         #:when (get-extra-info #'ty)
         #'()]
        ;; comma tup syntax always has parens
        [{(~and ps (p1 (unq p) ...))}
         #:when (not (stx-null? #'(p ...)))
         #:when (andmap (lambda (u) (equal? u 'unquote)) (syntax->datum #'(unq ...)))
         (unify-pat+ty #'(ps ty))]
        [{p ...} 
         (unify-pat+ty (list (syntax/loc #'pat (p ...)) #'ty))])] ; pair
      [((~datum _) ty) #'()]
      [((~or (~literal stlc+cons:nil)) ty) #'()]
      [(A:id ty) ; disambiguate 0-arity constructors (that don't need parens)
       #:with (_ (_ (_ C) . _) ...) (get-extra-info #'ty)
       #:when (member (syntax->datum #'A) (syntax->datum #'(C ...)))
       #'()]
      [(x:id ty)  #'((x ty))]
      [((p1 (unq p) ...) ty) ; comma tup stx
       #:when (not (stx-null? #'(p ...)))
       #:when (andmap (lambda (u) (equal? u 'unquote)) (syntax->datum #'(unq ...)))
       #:with (~× t ...) #'ty
       #:with (pp ...) #'(p1 p ...)
       (unifys #'([pp t] ...))]
      [(((~literal stlc+tup:tup) p ...) ty) ; tup
       #:with (~× t ...) #'ty
       (unifys #'([p t] ...))]
      [(((~literal stlc+cons:list) p ...) ty) ; known length list
       #:with (~List t) #'ty
       (unifys #'([p t] ...))]
     [(((~seq p (~datum ::)) ... rst) ty) ; nicer cons stx
      #:with (~List t) #'ty
       (unifys #'([p t] ... [rst ty]))]
      [(((~literal stlc+cons:cons) p ps) ty) ; arb length list
       #:with (~List t) #'ty
       (unifys #'([p t] [ps ty]))]
      [((Name:id p ...) ty)
       #:do[(define extra-info (get-extra-info #'ty))]
       #:when extra-info
       #:with (_ (_ Cons) _ _ [_ _ τ] ...)
              (stx-findf
                (syntax-parser
                 [(_ 'C . rst) (datum=? #'Name #'C)])
                (stx-cdr extra-info))
       (unifys #'([p τ] ...))]
     [((p) t)
       #:when (type-error #:src #'p
                #:msg "Pattern ~a does not match type of scrutinee ~a. Try dropping outer parens?"
                          #'(p) #'t)
       #'()]
     [(p t)
       #:when (type-error #:src #'p
               #:msg "Pattern ~a does not match type of scrutinee ~a."
                          #'p #'t)
       #'()]))
  (define (unifys p+tys) (stx-appendmap unify-pat+ty p+tys))
  
  (define (compile-pat p ty)
    (syntax-parse p
     [pat #:when (brace? #'pat) ; handle root pattern specially (to avoid some parens)
      (syntax-parse #'pat
        [{(~datum _)} #'_]
        [{(~literal stlc+cons:nil)}  (syntax/loc p (list))]
        [{A:id} ; disambiguate 0-arity constructors (that don't need parens)
         #:when (get-extra-info ty)
         (compile-pat #'(A) ty)]
        ;; comma tup stx always has parens
        [{(~and ps (p1 (unq p) ...))}
         #:when (not (stx-null? #'(p ...)))
         #:when (andmap (lambda (u) (equal? u 'unquote)) (syntax->datum #'(unq ...)))
         (compile-pat #'ps ty)]
        [{pat ...} (compile-pat (syntax/loc p (pat ...)) ty)])]
     [(~datum _) #'_]
     [(~literal stlc+cons:nil) ; nil
      #'(list)]
     [A:id ; disambiguate 0-arity constructors (that don't need parens)
      #:with (_ (_ (_ C) . _) ...) (get-extra-info ty)
      #:when (member (syntax->datum #'A) (syntax->datum #'(C ...)))
      (compile-pat #'(A) ty)]
     [x:id p]
     [(p1 (unq p) ...) ; comma tup stx
      #:when (not (stx-null? #'(p ...)))
      #:when (andmap (lambda (u) (equal? u 'unquote)) (syntax->datum #'(unq ...)))
      #:with (~× t ...) ty
      #:with (p- ...) (stx-map (lambda (p t) (compile-pat p t)) #'(p1 p ...) #'(t ...))
      #'(list p- ...)]
     [((~literal stlc+tup:tup) . pats)
      #:with (~× . tys) ty
      #:with (p- ...) (stx-map (lambda (p t) (compile-pat p t)) #'pats #'tys)
      (syntax/loc p (list p- ...))]
     [((~literal stlc+cons:list) . ps)
      #:with (~List t) ty
      #:with (p- ...) (stx-map (lambda (p) (compile-pat p #'t)) #'ps)
      (syntax/loc p (list p- ...))]
     [((~seq pat (~datum ::)) ... last) ; nicer cons stx
      #:with (~List t) ty
      #:with (p- ...) (stx-map (lambda (pp) (compile-pat pp #'t)) #'(pat ...))
      #:with last- (compile-pat #'last ty)
      (syntax/loc p (list-rest p- ... last-))]
     [((~literal stlc+cons:cons) p ps)
      #:with (~List t) ty
      #:with p- (compile-pat #'p #'t)
      #:with ps- (compile-pat #'ps ty)
      #'(cons p- ps-)]
     [(Name:id . pats)
      #:with (_ (_ Cons) (_ StructName) _ [_ _ τ] ...)
             (stx-findf
               (syntax-parser
                [(_ 'C . rst) (datum=? #'Name #'C)])
               (stx-cdr (get-extra-info ty)))
      #:with (p- ...) (stx-map compile-pat #'pats #'(τ ...))
      (syntax/loc p (StructName p- ...))]))

  ;; pats = compiled pats = racket pats
  (define (check-exhaust pats ty)
    (define (else-pat? p)
      (syntax-parse p [(~literal _) #t] [_ #f]))
    (define (nil-pat? p)
      (syntax-parse p
        [((~literal list)) #t]
        [_ #f]))
    (define (non-nil-pat? p)
      (syntax-parse p
        [((~literal list-rest) . rst) #t]
        [((~literal cons) . rst) #t]
        [_ #f]))
    (define (tup-pat? p)
      (syntax-parse p
        [((~literal list) . _) #t] [_ #f]))
    (cond
     [(or (stx-ormap else-pat? pats) (stx-ormap identifier? pats)) #t]
     [(List? ty) ; lists
      (unless (stx-ormap nil-pat? pats)
        (error 'match2 (let ([last (car (stx-rev pats))])
                         (format "(~a:~a) missing nil clause for list expression"
                                 (syntax-line last) (syntax-column last)))))
      (unless (stx-ormap non-nil-pat? pats)
        (error 'match2 (let ([last (car (stx-rev pats))])
                         (format "(~a:~a) missing clause for non-empty, arbitrary length list"
                                 (syntax-line last) (syntax-column last)))))
      #t]
     [(×? ty) ; tuples
      (unless (stx-ormap tup-pat? pats)
        (error 'match2 (let ([last (car (stx-rev pats))])
                         (format "(~a:~a) missing pattern for tuple expression"
                                 (syntax-line last) (syntax-column last)))))
      (syntax-parse pats
        [((_ p ...) ...)
         (syntax-parse ty
           [(~× t ...)
            (apply stx-andmap 
                   (lambda (t . ps) (check-exhaust ps t)) 
                   #'(t ...) 
                   (syntax->list #'((p ...) ...)))])])]
     [else ; algebraic datatypes
      (syntax-parse (get-extra-info ty)
        [(_ (_ (_ C) (_ Cstruct) . rst) ...)
         (syntax-parse pats
           [((Cpat _ ...) ...)
            (define Cs (syntax->datum #'(C ...)))
            (define Cstructs (syntax->datum #'(Cstruct ...)))
            (define Cpats (syntax->datum #'(Cpat ...)))
            (unless (set=? Cstructs Cpats)
              (error 'match2
                (let ([last (car (stx-rev pats))])
                  (format "(~a:~a) clauses not exhaustive; missing: ~a"
                          (syntax-line last) (syntax-column last)
                          (string-join      
                            (for/list ([C Cs][Cstr Cstructs] #:unless (member Cstr Cpats))
                              (symbol->string C))
                            ", ")))))
            #t])]
        [_ #t])]))

  ;; TODO: do get-ctx and compile-pat in one pass
  (define (compile-pats pats ty)
    (stx-map (lambda (p) (list (get-ctx p ty) (compile-pat p ty))) pats))
  )

(define-typed-syntax match2 #:datum-literals (with ->)
  [(match2 e with . clauses) ≫
   #:fail-unless (not (null? (syntax->list #'clauses))) "no clauses"
   [⊢ e ≫ e- ⇒ τ_e]
   #:with ([(~seq p ...) -> e_body] ...) #'clauses
   #:with (pat ...) (stx-map ; use brace to indicate root pattern
                     (lambda (ps) (syntax-parse ps [(pp ...) (syntax/loc this-syntax {pp ...})]))
                     #'((p ...) ...))
   #:with ([(~and ctx ([x ty] ...)) pat-] ...) (compile-pats #'(pat ...) #'τ_e)
   #:with ty-expected (get-expected-type this-syntax)
   [[x ≫ x- : ty] ... ⊢ (add-expected e_body ty-expected) ≫ e_body- ⇒ ty_body] ...
   #:when (check-exhaust #'(pat- ...) #'τ_e)
   --------
   [⊢ (match- e- [pat- (let- ([x- x] ...) e_body-)] ...) ⇒ (⊔ ty_body ...)]])

(define-typed-syntax match #:datum-literals (with -> ::)
  ;; e is a tuple
  [(match e with . clauses) ≫
   #:fail-unless (not (null? (syntax->list #'clauses))) "no clauses"
   [⊢ e ≫ e- ⇒ τ_e]
   #:when (×? #'τ_e)
   #:with t_expect (get-expected-type this-syntax) ; propagate inferred type
   #:with ([x ... -> e_body]) #'clauses
   #:with (~× ty ...) #'τ_e
   #:fail-unless (stx-length=? #'(ty ...) #'(x ...))
                 "match clause pattern not compatible with given tuple"
   [[x ≫ x- : ty] ... ⊢ (add-expected e_body t_expect) ≫ e_body- ⇒ ty_body]
   #:with (acc ...) (for/list ([(a i) (in-indexed (syntax->list #'(x ...)))])
                      #`(lambda (s) (list-ref s #,(datum->syntax #'here i))))
   #:with z (generate-temporary)
   --------
   [⊢ (let- ([z e-])
        (let- ([x- (acc z)] ...) e_body-)) ⇒ ty_body]]
  ;; e is a list
  [(match e with . clauses) ≫
   #:fail-unless (not (null? (syntax->list #'clauses))) "no clauses"
   [⊢ e ≫ e- ⇒ τ_e]
   #:when (List? #'τ_e)
   #:with t_expect (get-expected-type this-syntax) ; propagate inferred type
   #:with ([(~or (~and (~and xs [x ...]) (~parse rst (generate-temporary)))
                 (~and (~seq (~seq x ::) ... rst:id) (~parse xs #'())))
            -> e_body] ...+)
          #'clauses
   #:fail-unless (stx-ormap 
                  (lambda (xx) (and (brack? xx) (zero? (stx-length xx)))) 
                  #'(xs ...))
                 "match: missing empty list case"
   #:fail-unless (not (and (stx-andmap brack? #'(xs ...))
                           (= 1 (stx-length #'(xs ...)))))
                 "match: missing non-empty list case"
   #:with (~List ty) #'τ_e
   [[x ≫ x- : ty] ... [rst ≫ rst- : (List ty)]
    ⊢ (add-expected e_body t_expect) ≫ e_body- ⇒ ty_body] ...
   #:with (len ...) (stx-map (lambda (p) #`#,(stx-length p)) #'((x ...) ...))
   #:with (lenop ...) (stx-map (lambda (p) (if (brack? p) #'=- #'>=-)) #'(xs ...))
   #:with (pred? ...) (stx-map
                       (lambda (l lo) #`(λ- (lst) (#,lo (length lst) #,l)))
                       #'(len ...) #'(lenop ...))
   #:with ((acc1 ...) ...) (stx-map 
                            (lambda (xs)
                              (for/list ([(x i) (in-indexed (syntax->list xs))])
                                #`(lambda- (lst) (list-ref- lst #,(datum->syntax #'here i)))))
                            #'((x ...) ...))
   #:with (acc2 ...) (stx-map (lambda (l) #`(lambda- (lst) (list-tail- lst #,l))) #'(len ...))
   --------
   [⊢ (let- ([z e-])
        (cond-
         [(pred? z)
          (let- ([x- (acc1 z)] ... [rst- (acc2 z)]) e_body-)] ...))
      ⇒ (⊔ ty_body ...)]]
  ;; e is a variant
  [(match e with . clauses) ≫
   #:fail-unless (not (null? (syntax->list #'clauses))) "no clauses"
   [⊢ e ≫ e- ⇒ τ_e]
   #:when (and (not (×? #'τ_e)) (not (List? #'τ_e)))
   #:with t_expect (get-expected-type this-syntax) ; propagate inferred type
   #:with ([Clause:id x:id ... 
                      (~optional (~seq #:when e_guard) #:defaults ([e_guard #'(ext-stlc:#%datum . #t)]))
                      -> e_c_un] ...+) ; un = unannotated with expected ty
          #'clauses
   ;; length #'clauses may be > length #'info, due to guards
   #:with info-body (get-extra-info #'τ_e)
   #:with (_ (_ (_ ConsAll) . _) ...) #'info-body
   #:fail-unless (set=? (syntax->datum #'(Clause ...))
                        (syntax->datum #'(ConsAll ...)))
   (type-error #:src this-syntax
               #:msg (string-append
                      "match: clauses not exhaustive; missing: "
                      (string-join      
                       (map symbol->string
                            (set-subtract 
                             (syntax->datum #'(ConsAll ...))
                             (syntax->datum #'(Clause ...))))
                       ", ")))
   #:with ((_ _ _ Cons? [_ acc τ] ...) ...)
          (map ; ok to compare symbols since clause names can't be rebound
           (lambda (Cl) 
             (stx-findf
              (syntax-parser
                [(_ 'C . rst) (equal? Cl (syntax->datum #'C))])
              (stx-cdr #'info-body))) ; drop leading #%app
           (syntax->datum #'(Clause ...)))
   ;; this commented block experiments with expanding to unsafe ops
   ;; #:with ((acc ...) ...) (stx-map 
   ;;                         (lambda (accs)
   ;;                          (for/list ([(a i) (in-indexed (syntax->list accs))])
   ;;                            #`(lambda (s) (unsafe-struct*-ref s #,(datum->syntax #'here i)))))
   ;;                         #'((acc-fn ...) ...))
   #:with (e_c ...+) (stx-map (lambda (ec) (add-expected-ty ec #'t_expect)) #'(e_c_un ...))
   [[x ≫ x- : τ] ... ⊢ [e_guard ≫ e_guard- ⇐ Bool] [e_c ≫ e_c- ⇒ τ_ec]] ...
   #:with z (generate-temporary) ; dont duplicate eval of test expr
   --------
   [⊢ (let- ([z e-])
        (cond-
         [(and- (Cons? z) 
                (let- ([x- (acc z)] ...) e_guard-))
          (let- ([x- (acc z)] ...) e_c-)] ...))
       ⇒ (⊔ τ_ec ...)]])

; special arrow that computes free vars; for use with tests
; (because we can't write explicit forall
(define-syntax →/test 
  (syntax-parser
    [(→/test (~and Xs (X:id ...)) . rst)
     #:when (brace? #'Xs)
     #'(?∀ (X ...) (ext-stlc:→ . rst))]
    [(→/test . rst)
     #:with Xs (compute-tyvars #'rst)
     #'(?∀ Xs (ext-stlc:→ . rst))]))

; all λs have type (?∀ (X ...) (→ τ_in ... τ_out))
(define-typed-syntax λ #:datum-literals (:)
  [(λ (x:id ...) body) ⇐ (~?∀ (X ...) (~ext-stlc:→ τ_in ... τ_out)) ≫
   #:fail-unless (stx-length=? #'[x ...] #'[τ_in ...])
   (format "expected a function of ~a arguments, got one with ~a arguments"
           (stx-length #'[τ_in ...]) (stx-length #'[x ...]))
   [(X ...) ([x ≫ x- : τ_in] ...) ⊢ [body ≫ body- ⇐ τ_out]]
   --------
   [⊢ (λ- (x- ...) body-)]]
  [(λ ([x : τ_x] ...) body) ⇐ (~?∀ (V ...) (~ext-stlc:→ τ_in ... τ_out)) ≫
   #:with [X ...] (compute-tyvars #'(τ_x ...))
   #:with ((X- ...) (τ_x-:type ...) _) (infers/ctx+erase #'(X ...) #'(τ_x ...) #:tag '::)
;   [[X ≫ X- :: #%type] ... ⊢ [τ_x ≫ τ_x- ⇐ :: #%type] ...]
   [τ_in τ⊑ τ_x- #:for x] ...
   ;; TODO is there a way to have λs that refer to ids defined after them?
   [(V ... X- ...) ([x ≫ x- : τ_x-] ...) ⊢ body ≫ body- ⇐ τ_out]
   --------
   [⊢ (λ- (x- ...) body-)]]
  [(λ ([x : τ_x] ...) body) ≫
   #:with [X ...] (compute-tyvars #'(τ_x ...))
   ;; TODO is there a way to have λs that refer to ids defined after them?
   [([X ≫ X- :: #%type] ...) ([x ≫ x- : τ_x] ...) ⊢ body ≫ body- ⇒ τ_body]
   #:with [τ_x* ...] (inst-types/cs #'[X ...] #'([X X-] ...) #'[τ_x ...])
   #:with τ_fn (add-orig #'(?∀ (X- ...) (ext-stlc:→ τ_x* ... τ_body))
                         #`(→ #,@(stx-map get-orig #'[τ_x* ...]) #,(get-orig #'τ_body)))
   --------
   [⊢ (λ- (x- ...) body-) ⇒ τ_fn]])


;; #%app --------------------------------------------------
(define-typed-syntax mlish:#%app
  [(_ e_fn e_arg ...) ≫
   ;; compute fn type (ie ∀ and →)
   [⊢ e_fn ≫ e_fn- ⇒ (~?∀ Xs (~ext-stlc:→ . tyX_args))]
   ;; solve for type variables Xs
   #:with [[e_arg- ...] Xs* cs] (solve #'Xs #'tyX_args this-syntax)
   ;; instantiate polymorphic function type
   #:with [τ_in ... τ_out] (inst-types/cs #'Xs* #'cs #'tyX_args)
   #:with (unsolved-X ...) (find-free-Xs #'Xs* #'τ_out)
   ;; arity check
   #:fail-unless (stx-length=? #'[τ_in ...] #'[e_arg ...])
                 (num-args-fail-msg #'e_fn #'[τ_in ...] #'[e_arg ...])
   ;; compute argument types
   #:with (τ_arg ...) (stx-map typeof #'(e_arg- ...))
   ;; typecheck args
   [τ_arg τ⊑ τ_in #:for e_arg] ...
   #:with τ_out* (if (stx-null? #'(unsolved-X ...))
                     #'τ_out
                     (syntax-parse #'τ_out
                       [(~?∀ (Y ...) τ_out)
                        #:fail-unless (→? #'τ_out)
                        (mk-app-poly-infer-error this-syntax #'(τ_in ...) #'(τ_arg ...) #'e_fn)
                        (for ([X (in-list (syntax->list #'(unsolved-X ...)))])
                          (unless (covariant-X? X #'τ_out)
                            (raise-syntax-error
                             #f
                             (mk-app-poly-infer-error this-syntax #'(τ_in ...) #'(τ_arg ...) #'e_fn)
                             this-syntax)))
                        #'(∀ (unsolved-X ... Y ...) τ_out)]))
   --------
   [⊢ (#%app- e_fn- e_arg- ...) ⇒ τ_out*]])


;; define these explicitly (instead of typed-out), for use in desugarings
(define-primop void : (→ Unit))
(define-primop not : (→ Bool Bool))

;; cond and other conditionals
(define-typed-syntax cond
  [(_ [(~or (~and (~datum else) (~parse test #'(ext-stlc:#%datum . #t)))
               test)
          b ... body] ...+) ⇐ τ_expected ≫
   [⊢ test ≫ test- ⇐ Bool] ...
   [⊢ (begin b ... body) ≫ body- ⇐ τ_expected] ...
   --------
   [⊢ (cond- [test- body-] ...)]]
  [(_ [(~or (~and (~datum else) (~parse test #'(ext-stlc:#%datum . #t)))
               test)
          b ... body] ...+) ≫
   [⊢ test ≫ test- ⇐ Bool] ...
   [⊢ (begin b ... body) ≫ body- ⇒ τ_body] ...
   --------
   [⊢ (cond- [test- body-] ...) ⇒ (⊔ τ_body ...)]])
(define-typed-syntax (when test body ...) ≫
 ----------------
 [≻ #,(syntax/loc this-syntax (cond [test body ... (mlish:#%app void)]))])
(define-typed-syntax (unless test body ...) ≫
 -------
 [≻ #,(syntax/loc this-syntax (cond [test (mlish:#%app void)]
                                    [else body ... (mlish:#%app void)]))])

;; sync channels and threads
(define-type-constructor Channel)

(define-typed-syntax make-channel
  [(make-channel (~and tys {ty})) ≫
   #:when (brace? #'tys)
   --------
   [⊢ [_ ≫ (make-channel-) ⇒ : (Channel ty)]]])

(define-base-type Thread)

(define-typed-syntax number->string
  [number->string:id ≫
   --------
   [⊢ [_ ≫ number->string- ⇒ : (→ Int String)]]]
  [(number->string n) ≫
   --------
   [_ ≻ (number->string n (ext-stlc:#%datum . 10))]]
  [(number->string n rad) ≫
   [⊢ [n ≫ n- ⇐ : Int]]
   [⊢ [rad ≫ rad- ⇐ : Int]]
   --------
   [⊢ [_ ≫ (number->string- n- rad-) ⇒ : String]]])

(define-typed-syntax string-append
  [(string-append str ...) ≫
   [⊢ [str ≫ str- ⇐ : String] ...]
   --------
   [⊢ [_ ≫ (string-append- str- ...) ⇒ : String]]])

;; vectors
(define-type-constructor Vector)

(define-typed-syntax vector
  [(vector (~and tys {ty})) ≫
   #:when (brace? #'tys)
   --------
   [⊢ [_ ≫ (vector-) ⇒ : (Vector ty)]]]
  [(vector v ...) ⇐ : (Vector ty) ≫
   [⊢ [v ≫ v- ⇐ : ty] ...]
   --------
   [⊢ [_ ≫ (vector- v- ...) ⇐ : _]]]
  [(vector v ...) ≫
   [⊢ [v ≫ v- ⇒ : ty] ...]
   #:when (same-types? #'(ty ...))
   #:with one-ty (stx-car #'(ty ...))
   --------
   [⊢ [_ ≫ (vector- v- ...) ⇒ : (Vector one-ty)]]])
(define-typed-syntax make-vector
  [(make-vector n) ≫
   --------
   [_ ≻ (make-vector n (ext-stlc:#%datum . 0))]]
  [(make-vector n e) ≫
   [⊢ [n ≫ n- ⇐ : Int]]
   [⊢ [e ≫ e- ⇒ : ty]]
   --------
   [⊢ [_ ≫ (make-vector- n- e-) ⇒ : (Vector ty)]]])

;; sequences and for loops

(define-type-constructor Sequence)

(define-typed-syntax in-range
  [(in-range end) ≫
   --------
   [_ ≻ (in-range (ext-stlc:#%datum . 0) end (ext-stlc:#%datum . 1))]]
  [(in-range start end) ≫
   --------
   [_ ≻ (in-range start end (ext-stlc:#%datum . 1))]]
  [(in-range start end step) ≫
   [⊢ [start ≫ start- ⇐ : Int]]
   [⊢ [end ≫ end- ⇐ : Int]]
   [⊢ [step ≫ step- ⇐ : Int]]
   --------
   [⊢ [_ ≫ (in-range- start- end- step-) ⇒ : (Sequence Int)]]])

(define-typed-syntax in-naturals
 [(in-naturals) ≫
  --------
  [_ ≻ (in-naturals (ext-stlc:#%datum . 0))]]
 [(in-naturals start) ≫
  [⊢ [start ≫ start- ⇐ : Int]]
  --------
  [⊢ [_ ≫ (in-naturals- start-) ⇒ : (Sequence Int)]]])

(define-typed-syntax in-lines
  [(in-lines e) ≫
   [⊢ [e ≫ e- ⇐ : String]]
   --------
   [⊢ [_ ≫ (in-lines- (open-input-string- e-)) ⇒ : (Sequence String)]]])

(define-typed-syntax for
  [(for ([x:id e]...) b ... body) ≫
   [⊢ [e ≫ e- ⇒ : (~Sequence ty)] ...]
   [() ([x ≫ x- : ty] ...)
    ⊢ [b ≫ b- ⇒ : _] ... [body ≫ body- ⇒ : _]]
   --------
   [⊢ [_ ≫ (for- ([x- e-] ...) b- ... body-) ⇒ : Unit]]])
(define-typed-syntax for*
  [(for* ([x:id e]...) b ... body) ≫
   [⊢ [e ≫ e- ⇒ : (~Sequence ty)] ...]
   [() ([x ≫ x- : ty] ...)
    ⊢ [b ≫ b- ⇒ : _] ... [body ≫ body- ⇒ : _]]
   --------
   [⊢ [_ ≫ (for*- ([x- e-] ...) b- ... body-) ⇒ : Unit]]])

(define-typed-syntax for/list
  [(for/list ([x:id e]...) body) ≫
   [⊢ [e ≫ e- ⇒ : (~Sequence ty)] ...]
   [() ([x ≫ x- : ty] ...) ⊢ [body ≫ body- ⇒ : ty_body]]
   --------
   [⊢ [_ ≫ (for/list- ([x- e-] ...) body-) ⇒ : (List ty_body)]]])
(define-typed-syntax for/vector
  [(for/vector ([x:id e]...) body) ≫
   [⊢ [e ≫ e- ⇒ : (~Sequence ty)] ...]
   [() ([x ≫ x- : ty] ...) ⊢ [body ≫ body- ⇒ : ty_body]]
   --------
   [⊢ [_ ≫ (for/vector- ([x- e-] ...) body-) ⇒ : (Vector ty_body)]]])
(define-typed-syntax for*/vector
  [(for*/vector ([x:id e]...) body) ≫
   [⊢ [e ≫ e- ⇒ : (~Sequence ty)] ...]
   [() ([x ≫ x- : ty] ...) ⊢ [body ≫ body- ⇒ : ty_body]]
   --------
   [⊢ [_ ≫ (for*/vector- ([x- e-] ...) body-) ⇒ : (Vector ty_body)]]])
(define-typed-syntax for*/list
  [(for*/list ([x:id e]...) body) ≫
   [⊢ [e ≫ e- ⇒ : (~Sequence ty)] ...]
   [() ([x ≫ x- : ty] ...) ⊢ [body ≫ body- ⇒ : ty_body]]
   --------
   [⊢ [_ ≫ (for*/list- ([x- e-] ...) body-) ⇒ : (List ty_body)]]])
(define-typed-syntax for/fold
  [(for/fold ([acc init]) ([x:id e] ...) body) ⇐ : τ_expected ≫
   [⊢ [init ≫ init- ⇐ : τ_expected]]
   [⊢ [e ≫ e- ⇒ : (~Sequence ty)] ...]
   [() ([acc ≫ acc- : τ_expected] [x ≫ x- : ty] ...)
    ⊢ [body ≫ body- ⇐ : τ_expected]]
   --------
   [⊢ [_ ≫ (for/fold- ([acc- init-]) ([x- e-] ...) body-) ⇐ : _]]]
  [(for/fold ([acc init]) ([x:id e] ...) body) ≫
   [⊢ [init ≫ init- ⇒ : τ_init]]
   [⊢ [e ≫ e- ⇒ : (~Sequence ty)] ...]
   [() ([acc ≫ acc- : τ_init] [x ≫ x- : ty] ...)
    ⊢ [body ≫ body- ⇐ : τ_init]]
   --------
   [⊢ [_ ≫ (for/fold- ([acc- init-]) ([x- e-] ...) body-) ⇒ : τ_init]]])

(define-typed-syntax for/hash
  [(for/hash ([x:id e]...) body) ≫
   [⊢ [e ≫ e- ⇒ : (~Sequence ty)] ...]
   [() ([x ≫ x- : ty] ...) ⊢ [body ≫ body- ⇒ : (~× ty_k ty_v)]]
   --------
   [⊢ [_ ≫ (for/hash- ([x- e-] ...)
             (let- ([t body-])
               (values- (car- t) (cadr- t))))
       ⇒ : (Hash ty_k ty_v)]]])

(define-typed-syntax for/sum
  [(for/sum ([x:id e]... 
             (~optional (~seq #:when guard) #:defaults ([guard #'(ext-stlc:#%datum . #t)])))
     body) ≫
   [⊢ [e ≫ e- ⇒ : (~Sequence ty)] ...]
   [() ([x ≫ x- : ty] ...)
    ⊢ [guard ≫ guard- ⇒ : _] [body ≫ body- ⇐ : Int]]
   --------
   [⊢ [_ ≫ (for/sum- ([x- e-] ... #:when guard-) body-) ⇒ : Int]]])

; printing and displaying
(define-typed-syntax printf
  [(printf str e ...) ≫
   [⊢ [str ≫ s- ⇐ : String]]
   [⊢ [e ≫ e- ⇒ : ty] ...]
   --------
   [⊢ [_ ≫ (printf- s- e- ...) ⇒ : Unit]]])
(define-typed-syntax format
  [(format str e ...) ≫
   [⊢ [str ≫ s- ⇐ : String]]
   [⊢ [e ≫ e- ⇒ : ty] ...]
   --------
   [⊢ [_ ≫ (format- s- e- ...) ⇒ : String]]])

(define-typed-syntax let
  [(let name:id (~datum :) ty:type ~! ([x:id e] ...) b ... body) ≫
   [⊢ [e ≫ e- ⇒ : ty_e] ...]
   [() ([name ≫ name- : (→ ty_e ... ty.norm)] [x ≫ x- : ty_e] ...)
    ⊢ [b ≫ b- ⇒ : _] ... [body ≫ body- ⇐ : ty.norm]]
   --------
   [⊢ [_ ≫ (letrec- ([name- (λ- (x- ...) b- ... body-)])
             (name- e- ...))
       ⇒ : ty.norm]]]
  [(let ([x:id e] ...) body ...) ≫
   --------
   [_ ≻ (ext-stlc:let ([x e] ...) (begin body ...))]])
(define-typed-syntax let*
  [(let* ([x:id e] ...) body ...) ≫
   --------
   [_ ≻ (ext-stlc:let* ([x e] ...) (begin body ...))]])

(define-typed-syntax begin
  [(begin body ... b) ⇐ : τ_expected ≫
   [⊢ [body ≫ body- ⇒ : _] ...]
   [⊢ [b ≫ b- ⇐ : τ_expected]]
   --------
   [⊢ [_ ≫ (begin- body- ... b-) ⇐ : _]]]
  [(begin body ... b) ≫
   [⊢ [body ≫ body- ⇒ : _] ...]
   [⊢ [b ≫ b- ⇒ : τ]]
   --------
   [⊢ [_ ≫ (begin- body- ... b-) ⇒ : τ]]])

;; hash
(define-type-constructor Hash #:arity = 2)

; mutable hashes
(define-typed-syntax hash
  [(hash (~and tys {ty_key ty_val})) ≫
   #:when (brace? #'tys)
   --------
   [⊢ [_ ≫ (make-hash-) ⇒ : (Hash ty_key ty_val)]]]
  [(hash (~seq k v) ...) ≫
   [⊢ [k ≫ k- ⇒ : ty_k] ...]
   [⊢ [v ≫ v- ⇒ : ty_v] ...]
   #:when (same-types? #'(ty_k ...))
   #:when (same-types? #'(ty_v ...))
   #:with ty_key (stx-car #'(ty_k ...))
   #:with ty_val (stx-car #'(ty_v ...))
   --------
   [⊢ [_ ≫ (make-hash- (list- (cons- k- v-) ...)) ⇒ : (Hash ty_key ty_val)]]])
(define-typed-syntax hash-ref
  [(hash-ref h k) ≫
   [⊢ [h ≫ h- ⇒ : (~Hash ty_k ty_v)]]
   [⊢ [k ≫ k- ⇐ : ty_k]]
   --------
   [⊢ [_ ≫ (hash-ref- h- k-) ⇒ : ty_v]]]
  [(hash-ref h k fail) ≫
   [⊢ [h ≫ h- ⇒ : (~Hash ty_k ty_v)]]
   [⊢ [k ≫ k- ⇐ : ty_k]]
   [⊢ [fail ≫ fail- ⇐ : (→ ty_v)]]
   --------
   [⊢ [_ ≫ (hash-ref- h- k- fail-) ⇒ : ty_val]]])

(define-base-type String-Port)
(define-base-type Input-Port)

(define-primop string-length : (→ String Int))

(define-typed-syntax write-string
 [(write-string str out) ≫
  --------
  [_ ≻ (write-string str out (ext-stlc:#%datum . 0) (mlish:#%app string-length str))]]
 [(write-string str out start end) ≫
  [⊢ [str ≫ str- ⇐ : String]]
  [⊢ [out ≫ out- ⇐ : String-Port]]
  [⊢ [start ≫ start- ⇐ : Int]]
  [⊢ [end ≫ end- ⇐ : Int]]
  --------
  [⊢ [_ ≫ (begin- (write-string- str- out- start- end-) (void-)) ⇒ : Unit]]])

(define-typed-syntax string-copy!
  [(string-copy! dest dest-start src) ≫
   --------
   [_ ≻ (string-copy!
         dest dest-start src (ext-stlc:#%datum . 0) (mlish:#%app string-length src))]]
  [(string-copy! dest dest-start src src-start src-end) ≫
   [⊢ [dest ≫ dest- ⇐ : String]]
   [⊢ [src ≫ src- ⇐ : String]]
   [⊢ [dest-start ≫ dest-start- ⇐ : Int]]
   [⊢ [src-start ≫ src-start- ⇐ : Int]]
   [⊢ [src-end ≫ src-end- ⇐ : Int]]
   --------
   [⊢ [_ ≫ (string-copy!- dest- dest-start- src- src-start- src-end-) ⇒ : Unit]]])

(define-typed-syntax quotient+remainder
  [(quotient+remainder x y) ≫
   [⊢ [x ≫ x- ⇐ : Int]]
   [⊢ [y ≫ y- ⇐ : Int]]
   --------
   [⊢ [_ ≫ (let-values- ([[a b] (quotient/remainder- x- y-)])
             (list- a b))
       ⇒ : (stlc+rec-iso:× Int Int)]]])

(define-typed-syntax set!
  [(set! x:id e) ≫
   [⊢ [x ≫ x- ⇒ : ty_x]]
   [⊢ [e ≫ e- ⇐ : ty_x]]
   --------
   [⊢ [_ ≫ (set!- x e-) ⇒ : Unit]]])

(define-typed-syntax provide-type
  [(provide-type ty ...) ≫
   --------
   [_ ≻ (provide- ty ...)]])

(define-typed-syntax mlish-provide
  [(provide x:id ...) ≫
   [⊢ [x ≫ x- ⇒ : ty_x] ...]
   ; TODO: use hash-code to generate this tmp
   #:with (x-ty ...) (stx-map (lambda (y) (format-id y "~a-ty" y)) #'(x ...))
   --------
   [_ ≻ (begin-
          (provide- x ...)
          (stlc+rec-iso:define-type-alias x-ty ty_x) ...
          (provide- x-ty ...))]])
(define-typed-syntax require-typed
  [(require-typed x:id ... #:from mod) ≫
   #:with (x-ty ...) (stx-map (lambda (y) (format-id y "~a-ty" y)) #'(x ...))
   #:with (x- ...) (generate-temporaries #'(x ...))
   --------
   [_ ≻ (begin-
          (require- (rename-in (only-in mod x ... x-ty ...) [x x-] ...))
          (define-typed-variable-rename x ≫ x- : x-ty) ...)]])

(define-base-type Regexp)

(define-typed-syntax read-int
  [(read-int) ≫
   --------
   [⊢ [_ ≫ (let- ([x (read-)])
             (cond- [(exact-integer?- x) x]
                    [else (error- 'read-int "expected an int, given: ~v" x)]))
       ⇒ : Int]]])

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(module+ test
  (begin-for-syntax
    (check-true  (covariant-Xs? #'Int))
    (check-true  (covariant-Xs? #'(stlc+box:Ref Int)))
    (check-true  (covariant-Xs? #'(→ Int Int)))
    (check-true  (covariant-Xs? #'(∀ (X) X)))
    (check-false (covariant-Xs? #'(∀ (X) (stlc+box:Ref X))))
    (check-false (covariant-Xs? #'(∀ (X) (→ X X))))
    (check-false (covariant-Xs? #'(∀ (X) (→ X Int))))
    (check-true  (covariant-Xs? #'(∀ (X) (→ Int X))))
    (check-true  (covariant-Xs? #'(∀ (X) (→ (→ X Int) X))))
    (check-false (covariant-Xs? #'(∀ (X) (→ (→ (→ X Int) Int) X))))
    (check-false (covariant-Xs? #'(∀ (X) (→ (stlc+box:Ref X) Int))))
    (check-false (covariant-Xs? #'(∀ (X Y) (→ X Y))))
    (check-true  (covariant-Xs? #'(∀ (X Y) (→ (→ X Int) Y))))
    (check-false (covariant-Xs? #'(∀ (X Y) (→ (→ X Int) (→ Y Int)))))
    (check-true  (covariant-Xs? #'(∀ (X Y) (→ (→ X Int) (→ Int Y)))))
    (check-false (covariant-Xs? #'(∀ (A B) (→ (→ Int (stlc+rec-iso:× A B))
                                              (→ String (stlc+rec-iso:× A B))
                                              (stlc+rec-iso:× A B)))))
    (check-true  (covariant-Xs? #'(∀ (A B) (→ (→ (stlc+rec-iso:× A B) Int)
                                              (→ (stlc+rec-iso:× A B) String)
                                              (stlc+rec-iso:× A B)))))
    ))
