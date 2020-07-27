package: std/make
(import :std/misc/list)
(export gsc-compile-opts)
(def (gsc-compile-opts opts)
  (match opts
    ([[plist ...] . rest] (listify rest))
    (_ (listify opts))))
