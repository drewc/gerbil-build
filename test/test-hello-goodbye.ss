(import :std/test)
(def test-settings (settings srcdir: "~/src/gerbil-build"))

(def test/hello-module (mod-module "test/hello" test-settings))
(def test/sub/goodbye-module (mod-module "test/sub/goodbye" test-settings #t))
(def test/hello-no-package-module (mod-module "test/hello-no-package" test-settings))

(check (module-id test/hello-module) => 'drewc/hello)
(check (module-id test/sub/goodbye-module) => 'drewc/take-on-me/goodbye)
(check (module-id test/hello-no-package-module)
       => 'drewc/build-test/hello-no-package)
