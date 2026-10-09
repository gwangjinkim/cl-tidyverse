;;;; cl-tidyverse.asd

(asdf:defsystem #:cl-tidyverse
  :description "One quickload for the Common Lisp tidyverse: cl-tibble,
cl-readr, cl-dplyr, cl-tidyr, cl-stringr, cl-forcats, cl-lubridate,
cl-ggplot2 and cl-vctrs-lite, re-exported from one package (TIDYVERSE)
with all name conflicts resolved."
  :author "Gwang-Jin Kim <gwang.jin.kim.phd@gmail.com>"
  :license "MIT"
  :version "0.1.0"
  :depends-on (#:cl-vctrs-lite
               #:cl-tibble
               #:cl-readr
               #:cl-dplyr
               #:cl-tidyr
               #:cl-stringr
               #:cl-forcats
               #:cl-lubridate
               #:cl-ggplot2)
  :serial t
  :components ((:module "src"
                :serial t
                :components ((:file "package")
                             (:file "tidyverse")
                             (:file "user"))))
  :in-order-to ((asdf:test-op (asdf:test-op #:cl-tidyverse/tests))))

(asdf:defsystem #:cl-tidyverse/tests
  :description "Tests for cl-tidyverse."
  :author "Gwang-Jin Kim <gwang.jin.kim.phd@gmail.com>"
  :license "MIT"
  :depends-on (#:cl-tidyverse #:fiveam)
  :serial t
  :components ((:module "tests"
                :serial t
                :components ((:file "package")
                             (:file "main"))))
  :perform (asdf:test-op (op c)
             (declare (ignore op c))
             (unless (uiop:symbol-call :fiveam :run! :cl-tidyverse)
               (error "cl-tidyverse tests failed"))))
