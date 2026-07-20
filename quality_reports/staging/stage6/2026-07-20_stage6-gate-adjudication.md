# Stage 6 gate adjudication: run_grc_robust_vv sample scoping and the Verdier table tail

Date: 2026-07-20.
Spec: [2026-07-20-stage6-verdier-cleanup.md](file:///C:/git/ckt/quality_reports/specs/2026-07-20-stage6-verdier-cleanup.md); stage plan: [2026-07-20-stage6-verdier-cleanup.md](file:///C:/git/ckt/quality_reports/plans/2026-07-20-stage6-verdier-cleanup.md).
Implementation commit: `b572508` on branch `stage6-verdier-cleanup`.

## Design

Because the stage34/stage5 gate panels ran the Verdier leg on TZA only, no frozen baseline exists for the IDN and CHN Verdier cells.
The gate therefore generated the old computation fresh as leg A (pre-fix scripts snapshot in `RP7/tests/stage0/stage6_rootA`) and required leg B (post-fix snapshot in `stage6_rootB`) to match it bitwise: all three countries, both GMM steps, five covariate specs, 30 parent fits and 150 sters per leg, both legs reading the canonical hub read-only and writing only inside their shadow roots.

## Results, all checks PASS

Ster identity: 150 of 150 leg B sters bitwise-identical to their leg A counterparts (no missing pairs), so the sample-scoping fix is a no-op on today's data, as the spec requires; artifact [gate_results.csv](file:///C:/git/ckt/quality_reports/staging/stage6/gate_results.csv).
Marker inventory: 60 of 60 parent sters (both legs) carry an `_esample.dta` marker with exactly `e(N)` rows; artifact [marker_inventory.csv](file:///C:/git/ckt/quality_reports/staging/stage6/marker_inventory.csv).
Cross-leg marker equality: 30 of 30 marker pairs identical under `cf` (same pid-period fit sample either leg).
TZA continuity: 50 of 50 leg A TZA sters bitwise-identical to the retained `stage5_root` refits, anchoring this gate to the Stage 3+4 baseline chain; artifact [tza_continuity.csv](file:///C:/git/ckt/quality_reports/staging/stage6/tza_continuity.csv).
Table regeneration: leg A's stale tail failed exactly as diagnosed (r(601) on the `_never` load, zero tables produced), while leg B's fixed tail completed and wrote all six `verdier_robust_*.tex` tables plus the three `GRC_*_cluster.tex` copies.

## Contract test

[contract_stage6_vv_sample.do](file:///C:/git/ckt/RP7/tests/stage0/contract_stage6_vv_sample.do), ALL PASS (rc=0), log beside the driver in `stage6_ctroot`.
With a copy of the TZA cluster index set to missing in all waves for every 50th individual, call 1 fit on the reduced 29,260-row sample and call 2 on the intact index recovered the full 29,862-row baseline, including the injected individuals the pre-fix code would have lost; after each call the caller's data were row-for-row identical to the pre-call snapshot (`cf _all`) with no leaked `vfirst` or `swd_*` columns.

## Regenerated tables against the frozen 2026-05-06 production versions

Artifact: [table_diff_vs_frozen.csv](file:///C:/git/ckt/quality_reports/staging/stage6/table_diff_vs_frozen.csv); the frozen files in `RP7/output/tables/` are untouched.
All nine tables are structurally identical to the frozen versions (same rows, columns, labels, and envelope once numerals and significance stars are masked); the movement is numeric only, expected from the per-capita outcome and Change A, which the frozen tables predate.
Numeric movement by table: 39 of 76 cells in IDN onestep (and its cluster copy), 39 of 77 in IDN twostep, 25 of 76 in TZA onestep (and its cluster copy), 28 of 86 in TZA twostep, 14 of 76 in CHN onestep (and its cluster copy), 19 of 86 in CHN twostep.
Significance-star changes appear on one line per table for IDN (both steps), TZA (both steps), and CHN twostep; CHN onestep has none.

One substantive change for author attention: the TZA `covs_0` column (no covariates) now reports Converged = Y in both GMM steps where the frozen tables report N, and its Average $\Delta$ row loses its stars in the twostep table.
The refreshed data (per-capita outcome plus Change A) evidently moved the TZA no-covariate cell into convergence; this is a data-refresh effect, not a code effect, since leg A and leg B agree bitwise on every TZA ster.

## Standing items

The regenerated tables are gate evidence only; nothing ships to coauthors or Overleaf before the definitive run.
The IDN Verdier `vfirst` reassignment for 45 pids (Stage 3 acceptance) is inside the numeric movement above and gets enumerated at the end sweep.
Gate evidence (`stage6_rootA`, `stage6_rootB`, `stage6_ctroot`) is retained until the definitive run, alongside the earlier stage roots.
