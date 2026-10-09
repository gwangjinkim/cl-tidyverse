;;;; src/package.lisp

;;; TIDYVERSE re-exports every exported symbol of the component packages.
;;;
;;; Measured when this package was written (cl-tidystat ADR-0002): the
;;; component packages export no two different symbols with the same name,
;;; so re-exporting them together is conflict-free, except for two symbols
;;; that shadow COMMON-LISP:
;;;   FILL   (cl-tidyr)      - on non-tibbles it calls CL:FILL
;;;   SECOND (cl-lubridate)  - on lists it calls CL:SECOND
;;; Both are shadowing-imported here, re-exported, and listed by
;;; TIDYVERSE-CONFLICTS. DEFINE-TIDY-PACKAGE shadows them for you.

(uiop:define-package #:tidyverse
  (:nicknames #:cl-tidyverse)
  (:use #:cl)
  (:shadowing-import-from #:cl-tidyr #:fill)
  (:shadowing-import-from #:cl-lubridate #:second)
  (:use-reexport #:cl-vctrs-lite
                 #:cl-tibble
                 #:cl-readr
                 #:cl-dplyr
                 #:cl-tidyr
                 #:cl-stringr
                 #:cl-forcats
                 #:cl-lubridate
                 #:cl-ggplot2)
  (:export #:*tidyverse-packages*
           #:tidyverse-packages
           #:tidyverse-conflicts
           #:define-tidy-package
           #:use-tidyverse
           ;; bare verb names (src/verbs.lisp); dotted names come from cl-dplyr
           #:filter #:mutate #:select #:rename #:arrange
           #:summarise #:summarize #:distinct
           #:group-by #:ungroup #:pull
           #:inner-join #:left-join #:right-join #:full-join
           #:semi-join #:anti-join))
