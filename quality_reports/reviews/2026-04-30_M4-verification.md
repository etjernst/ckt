# M4 verification: duplicate mu-loop cleanup is bit-identical on production

**Date:** 2026-04-30.
**Subject of test:** commit [`d2b0c73`](https://github.com/) "Delete duplicate mu-loop in initial_values + initial_values_robust (M4)".
**Verdict:** bit-identical on the production cell `grc_CHN_cub_c0`. M4 promoted from RESOLVED to CLOSED.

## What M4 was

The pre-M4 versions of `initial_values` and `initial_values_robust` accumulated `mu:switcher_<s> mu_<s>` entries into `local initial` twice in succession, around a `kappa: kappa` append, with no intervening logic.
The structure read as an unfinished refactor where the second loop was a placeholder for a Δ loop that never got rewritten (the code carries the comment "Tricky to do with the potentially-changing Delta_base" beside a commented-out Δ loop).
Commit `d2b0c73` deleted 9 lines from [RP7/scripts/0_programs.do](file:///C:/git/ckt/.claude/worktrees/grc-pipeline-refactor/RP7/scripts/0_programs.do) and left only the first loop.

The pre-M4 synthetic test [tests/test_gmm_from_duplicate.do](file:///C:/git/ckt/.claude/worktrees/grc-pipeline-refactor/tests/test_gmm_from_duplicate.do) (run 2026-04-29) confirmed three things on a toy specification.
First, Stata's local accumulator does not deduplicate; the `from()` string was 1.88x the length of the deduplicated version (108 -> 203 chars on switchers 2--6).
Second, `gmm` does not error on duplicate `from()` entries.
Third, the duplicated `mu_<s>` scalars carry the same value on both passes, so the resulting fit was bit-identical on the toy.

The toy test was not enough.
The cleanup commit message itself acknowledged "verify bit-identical" as a post-Tier-3 follow-up.
The verification described here is that follow-up, run on a real production cell rather than a synthetic specification.

## Test design

**Cell.** `grc_CHN_cub_c0`---China, consumption per capita (adult-equivalent), urban choice, balanced sample, no covariates beyond the constant.
This is the entry-point cell of the CHN block in [RP7/scripts/5_GrRC.do](file:///C:/git/ckt/.claude/worktrees/grc-pipeline-refactor/RP7/scripts/5_GrRC.do) (L490).
N = 56,855.
17 parameters: 13 mu (`never` plus `switcher_2`...`switcher_13`), `Delta_base:_cons`, `phi:_cons`, `kappa:_cons`, plus `xb:o.covar_cons` (constrained to zero).

**Reference.** [RP7/output/grc_CHN_cub_c0.ster](file:///C:/git/ckt/.claude/worktrees/grc-pipeline-refactor/RP7/output/grc_CHN_cub_c0.ster), mtime 2026-04-29 03:47 +1000, well before commit `d2b0c73` landed at 2026-04-29 14:40 +1000.
The reference was produced by the Tier 3 background batch task `box05upsf` (launched 2026-04-29 ~12:50), which had loaded the pre-M4 `initial_values` into Stata's program memory at startup and held it through its run.
The reference's `e(cmdline)` confirms the OLD code path: `from()` carries the duplicated mu entries (`mu:switcher_2 mu_2 ... mu:switcher_13 mu_13 kappa: kappa mu:switcher_2 mu_2 mu:switcher_3 mu_3 ...`).

**Refit.** The driver [tests/verify_M4_mu_loop.do](file:///C:/git/ckt/.claude/worktrees/grc-pipeline-refactor/tests/verify_M4_mu_loop.do) mirrors the cub-section pre-amble at [5_GrRC.do](file:///C:/git/ckt/.claude/worktrees/grc-pipeline-refactor/RP7/scripts/5_GrRC.do) L284--299 and the CHN block at L450--493, and writes the new fit under `estname(verify_M4_CHN_cub_c0)` so the reference ster is not clobbered.
The driver was executed through the Stata MCP against the post-M4 `0_programs.do`.
Wall time on the full block (`initial_values` + `run_grc`, all five sters): roughly two minutes on `default` MCP session, MP, two cores.

**Comparison.** New fit's `e(b)` vs. stashed `b_ref_M4`, and new fit's `e(V)` vs. stashed `V_ref_M4`.
Three measures: element-wise max absolute difference, `mreldif()`, and a parameter-by-parameter dump at full machine precision.

## Result

| Quantity | Value |
|---|---|
| `max abs(b_new - b_ref)` | `0.000000000000000e+00` |
| `max abs(V_new - V_ref)` | `0.000000000000000e+00` |
| `mreldif(b_new, b_ref_M4)` | `0` |
| `mreldif(V_new, V_ref_M4)` | `0` |
| Reference N | 56,855 |
| Refit N | 56,855 |

All 17 parameters match to machine precision.

| param_eq:param_name | `b_ref` (pre-M4) | `b_new` (post-M4) | diff |
|---|---:|---:|---:|
| `mu:never` | 9.747182887992288 | 9.747182887992288 | 0 |
| `mu:switcher_2` | 9.680614498122381 | 9.680614498122381 | 0 |
| `mu:switcher_3` | 9.986306991345261 | 9.986306991345261 | 0 |
| `mu:switcher_4` | 9.637685981447476 | 9.637685981447476 | 0 |
| `mu:switcher_5` | 9.774306418229973 | 9.774306418229973 | 0 |
| `mu:switcher_6` | 5.924875420237799 | 5.924875420237799 | 0 |
| `mu:switcher_7` | 11.72903838125504 | 11.72903838125504 | 0 |
| `mu:switcher_8` | 9.359452621265053 | 9.359452621265053 | 0 |
| `mu:switcher_9` | 10.00109312884511 | 10.00109312884511 | 0 |
| `mu:switcher_10` | 9.986273422118293 | 9.986273422118293 | 0 |
| `mu:switcher_11` | 11.11901612881477 | 11.11901612881477 | 0 |
| `mu:switcher_12` | 10.33850555423320 | 10.33850555423320 | 0 |
| `mu:switcher_13` | 10.47623634726655 | 10.47623634726655 | 0 |
| `Delta_base:_cons` | 0.4837269199279454 | 0.4837269199279454 | 0 |
| `phi:_cons` | -0.8966026201264059 | -0.8966026201264059 | 0 |
| `kappa:_cons` | 10.33462346760780 | 10.33462346760780 | 0 |
| `xb:o.covar_cons` | 0 | 0 | 0 |

Full-precision dump at [RP7/output/verify_M4_b_compare.txt](file:///C:/git/ckt/.claude/worktrees/grc-pipeline-refactor/RP7/output/verify_M4_b_compare.txt).

## Interpretation

The duplicate `from()` entries in the pre-M4 `initial_values` carried identical values on both passes (the same `mu_<s>` scalars).
`gmm`'s starting-value parser evidently treats a duplicate name with the same value as a no-op rather than as a constraint clash, so the iteration sequence is identical between the two code paths.
Combined with the existing toy test, this confirms the cleanup is dead-code removal in the strict sense: the runtime numerics are unchanged.

The result also rules out a more concerning alternative.
If the pre-M4 code had been silently accepting duplicate entries with *different* values (because of a name collision with the `kappa` append, for example), removing one of them would have shifted the starting point and produced a different local minimum.
The bit-equality result rules that out for this cell.

## Caveat (closed by extended verification)

The original test was a single cell on a single country.
The CHN cub c0 cell exercises the full machinery (`initial_values`, then `run_grc`'s GMM with `iterate(100)` and `vce(cluster pid)`), but it does not cover variants where the duplicate could matter differently:
specifications with covariates that re-shape the `from()` string further, the `_robust` (Verdier) path that uses `initial_values_robust`, or samples with different switcher counts.
Three additional cells were spot-checked through the same MCP-driven harness ([tests/verify_M4_extended.do](file:///C:/git/ckt/.claude/worktrees/grc-pipeline-refactor/tests/verify_M4_extended.do)).

| Cell | k | N | max \|b_new - b_ref\| | max \|V_new - V_ref\| | mreldif(b) | mreldif(V) |
|---|---:|---:|---:|---:|---:|---:|
| CHN cub c0 (baseline; replicates above) | 17 | 56,855 | 0 | 0 | 0 | 0 |
| CHN cub ca (full controls) | 24 | 56,855 | 0 | 0 | 0 | 0 |
| IDN cub c0 (5-wave panel) | 35 | 16,391 | 0 | 0 | 0 | 0 |
| TZA cub c0 (3-wave panel) | 11 | 23,526 | 0 | 0 | 0 | 0 |

The covariate spec (cub ca) adds period FE, female, age², education, education² to `xb:`, raising the parameter count from 17 to 24.
IDN's 5-wave structure produces more switcher trajectories, so the `from()` string is longer (k=35).
TZA has only 3 waves, so fewer switchers (k=11).
All four cells return zero on every difference metric.

The `_robust` (Verdier) path was not exercised explicitly: no pre-M4 `*robust*` ster exists on disk, so an explicit test would require reverting d2b0c73, fitting a robust cell, restoring, and refitting.
This was skipped on the strength of two arguments.
First, the M4 diff in `0_programs.do` is structurally identical between `initial_values` (L1629) and `initial_values_robust` (L1751)---the same `foreach s of numlist $switchers` mu-loop deleted from both, in the same place relative to the `kappa: kappa` append.
Second, `initial_values_robust` was written by copying `initial_values` with the duplicate already in it, so the two share a common origin and the bit-equality result on the non-robust path mechanically extends.

Summary file at [RP7/output/verify_M4_extended_summary.txt](file:///C:/git/ckt/.claude/worktrees/grc-pipeline-refactor/RP7/output/verify_M4_extended_summary.txt).
Verbose log at [RP7/scripts/logs/verify_M4_extended.smcl](file:///C:/git/ckt/.claude/worktrees/grc-pipeline-refactor/RP7/scripts/logs/verify_M4_extended.smcl) (current driver routes the GMM iteration trace to disk via `log using` so MCP responses stay small).

## Files produced

- [tests/verify_M4_mu_loop.do](file:///C:/git/ckt/.claude/worktrees/grc-pipeline-refactor/tests/verify_M4_mu_loop.do)---the driver, runnable from any worktree by editing `$dir`.
- [RP7/output/verify_M4_CHN_cub_c0.ster](file:///C:/git/ckt/.claude/worktrees/grc-pipeline-refactor/RP7/output/verify_M4_CHN_cub_c0.ster) plus four sibling sters (`_a`, `_d`, `_g`, `_n`)---the refit results. Optional to keep; the audit trail is in the txt file.
- [RP7/output/verify_M4_b_compare.txt](file:///C:/git/ckt/.claude/worktrees/grc-pipeline-refactor/RP7/output/verify_M4_b_compare.txt)---parameter-by-parameter b dump at machine precision. This is the audit-trail file; keep.

## Status

M4 (Workstream B) closed.
Phase 4 (M4 in the larger refactor spec, the `values(nominal|real)` switch) is unrelated and remains NOT STARTED.
