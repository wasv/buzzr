#lang racket/base

(module+ test
  (require rackunit))

;; Notice
;; To install (from within the package directory):
;;   $ raco pkg install
;; To install (once uploaded to pkgs.racket-lang.org):
;;   $ raco pkg install <<name>>
;; To uninstall:
;;   $ raco pkg remove <<name>>
;; To view documentation:
;;   $ raco docs <<name>>

(require "private/buzzr.rkt")
(provide (all-from-out "private/buzzr.rkt"))

(module* main #f
    (define ADDRESS "tcp://localhost:1883")
    (define CLIENTID "ExampleClient")
    (define client (buzzr:client-create ADDRESS CLIENTID 0 #f))
    (define conn_opts (buzzr:connect-options-create))

    (buzzr:succeed-or-exit (buzzr:client-connect client conn_opts))
    (buzzr:succeed-or-exit (buzzr:publish client "/topic" #"test" 0 0))

    (buzzr:client-disconnect client 0))

(module+ test
  ;; Any code in this `test` submodule runs when this file is run using DrRacket
  ;; or with `raco test`. The code here does not run when this file is
  ;; required by another module.

  (check-equal? (+ 2 2) 4))
