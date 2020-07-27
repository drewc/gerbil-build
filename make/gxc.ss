package: std/make
(import ./base ./settings ./mod ./gsc :std/misc/list :gerbil/compiler)
(export gxc-compile gxc-outputs)

(def (gxc-outputs mod opts settings)
  [(library-path mod ".ssi" settings)
  ; (when/list (settings-static settings) [(static-path mod settings)]) ...
  ])

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

(def gxc-compile gxc-compile-file)
