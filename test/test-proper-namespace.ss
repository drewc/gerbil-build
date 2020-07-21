(import :std/sugar :std/test :foobarbaz)
(check (hello) => "Hello World... New Project!")

;;; This test passes!

(check (foobarbaz#hello) => "Hello World... New Project!")

;;; because it's not in another namespace
(check (try (drewc/build-test/new-project/new-hello-no-package#hello)
         (catch _ #f)) => #f)
