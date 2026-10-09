;;;; tests/package.lisp

;;; The test package is itself made with DEFINE-TIDY-PACKAGE and also uses
;;; FiveAM, whose ! clashes with the tidyverse ! - so loading this file is
;;; already a test of conflict resolution.
(tidyverse:define-tidy-package #:cl-tidyverse/tests
  (:also-use #:fiveam))

(in-package #:cl-tidyverse/tests)

(def-suite :cl-tidyverse :description "cl-tidyverse meta-package tests.")
