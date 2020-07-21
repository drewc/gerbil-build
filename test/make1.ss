(import :gerbil/compiler :std/srfi/13)
;; (export #t)

(def gerbil-path (getenv "GERBIL_PATH" "~/.gerbil"))
(def libdir (string-append gerbil-path "/lib"))
(def (module-package ctx)
  (let (id (symbol->string (gx#expander-context-id ctx)))
    (cond ((string-rindex id #\/)
           => (lambda (x) (substring id 0 x)))
          (#t ""))))
(def (ss-file-libdir file)
  (string-append libdir "/" (module-package (gx#import-module file))))

(def (make-ss file)
    (compile-file file
                  [output-dir:
                   libdir
                   invoke-gsc: #t
                ;   keep-scm: #f
                 ;  generate-ssxi: #t
                   verbose: #t
                   ]))
