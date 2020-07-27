package: std/make
(import ./spec ./base ./settings)
(export make)

(def (make-spec spec settings)
  (def inputs (spec-inputs spec settings))
  (def outputs (spec-outputs spec settings))

  (let exists? ((is inputs))
    (unless (null? is)
      (unless (file-exists? (car is))
        (error "Build Input file does not exist: " (car is)))
      (exists? (cdr is))))

  (let (res (spec-build spec settings))
    (begin0 res
      (message "build result " res " for " spec)
      (let exists? ((os outputs))
        (unless (null? os) (unless (file-exists? (car os))
                             (displayln "\nBuild Output file does not exist: " (car os)))
                (exists? (cdr os)))))))

(def (make build-spec . args)
  (def settings (apply make-settings args))
  (let %make ((s build-spec))
    (def spec (car s)) (def rest (cdr s))
    (make-spec spec settings) (unless (null? rest) (%make rest))))
