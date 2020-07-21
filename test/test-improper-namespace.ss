(import :std/sugar :std/test :foobarbaz)
(check (hello) => "Hello World... New Project!")

;;; This test passes but it shoudn't
(check (try (foobarbaz#hello) (catch _ #f)) => #f)

;;; because it's in another namespace
(check (drewc/build-test/new-project/new-hello-no-package#hello)
       => "Hello World... New Project!")
