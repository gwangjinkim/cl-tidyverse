# cl-tidyverse

One quickload for the Common Lisp tidyverse.

```lisp
(ql:quickload :cl-tidyverse)
(in-package :tidyverse-user)

(-> (read-csv "trial.csv")
    (filter (! (is-na sbp_wk4)))
    (mutate change (- sbp_wk4 sbp_base)
            visit  (map 'vector #'ymd visit_date))
    (group-by arm)
    (summarise n (n) mean (mean change) sd (sd change)))
```

Like R's `tidyverse`, it loads the core packages and makes them available
from **one package**, `TIDYVERSE` (nickname `CL-TIDYVERSE`):

| Package | For |
|---|---|
| cl-tibble | data frames (tibbles) |
| cl-readr | reading/writing CSV, TSV |
| cl-dplyr | `filter`, `mutate`, `summarise`, joins, `->` pipelines |
| cl-tidyr | `pivot-longer`/`-wider`, `separate`, `unite`, `nest`, `fill`, `drop-na` |
| cl-stringr | strings (`str-trim`, `str-detect`, `str-glue`, ...) |
| cl-forcats | factors (`factor`, `fct-lump`, `fct-reorder`, ...) |
| cl-lubridate | dates and times (`ymd`, `year`, intervals, ...) |
| cl-ggplot2 | grammar-of-graphics plots (`gg`, `aes`, `geom_point`, ...) |
| cl-vctrs-lite | vectors, the missing value `*na*`, recycling |

## Using it in your own package

```lisp
(tidyverse:define-tidy-package #:my-analysis
  (:also-use #:fiveam)          ; optional: other packages you want to :use
  (:export #:run))
```

This expands to a `defpackage` that uses `CL`, `TIDYVERSE` and the
`:also-use` packages, and resolves every name clash in favour of the
tidyverse. To see what is resolved:

```lisp
(tidyverse:tidyverse-conflicts :with '(:serapeum))
;; -- Conflicts (resolved in favour of TIDYVERSE) --
;; cl-tidyr:fill masks common-lisp:fill
;; cl-lubridate:second masks common-lisp:second
;; cl-tibble:slice masks serapeum:slice
;; cl-tidyr:nest masks serapeum:nest
;; cl-dplyr:-> masks serapeum:->
;; cl-lubridate:interval masks serapeum:interval
```

The two `COMMON-LISP` clashes are transparent: `(fill (list 1 2) 0)` is
`cl:fill` and `(second '(a b))` is `cl:second`; they only behave
differently on tibbles and timestamps respectively.

If you prefer to write it by hand:

```lisp
(defpackage #:my-analysis
  (:use #:cl #:tidyverse)
  (:shadowing-import-from #:tidyverse #:fill #:second))
```

## Missing values

All packages share one missing value, `*na*` (from cl-vctrs-lite). `NIL`
means FALSE. Missing in, missing out; aggregates accept `:na-rm t`;
`(is-na col)` tests for missing values inside verbs.

## Status

Version 0.1.0. Part of the plan in
[cl-tidystat](../cl-tidystat/PLAN.md) (§5.1). Still to come: an opt-in named
readtable for the `#c"col"` syntax, CI, and the statistical layers
(cl-stats, cl-statframe, cl-models, cl-broom, cl-statproc).

## Tests

```sh
make test
```

Licence: MIT.
