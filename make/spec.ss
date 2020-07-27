package: std/make
(import ./mod ./gxc :std/srfi/1)
(export #t)
;;; Build item spec
(def (spec-type spec)
  (match spec
    ((? string? _) gxc:)
    ([(? keyword? type) . _] type)
    (else (error "Bad buildspec" spec))))

(def (spec-file spec settings)
  (match spec
    ((? string? modf) (source-path modf ".ss" settings))
    ([gxc: modf . opts] (source-path modf ".ss" settings))
    ([gsc: modf . opts] (source-path modf ".scm" settings))
    ([ssi: modf . deps] (source-path modf ".ssi" settings))
    ([exe: modf . opts] (source-path modf ".ss" settings))
    ([static-exe: modf . opts] (source-path modf ".ss" settings))
    ([static-include: file] (static-file-path file settings))
    ([copy: file] file)
    (else
     (error "Bad buildspec" spec))))

(def (spec-inputs spec settings)
  [(spec-file spec settings) (spec-extra-inputs spec settings) ...])

(def (spec-extra-inputs spec settings)
  (match spec
    ([gxc: . _] (pgetq extra-inputs: (spec-plist spec) []))
    ([gsc: . _] (pgetq extra-inputs: (spec-plist spec) []))
    ([ssi: _ . submodules] (append-map (cut spec-inputs <> settings) submodules))
    (_ [])))

(def (spec-plist spec)
  (match spec
    ([(? (cut member <> '(gxc: gsc:))) _ [plist ...] . _] plist)
    (_ [])))

(def (spec-outputs spec settings)
  (match spec
    ((? string? modf) (gxc-outputs modf #f settings))
    ([gxc: modf . opts] (gxc-outputs modf opts settings))
    ;; ([gsc: modf . opts] [(gsc-c-path modf settings)])
    ([ssi: modf . submodules] [(library-path modf ".ssi" settings)
                               (append-map (cut spec-outputs <> settings) submodules) ...])
    ;; ([exe: modf . opts] [(library-path modf ".ssi" settings)
    ;;                      (binary-path modf opts settings)])
    ;; ([static-exe: modf . opts] [(binary-path modf opts settings)
    ;;                            (static-path modf settings)])
    ([static-include: file] [(static-file-path file settings)])
    ([copy: file] [(library-path file #f settings)])
    (else (error "Bad buildspec" spec))))

(def (spec-backgroundable? spec)
  (case (spec-type spec)
    ((gxc:) (not (pgetq foreground: (spec-plist spec))))
    ((gsc:) #t)
    (else #f)))

(def (spec-build spec settings)
  (match spec
    ((? string? modf)
     (gxc-compile modf #f settings #t))
    ([gxc: modf . opts]
     (gxc-compile modf opts settings #t))
    ;; ([gsc: modf . opts]
    ;;  (gsc-compile modf opts settings))
    ;; ([ssi: modf . submodules]
    ;;  (for-each (cut build <> settings) submodules)
    ;;  (compile-ssi modf '() settings))
    ;; ([exe: modf . opts]
    ;;  (compile-exe modf opts settings))
    ;; ([static-exe: modf . opts]
    ;;  (compile-static-exe modf opts settings))
    ;; ([static-include: file]
    ;;  (copy-static file settings))
    ;; ([copy: file]
    ;;  (copy-compiled file settings))
    (else
     (error "Bad buildspec" spec))))
