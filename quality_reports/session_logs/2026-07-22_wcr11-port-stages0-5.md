# Session log 2026-07-22 (late evening): WCR11 port Stages 0-5 implemented

## If you resume

- Branch `wcr11-inversion-port` lives in the worktree `C:/git/ckt/.claude/worktrees/wcr11-inversion-port`; six commits, `6ca5884` through the review-report commit after `4b0ec70`.
  All work below happened there; main is untouched.
- Three things were still running at wrap-up, all detached or background:
  1. The Stage 5 pilot (three arms on IDN cuu ca), launched about 22:00 via PowerShell Start-Process; expect 6-8 hours total.
     Progress: [pilot_run.txt](file:///C:/git/ckt/.claude/worktrees/wcr11-inversion-port/quality_reports/staging/wcr11/pilot_run.txt); results append per arm to [pilot_idn_cuu_ca.csv](file:///C:/git/ckt/.claude/worktrees/wcr11-inversion-port/quality_reports/staging/wcr11/pilot_idn_cuu_ca.csv); `pilot_rc.txt` appears on exit (0 = clean).
  2. Gate B (same-seed anchor reproduction, 500 reps), launched about 22:05, expected 25-40 minutes; a background watcher writes [gateB_verdict.txt](file:///C:/git/ckt/.claude/worktrees/wcr11-inversion-port/quality_reports/staging/wcr11/gateB_verdict.txt) with PASS or MISMATCH the moment the raw parquet lands.
     PASS requires exact equality with the reference row (uncorrected 0.264, WCR 0.048) since the seed is the same.
  3. The definitive master run (unrelated to this branch) was still healthy in its extras block; check [definitive_run_rc.txt](file:///C:/git/ckt/RP7/tests/definitive_run_rc.txt) and [0_master.log](file:///C:/git/ckt/RP7/scripts/0_master.log) before touching anything under `C:/git/ckt/RP7`.
- Next actions in order: read gateB_verdict (must be PASS before Stage 6); read the pilot CSV and put timing plus endpoint movement to the author for the production-B decision (approval checklist item 3); get author decisions on the review fixes in [2026-07-22-wcr11-port-code-review.md](file:///C:/git/ckt/.claude/worktrees/wcr11-inversion-port/quality_reports/reviews/2026-07-22-wcr11-port-code-review.md); after the rc sentinel appears and gates pass, Stage 6 regeneration per the plan.
- Two items for the author beyond the plan's checklist: the delta scrub breaks the CHN_rf E1 counterfactual bound loudly (see Decisions below), and the review's M3 kernel guard needs an oracle re-run if approved.

---

## Context

Continuation of the same-day planning session (spec, plan, review committed at `776ea83`).
The author had approved the plan and directed Stage 0 to start in a fresh session.
This session implemented Stages 0 through 5.

## What was done, by stage

Stage 0 (`6ca5884`): worktree `wcr11-inversion-port` cut from main (junction scan clean; `RP7/data` did not materialize since it is gitignored).
Kernel `wcr_bootstrap.py`, oracle `wcr_oracle.py`, and the algorithm note retrieved via `git show worktree-extension-sims:...` into `explorations/python-grc/`, verified byte-identical to the sims working copies; `wcr_size.csv` staged with the factor-1.0 anchor rows split into `wcr_size_reference.csv`.

Stage 1, Gate A (in `7bb2532`): oracle run in the extension-sims worktree (whose kernel is byte-identical to the port), toy enumeration plus 12 real anchor cases, every intermediate at 1e-8, all passed.
Log at [gateA_oracle_real.txt](file:///C:/git/ckt/.claude/worktrees/wcr11-inversion-port/quality_reports/staging/wcr11/gateA_oracle_real.txt) (renamed from .log because the repo gitignores `*.log`).
Gate B launched this session (see If you resume).

Stage 2 (`7bb2532`): `lca_inversion.py` wired.
`grid_lca_inversion` gained `method="wcr11"` (default) requiring an explicit `ClusterDesign` and a pre-drawn sign matrix, with chi2 unchanged behind `method="chi2"`; strict p* > alpha acceptance for wcr11 threaded through `find_islands` (new `strict` parameter) with insufficient-draw points excluded always; `compute_all_inversion_cis` under wcr11 builds the design via `build_aux_design`, hard-asserts names, coefficients, and CV1 covariance against `fit_auxiliary_ols` at 1e-8, draws one G x B Rademacher matrix from `SeedSequence(20260722, sha256(seed_token))`, runs the phi leg only, and returns bootstrap provenance; the three delta MD inversions run only on the chi2 comparison path.
`attach_inversion_for_stata` threads method, B, seed_token, weights and emits provenance locals; delta locals only under chi2.

Stage 3/3b (`1b48c63`): `attach_inversion_ci` gained `method()/bdraws()/weights()`, uses estbase as the seed token, attaches phi plus provenance to all four suffix sters, scrubs the delta families on every wcr11 re-save (scalars to missing, macros emptied); 5b/5c skip guards rekeyed from `e(inv_phi_ci95_lo)` to the `e(inv_method)` tag, with `$inversion_bdraws` / `$inversion_method` overrides; `grc_tex_table_trend`'s invci gate keeps the phi CI row and drops the three delta CI rows.

Stage 4 (`108a599`): new [test_wcr11_inversion.py](file:///C:/git/ckt/.claude/worktrees/wcr11-inversion-port/explorations/python-grc/test_wcr11_inversion.py) with six tests, all passing: pinned seed scheme (spawn key and sign matrix for a known token), same-seed reproducibility, boundary tie at the exact p* = alpha lattice point, typed failure never accepted, design-drift assert, chi2 fixture regression (fixture committed).
Live standalone runners and smokes pinned to `method="chi2"` explicitly with comments (keep-list agreement runner, IDN runner, MD-vs-just-identified smoke, synthetic overid, all-inversions smoke, legacy .ado helper).
Stage 9 keep-list test re-run against the worktree's edited `0_programs.do`: all 8 cases pass.
The remaining legacy python tests import only `grc_gmm`, untouched by the port, and were not re-run.

Stage 5 (`4b0ec70`): timing probe on the real IDN cuu ca design gave 14.4 s per grid point at B=399 with BLAS capped at 2 threads, hence about 96 minutes per cell and about 32 hours for the 20-cell regeneration at that rate before cross-cell parallelization (the machine has 22 logical cores, so 4-6 parallel cells are realistic in Stage 6).
The design-vs-fit assert PASSED on real production data, so the plan's named contingency never fired.
Full pilot launched detached: arm 1 is the production computation for the cell (same sample via the esample marker, same token, B=399), arm 2 second seed, arm 3 B=999.
The esample marker for grc_IDN_cuu_ca flags 92,438 of 92,449 rows, identical to the reconstruction count.

Review (Stage 8 brought forward while pilots run): critic-python and critic-stata in fresh context, findings consolidated in [2026-07-22-wcr11-port-code-review.md](file:///C:/git/ckt/.claude/worktrees/wcr11-inversion-port/quality_reports/reviews/2026-07-22-wcr11-port-code-review.md).
No CRITICAL; three MAJORs (chi2 re-save provenance asymmetry; grid-level design self-check missing; unguarded W_obs solve in the kernel) and four MINORs.
Fixes held for author approval per Mode 3; the proposed batch including the Gate A re-run is under an hour.

## Decisions, with the why

- Gate A ran in the sims worktree rather than the port worktree because the oracle imports sims-only modules (dgp, sparse_dial, restriction_projection, config) and the sims data; byte-identity of the kernel (verified by diff) makes that run certify the ported copy.
- The wcr11 branch of `compute_all_inversion_cis` skips the delta MD inversions entirely rather than computing-but-not-attaching them: mixing a corrected phi with uncorrected delta CIs inside one result dict is the forbidden-table shape at the source, and nothing consumes the delta values anymore.
- estbase doubles as the bootstrap seed token so no caller carries a second identifier and the recorded `e(inv_seed_token)` alone reproduces the CI.
- The delta scrub writes literals (missing, empty), never locals, so a chi2-then-wcr11 session cannot leak stale values; the Stata critic verified this directly.
- The pilot uses the esample marker rather than the reconstructed sample so arm 1 IS the production CI for the cell, not an approximation of it.
- Detached launches (PowerShell Start-Process) for pilot and Gate B because background Bash tasks are reaped about 30 minutes after session idle (2026-07-15 incident); a background watcher handles only the short Gate B verdict step.
- Both compute jobs run with capped BLAS threads (pilot 4, Gate B workers 1 x 6 processes) to protect the live definitive Stata run on the shared machine.

## Rejected approaches

- Modifying `fit_auxiliary_ols` to return its design matrix (removing the duplicate construction risk entirely): rejected because the plan pins the build_aux_design-plus-assert architecture the oracle certified, and the assert passed on production data.
- Making `attach_inversion_for_stata` clear delta locals under wcr11: unnecessary once the Stata side writes scrub literals; emptied locals would add dead code.
- Running the stale `test_attach_inversion_ci.do`: it targets the lca-inversion worktree with the pre-rename `estname()` option and old data paths; the Stage 5 pilot and Stage 6 re-run exercise the live attach path instead.

## Open items

- Gate B verdict and pilot results (in flight; see If you resume).
- Author decisions: review-fix batch (M1-M3 plus MINORs), production B after the pilot, the CHN_rf counterfactual-bound consequence of the delta scrub (`_export_e1_inputs*.do` read `inv_dN` scalars and `counterfactuals.py` requires finite CHN_rf delta CI endpoints, so `12_counterfactuals` fails loudly on scrubbed sters until the coverage study lands or the bound is reworked).
- Stage 6 regeneration blocked on: definitive run rc sentinel, Gate B PASS, author's B choice.
- Stage 7 (table macros, CHN urban-first wording) and the merge remain per plan.
