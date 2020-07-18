(def test/new-project-hello-no-package-core-module
    (mod-core-module "new-hello-no-package" test-new-project-settings))

(set! (module-id test/new-project-hello-no-package-module)
      (core-module-id test/new-project-hello-no-package-core-module))
