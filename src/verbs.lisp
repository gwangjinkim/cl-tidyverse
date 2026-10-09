;;;; src/verbs.lisp

(in-package #:tidyverse)

;;; Bare verb names (decision D10). cl-dplyr exports dot-prefixed verbs
;;; (.filter, .mutate, ...) so that it can be :used alone without clashes;
;;; TIDYVERSE adds the R spelling on top. Only names that do not clash with
;;; COMMON-LISP or with another component are added:
;;;
;;;   added:      filter mutate select rename arrange summarise summarize
;;;               distinct group-by ungroup pull and the six joins
;;;   not added:  slice (= cl-tibble:slice, different signature),
;;;               count / first / last (COMMON-LISP); use .slice etc.
;;;
;;; Clashes with other libraries (serapeum: filter select distinct;
;;; sb-ext: rename; parachute: summarize) are resolved by
;;; DEFINE-TIDY-PACKAGE / USE-TIDYVERSE, with :PREFER as the escape hatch.
;;; Inside -> pipelines both spellings always work.

;; Verbs that are macros in cl-dplyr (they rewrite column expressions).
(macrolet ((alias-macros (&rest pairs)
             `(progn
                ,@(loop for (bare dotted) on pairs by #'cddr
                        collect `(defmacro ,bare (data &rest args)
                                   ,(format nil "Same as CL-DPLYR:~a." dotted)
                                   (list* ',dotted data args))))))
  (alias-macros filter    cl-dplyr:.filter
                mutate    cl-dplyr:.mutate
                select    cl-dplyr:.select
                rename    cl-dplyr:.rename
                arrange   cl-dplyr:.arrange
                summarise cl-dplyr:.summarise
                summarize cl-dplyr:.summarize
                distinct  cl-dplyr:.distinct))

;; Verbs that are functions in cl-dplyr: plain functions, so #'pull works.
(defun group-by (data &rest variables)
  "Same as CL-DPLYR:.GROUP-BY."
  (apply #'cl-dplyr:.group-by data variables))

(defun ungroup (data)
  "Same as CL-DPLYR:.UNGROUP."
  (cl-dplyr:.ungroup data))

(defun pull (data var)
  "Same as CL-DPLYR:.PULL."
  (cl-dplyr:.pull data var))

(macrolet ((alias-joins (&rest pairs)
             `(progn
                ,@(loop for (bare dotted) on pairs by #'cddr
                        collect `(defun ,bare (x y &rest args)
                                   ,(format nil "Same as CL-DPLYR:~a." dotted)
                                   (apply #',dotted x y args))))))
  (alias-joins inner-join cl-dplyr:.inner-join
               left-join  cl-dplyr:.left-join
               right-join cl-dplyr:.right-join
               full-join  cl-dplyr:.full-join
               semi-join  cl-dplyr:.semi-join
               anti-join  cl-dplyr:.anti-join))
