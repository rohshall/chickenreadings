(use spiffy spiffy-uri-match)

;; Routes
(vhost-map `((".*" . ,(uri-match/spiffy
                        `(((/ "api" "1" "devices")
                           (GET ,(lambda (continue)
                                   (send-response
                                     status: 'ok
                                     body: "Devices"
                                     headers: '((content-type application/json)))))
                            (POST ,(lambda (continue)
                                     (send-response
                                       status: 'ok
                                       body: "Creating device"
                                       headers: '((content-type application/json)))))
                              ((/ (submatch (+ any)))
                               (GET ,(lambda (continue device-id)
                                       (send-response
                                         status: 'ok
                                         body: (format "Device ~A" device-id)
                                         headers: '((content-type application/json)))))
                                ((/ "readings")
                                 (GET ,(lambda (continue device-id)
                                         (send-response
                                           status: 'ok
                                           body: (format "Readings for Device ~A" device-id)
                                           headers: '((content-type application/json)))))
                                 (POST ,(lambda (continue device-id)
                                         (send-response
                                           status: 'ok
                                           body: (format "Creating readings for Device ~A" device-id)
                                           headers: '((content-type application/json)))))
                                     ))))))))
(start-server)
