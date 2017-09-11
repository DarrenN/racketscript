#lang typed/racket/base

(require "language.rkt"
         "ident.rkt")

(provide (all-defined-out))

(struct Module  ([id      : Symbol]
                 [path    : Path]
                 [lang    : (U Symbol String (Listof Symbol))]
                 [imports : (Setof (U Path Symbol))]
                 [quoted-bindings : (Setof Symbol)]
                 [forms   : (Listof ModuleLevelForm)])
  #:transparent)

(define-language Absyn
  #:alias
  [Program      TopLevelForm]
  [ModuleName   (U Symbol Path)]

  #:forms
  ;; Top Level Forms

  [TopLevelForm             GeneralTopLevelForm
                            Expr
                            Module
                            Begin]

  [GeneralTopLevelForm      Expr
                            (DefineValues [ids : Args] [expr : Expr])
                            ;; DefineSyntaxes

                            ;; Same as ILRequire, but can't use to
                            ;; avoid cyclic depnedency.
                            (JSRequire [alias : Symbol]
                                       [path : (U Symbol Path-String)]
                                       [mode : (U 'default '*)])
                            #;Require*]

  ;; Module Level Forms
  [Provide*            (Listof Provide)]
  [Provide             (SimpleProvide     [id       : Symbol])
                       (RenamedProvide    [local-id : Symbol]
                                          [exported-id : Symbol])
                       (AllDefined        [exclude : (Setof Symbol)])
                       (PrefixAllDefined  [prefix-id : Symbol]
                                          [exclude : (Setof Symbol)])]
  [ModuleLevelForm     GeneralTopLevelForm
                       Provide*
                       SubModuleForm]

  [SubModuleForm       Module]

  ;; Expressions

  [Expr    Ident
           (TopId             [id       : Symbol])
           (VarRef            [var      : (Option (U Symbol TopId))])
           (Quote             [datum    : Any])


           Begin
           (Begin0            [expr0    : Expr]
                              [expr*    : (Listof Expr)])

           (PlainApp          [lam      : Expr]    [args  : (Listof Expr)])
           (PlainLambda       [formals  : Formals] [exprs : (Listof Expr)])
           (CaseLambda        [clauses  : (Listof PlainLambda)])


           (If                [pred     : Expr]
                              [t-branch : Expr]
                              [f-branch : Expr])

           ;; This also acts as LetRecValues because Absyn is
           ;; freshened.
           (LetValues         [bindings : (Listof Binding)]
                              [body     : (Listof Expr)])
           (Set!              [id       : LocalIdent] [expr : Expr])

           (WithContinuationMark   [key    : Expr]
                                   [value  : Expr]
                                   [result : Expr])]

  [Ident  LocalIdent
          ImportedIdent
          TopLevelIdent]

  [Begin   (Listof TopLevelForm)]

  ;; Bindings and Formal Arguments

  [Binding      (Pairof Args Expr)]

  [Args         (Listof LocalIdent)]

  [Formals      LocalIdent
                (Listof LocalIdent)
                (Pairof (Listof LocalIdent) LocalIdent)])

(struct LocalIdent     ([id : Symbol]))
(struct ImportedIdent  ([id : Symbol] [src-mod : Module-Path] [reachable? : Boolean]))
(struct TopLevelIdent  ([id : Symbol]))

(: lambda-arity (-> PlainLambda (U Natural arity-at-least)))
(define (lambda-arity f)
  (define frmls (PlainLambda-formals f))
  (cond
    [(LocalIdent? frmls) (arity-at-least 0)]
    [(list? frmls) (length frmls)]
    [(pair? frmls) (arity-at-least (length (car frmls)))]))


(: fresh-id (-> Symbol LocalIdent))
(define (fresh-id sym)
  (LocalIdent (fresh-id-symbol sym)))
