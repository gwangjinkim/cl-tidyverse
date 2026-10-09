;;;; tests/main.lisp

(in-package #:cl-tidyverse/tests)

(in-suite :cl-tidyverse)

(defun external-in-tidyverse-p (name)
  (eq :external (nth-value 1 (find-symbol name :tidyverse))))

(test reexports-every-component-package
  (dolist (pkg tidyverse:*tidyverse-packages*)
    (do-external-symbols (s pkg)
      (is (external-in-tidyverse-p (symbol-name s))
          "~a:~a is not exported from TIDYVERSE" pkg (symbol-name s)))))

(test component-packages-and-versions
  (let ((pkgs (tidyverse-packages)))
    (is (= 9 (length pkgs)))
    (is (every #'second pkgs) "every component has a version")))

(test cl-shadows-are-reported-and-transparent
  (let ((names (mapcar (lambda (m) (getf m :name)) (tidyverse-conflicts :stream nil))))
    (is (equal '("FILL" "SECOND") (sort (copy-list names) #'string<))))
  ;; FILL and SECOND behave like CL on ordinary data ...
  (is (eq 'b (second '(a b c))))
  (is (equal '(0 0) (fill (list 1 2) 0)))
  ;; ... and like the tidy versions on tibbles / timestamps.
  (is (= 45 (second (ymd-hms "2023-01-01 12:30:45")))))

(test conflicts-with-other-libraries
  (let ((names (mapcar (lambda (m) (getf m :name))
                       (tidyverse-conflicts :with '(:fiveam) :stream nil))))
    (is (member "!" names :test #'string=)))
  ;; this package was defined with (:also-use #:fiveam): ! is the DSL's
  (is (eq (find-symbol "!" :cl-dplyr) (find-symbol "!" :cl-tidyverse/tests))))

(test define-tidy-package-with-serapeum
  (let ((pkg (eval '(tidyverse:define-tidy-package #:cl-tidyverse/scratch
                     (:also-use #:serapeum)))))
    (unwind-protect
         (progn
           (is (packagep pkg))
           ;; Serapeum's -> and SLICE lose to the tidyverse ones
           (is (eq (find-symbol "->" :cl-dplyr) (find-symbol "->" pkg)))
           (is (eq (find-symbol "SLICE" :cl-tibble) (find-symbol "SLICE" pkg))))
      (delete-package pkg))))

(test standard-reader-syntax-survives
  (is (eql #C(1 2) (read-from-string "#C(1 2)")))
  (is (eql 10 (read-from-string "#2r1010"))))

(test tidyverse-user-package-exists
  (let ((pkg (find-package :tidyverse-user)))
    (is (packagep pkg))
    (is (eq (find-symbol ".FILTER" :cl-dplyr) (find-symbol ".FILTER" pkg)))
    (is (eq (find-symbol "FILL" :cl-tidyr) (find-symbol "FILL" pkg)))))

(defparameter *trial*
  (asdf:system-relative-pathname :cl-tidyverse/tests "tests/data/trial.csv"))

(test whole-pipeline-with-unqualified-names
  "Every name below comes from TIDYVERSE without a package prefix."
  (let* ((df (read-csv *trial*))
         (res (-> df
                  (filter (! (is-na sbp_wk4)))
                  (mutate change (- sbp_wk4 sbp_base)
                          note (str-trim note)
                          day (map 'vector #'ymd visit_date))
                  (group-by arm)
                  (summarise n (n) mean (mean change) sd (sd change)))))
    (is (equalp #("Drug" "Placebo") (.pull res :arm)))
    (is (equalp #(4 3) (.pull res :n)))
    (is (= -15.25d0 (aref (.pull res :mean) 0)))
    (is (equalp #("Drug" "Placebo")
                (fct-levels (factor (tbl-col df "arm")))))
    (is (search "<svg"
                (render (gg (df (aes :x :sbp_base :y :id :color :arm))
                          (geom_point))
                        :device :svg :width 300 :height 200)))))
