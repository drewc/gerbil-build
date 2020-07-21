(import :no-prelude/hello :std/test)

(check ((car (np#hello))) =>"Hello World")
