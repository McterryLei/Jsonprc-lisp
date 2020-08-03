#lang racket

(require "jrpc-utils.rkt")

(define *host* "localhost")
(define *port* 1234)

(define (send method params)
  (jrpc-send *host* *port* method params))

;; Say hi to server
(define (hello name)
  (send "hello" (hash 'name name)))

