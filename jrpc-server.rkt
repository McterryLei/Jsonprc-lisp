#lang racket

(require "jrpc-utils.rkt")

(define (jrpc-hello req)
  (define (hello-result name)
    (with-output-to-string (lambda ()
                             (printf "Hello ~a" name))))
  
  (let* ([params (request-params req)]
         [name (hash-ref params 'name)])
    (make-success-response req (hello-result name))))

;; Register jrpc procedures
(register-proc "hello" jrpc-hello)

;; Run server
(jrpc-server-run 1234)