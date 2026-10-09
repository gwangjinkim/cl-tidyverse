;;;; src/user.lisp

;;; A ready-made scratch package, like CL-USER but with the tidyverse:
;;;   (ql:quickload :cl-tidyverse)
;;;   (in-package :tidyverse-user)

(uiop:define-package #:tidyverse-user
  (:use #:cl #:tidyverse)
  (:shadowing-import-from #:tidyverse #:fill #:second))
