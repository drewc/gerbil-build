(import :no-prelude/hello :std/test)
(check ((car (hello)) (cadr (hello))) => '("Hello World"))
