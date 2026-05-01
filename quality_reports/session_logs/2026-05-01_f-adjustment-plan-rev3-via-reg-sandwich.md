# Session log: 2026-05-01 F-adjustment plan rev 3 via reg_sandwich

Mode: Implementation (planning + alignment).
Branch: `lca-inversion`.
Continues from [`2026-04-30_md-inversion-and-three-country-validation.md`](file:///C:/git/ckt/.claude/worktrees/lca-inversion/quality_reports/session_logs/2026-04-30_md-inversion-and-three-country-validation.md), which carried the morning's M11 read and the first F-adjustment spec/plan.

## Goals

The session opened as a continuation of the chi-squared finite-sample work documented in [`docs/notes/2026-04-30_chi-squared-finite-sample.md`](file:///C:/git/ckt/.claude/worktrees/lca-inversion/docs/notes/2026-04-30_chi-squared-finite-sample.md).
The next robustness path was the Imbens-Kolesár (2016) Bell-McCaffrey-Satterthwaite F adjustment.

User pointed at [`STER_NAMING.md`](file:///C:/git/ckt/.claude/worktrees/grc-pipeline-refactor/RP7/scripts/STER_NAMING.md) on the `worktree-grc-pipeline-refactor` branch.
The M11 rename (`grc_<country>_<spec3>_<covs2>_<sfx1>$`, e.g. `grc_IDN_cuu_ca`) solves the 32-char `_est_<name>` issue from the prior session's third concrete next move.
First decision of the session: pause the Stata-side wiring of inversion CIs into the production pipeline (5b_inversion.do, esttab `stats()` extension) and continue Python-side robustness work in parallel.

Mid-session course corrections:

1. After the methods review and first plan review surfaced three Red findings on the from-scratch Python implementation (PT 2018 vs 2023 corrigendum, BRL-FE vs CR2 distinction, GMM-OLS bridge undocumented), the user flagged the path as quasi-novel and asked for cleaner alternatives.
2. After surveying five alternatives, user pointed at the Stata `reg_sandwich` package by Pustejovsky.
That changed the plan substantially: from "implement CR2 + Satterthwaite ourselves with a clubSandwich-via-R anchor" to "call Pustejovsky's own implementation."
3. User asked for a third plan-review pass on rev 3 to make sure the new sourcing-path Reds were closed.
4. User authorized SSC installs explicitly partway through, so Step 0's `ssc install reg_sandwich` no longer needs separate approval.

## What got built or changed

Specs, plans, reviews:

- [`quality_reports/specs/2026-05-01-f-adjustment-inversion.md`](file:///C:/git/ckt/.claude/worktrees/lca-inversion/quality_reports/specs/2026-05-01-f-adjustment-inversion.md): MUST/SHOULD/MAY spec for adding an F-adjusted variant of every chi-squared inversion in `lca_inversion.py`.
- [`quality_reports/reviews/2026-05-01_f-adjustment-spec-methods-review.md`](file:///C:/git/ckt/.claude/worktrees/lca-inversion/quality_reports/reviews/2026-05-01_f-adjustment-spec-methods-review.md): econometrics-methods-review of the spec.
0 critical, 4 major (synth scope at $J_R=26$, rank-deficient anchor, PT memory complexity, nlcom width sanity check).
- [`quality_reports/plans/2026-05-01-f-adjustment-inversion.md`](file:///C:/git/ckt/.claude/worktrees/lca-inversion/quality_reports/plans/2026-05-01-f-adjustment-inversion.md): plan rev 3.
Final structure has Step 0 (smoke test), Step 0a (corrigendum + FE-absorption A/B), Step 1 (Stata wrapper), Step 2 (Python bridge with subprocess verification scaffold), Step 3 (synth coverage at $T=4$ and $T=5, K=27$ both $R = 1000$, with a 50-rep pystata pilot), Step 3.5 (conditional WCB comparison via boottest joint syntax with $B = 9999$), Step 4 (smaller-$J_R$ regression), Step 5 (empirical re-run with contiguous-acceptance fallback), Step 6 (note + validation-gate update), Step 7 (commits).

Session-log update:

- Appended a "Sub-session 2026-05-01" block to [`2026-04-30_md-inversion-and-three-country-validation.md`](file:///C:/git/ckt/.claude/worktrees/lca-inversion/quality_reports/session_logs/2026-04-30_md-inversion-and-three-country-validation.md) capturing the M11 read, the alternatives discussion, and the recommendation to pivot to `reg_sandwich`.
That block landed in commit `0938160` and is now the "morning" of the day's work; this file is the wrap-up.

Commits this session:

- `2208cbc` spec + methods review.
- `833a965` plan rev 3 (with the full three-pass review chain captured in the commit body).
- `0938160` 2026-04-30 session-log update.

## Decisions, with the why

Decision: pause the Stata-side wiring of inversion CIs into the production pipeline.
Why: the grc-pipeline-refactor branch has M11 (rename) and M3 (collapses four `grc_tex_table_trend*` programs into one).
M3 collides directly with our esttab `stats()` extension; M11 solves the 32-char block we hit at end of last session.
Doing the wiring on `lca-inversion` now means redoing it post-merge.
The chi-squared finite-sample work is fully decoupled and lives in `explorations/python-grc/`.

Decision: route the F adjustment through `reg_sandwich` (Stata), not a from-scratch Python port.
Why: three Red findings from the first plan-review on rev 1, all of which dissolve under Pustejovsky's own implementation.
PT 2018 had a 2023 corrigendum to Theorem 2 (multi-parameter Wald-Satterthwaite); SSC `reg_sandwich` is maintained by the same author and presumably tracks it.
The BRL-FE vs CR2 distinction is handled correctly by `reg_sandwich`'s design.
The "GMM-Wald-inversion bridge" turned out to be a framing issue: the inversion is OLS Wald on a linear restriction at each $\phi$, not GMM novelty; `reg_sandwich` applies directly.
Stata is already a hard project dependency; adding R was the cost we wanted to avoid, and `reg_sandwich` removes it.

Decision: Step 0a verifies `reg_sandwich`'s corrigendum compliance via GitHub commit-history pin.
Why: the SSC release may lag the 2023 corrigendum.
The LCA test is multi-parameter ($J_R = 4$ to $26$), so the corrigendum's regime is exactly ours.
Step 0a pulls the GitHub history at jepusto/clubSandwich-Stata, identifies the corrigendum-addressing commit, compares against SSC `.pkg` metadata, and falls back to `net install` from a pinned commit SHA if SSC lags.

Decision: Step 0a runs an FE-absorption A/B test (`i.trajectory` vs `absorb(trajectory)`) before locking the production OLS spec.
Why: `reg_sandwich.ado`'s source comments distinguish absorbed vs unabsorbed FE in the adjustment-matrix computation.
Our auxiliary OLS uses unabsorbed `i.trajectory` dummies; with $K = 27$ and $J_R = 26$, the unabsorbed path could near-singularly collapse the AHZ df.
A/B catches it in <2 hours; production specification is then locked.

Decision: Step 2 includes an explicit subprocess verification scaffold.
Why: Stata returns exit code 0 in batch mode even on script errors.
A silent failure during the 14-hour Step 3 simulation would corrupt coverage numbers and could not be distinguished from a genuine F-adjustment shortfall.
The scaffold checks (a) CSV existence, (b) row count = grid length, (c) no missing `ahz_pvalue`, (d) regex-scan of the `.log` for `r(\d+)` error codes, raising on any failure.

Decision: headline coverage runs at $R = 1000$, not the rev 1/rev 2 default of $R = 200$.
Why: MC SE at $R = 200$ is 0.018, too wide to call the $[0.92, 0.935]$ decision boundary cleanly.
$R = 1000$ gives MC SE 0.007 at $p = 0.95$, decisive at the cutoffs.

Decision: probe both $T=4, K=14$ and $T=5, K=27$ in synth coverage.
Why: $K = 14$ does not exercise IDN scale ($J_R = 26$), and the chi-squared bias scales with $J_R$.
A "gap closes at $K=14$" result without the $K=27$ check would not be enough evidence to trust F-adjusted IDN CIs.

Decision: contiguous-acceptance fallback rule (locked decision 4).
Why: per-grid $\widehat{\nu}$ varies across $\phi$, so the F critical value varies, and the acceptance region need not be an interval.
Pre-commit the rule rather than discover it during Step 5: if $(p - \alpha)$ has more than one sign change across the grid in a cell, fall back to single $\widehat{\nu}$ at the OLS point estimate.
The empirical-table footnote reports the per-country/spec fallback rate.

Decision: Step 3.5 (conditional WCB comparison) fires only if Step 3 lands in $[0.92, 0.935)$.
Why: PT 2018 simulations report HTZ achieving 0.94--0.95 at comparable cluster counts; if F-adj only delivers 0.92--0.935, a referee will ask "why not WCB?"
Step 3.5 pre-empts the question with a small ($R = 200$) `boottest` comparison in joint-syntax form.
We do not pay the 4-hour cost unless the trigger fires.

## Approaches rejected and the reason

Implementing CR2 + Satterthwaite from scratch in Python with a clubSandwich-via-R anchor (the rev 1 plan).
Why dropped: three Red findings from the methods review concentrated in the bridge derivation and the BRL-FE distinction; user explicitly objected to the novelty risk.

Wild cluster bootstrap as the primary correction (option 2 in the alternatives discussion).
Why dropped: user worried about extending OLS-developed methodology to MD, even though that concern dissolves on inspection (our test is OLS Wald not MD).
WCB is more expensive ($B \times $grid Walds per cell) and less directly cited than the F adjustment.

Hall-Horowitz (1996) bootstrap calibration as primary (option 3).
Why dropped: more expensive than WCB, harder to verify, and dominated by WCB on cluster-robust testing.

Empirically calibrated chi-squared quantiles via per-country Monte Carlo (option 4).
Why dropped: per-country DGP calibration; a referee could push back as circular.

clubSandwich-via-R-subprocess (option 1a) once `reg_sandwich` surfaced.
Why dropped: `reg_sandwich` is the same author's Stata implementation; Stata is already a hard project dependency, R is not.
No need to add R when Pustejovsky maintains both.

`pyfixest` as a Python equivalent of clubSandwich.
Why dropped: verified via web search that `pyfixest` explicitly supports CRV1 and CRV3 but NOT CRV2 (Bell-McCaffrey/CR2).
There is no maintained Python implementation of CR2 + Satterthwaite Wald as of May 2026.

## Open items going into next session

- Plan rev 3 was APPROVE'd by the third plan-review pass; no further structural revisions pending.
- Step 0 (`ssc install reg_sandwich` + AHZ-vs-HTZ $q \ge 2$ toy cross-check on a simulated balanced panel or `MortalityRates`) is the next concrete action.
- Step 0a (GitHub history check + FE-absorption A/B) follows immediately.
- Stata-pipeline integration of inversion CIs stays paused pending the `worktree-grc-pipeline-refactor` merge to main.
- Three TODOs in [`docs/TODO.md`](file:///C:/git/ckt/.claude/worktrees/lca-inversion/docs/TODO.md) remain open: WCB inversion (conditional on Step 3 outcome), empirically calibrated coverage test (independent path), Stata-pipeline integration (blocked).

## Picking back up

If you resume on `lca-inversion`:

Read [`quality_reports/plans/2026-05-01-f-adjustment-inversion.md`](file:///C:/git/ckt/.claude/worktrees/lca-inversion/quality_reports/plans/2026-05-01-f-adjustment-inversion.md) (rev 3) first.
The plan carries everything load-bearing: the locked decisions, the eight-step structure, the fallback rules, and the success criteria.
Read [`quality_reports/reviews/2026-05-01_f-adjustment-spec-methods-review.md`](file:///C:/git/ckt/.claude/worktrees/lca-inversion/quality_reports/reviews/2026-05-01_f-adjustment-spec-methods-review.md) only if you want the original four-major-finding rationale that drove the plan additions.

Open thread: F-adjustment via `reg_sandwich`, plan approved across three review passes, Step 0 ready to execute.

Next concrete action: `ssc install reg_sandwich` (user authorized SSC installs in this session), run an AHZ test on a multi-parameter ($q \ge 2$) toy contrast, capture the AHZ statistic / df / p-value as scalars from `r()` or `e()`, and cross-check against R `clubSandwich::Wald_test(test = "HTZ")` on the same toy data.
Tolerance: $10^{-4}$ on the statistic, $10^{-3}$ on the df.

State to know:

- Three commits this session on `lca-inversion`: `2208cbc` spec + methods review, `833a965` plan rev 3, `0938160` morning session-log update.
None pushed to remote.
- Working tree is clean except for `.claude/scheduled_tasks.lock` and `.claude/settings.local.json`, both gitignored-equivalent.
- The `prose-rules-enforcer` hook fired once early in the session; resets next session.
The post-edit-scan hook flagged em dash format violations twice and was satisfied each time after a small edit.
- User authorized SSC installs partway through; do not block on that for Step 0.
- The morning sub-session of 2026-05-01 lives in [`2026-04-30_md-inversion-and-three-country-validation.md`](file:///C:/git/ckt/.claude/worktrees/lca-inversion/quality_reports/session_logs/2026-04-30_md-inversion-and-three-country-validation.md).
The two logs together cover the whole day; this file holds the afternoon and the wrap-up.
- M11 short-naming convention is documented at [`STER_NAMING.md`](file:///C:/git/ckt/.claude/worktrees/grc-pipeline-refactor/RP7/scripts/STER_NAMING.md); when grc-pipeline-refactor merges, `5b_inversion.do` and `attach_inversion_ci` need to switch from `grc_<country>_urban_<spec>` to `grc_<country>_<spec3>_<covs2>` naming.
That is parallel to the F-adjustment work and lives in a different bucket of the TODO.
