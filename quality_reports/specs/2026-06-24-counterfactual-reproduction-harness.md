# Spec: counterfactual reproduction harness

Date: 2026-06-24.
Branch: lca-inversion.
Mode: Implementation (workflow.md Mode 2).

## Problem

The E1 misallocation numbers in `paper/results_counterfactuals.tex` are produced by dated exploration drivers in `explorations/`, not by a re-runnable pipeline step.
The numbers reproduce exactly today (verified 2026-06-24 against all five cells), but three reproducibility gaps remain: no single entry point in `0_master.do`, no persisted outputs (results live only in stdout), and the paper prose is hand-transcribed with no drift guard.

This spec covers the harness that closes those gaps.
It does not cover E2 (the hukou-wedge counterfactual), which is a separate deliverable.

## MUST

- M1: A new Stata driver `12_counterfactuals.do` reproduces all E1 headline numbers end to end when run after the inversion sters exist.
- M2: The driver mirrors the existing `5b_inversion.do` Stata-orchestrates-Python pattern, calling into `counterfactuals.py` over the SFI `python:` bridge already used by `attach_inversion_ci`.
- M3: The heavy computation stays in `counterfactuals.py`; the driver does not reimplement the joint-CI or aggregate logic in Stata.
- M4: The graduated orchestration entry point in `counterfactuals.py` is named to match the module's existing convention (e.g. `run_counterfactuals_for_stata`), not with an `e1_` prefix.
- M5: Every headline number (point estimate plus convex-hull CI, P3 and with-$d_T$, per cell: IDN, TZA, CHN-RF, CHN-UF, CHN national) is persisted to a results file under `RP7/output/`.
- M6: The driver emits the LaTeX table the paper can `\input`, so the paper number stops being hand-transcribed.
- M7: The harness carries a self-check that compares the reproduced numbers against a committed baseline snapshot (`counterfactual_results_baseline.csv`, frozen from a verified run), and fails loudly on any drift beyond a stated tolerance.
The baseline is a versioned artifact, so drift surfaces as both a test failure and a git diff; updating it is a deliberate, reviewable commit, not an edit to in-code constants.
The final aggregates live only in this CSV, never in a `.ster` (the sters hold the upstream $\hat\phi$, $\hat\beta$, $\mu_d$, $J$ that feed the aggregation, not its output).
- M8: `0_master.do` gains a documented switch (default off) that includes `12_counterfactuals.do` after the inversion step.
- M9: The reproduced numbers match what is currently in the paper to the rounding shown in the paper.

## SHOULD

- S1: The two dated exploration drivers' duplicated glue (`prepare_data`, `load_v2_inputs`, `compute_alpha_dT_obs`, the `delta_at` closure, the propagation loop) is consolidated into `counterfactuals.py` so there is one code path, not three.
- S2: The Stata input-export step (`_export_e1_inputs.do`, `_export_e1_inputs_hukou.do`) is run or included by `12_counterfactuals.do` so the input CSVs are regenerated from the current sters rather than trusted as stale artifacts.
- S3: A short README documents the full two-tier chain: Tier 1 (Python from committed input CSVs, seconds) and Tier 2 (Stata GRC then inversion then export regenerates those CSVs).
- S4: The persisted results file is machine-readable (CSV or JSON) so a future table-builder or robustness check can consume it without re-running.

## MAY

- MAY1: Move `counterfactuals.py` and `lca_inversion.py` under `RP7/scripts/` for a cleaner replication package. Deferred; the existing `explorations/python-grc/` import path is consistent with how the shipped inversion helper already loads.
- MAY2: Emit the per-cell diagnostics (island counts, boundary-crossing flags) to a side CSV for audit.
- MAY3: Wire the persisted results into a regression test under `tests/`.

## Non-goals

- E2 hukou-wedge counterfactual (separate spec).
- The full production pipeline from the 2026-05-18 plan (tables T1--T3, figures F1--F2, diagnostics D1--D9). The lean harness is the first step; the full pipeline waits until E2 exists so it is built once.
- Any change to the estimation, sample construction, or the inversion machinery. The numbers must not move.

## Acceptance

A coauthor who runs `0_master.do` with the switch on reproduces every E1 number in the paper, the run writes a persisted results file and the `\input` table, and the self-check passes.
The two dated drivers can then be archived, since the graduated module supersedes them.
