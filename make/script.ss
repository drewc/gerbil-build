;;; -*- Gerbil -*-
;;; (C) vyzo at hackzen.org, me at drewc.ca
;;; package build script template
package: std/make
(import :std/make/make
        :gerbil/gambit/misc)

(export defmake-script build-main)

(def (build-main args build-spec keys that-file)
  (def srcdir (path-normalize (path-directory that-file)))
  (def (build) (apply make build-spec srcdir: srcdir keys))
  (match args
    (["meta"] (write '("spec" "compile")) (newline))
    (["spec"] (pretty-print build-spec))
    (["compile"] (build))
    ([] (build))))

(defsyntax (defmake-script stx)
  (syntax-case stx ()
    ((macro build-spec keys ...)
     (with-syntax* ((@this-script (stx-identifier #'macro 'this-source-file))
                    (+this-source-file+ (syntax/loc stx (@this-script)))
                    (@main        (stx-identifier #'macro 'main)))
       #'(def (@main . args)
           (build-main args build-spec [keys ...] +this-source-file+))))))