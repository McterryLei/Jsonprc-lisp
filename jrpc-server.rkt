#lang racket

(require "jrpc-utils.rkt")

(register-proc "config.query"
               (lambda (req)
                 (make-response req 0 "success" (hash))))

(jrpc-server-run 1234)