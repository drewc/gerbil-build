(def test/new-project-hello-no-package-core-module
    (mod-core-module "new-hello-no-package" test-new-project-settings))

(set! (module-id test/new-project-hello-no-package-module) 'foobarbaz)
(set! (module-ns test/new-project-hello-no-package-module) "foobarbaz")

(set! (gx#&module-context-code test/new-project-hello-no-package-module)
  (prep-module-code test/new-project-hello-no-package-module (core-module-code test/new-project-hello-no-package-core-module)))
