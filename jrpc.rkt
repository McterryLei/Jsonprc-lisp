#lang racket

(require racket/tcp)
(require json)

(provide (all-defined-out))
   
;;;
;;; Send jrpc request to server 
;;; 
(define (jrpc-send host port method params)
  
  (define (write-request out request)
    (printf "Send to ~a:~a :\n" host port)
    (write-json request)
    (write-json request out)
    (close-output-port out))
    
  (define (read-response in)
    (let ([result (read-string 65535 in)]) 
      (printf "\n\nResponse :\n")
      (printf "~a\n\n" result)
      (close-input-port in)
      (with-input-from-string result
        (λ () (read-json)))))

  (let-values ([(in out) (tcp-connect host port)])
    (write-request out (make-request method params))
    (read-response in)))


;;;
;;; Run jrpc server
;;;
(define (jrpc-server-run port)
  ;; Main loop
  (define (loop listener)
    (with-handlers ([exn:fail? (lambda (exn) 'error)])
      (let-values ([(in out) (tcp-accept listener)])
        (handle (read-request in) out)
        (close-input-port in)
        (close-output-port out)))
    (loop listener))

  ;; Read request from client
  (define (read-request in)
    (let ([req (read-json in)])
      (printf "Got request: ")
      (write-json req)
      (printf "\n")
      req))

  ;; Handle request 
  (define (handle req out)
    (let* ([name   (request-name req)]
           [params (request-params req)]
           [proc   (lookup-proc name)])
      (write-json (proc req) out)))

  (loop (tcp-listen port)))


;;;
;;; Jrpc server procedures
;;;
(define *procedures* (hash))

(define (jrpc-register-proc method proc)
  (if (hash-has-key? *procedures* method)
      (printf "ERROR: Procedure is already registered: ~a~%" method)
      (set! *procedures* (hash-set *procedures* method proc))))
       
(define (lookup-proc method)
  (if (hash-has-key? *procedures* method)
      (hash-ref *procedures* method)
      unfound-proc))
  
(define (unfound-proc req)
  (printf "ERROR: Method not found: ~a~%" (request-name req))
  (jrpc-error (request-id req)
              (- 32601)
              "Method not found"))


;;;
;;; Jprc request
;;;
(define (make-request method params)
  (hash 'jsonrpc "2.0"
        'id 1
        'method method
        'params params))

(define (request-id req) (hash-ref req 'id))
(define (request-name req) (hash-ref req 'method))
(define (request-params req) (hash-ref req 'params))


;;;
;;; Jprc response
;;;
(define (jrpc-success req [data (json-null)])
  (jrpc-response req 0 "Success" data))

(define (jrpc-response req code message [data (json-null)])
  (hash 'id (request-id req)
        'result (hash 'code code
                      'message message
                      'data data)))

(define (jrpc-error id code message)
  (hash 'id id
        'error (hash 'code  code
                     'message message)))
