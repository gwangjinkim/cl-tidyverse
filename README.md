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

## Verb names: `filter` and `.filter`

`TIDYVERSE` exports the R spelling **and** cl-dplyr's dotted spelling:

| Bare (TIDYVERSE) | Dotted (cl-dplyr, always available) |
|---|---|
| `filter mutate select rename arrange summarise summarize distinct` | `.filter .mutate ...` |
| `group-by ungroup pull`, `inner-/left-/right-/full-/semi-/anti-join` | `.group-by ...`, `.left-join ...` |
| — (`slice` is `cl-tibble:slice`; `count`, `first`, `last` are CL) | `.slice`, `.count`, ... |

Inside `->` both spellings work. None of the bare names clashes with
COMMON-LISP. Some clash with other libraries (`serapeum:filter`,
`serapeum:select`, `serapeum:distinct`, `sb-ext:rename`,
`parachute:summarize`); the three ways of using the tidyverse below resolve
those for you.

## Three ways to use it (and how conflicts are resolved)

**1. The scratch package** — nothing to resolve, it uses only CL:

```lisp
(in-package :tidyverse-user)
```

**2. Your own package** — clashes resolved in favour of the tidyverse,
with `:prefer` to keep another library's name:

```lisp
(tidyverse:define-tidy-package #:my-analysis
  (:also-use #:fiveam #:serapeum)  ; other packages you want to :use
  (:prefer #:serapeum #:filter)    ; keep serapeum's FILTER (use .filter)
  (:export #:run))
```

**3. An existing package such as SBCL's `CL-USER`** — like R's
`library()`:

```lisp
(tidyverse:use-tidyverse)
;; -- Attached TIDYVERSE to COMMON-LISP-USER --
;; cl-tidyr:fill masks common-lisp:fill
;; tidyverse:rename masks sb-ext:rename
;; cl-lubridate:second masks common-lisp:second
```

Inherited symbols are masked; symbols you defined in that package yourself
are kept (as R's global environment masks packages) and reported.
`(use-tidyverse :prefer '((:serapeum "FILTER")))` keeps chosen names.

`(tidyverse:tidyverse-conflicts :with '(:serapeum))` lists every clash
before you decide.

The two `COMMON-LISP` clashes are transparent: `(fill (list 1 2) 0)` is
`cl:fill` and `(second '(a b))` is `cl:second`; they only behave
differently on tibbles and timestamps respectively.

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
