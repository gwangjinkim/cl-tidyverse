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

(defun %prefer-clauses (options)
  "From DEFINE-TIDY-PACKAGE options, an alist (package . names) of every
(:prefer package name...) clause."
  (loop for opt in options
        when (eq (car opt) :prefer)
          collect (cons (second opt) (mapcar #'string (cddr opt)))))

(defmacro define-tidy-package (name &body options)
  "DEFPACKAGE for an analysis package that uses COMMON-LISP and TIDYVERSE
with every name conflict resolved, by default in favour of TIDYVERSE.

  (tidyverse:define-tidy-package #:my-analysis
    (:also-use #:fiveam #:serapeum)    ; optional extra packages to :use
    (:prefer #:serapeum #:filter)      ; optional: keep these names from
                                       ;   another package instead
    (:export #:run))                   ; any other DEFPACKAGE option

Every TIDYVERSE export that clashes with CL or an :ALSO-USE package is
shadowing-imported from TIDYVERSE, except names listed in a :PREFER
clause, which are shadowing-imported from that package. Dotted verbs
(.filter, ...) are always available, so preferring another FILTER loses
nothing. The :ALSO-USE and :PREFER packages must already be loaded when the
form is macroexpanded."
  (let* ((also (cdr (assoc :also-use options)))
         (prefer (%prefer-clauses options))
         (preferred-names (loop for (nil . names) in prefer append names))
         (other (remove-if (lambda (o) (member (car o) '(:also-use :prefer))) options))
         (masks (%masks (mapcar (lambda (p)
                                  (or (find-package p)
                                      (error "define-tidy-package: package ~s is not loaded" p)))
                                also)))
         (names (remove-duplicates
                 (remove-if (lambda (n) (member n preferred-names :test #'string=))
                            (mapcar (lambda (m) (getf m :name)) masks))
                 :test #'string=)))
    (dolist (clause prefer)
      (unless (find-package (car clause))
        (error "define-tidy-package: :prefer package ~s is not loaded" (car clause))))
    `(defpackage ,name
       (:use #:cl #:tidyverse ,@also)
       (:shadowing-import-from #:tidyverse
                               ,@(mapcar #'make-symbol names))
       ,@(loop for (pkg . pnames) in prefer
               collect `(:shadowing-import-from ,pkg ,@(mapcar #'make-symbol pnames)))
       ,@other)))

(defun use-tidyverse (&key (package *package*) prefer (stream *standard-output*))
  "Make an existing PACKAGE (default: the current one, e.g. CL-USER) use
TIDYVERSE, resolving name clashes like R's library():

- a symbol PACKAGE inherits from another used package (CL:FILL,
  SB-EXT:RENAME in SBCL's CL-USER, SERAPEUM:FILTER, ...) is masked by the
  TIDYVERSE symbol (shadowing import);
- a symbol PACKAGE owns itself (one you defined there) is kept, like R's
  global environment masking packages; it is reported;
- PREFER, an alist ((package . (name ...)) ...), keeps the named symbols
  from that package instead.

Prints what was masked to STREAM (NIL for silent) and returns a list of
plists (:name :kept :masked)."
  (let* ((package (or (find-package package) (error "use-tidyverse: no package ~s" package)))
         (preferred (loop for (pkg . names) in prefer
                          append (mapcar (lambda (n) (cons (string n) pkg)) names)))
         (report '()))
    (dolist (ours (%external-symbols :tidyverse))
      (let ((name (symbol-name ours)))
        (multiple-value-bind (theirs status) (find-symbol name package)
          (when (and status (not (eq theirs ours)))
            (let ((pref (cdr (assoc name preferred :test #'string=))))
              (cond
                (pref
                 (let ((sym (find-symbol name pref)))
                   (shadowing-import (list sym) package)
                   (push (list :name name :kept sym :masked ours) report)))
                ((member status '(:internal :external))
                 ;; PACKAGE's own symbol: keep it, but make sure USE-PACKAGE
                 ;; does not complain by marking it as a shadowing symbol.
                 (shadow (list name) package)
                 (push (list :name name :kept theirs :masked ours) report))
                (t
                 (shadowing-import (list ours) package)
                 (push (list :name name :kept ours :masked theirs) report))))))))
    (use-package :tidyverse package)
    (setf report (sort report #'string< :key (lambda (r) (getf r :name))))
    (when stream
      (format stream "~&-- Attached TIDYVERSE to ~a --~%" (package-name package))
      (dolist (r report)
        (format stream "~&~(~a~) masks ~(~a~)~%"
                (%qualified (getf r :kept)) (%qualified (getf r :masked)))))
    report))

(defun %qualified (symbol)
  (format nil "~a:~a" (package-name (symbol-package symbol)) (symbol-name symbol)))
