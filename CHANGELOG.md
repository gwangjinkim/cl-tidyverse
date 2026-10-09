# Changelog

All notable changes to this project are documented here. Format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/). See AGENTS.md
("Change Discipline") for how entries and commits are written.

## [Unreleased]

### Added
- System `cl-tidyverse`: loads cl-vctrs-lite, cl-tibble, cl-readr,
  cl-dplyr, cl-tidyr, cl-stringr, cl-forcats, cl-lubridate and cl-ggplot2.
- Package `TIDYVERSE` (nickname `CL-TIDYVERSE`) re-exporting every
  exported symbol of those packages. The CL clashes `FILL` (cl-tidyr) and
  `SECOND` (cl-lubridate) are shadowing-imported and re-exported; both now
  fall back to `cl:fill` / `cl:second` on ordinary data.
- Package `TIDYVERSE-USER`: CL + TIDYVERSE, ready for interactive work.
- `define-tidy-package`: `defpackage` with CL, TIDYVERSE and `:also-use`
  packages, with all clashes resolved in favour of TIDYVERSE (computed at
  macroexpansion time from the loaded packages).
- `tidyverse-conflicts` (R's `tidyverse_conflicts()`): prints and returns
  the clashes with CL and with packages given in `:with`.
- `tidyverse-packages`, `*tidyverse-packages*`: component list with versions.

- Bare verb names (decision D10): `filter`, `mutate`, `select`, `rename`,
  `arrange`, `summarise`, `summarize`, `distinct` (macros expanding to the
  cl-dplyr dotted verbs), `group-by`, `ungroup`, `pull` and the six joins
  (functions). Not added: `slice` (clashes with `cl-tibble:slice`),
  `count`/`first`/`last` (COMMON-LISP). The dotted verbs stay exported.
- `define-tidy-package` accepts `(:prefer package name...)` to keep a
  clashing name from another package instead of the tidyverse one.
- `use-tidyverse`: makes an existing package (e.g. SBCL's `CL-USER`, which
  uses `SB-EXT` with its `RENAME`) use TIDYVERSE like R's `library()`:
  inherited clashes are masked, the package's own symbols are kept and
  reported, `:prefer` keeps chosen names. Prints a masking report.

### Tests
- `cl-tidyverse/tests` (8 tests, 338 checks): every component export is
  re-exported; conflict reporting; FiveAM `!` and Serapeum `->`/`slice`
  resolved by `define-tidy-package`; `#C(1 2)` and `#2r1010` still read
  correctly; a full read → filter → mutate → summarise → factor → plot
  pipeline written with unqualified names.
- 6 new tests for D10 (bare verbs behave like dotted ones; no CL clashes;
  Serapeum clashes reported; `:prefer`; `use-tidyverse` on a package that
  uses CL and SB-EXT and owns a `MUTATE`; `use-tidyverse :prefer`).
  Suite: 370 checks, 370 pass.
