package: std/make
(import :std/misc/func :gerbil/expander/module :std/lazy)
(export #t)

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


(def expander-module-id gx#expander-context-id)

(def expander-module-name
  (compose string->symbol path-strip-directory
           symbol->string expander-module-id))

(def expander-module-relative-library-directory
  (compose path-strip-trailing-directory-separator path-directory
           symbol->string expander-module-id))

(def (expander-module-package m)
  (let (d (expander-module-relative-library-directory m))
    (if (equal? "" d) #f (string->symbol d))))


(def expander-module-namespace gx#module-context-ns)
(def expander-module-prelude gx#&phi-context-super)
