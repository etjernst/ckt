# Review: Stage 9 switcher-inclusion, Python leg

Reviewer: critic-python (sonnet), 2026-07-21.
Target: branch `stage9-switcher-inclusion`, commit `06b0212`.
Files: [lca_inversion.py](file:///C:/git/ckt/explorations/python-grc/lca_inversion.py), [lca_inversion_ci_helper.py](file:///C:/git/ckt/explorations/python-grc/lca_inversion_ci_helper.py), [run_all_countries_inversion.py](file:///C:/git/ckt/explorations/python-grc/run_all_countries_inversion.py), cross-referenced against `0_programs.do`, `0_path_config.do`, `5b_inversion.do`, and `lca_inversion_ci.ado`.

Severity counts: CRITICAL 0, MAJOR 1, MINOR 6.
Score: 82/100.
Clears the exploration-tier gate (60); below the PR gate (90) mainly because of the one MAJOR on the production-facing attach path.

## MAJOR

M1. Truthy empty-string check on Stata locals is not whitespace-safe (production attach path).
[lca_inversion.py:952](file:///C:/git/ckt/explorations/python-grc/lca_inversion.py): `kept_list = [int(s) for s in switchers_kept.split()] if switchers_kept else None`; [lca_inversion_ci_helper.py:91](file:///C:/git/ckt/explorations/python-grc/lca_inversion_ci_helper.py): `if supplied_raw:`.
A whitespace-only macro value is truthy, so it enters the branch; `" ".split()` yields `[]`, giving an empty supplied list that then compares against a non-empty recomputed keep-list and raises a spurious disagreement hard error.
Under current call sites the Stata `syntax` parser leaves an unspecified `numlist` option as a genuine `""`, so this is latent, not currently triggered.
Fix: `if switchers_kept.strip():` / `if supplied_raw.strip():`.
Confidence: medium.

## MINOR

MI1. `int()` truncates rather than rounds Stata-float trajectory codes in `drop_sparse_switchers` and `fit_auxiliary_ols` (`sorted(int(t) for t in ...)`); a float round-trip artifact like 2.9999999999999 would silently misclassify. Pre-existing pattern, not introduced by this diff; harden with `round()` plus a closeness assertion.

MI2. No explicit missing-value guard on `hhid` inside the both-state counter: `pandas.unique()` collapses NaNs to a single NaN object, and set intersection identity-matches it, so a missing `pid` with rows in both states would silently count as one shared unit. Add `dropna(subset=[hhid])` or assert no missing `hhid`.

MI3. Stale module docstring at the top of `lca_inversion.py` (lines 5-7) still describes the old one-sided rule while the function docstring documents the both-states rule.

MI4. Stale console message in `lca_inversion_ci.ado:97`: "switchers kept (>= `threshold' treated pids)" misdescribes the now-both-state rule it reports on.

MI5. `counterfactuals.py:361` hardcodes `THRESHOLD = 5` instead of importing `SWITCHER_KEEP_MIN`, undermining the single-source-of-truth goal; that call site would silently desync from a future threshold change.

MI6. The CSV-verification branch in `run_all_countries_inversion.py` is unexercised until the hub rebuild populates `RP7/output/keeplists/`; smoke it against a fixture before trusting it once the rebuild lands.

## Verified correct

The both-state counting matches `compute_switcher_keeplist` in `0_programs.do` exactly (distinct units with at least one urban and one rural row, `>=` threshold), and `SWITCHER_KEEP_MIN = 5` matches `$grc_switcher_keep_min`.
The redundant-recompute check is not tautological: on the attach path it re-verifies the supplied kept switchers clear the threshold on the exact esample-filtered subset per spec, the drift case the plan's K-4 assumption covers; the standalone CSV path is genuinely independent since `data_loader.py` never applies Stata's in-memory lumping.
All other `drop_sparse_switchers` callers in explorations/python-grc inherit the tightened rule with no independent reimplementation; `synth_overid.py` already renormalizes `pi_within` over the realized kept set.
Prior artifacts in the folder (`results/lca_inversion_three_countries.md`, `rerun_workdir/*.csv`) reflect the old one-sided rule and are stale for citation purposes.
No hardcoded absolute paths, no syntax errors, no seed-requiring stochastic operations in the reviewed files.
