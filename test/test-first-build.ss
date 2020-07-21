;;; Settings: see details in doc/reference/make.md
(defstruct settings
  (srcdir libdir bindir force optimize debug static
          static-debug verbose build-deps parallelize gerbil.pkg)
  transparent: #t constructor: :init!)

(def current-make-settings (make-parameter #f))

(def (gerbil-build-cores)
  (with-catch (lambda (_) (##cpu-count)) (lambda () (string->number (getenv "GERBIL_BUILD_CORES")))))

(def (read-gerbil.pkg-plist srcdir)
  (with-catch
   false (lambda () (call-with-input-file (path-expand "gerbil.pkg" srcdir) read))))

(defmethod {:init! settings}
 (lambda (self
     srcdir: (srcdir_ #f) libdir: (libdir_ #f) bindir: (bindir_ #f)
     gerbil.pkg: (gxpkg_ #f) force: (force? #f)
     optimize: (optimize #t) debug: (debug 'env)
     static: (static #t) static-debug: (static-debug #f)
     verbose: (verbose #f) build-deps: (build-deps_ #f)
     parallelize: (parallelize_ #t))
   (def gerbil-path (getenv "GERBIL_PATH" "~/.gerbil"))
   (def srcdir (or srcdir_ (error "srcdir must be specified")))
   (def gerbil.pkg (or gxpkg_ (read-gerbil.pkg-plist srcdir_ )))
   (def libdir (or libdir_ (path-expand "lib" gerbil-path)))
   (def bindir (or bindir_ (path-expand "bin" gerbil-path)))
   (def build-deps (path-expand (or build-deps_ "build-deps") srcdir))
   (def parallelize (if (eq? parallelize_ #t) (gerbil-build-cores) (or parallelize_ 0)))
   (struct-instance-init!
     self
     srcdir libdir bindir force? optimize debug static static-debug verbose build-deps
     parallelize gerbil.pkg))
   rebind: #t)

(def (settings-gerbil.pkg-pgetq s k (nope #f))
  (let (plist (settings-gerbil.pkg s))
    (if (not plist) nope (pgetq plist k nope))))

(def settings-package (cut settings-gerbil.pkg-pgetq <> package:))
(def settings-namespace (cut settings-gerbil.pkg-pgetq <> namespace:))
(def settings-prelude (cut settings-gerbil.pkg-pgetq <> prelude:))

(def first-build-settings (settings srcdir: "~/src/gerbil-build/"))

(def mods
  '("make/base" "make/settings" "make/expander-module" "make/mod"))

(let lp ((ms mods))
  (let ((mod (car ms))
        (settings first-build-settings))
     (import-module
     (source-path mod ".ss" settings) #t)
    ;; (prep-import-module                 ;
    ;;  (source-path mod ".ss" settings)
    ;;  srcdir: (settings-srcdir settings)
    ;;  package: (settings-package settings)
    ;;  namespace: (settings-namespace settings))
     ;(make-ss (source-path mod ".ss" settings))
    (unless (null? (cdr ms)) (lp (cdr ms)))))
