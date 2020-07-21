#lang :gerbil/polydactyl
;;; does not work? prelude: :gerbil/polydactyl
(export hello)

(def (hello) [list . ("Hello World" 2 3)])
