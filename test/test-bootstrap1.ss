(import :std/misc/path :std/misc/list :gerbil/compiler)

;;; Settings: see details in doc/reference/make.md
(defstruct settings
  (srcdir libdir bindir force optimize debug static
          static-debug verbose build-deps parallelize gerbil.pkg)
  transparent: #t constructor: :init!)

(def current-make-settings (make-parameter #f))

(def (settings-verbose>=? settings level)
  (def verbose (settings-verbose settings))
  (and (real? level) (real? verbose) (>= verbose level)))
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

;;; -*- Gerbil -*-
;;; (C) vyzo at hackzen.org, me at drewc.ca
(import :gerbil/expander/module :std/lazy)
(def (prep-import-module
      rpath
      srcdir: (srcdir "/")
      package: (_package #f)
      id: (_id #f)
      namespace: (_ns #f)
      pre: (_pre #f)
      (reload? #f))

  (def (import-source path)
    (def mod-path (path-normalize path (or srcdir #f) (or srcdir "")))

    (when (member path (gx#current-expander-path))
      (error "Cyclic expansion" path))
    (parameterize ((gx#current-expander-context (gx#core-context-root))
                   (gx#current-expander-marks [])
                   (gx#current-expander-phi 0)
                   (gx#current-expander-path
                    (cons path (gx#current-expander-path)))
                   (gx#current-import-expander-phi #f)
                   (gx#current-export-expander-phi #f))
      (let-values (((pre id ns body)
                    (gx#core-read-module mod-path)))
        (def module-name (path-strip-directory (path-strip-extension path)))
        (def module-id
          ;; If we provide _id, use it(d)!
          (or _id
            ;; If the core module package is the same as the mod that means we could not
            ;; find a package.
            (if (not (equal? module-name (symbol->string id))) id
              ;; If we do not have a toplevel package we are the id.
              (if (not _package) id
                  ;; otherwise add it as the package as a supercontainer and return
                  (string->symbol (path-expand module-name (symbol->string _package)))))))
        (def module-ns (or _ns (if (equal? module-name ns) (symbol->string module-id) ns)))
        (let* ((prelude
                (cond
                 ((gx#prelude-context? pre) pre)
                 ((gx#module-context? pre)
                  (gx#core-module->prelude-context pre))
                 ((string? pre)
                  (gx#core-module->prelude-context
                   (core-import-module pre)))
                 ((not pre)
                  (or (gx#current-expander-module-prelude)
                      (gx#make-prelude-context #f)))
                 (else
                  (error "Cannot import module; unknown prelude" rpath pre))))
               (ctx
                (gx#make-module-context module-id prelude module-ns path))
               (body
               (gx#core-expand-module-begin body ctx))
               (body
                (gx#core-quote-syntax
                 (gx#core-cons '%#begin body)
                 path ctx [])))
           (set! (gx#&module-context-e ctx)
             (delay (gx#eval-syntax* body)))
          (set! (gx#&module-context-code ctx)
            body)
          (hash-put! (gx#current-expander-module-registry) path ctx)
          (hash-put! (gx#current-expander-module-registry) id ctx)
          ctx))))

  (let (npath (path-normalize rpath #f))
    (cond
     ((and (not reload?)
           (hash-get (gx#current-expander-module-registry) npath))
      => values)
     (else (parameterize ((current-directory (or srcdir (current-directory))))
             (import-source (path-normalize rpath #f)))))))


(def (source-path mod ext settings)
  (path-expand (path-default-extension mod ext) (settings-srcdir settings)))

(def (force-outputs) (force-output (current-error-port)) (force-output)) ;; move to std/misc/ports ?
(def (message . lst) (apply displayln lst) (force-outputs)) ;; move to std/misc/ports ?

(def (gsc-compile-opts opts)
  (match opts
    ([[plist ...] . rest] (listify rest))
    (_ (listify opts))))

(def (gxc-compile-file mod opts settings (invoke-gsc? #t))
  (message "... compile-file " mod)
  (def gsc-opts (gsc-compile-opts opts))
  (def srcpath (source-path mod ".ss" settings))
  (let ((gxc-opts
         [invoke-gsc: invoke-gsc?
                      keep-scm: (not invoke-gsc?)
                      output-dir: (settings-libdir settings)
                      optimize: (settings-optimize settings)
                      debug: (settings-debug settings)
                      generate-ssxi: #t
                      static: (settings-static settings)
                      verbose: (settings-verbose>=? settings 9)
                      (when/list gsc-opts [gsc-options: gsc-opts]) ...]))
    (compile-file srcpath gxc-opts)))

(def (set-loadpath settings)
  (let* ((loadpath (getenv "GERBIL_LOAD_PATH" #f))
         (loapath (if loadpath (string-append loadpath ":") ""))
         (loadpath (string-append (or loadpath "") (settings-srcdir settings))))
    (setenv "GERBIL_LOAD_PATH" loadpath)))

(def (prep-mod mod settings (reload? #f))
  (prep-import-module                   ;
   (source-path mod ".ss" settings)
   srcdir: (settings-srcdir settings)
   package: (settings-package settings)
   namespace: (settings-namespace settings)
   reload?))

(def (build-mods mods (srcdir (path-normalize (path-directory (this-source-file)))))
  (def settings (make-settings srcdir: srcdir verbose: #t))
  (set-loadpath settings)

  (def (build-mod mod) (message "building " mod)
    (prep-mod mod settings)
    (gxc-compile-file mod [] settings))


  (message "Builings Mods " mods)

  (let build ((ms mods))
    (unless (null? ms)
      (build-mod (car ms)) (build (cdr ms)))))
