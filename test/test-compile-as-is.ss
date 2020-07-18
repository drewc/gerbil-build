(def test-new-project-settings (settings srcdir: "~/src/gerbil-build/test/new-project"))

 (def test/new-project-hello-no-package-module
   (mod-module "new-hello-no-package" test-new-project-settings))
