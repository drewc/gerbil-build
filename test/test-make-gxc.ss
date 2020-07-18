(import :gerbil/compiler :std/misc/path :std/misc/list
      :std/misc/concurrent-plan)

 ;;; Settings: see details in doc/reference/make.md
 (defstruct settings
   (srcdir libdir bindir package force optimize debug static static-debug verbose build-deps
    libdir-prefix parallelize)
   transparent: #t constructor: :init!)

(def current-make-settings (make-parameter #f))

(def (gerbil-build-cores)
  (with-catch (lambda (_) (##cpu-count)) (lambda () (string->number (getenv "GERBIL_BUILD_CORES")))))

(defmethod {:init! settings}
 (lambda (self
     srcdir: (srcdir_ #f) libdir: (libdir_ #f) bindir: (bindir_ #f)
     package: (package_ #f) force: (force? #f)
     optimize: (optimize #t) debug: (debug 'env)
     static: (static #t) static-debug: (static-debug #f)
     verbose: (verbose #f) build-deps: (build-deps_ #f)
     parallelize: (parallelize_ #t))
   (def gerbil-path (getenv "GERBIL_PATH" "~/.gerbil"))
   (def srcdir (or srcdir_ (error "srcdir must be specified")))
   (def libdir (or libdir_ (path-expand "lib" gerbil-path)))
   (def bindir (or bindir_ (path-expand "bin" gerbil-path)))
   (def package (and package_ (if (symbol? package_) (symbol->string package_) package_)))
   (def libdir-prefix (if package (path-expand package libdir) libdir))
   (def build-deps (path-expand (or build-deps_ "build-deps") srcdir))
   (def parallelize (if (eq? parallelize_ #t) (gerbil-build-cores) (or parallelize_ 0)))
   (struct-instance-init!
     self
     srcdir libdir bindir package force? optimize debug static static-debug verbose build-deps
     libdir-prefix parallelize))
 rebind: #t)

(def (source-path mod ext settings)
  (path-expand (path-default-extension mod ext) (settings-srcdir settings)))

(def mod-modules (make-hash-table)) ;;; cache
(def (mod-module mod (settings (current-make-settings)) (reload? #f))
  (let (v (hash-ref mod-modules mod (void)))
    (if (and (not (void? v)) (not reload?)) v
        (let* ((src (source-path mod ".ss" settings))
               (m (and (file-exists? src) (gx#import-module src reload?))))
          (begin0 m (hash-put! mod-modules mod m))))))

(def (module-id ctx) (gx#expander-context-id ctx))
(def (module-package ctx) (symbol->string (mod-module-id ctx)))


(def mod-core-modules (make-hash-table))
(def (mod-core-module mod settings (reload? #f))
  ;; => (values prelude module-id module-ns body)
  (def (mrm)
    (let (v (if reload? (void) (hash-ref mod-core-modules mod (void))))
      (if (not (void? v)) v
          (let* ((src (path-force-extension mod ".ss"))
                 (rm (and (file-exists? src) (gx#core-read-module src))))
            (begin0 rm (hash-put! mod-core-modules mod rm))))))
  (let ((srcdir (path-normalize (settings-srcdir settings)))
        (cd (path-normalize (current-directory))))
    (if (equal? srcdir cd) (mrm)
        (parameterize ((current-directory srcdir))
          (mrm)))))

(def core-module-id (cut values-ref <> 1))
(def (core-module-package mrm)
  (symbol->string (core-module-id mrm)))
