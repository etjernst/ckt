# Plan: wire the WCR11-corrected inversion into the real-data pipeline

Date: 2026-07-22 (revised the same day after the fresh-context plan review, [2026-07-22-wcr11-inversion-port-review.md](file:///C:/git/ckt/quality_reports/reviews/2026-07-22-wcr11-inversion-port-review.md); all eleven review revisions applied).
Spec: [2026-07-22-wcr11-inversion-port.md](file:///C:/git/ckt/quality_reports/specs/2026-07-22-wcr11-inversion-port.md) (authored on `worktree-extension-sims`, saved verbatim).
Branch: `wcr11-inversion-port`, cut from main, developed in a git worktree so the main tree stays untouched while the definitive master run is in flight.

## Verified preconditions (checked 2026-07-22 before this plan)

- The four reference artifacts exist on `worktree-extension-sims` and are retrievable via `git show`: `sims/src/wcr_bootstrap.py`, `sims/src/wcr_oracle.py` (231 lines), `sims/docs/wcr11_inversion_bootstrap_note.md` (60 lines), `sims/results/inversion_size_remediation/summary/wcr_size.csv`.
- The pipeline imports the production [lca_inversion.py](file:///C:/git/ckt/explorations/python-grc/lca_inversion.py): `0_programs.do` (lines 4029-4040) inserts `explorations/python-grc` on `sys.path` at file level, so the bare `import lca_inversion` resolves there.
- The chi-squared reference appears at five sites in `lca_inversion.py`, scoped here by function name because line numbers are brittle: `grid_lca_inversion` is the SOLE port target; `grid_md_inversion` (a phi minimum-distance variant used only by smoke and validation scripts, off the attach path) stays chi-squared; and the three derived-quantity MD inversions (`grid_delta_never_md_inversion`, `grid_delta_avg_md_inversion`, `grid_delta_always_md_inversion`) are untouched per the spec.
  (Correction from the plan review: the first draft claimed exactly three sites off a truncated grep; the count is five, and the misidentified site was `grid_md_inversion`, not a delta inversion.)
- The main-branch `attach_inversion_for_stata` already accepts `esample=` and `switchers_kept=`; it ran with the esample flag in the 2026-07-21 definitive-run 5c log, so main is current and the worktree copy is the laggard. No reconciliation needed on main.
- Sequencing constraint: the definitive `0_master.do` run is still in flight (extras block). Development on `lca_inversion.py`, `5b_inversion.do`, and `attach_inversion_ci` is safe now because none of those files is re-read by the running session (programs and scripts already executed; nothing downstream re-imports the Python module). The CI regeneration itself waits for the master to finish.
- Current-run state that bears on the spec's "missing China attachment" MUST: this run's `5b` aborted on its first cell (the since-deleted `grc_IDN_cuu_c0` fossil), so NO mainline cell (including China national) has attached CIs from this run, while `5c` attached the two hukou splits 4/4 cleanly. The spec's diagnosis targets an earlier regeneration; the fresh diagnosis happens after the WCR re-run on this run's sters.

## Stage 0: branch and retrieve

Cut `wcr11-inversion-port` and develop it in a git worktree, never by checking the branch out in the main tree: the running master still re-reads not-yet-executed scripts (`10_make_tables.do`, `11_make_figures.do`, the Verdier pair, `11b`) from disk, and a checkout swaps the whole tree.
Before any worktree operation, check every junction target under the new worktree per the 2026-06-23 data-loss protocol.
Retrieve from `worktree-extension-sims` via `git show` into the working tree:
`wcr_bootstrap.py` and `wcr_oracle.py` into `explorations/python-grc/` (same directory as `lca_inversion.py`, so the existing `sys.path` insert covers them);
the algorithm note into `explorations/python-grc/wcr11_inversion_bootstrap_note.md`;
the IDN-anchor rows of `wcr_size.csv` into `quality_reports/staging/wcr11/wcr_size_reference.csv` as the parity target.
Read the note end to end before any wiring; the kernel implements it and the port must not drift from it.

## Stage 1: parity gate (MUST; no reported CI until this passes)

Two checks, artifacts committed to `quality_reports/staging/wcr11/`:

- Gate A, oracle agreement: run `wcr_oracle.py` against the ported kernel on the anchor case; the vectorized kernel must reproduce the per-draw statsmodels refit to the note's stated tolerance.
- Gate B, size reproduction: on a shared design, reproduce the IDN anchor row of `wcr_size.csv` (J = 26: uncorrected 0.264, WCR 0.048).
The comparison rule is stated up front: same-seed reproduction must match exactly; an independent-seed reproduction tolerates root-sum-of-variances Monte Carlo error, about 0.014 at R = 500, not the single-run 0.010.
Gate B is itself a small Monte Carlo; its runtime gets measured and reported alongside the Stage 5 pilot pricing.

## Stage 2: wire the kernel into the phi inversion

In `grid_lca_inversion` (and only there):

- Build one `ClusterDesign` per (country, spec) fit via `build_aux_design`, verified byte-identical in columns to `fit_auxiliary_ols` output (assert, not assume: a column-order or dtype drift here invalidates the parity gate); reuse it across every grid point and draw.
Named contingency if the assert fires: reconcile `build_aux_design` against `fit_auxiliary_ols` (or construct the design from the fit's own code path), then re-run Gates A and B before Stage 2 proceeds; the kernel was written on the sims branch and may not have seen every production quirk (factor-variable expansion, unbalanced columns, esample subsetting).
- At each grid value: constrained least squares under G(phi0) b = 0 (restricted residuals refit per grid point, since the null moves with phi0), then B vectorized Rademacher draws, CV1 covariance in every statistic, finite-B rule p* = (1 + #{W*_b >= W_obs})/(B_valid + 1), accept when p* > 0.05 (95 percent set) and p* > 0.10 (90 percent set).
- The strict inequality is threaded consistently through `find_islands`, which currently accepts on >=: at B = 399 the lattice contains p* = 20/400 = 0.05 exactly with positive probability, and >= versus > changes the set precisely at the endpoints.
A boundary-tie unit test pins the strict rule.
- Rademacher weights are justified in the algorithm note in one sentence (the bootstrap clusters on individuals, a large count, and the simulation validated size on the actual sparsity surface); the weight family is exposed as a parameter so a Webb six-point comparison run costs nothing to wire later.
- `B` defaults to 399, exposed as a parameter end to end (Python function through the Stata option).
- Reproducibility: the G x B sign matrix draws from a `SeedSequence` keyed on (country, spec) with the keying scheme documented in the code and the key recorded in the run log and in the attached results, so a CI is reproducible from the seed alone.
- Diagnostics per grid point: B_valid, tie count, per-type invalid-draw counts; a grid point with B_valid < 0.95 B is a typed failure surfaced in the curve and the run log, never a silent accept.
- The chi-squared path stays available behind an explicit `method` argument for comparison runs, with `wcr11` the default; lines 312/442 (delta MD inversions) are untouched.

## Stage 3: thread the bridge and drivers

- `attach_inversion_for_stata` and `attach_inversion_ci` gain the B parameter and the seed-key recording, and attach the new diagnostics (B, minimum B_valid across the grid, seed key) as e() scalars/macros beside the existing CI scalars, plus a method tag `e(inv_method) = "wcr11"`.
- Per the spec's mixed-table rule, implemented end to end rather than by omission (the review's Red finding): the attach step ACTIVELY SCRUBS the delta-inversion scalar and macro families (`inv_dN`, `inv_davg`, `inv_dT`) from every ster it re-saves, because merely ceasing to write them leaves stale chi-squared values on sters the definitive run already attached (both hukou splits, 4 of 4).
The delta rows disappear from tables pending the derived-quantity coverage study on the sims branch; GMM inference for those quantities is already printed.
This is the plan's rendering of the spec's "decision this port must not make silently"; it needs explicit author approval here since it changes what the tables show.
- The `5b`/`5c` skip-if-exists guards are rekeyed from `e(inv_phi_ci95_lo)` (which chi-squared-era sters also satisfy, so a resumed run would silently keep uncorrected CIs) to the `e(inv_method)` tag.
- `5b_inversion.do` and `5c_inversion_hukou.do`: pass B and any method override; the covs_0 loop iterations skip via the no-parent branch (c0 decommissioned; fossils deleted 2026-07-22), which satisfies "every reported specification" since no table reports c0.

## Stage 3b: table program edit (lands with the port, before any Stage 6 rebuild)

`grc_tex_table_trend`'s `invci` block hardcodes the three delta CI `stats()` rows; without this edit the rebuilt tables either print stale chi-squared delta CIs or dangle empty label rows.
Drop the `ci_never`/`ci_avg`/`ci_always` rows, keep the phi inversion CI row, and leave everything else in the table program untouched.
This edit is safe to make while the master runs: the running session already loaded its programs into memory and never re-reads `0_programs.do` from disk, and the definitive run's tables get rebuilt in Stage 6 regardless.

## Stage 4: tests

- Port the kernel's unit tests; add a reproducibility test (same seed key, same design: identical CI bounds), a typed-failure test (forced invalid draws below the 0.95 B floor must raise, not accept), and the boundary-tie test for the strict p* > alpha rule.
- Add a fixture regression test pinning the chi-squared comparison path's output, so the port demonstrably left `method="chi2"` unchanged.
- Re-run the full suite plus the existing stage 9 keep-list test to confirm no interference.

## Stage 5: pilot pricing (MUST; approval gate)

Time one full cell (IDN cuu ca, meaning Indonesia, consumption/urban/unbalanced, full-covariate column: grid sweep x B = 399) on this machine.
Rerun the same cell with a second seed and once at B = 999 (also integral: 50 and 100), and report endpoint movement in grid steps alongside the timing, so the production B choice is made on evidence about endpoint stability, not just cost.
Report projected wall-clock for the full regeneration: 5 cells (IDN, TZA, CHN, CHN_rf, CHN_uf) x 4 estimated specs x grid points x B, plus Gate B's one-off cost.
Author approves production B and the full regeneration together.

## Stage 6: regeneration (after the definitive master run completes)

- Re-run `5b_inversion.do` and `5c_inversion_hukou.do` on the definitive-run sters (detached, per the detached-batch convention).
- Verify the phi CI row lands for all five cells: IDN, TZA, CHN national, CHN rural-first, CHN urban-first.
- Verify the mixed-table rule end to end: no delta-inversion CI macro remains on any reported ster (the Stage 3 scrub ran everywhere), and no delta CI row appears in any rebuilt table (the Stage 3b edit took).
- Per-cell grid-endpoint check: correcting a test with 0.264 size widens accept regions, so a region that touches a phi grid bound in ANY cell (not just CHN urban-first) triggers a widened grid and a rerun of that cell; the pilot's per-cell price bounds the cost.
The spec's "missing China attachment" gets its fresh diagnosis here: this run's mainline gap is fully explained by the fossil abort, and the hukou attachments succeeded, so if any China row is still missing after the WCR re-run, diagnose the e(sample)/base-selection path as the spec suggests; do not pre-fix what may already be resolved.
- Then rebuild only the affected tables (`10_make_tables.do` reads sters; no GMM re-run), and regenerate figures only if any consume the CI scalars.

## Stage 7: reporting decisions (author)

- CHN urban-first: weakly identified, expect an unbounded or one-sided phi region; the honest report is the region as-is, never a forced interval.
Author decides presentation wording.
- Table macros: `\GRCtable`, `\GRCexptable`, `\GRChukoutable` in the Overleaf `preamble.tex` need an inversion-CI row plus the table note naming the inversion CI as the preferred phi inference.
`preamble.tex` can carry coauthor track-changes, so these edits are proposed as a diff for the author to approve or place; regenerated tables copy additively into the Overleaf `tables/` folder as usual.

## Stage 8: review and close

`critic-python` on the changed Python (kernel, oracle port, `lca_inversion.py`), `critic-stata` on the touched do-files, fixes per the standard loop, author sign-off, merge with `--no-ff`.

## Out of scope (restating the spec)

No GMM re-runs; no changes to the delta MD inversions beyond ceasing to attach their CIs (pending the coverage study); no trajectory, sample, or auxiliary-column changes.
MAY items (Bartlett reference column, WCR31 variant) are not planned; they can be follow-ons if a referee asks.

## Risks and mitigations

- Bootstrap cost blowing up the grid sweep: the pilot prices it before anything runs; B and grid density are parameters if cost forces a tradeoff (author decides).
- Kernel-vs-production design drift: Gate A/B plus the byte-identity assert on `build_aux_design` columns.
- Definitive-run collision: no regeneration until the rc sentinel appears; development edits touch only files the running session never re-reads.
- Seeds: no `Date.now`-style incidental nondeterminism; the SeedSequence key is the only entropy source.

## Approval checklist for the author

1. The plan overall.
2. The Stage 3 decision to scrub delta-inversion CIs from the sters now (delta rows leave the tables until the coverage study reports).
3. Stage 5 pricing gate before full regeneration (you will see timing, seed-sensitivity, and B = 999 endpoint movement first, and pick production B).
4. Stage 7 table-macro diffs proposed for your placement rather than edited directly into the Overleaf preamble.
5. RATIFIED 2026-07-22 ("yeah no c0 spec"): the covs_0 iterations skip because c0 is decommissioned; the spec's every-specification MUST is satisfied by the four estimated specifications.
The c0 columns still visible in the paper are the frozen May 13 Overleaf tables, superseded when the definitive-run tables ship.
