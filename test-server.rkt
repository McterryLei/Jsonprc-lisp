#lang racket

(require "jrpc.rkt")

(define (jrpc-hello req)
  (define (hello-result name)
    (with-output-to-string (lambda ()
                             (printf "Hello ~a" name))))
  
  (let* ([params (request-params req)]
         [name   (hash-ref params 'name)])
    (jrpc-success req (hello-result name))))

;; Register jrpc procedures
(jrpc-register-proc "hello" jrpc-hello)

;; Run server
(jrpc-server-run 1234)