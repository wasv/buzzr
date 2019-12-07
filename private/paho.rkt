#lang racket/base

(require ffi/unsafe
         ffi/unsafe/define)

(provide (all-defined-out))

;; C Types
(define-cpointer-type _MQTTClient_t)

(define _paho_error_code
    (_enum '(paho_success = 0
             paho_error_generic = -1
             paho_error_persistence_error = -2
             paho_error_disconnected = -3
             paho_error_max_messages_inflight = -4
             paho_error_bad_utf8_string = -5
             paho_error_null_parameter = -6
             paho_error_topicname_trunacted = -7
             paho_error_bad_structure = -8
             paho_error_bad_qos = -9
             paho_error_ssl_not_supported = -10
             paho_error_bad_mqtt_version = -11
             paho_error_bad_portocol = -14
             paho_error_bad_mqtt_option = -15
             pago_error_mqtt-version = -16)
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

(define (paho-mqtt-connect-options-create)
    (make-MQTTClient_connectOptions_t
    (bytes->list #"MQTC") 6 60 1 1 #f #f #f 30 0 #f 0 #f 0 (list #f 0 0) (list 0 #f) -1 0))

(define-cstruct _MQTTProperties_t
    ([count _int]
     [max_count _int]
     [length _int]
     [array _pointer]))

(define-cstruct _MQTTClient_message_t
    ([struct_id (_array/list _byte 4)]
     [struct_version _int]
     [payloadlen _int]
     [payload _pointer]
     [qos _int]
     [retained _int]
     [dup _int]
     [msgid _int]
     [properties _MQTTProperties_t]))

(define (paho-mqtt-message-create payload len qos retained)
    (make-MQTTClient_message_t
    (bytes->list #"MQTM") 1 len payload qos retained 0 0 0 0 (list 0 0 0 #f)))

;; Start of FFI Imports
(define paho-ffi-lib (ffi-lib "libpaho-mqtt3cs" (list "1")))
(define-ffi-definer define-paho paho-ffi-lib)

(define-paho paho-mqtt-client-create
  (_fun [client : (_ptr o _MQTTClient_t)] _string _string _int _pointer -> _paho_error_code -> client)
    #:c-id MQTTClient_create)

(define-paho paho-mqtt-client-connect
  (_fun _MQTTClient_t _MQTTClient_connectOptions_t-pointer -> _paho_error_code)
    #:c-id MQTTClient_connect)

(define-paho paho-mqtt-client-disconnect
  (_fun _MQTTClient_t _int -> _paho_error_code)
    #:c-id MQTTClient_disconnect)

(define-paho paho-mqtt-version-info
  (_fun -> _MQTTClient_nameValue_t-pointer)
    #:c-id MQTTClient_getVersionInfo)
