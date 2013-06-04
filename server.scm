(use intarweb spiffy spiffy-uri-match postgresql json)

(define (get-devices)
  (let ((conn (connect '((dbname . sd_ventures_development) (user . sd_ventures)))))
    (with-output-to-string
       (lambda () 
        (json-write (row-fold-right cons '() (query conn "SELECT device_type_id::int2, mac_addr::text FROM devices")))))))

(define (get-device device-id)
  (let ((conn (connect '((dbname . sd_ventures_development) (user . sd_ventures)))))
    (with-output-to-string
       (lambda () 
        (json-write (row-values (query conn "SELECT device_type_id::int2, mac_addr::text FROM devices WHERE mac_addr = $1::text" device-id)))))))

(define (get-readings device-id)
  (let ((conn (connect '((dbname . sd_ventures_development) (user . sd_ventures)))))
    (with-output-to-string
       (lambda () 
        (json-write (row-fold-right cons '() (query conn "SELECT value::text, created_at::text FROM readings WHERE device_mac_addr = $1::text" device-id)))))))

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
                                       body: (format "Creating device: ~A" (read-urlencoded-request-data (current-request)))
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
                                           body: (format "Creating readings for Device ~A with ~A" device-id (read-urlencoded-request-data (current-request)))
                                           headers: '((content-type application/json)))))
                                     ))))))))
(start-server)
