# Spec: Stage 6, clean up run_grc_robust_vv and repair the Verdier table tail

Date: 2026-07-20.
Parent plan: [2026-07-14-pipeline-frontload-refactor.md](file:///C:/git/ckt/quality_reports/plans/2026-07-14-pipeline-frontload-refactor.md), Stage 6.
Mode 2 (correctness stage); author sign-off required before commit because the table fix regenerates paper-facing output.

## Problem

Two defects, both in the Verdier robustness leg.

First, `run_grc_robust_vv` mutates the caller's in-memory data: `gen_vfirst` plus `drop if missing(vfirst)` and the generated `swd_switcher_*_choice` instrument columns persist after the program exits.
Within `17_verdier_robust.do`'s ten calls per country (2 GMM steps x 5 covariate specs on one `use`), every spec after the first therefore starts from the previous spec's mutated data rather than the country baseline.
Today the contamination is value-neutral because the drop is idempotent within a country (same `vindex` every call), which is why current results are expected byte-identical; the contract is wrong in the general case (a future spec with a different cluster index, or any reuse of the program elsewhere).

Second, the table tail of `17_verdier_robust.do` (lines 154-157) loads sters under the pre-rename disk suffixes `_never` and `_avg`, while the fitter has saved `_n` (Delta_never), `_a` (Delta_always), `_d` (per-switcher Deltas), and `_g` (Delta_avg) since the suffix rename.
The load fails silently under the driver's `capture noisily` wrapper, so no run since the rename can regenerate the paper's Verdier robustness tables; the production `verdier_robust_*.tex` files are frozen 2026-05-06 artifacts.
Correction to the parent plan's text: the stale `_avg` load maps to `_g` (Delta_avg, the table's "Average Delta" row), not to `_a` (Delta_always, which no table consumes).

## MUST

- M1. `run_grc_robust_vv` leaves the caller's data exactly as it found them: every call starts from the caller's baseline sample, and the internal `drop if missing(vfirst)`, the `vfirst` column, and the `swd_switcher_*_choice` columns do not persist after exit.
- M2. All internal computations that key off `e(sample)` (the individual-count scalar, the esample marker, the `Delta_avg` trajectory shares) still run against the data state the GMM was fit on, so the persisted marker and scalars are unchanged in meaning.
- M3. The tail of `17_verdier_robust.do` loads `<stem>_n` into stored name `<stem>_never` and `<stem>_g` into stored name `<stem>_avg`, keeping the stored names `grc_tex_table_trend_robust` expects; stored names stay within Stata's 32-character `_est_` limit.
- M4. A synthetic contract test proves the sample-persistence fix: scratch data where the old code's persisted drop would shrink a later call's sample, asserting (a) the caller's row count and content are unchanged after each call and (b) a second call's fit sample matches the baseline-derived sample, not the first call's mutated one.
- M5. Gate: refit the Verdier cells for all three countries (both GMM steps, all five covariate specs) on the current canonical hub; Tier 1 provenance exact and Tier 2 byte-identity expected against the Stage 3+4 gate baseline where a baseline pair exists; any coefficient movement is a finding to surface, never to absorb.
- M6. Regenerate the six `verdier_robust_{onestep,twostep}_{country}_*.tex` tables and the three `GRC_*_cluster.tex` copies through the fixed tail, and diff against the frozen 2026-05-06 versions; numeric movement is expected (per-capita outcome plus Change A) and is reported to the author, while structural or formatting differences beyond the numbers are findings.
- M7. Nothing ships to coauthors or Overleaf from this stage; regenerated tables are gate evidence until the definitive run.

## SHOULD

- S1. Correct the stale documentation the fix orphans: the fitter's header comment still lists the old output suffixes (`_never`/`_always`/`_delta`/`_avg`) and the "SIDE EFFECT" block describing the persisting drop; the driver's resume comment says the final ster is `_avg` while the skip check actually tests `_g`.
- S2. The contract test lives beside the Stage 5 tests in `RP7/tests/stage0/` and follows their driver conventions.

## MAY

- Y1. Apply the same no-mutation treatment to legacy `run_grc_robust` (same `gen_vfirst`-plus-drop pattern, no live call site in RP7/scripts); default is to leave it for the Stage 8 dead-code sweep.

## Out of scope

The `${vsfx}` filename threading (Stage 8 removal), the Verdier IDN 45-pid `vfirst` reassignment already accepted at Stage 3 (end-sweep enumeration), and any change to the GMM specification, instruments, or moment equation.
