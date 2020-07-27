package: std/make
(import :std/misc/list :gerbil/gambit/ports)
(export #t)

(def default-gambit-gsc "gsc")
(def default-gerbil-gxc "gxc")

(def (gerbil-gsc)
  (getenv "GERBIL_GSC" default-gambit-gsc))
(def (gerbil-gxc)
  (getenv "GERBIL_GXC" default-gerbil-gxc))

;;; Functions that should be better moved some library...
(def (force-outputs) (force-output (current-error-port)) (force-output)) ;; move to std/misc/ports ?
(def (message . lst) (apply displayln lst) (force-outputs)) ;; move to std/misc/ports ?
(def (writeln x) (write x) (newline) (force-outputs)) ;; move to std/misc/ports ?
(def (prefix/ prefix path) (if prefix (string-append prefix "/" path) path)) ;; move to std/misc/path ?

;;; Functions partially reimplemented from std/srfi/43. See bug #465
(def (vector-for-each f v)
  (def l (vector-length v))
  (let loop ((i 0)) (when (< i l) (begin (f i (vector-ref v i)) (loop (+ 1 i))))))
(def (vector-ensure-ref v i f)
  (or (vector-ref v i) (let ((x (f))) (vector-set! v i x) x)))
