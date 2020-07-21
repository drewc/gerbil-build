(import :std/test)
(def test/foobarbaz-module
  (prep-import-module
   (source-path "new-hello-no-package" ".ss" test-new-project-settings)
   srcdir: (settings-srcdir test-new-project-settings)
   id: 'foobarbaz #t))

(check (module-id test/foobarbaz-module) => 'foobarbaz)
