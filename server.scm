(use srfi-69 intarweb spiffy spiffy-uri-match postgresql json)

;; utility functions
(define (json->string rows)
  (call-with-output-string (lambda (port) (json-write rows port))))

(define (string->json s)
  (call-with-input-string s (lambda (port) (json-read port))))

;; DB functions
(define (get-devices)
  (let* ((conn (connect '((dbname . sd_ventures_development) (user . sd_ventures))))
         (rows (row-fold-right cons '() (query conn "SELECT device_type_id::int2, mac_addr::text FROM devices"))))
    (json->string rows)))

(define (get-device device-id)
  (let* ((conn (connect '((dbname . sd_ventures_development) (user . sd_ventures))))
         (row (row-values (query conn "SELECT device_type_id::int2, mac_addr::text FROM devices WHERE mac_addr = $1::text" device-id))))
    (json->string row)))

(define (create-device attrib-vec)
  (let* ((conn (connect '((dbname . sd_ventures_development) (user . sd_ventures))))
         (attrib-map (alist->hash-table (vector->list attrib-vec))))
    (query conn "INSERT INTO devices (device_type_id, mac_addr, manufactured_at) VALUES ($1, $2, $3)"
      (hash-table-ref attrib-map "device_type_id")
      (hash-table-ref attrib-map "mac_addr")
      (hash-table-ref attrib-map "manufactured_at"))))

(define (get-readings device-id)
  (let* ((conn (connect '((dbname . sd_ventures_development) (user . sd_ventures))))
         (rows (row-fold-right cons '() (query conn "SELECT value::text, created_at::text FROM readings WHERE device_mac_addr = $1::text" device-id))))
    (json->string rows)))

(define (create-reading device-id attrib-vec)
  (let* ((conn (connect '((dbname . sd_ventures_development) (user . sd_ventures))))
         (attrib-map (alist->hash-table (vector->list attrib-vec))))
    (query conn "INSERT INTO readings (device_mac_addr, value, created_at) VALUES ($1, $2, $3)"
      device-id
      (hash-table-ref attrib-map "value")
      (hash-table-ref attrib-map "created_at"))))

;; Processing POST data in JSON format
(define (get-request-json-body)
   (let* ((headers (request-headers (current-request)))
          (content-length (header-value 'content-length headers))
          (body (read-string content-length (request-port (current-request)))))
     (string->json body)))

;; Routes
(vhost-map `((".*" . ,(uri-match/spiffy
                        `(((/ "api" "1" "devices")
                           (GET ,(lambda (continue)
                                   (send-response
                                     status: 'ok
                                     body: (get-devices)
                                     headers: '((content-type application/json)))))
                            (POST ,(lambda (continue)
                                     (send-response
                                       status: 'ok
                                       body: (begin (create-device (get-request-json-body)) "{\"status\": \"ok\"}")
                                       headers: '((content-type application/json)))))
                              ((/ (submatch (+ any)))
                               (GET ,(lambda (continue device-id)
                                       (send-response
                                         status: 'ok
                                         body: (get-device device-id)
                                         headers: '((content-type application/json)))))
                                ((/ "readings")
                                 (GET ,(lambda (continue device-id)
                                         (send-response
                                           status: 'ok
                                           body: (get-readings device-id)
                                           headers: '((content-type application/json)))))
                                 (POST ,(lambda (continue device-id)
                                         (send-response
                                           status: 'ok
                                           body: (begin (create-reading device-id (get-request-json-body)) "{\"status\": \"ok\"}")
                                           headers: '((content-type application/json)))))
                                     ))))))))
(start-server)
