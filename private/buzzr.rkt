#lang racket/base

(require racket/list
         ffi/unsafe
         ffi/unsafe/define
         ffi/unsafe/cvector)

(provide (prefix-out buzzr: (all-defined-out)))

;; C Types
(define-cpointer-type _MQTTClient_t)

(define _error_code
    (_enum '(success = 0
             error-generic = -1
             error-persistence-error = -2
             error-disconnected = -3
             error-max-messages-inflight = -4
             error-bad-utf8-string = -5
             error-null-parameter = -6
             error-topicname-trunacted = -7
             error-bad-structure = -8
             error-bad-qos = -9
             error-ssl-not-supported = -10
             error-bad-mqtt-version = -11
             error-bad-portocol = -14
             error-bad-mqtt-option = -15
             error-mqtt-version = -16)
           _fixint))

(define-cstruct _MQTTClient_nameValue_t
    ([name  _string]
     [value _string]))

(define-cstruct _MQTTClient_willPayload_t
    ([len _int]
     [data _pointer]))

(define-cstruct _MQTTClient_willOptions_t
    ([struct_id (_array _byte 4)]
     [struct_version _int]
     [topicName _string]
     [message _string]
     [retained _int]
     [qos _int]
     [payload _MQTTClient_willPayload_t]))

(define-cstruct _MQTTClient_connectOptions_t
    ([struct_id (_array/list _byte 4)]
     [struct_version _int]
     [keepAliveInterval _int]
     [cleansession _int]
     [reliable _int]
     [will _MQTTClient_willOptions_t-pointer/null]
     [username _string]
     [password _string]
     [connectTimeout _int]
     [retryInterval _int]
     [ssl _pointer]
     [serverURIcount _int]
     [serverURIs _pointer]
     [MQTTVersion _int]
     [returned (_list-struct _string _int _int)]
     [binarypwd (_list-struct _int _pointer)]
     [maxInflightMessages _int]
     [cleanstart _int]))

(define-cstruct _MQTTClient_message_t
    ([struct_id (_array/list _byte 4)]
     [struct_version _int]
     [payloadlen _int]
     [payload _pointer]
     [qos _int]
     [retained _int]
     [dup _int]
     [msgid _int]
     [properties (_list-struct _int _int _int _pointer)]))

(define (connect-options-create username password)
    (make-MQTTClient_connectOptions_t
    (bytes->list #"MQTC") 6 60 1 1 #f username password 30 0 #f 0 #f 0 (list #f 0 0) (list 0 #f) -1 0))

;; Start of FFI Imports
(define paho-ffi-lib (ffi-lib "libpaho-mqtt3cs" (list "1")))
(define-ffi-definer define-paho paho-ffi-lib)

(define-paho client-create
  (_fun [client : (_ptr o _MQTTClient_t)] _string _string [_int = 0] [_pointer = #f]
        -> [result : _error_code] -> (list result client))
    #:c-id MQTTClient_create)

(define-paho client-connect
  (_fun _MQTTClient_t _MQTTClient_connectOptions_t-pointer -> [result : _error_code] -> (list result '()))
    #:c-id MQTTClient_connect)

(define-paho client-disconnect
  (_fun _MQTTClient_t [_int = 100] -> [result : _error_code] -> (list result '()))
    #:c-id MQTTClient_disconnect)

(define-paho publish
  (_fun _MQTTClient_t _string [payloadLen : _int = (bytes-length payload)] [payload : _bytes] _int _int [token : (_ptr o _uint)]
         -> [result : _error_code] -> (list result token))
    #:c-id MQTTClient_publish)

(define-paho subscribe
  (_fun _MQTTClient_t _string _int
         -> [result : _error_code] -> (list result '()))
    #:c-id MQTTClient_subscribe)

(define-paho receive
  (_fun _MQTTClient_t [topic : (_ptr o _string)] [topiclen : (_ptr o _int)] [message : (_ptr o _MQTTClient_message_t-pointer)] _int
        -> [result : _error_code] -> (list result (list topic (list->bytes (cvector->list (make-cvector*
                                                               (MQTTClient_message_t-payload message) _uint8
                                                               (MQTTClient_message_t-payloadlen message)))))))
     #:c-id MQTTClient_receive)

(define-paho version-info
  (_fun -> [info : _MQTTClient_nameValue_t-pointer] -> (MQTTClient_nameValue_t-value info))
    #:c-id MQTTClient_getVersionInfo)

;; Start of helper functions.
(define (check retval)
    (if (not (equal? (car retval) 'success))
        (begin
         (error (car retval)))
        (cadr retval)))
