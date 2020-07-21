(def test/hello-no-prelude-prelude-module
  (prep-import-module
   (source-path "prehello" ".ss" test-no-prelude-settings)
   srcdir: (settings-srcdir test-no-prelude-settings)
   package: 'no-prelude
   namespace: 'np))
