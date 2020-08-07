#!/usr/bin/env gxi
(import :gerbil/expander :std/misc/path )

(def this-file (this-source-file))

(def srcdir (path-directory this-file))

(def build-specs
  '("make/base" "make/settings" "make/expander-module" "make/mod"
    "make/gsc" "make/gxc" "make/spec" "make/make" "make/script"))

(gx#import-module (path-expand "make/bootstrap.ss" srcdir) #t #t)

(def (main . _) ((eval 'std/make/bootstrap#bootstrap-make) build-specs srcdir))
