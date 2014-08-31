(use awful uuid redis-client uri-common)

(define hash "shortener")

;; connect to redis
(redis-connect "127.0.0.1" 6379)

;; find url from REDIS.  Result is a list so just get the first one.
(define (find-url key)
  (car (redis-hget hash key)))

;; validate url
(define (good-url? url)
  (let ((uri (uri-reference url)))
    (and (uri-scheme uri) (uri-host uri))))

;; http://ahsmart.com:8080/shorten?url=foo
(define-page "/shorten"
  (lambda ()
    (let ((url ($ 'url))
          (gen-uuid (lambda () (substring (uuid-v4) 0 8))))
      (if (not (good-url? url))
          (string-append "bad url: " url) ;; sxml
          (let loop ((uuid (gen-uuid)))
            (let ((result (find-url uuid)))
              (if (null? result) ;; hget returns list of list
                (begin 
                  (redis-hset hash uuid url)
                  uuid)
                (loop (gen-uuid)))))))) ;; find next uuid in case of collision
  no-template: #t)

;; http://ahsmart.com:8080/go?key=bar
(define-page "/go"
  (lambda ()
    (let ((url (find-url ($ 'key))))
      (if (null? url)
          (send-status 404 "Not found" "Sorry, unable to find URL from the key specified")
          (redirect-to url))))
  no-template: #t)
