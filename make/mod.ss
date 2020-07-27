package: std/make
(import ./expander-module :std/make/settings :std/misc/func :std/misc/path)
(export #t)

(def (source-path mod ext settings)
  (path-expand (path-default-extension mod ext) (settings-srcdir settings)))

(def mod-expander-modules (make-hash-table)) ;;; cache
(def (mod-expander-module mod (settings (current-make-settings)) (reload? #f))
  (let (v (hash-ref mod-expander-modules mod (void)))
    (if (and (not (void? v)) (not reload?)) v
        (let* ((src (source-path mod ".ss" settings))
               (m (and (file-exists? src)
                       (prep-import-module
                        src
                        srcdir: (settings-srcdir settings)
                        package: (settings-package settings)
                        namespace: (settings-namespace settings)
                        reload?))))
          (begin0 m (hash-put! mod-expander-modules mod m))))))

(def (library-path mod ext (settings (current-make-settings)))
  (let (expm (mod-expander-module mod settings))
    (path-expand (path-force-extension mod ext)
                 (path-expand (expander-module-relative-library-directory expm)
                              (settings-libdir settings)))))

(def (static-file-path file settings)
  (let* ((libdir (settings-libdir settings))
         (staticdir (path-expand "static" libdir))
         (filename (path-strip-directory file)))
    (path-expand filename staticdir)))
