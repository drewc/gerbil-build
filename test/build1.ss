#!/usr/bin/env gxi
(def +this-file+ (this-source-file))
(def +this-srcdir+ (path-normalize (path-directory +this-file+)))

(current-directory +this-srcdir+)
(load "test-bootstrap1.ss")

(def mods
  '("make/base" "make/settings" "make/expander-module" "make/mod"))

(def +mod-src-dir+ (path-expand ".." +this-srcdir+ ))

(current-directory +mod-src-dir+)

(message "srcdir " +mod-src-dir+)

(build-mods mods +mod-src-dir+)
