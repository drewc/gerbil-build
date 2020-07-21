(def test-no-prelude-settings (settings srcdir: "~/src/gerbil-build/test/prelude"))

(def test/hello-no-prelude-module
  (prep-import-module
   (source-path "hello" ".ss" test-no-prelude-settings)
   srcdir: (settings-srcdir test-no-prelude-settings)
   package: 'no-prelude
   namespace: 'np))
