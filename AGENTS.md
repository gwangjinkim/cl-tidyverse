# Agents guide — cl-tidyverse

cl-tidyverse is a **meta-package**: it contains no data-science code of its
own. It loads the component packages and re-exports them from one package,
`TIDYVERSE`, with every name conflict resolved. Functionality belongs in the
component packages (`../cl-dplyr`, `../cl-tidyr`, ...), never here.

What belongs here:
- the list of components (`*tidyverse-packages*`, `cl-tidyverse.asd`);
- conflict handling (`tidyverse-conflicts`, `define-tidy-package`);
- the `tidyverse-user` scratch package;
- tests that the union of the components behaves (re-exports, conflicts,
  a full pipeline written with unqualified names).

When a component adds an export that clashes with another component or
with COMMON-LISP, the test `reexports-every-component-package` or the
package definition itself fails at load time. Resolve it in the component
(rename or make the shadowing transparent, as done for FILL and SECOND),
then record it in ADR-0002 of `../cl-tidystat`.

Run tests: `make test`, or `../cl-tidystat/scripts/run-tests.sh cl-tidyverse`.
The plan for this package is `../cl-tidystat/PLAN.md` §5.1.

## Change Discipline (git + documentation)

Every change to this repository must be reconstructible later: what changed,
why, and what it means for users. Agents and humans follow these rules.

1. **Branch, never commit straight to `main`.** Use a topic branch such as
   `fix/<topic>` or `feat/<topic>` (cross-package work in the tidystat effort
   uses `fix/tidystat-phase0`, `feat/tidystat-phase1`, ...).
2. **One logical change per commit.** Test-suite repairs, bug fixes, new
   features and documentation go in separate commits, so each can be
   reviewed, bisected or reverted on its own.
3. **Commit messages explain the why.** Format:
   ```
   <area>: <imperative summary, <= 72 chars>

   Problem:  what was wrong / missing, with the observable symptom.
   Cause:    the root cause (file:function), if it is a fix.
   Change:   what this commit does.
   Impact:   behaviour change for users; mark BREAKING if any.
   Tests:    which tests were added/changed, and the suite result.
   ```
4. **Every commit updates `CHANGELOG.md`** under `## [Unreleased]`, in the
   sections *Fixed*, *Added*, *Changed*, *Breaking*, *Tests*. Each entry
   says what users will notice and names the commit topic.
5. **Run the full test suite before committing** (`make test`, or from the
   umbrella repo `../cl-tidystat/scripts/run-tests.sh <this-package>`) and put
   the result in the commit message. Never commit with a red suite unless
   the commit message says so and why.
6. **Cross-package changes** (e.g. an API in `cl-vctrs-lite` used by
   `cl-dplyr`) are recorded in both repos' changelogs and in
   `../cl-tidystat/docs/CHANGES-phase*.md`, which links the commits.
7. **Push only after review**; do not rewrite history that has been pushed.
