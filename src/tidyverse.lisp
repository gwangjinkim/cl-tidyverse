;;;; src/tidyverse.lisp

(in-package #:tidyverse)

(defparameter *tidyverse-packages*
  '(:cl-vctrs-lite :cl-tibble :cl-readr :cl-dplyr :cl-tidyr
    :cl-stringr :cl-forcats :cl-lubridate :cl-ggplot2)
  "Component packages re-exported by TIDYVERSE. Each is also an ASDF system
of the same name.")

(defun tidyverse-packages ()
  "List of (system-name version) for the loaded component packages."
  (loop for name in *tidyverse-packages*
        for system = (asdf:find-system name nil)
        collect (list name (and system (asdf:component-version system)))))

(defun %external-symbols (package)
  (let ((symbols '()))
    (do-external-symbols (s package symbols)
      (push s symbols))))

(defun %masks (other-packages)
  "Exported TIDYVERSE symbols whose names clash with an external symbol of
COMMON-LISP or of OTHER-PACKAGES. Returns a list of plists
(:name :symbol :from :masks)."
  (let ((ours (make-hash-table :test 'equal))
        (result '()))
    (dolist (s (%external-symbols :tidyverse))
      (setf (gethash (symbol-name s) ours) s))
    (dolist (other (cons :common-lisp other-packages) (nreverse result))
      (dolist (theirs (%external-symbols other))
        (let ((mine (gethash (symbol-name theirs) ours)))
          (when (and mine (not (eq mine theirs)))
            (push (list :name (symbol-name mine)
                        :symbol mine
                        :from (package-name (symbol-package mine))
                        :masks (package-name (find-package other)))
                  result)))))))

(defun tidyverse-conflicts (&key with (stream *standard-output*))
  "Report which TIDYVERSE exports mask COMMON-LISP (always checked) or the
packages listed in WITH (e.g. '(:fiveam :serapeum)). Prints a summary to
STREAM (NIL for silent) and returns a list of plists (:name :symbol :from
:masks). DEFINE-TIDY-PACKAGE resolves exactly these in favour of
TIDYVERSE."
  (let ((masks (%masks (mapcar (lambda (p)
                                 (or (find-package p)
                                     (error "tidyverse-conflicts: package ~s is not loaded" p)))
                               (if (listp with) with (list with))))))
    (when stream
      (format stream "~&-- Conflicts (resolved in favour of TIDYVERSE) --~%")
      (if masks
          (dolist (m masks)
            (format stream "~&~(~a~):~(~a~) masks ~(~a~):~(~a~)~%"
                    (getf m :from) (getf m :name) (getf m :masks) (getf m :name)))
          (format stream "~&none~%")))
    masks))

(defmacro define-tidy-package (name &body options)
  "DEFPACKAGE for an analysis package that uses COMMON-LISP and TIDYVERSE
with every name conflict resolved in favour of TIDYVERSE.

  (tidyverse:define-tidy-package #:my-analysis
    (:also-use #:fiveam #:serapeum)   ; optional extra packages to :use
    (:export #:run))                  ; any other DEFPACKAGE option

expands to a DEFPACKAGE that :uses CL, TIDYVERSE and the :ALSO-USE
packages, and shadowing-imports from TIDYVERSE every symbol that would
otherwise clash (FILL and SECOND with CL; e.g. ! with FiveAM, -> with
Serapeum). The :ALSO-USE packages must already be loaded when the form is
macroexpanded."
  (let* ((also (cdr (assoc :also-use options)))
         (other (remove :also-use options :key #'car))
         (masks (%masks (mapcar (lambda (p)
                                  (or (find-package p)
                                      (error "define-tidy-package: package ~s is not loaded" p)))
                                also)))
         (names (remove-duplicates (mapcar (lambda (m) (getf m :name)) masks)
                                   :test #'string=)))
    `(defpackage ,name
       (:use #:cl #:tidyverse ,@also)
       (:shadowing-import-from #:tidyverse
                               ,@(mapcar #'make-symbol names))
       ,@other)))
