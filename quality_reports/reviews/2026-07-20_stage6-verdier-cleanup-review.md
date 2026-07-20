# critic-stata review: Stage 6 diff (branch stage6-verdier-cleanup, commit b572508 plus working tree)

Date: 2026-07-20.
Reviewer: critic-stata (fresh context, diff-scoped).
Verdict: 93/100, no CRITICAL, no MAJOR; ready to commit.
Adjudication of the two actionable MINORs is recorded at the end.

## Findings as returned by the critic

F1 (informational; confirms the fix is real).
The pre-fix snapshot's own header documents the defect: the missing-`vfirst` drop "persists across calls within the same `use'", and `17_verdier_robust.do` loads each country once and calls the fitter ten times against that in-memory data, so any drop or leaked column from one cell previously bled into every later cell for that country, including after an errored cell.
The program-level `preserve` closes exactly this hole.

F2 (no residual issues in the preserve scoping).
The `preserve` sits after the skip-if-exists early exit and the data-free step resolution, so no mutation precedes the snapshot and the early exit never opens an unclosed preserve.
No explicit `restore` exists in the body, which is correct: Stata auto-restores when the program terminates, on success and on error alike.
The cluster-diagnostics tempfile round-trip saves before the destructive `duplicates drop`, so it is lossless, and `save_esample_marker`'s internal preserve executes at a nested program frame, which is legal.
An error inside the program (for example a `gmm` failure) propagates up, terminates the program, and triggers the same auto-restore; every caller wraps each call in `capture noisily`, so a failed cell no longer leaves mutated data for the next cell.

F3 (tail rename verified against the consumer and the old bug).
`grc_tex_table_trend_robust` builds stored names `<prefix><country>_<covs>_never` and `..._avg`; the new tail loads the on-disk `_n`/`_g` files into exactly those names.
The critic independently confirmed the old tail targeted files never written (only `_n`/`_g` exist on disk), reproducing the r(601) the leg A gate driver expects.

F4 (MINOR, watch-item): the worst-case stored name `_est_vv_CHN_os_covs_trend_never` is 31 characters, one under Stata's hard 32-character cap, so any future lengthening of the country tag (for example a hukou split `CHN_rf`) would overflow deep in the call chain with the confusing r(7).
Proposed: a defensive length assert at stem construction, and shorter covariate tags before any longer country tags.

F5 (MINOR): the contract test does not reset `$skip_if_exists`, so if it were ever `do`-chained inside a session where a sibling driver set the global to 1, both calls would silently skip estimation and compare stale sters against fresh expectations.
Proposed: `global skip_if_exists ""` at the top of the test, optionally erasing prior `ct6_*` artifacts.

F6 (MINOR, low confidence): the named leak check probes only the base trajectory's `swd_*` column; the column-count assert and `cf _all` already close the gap functionally, so at most a clarifying comment is warranted.

F7 (informational): hardcoded absolute paths in the gate and test drivers, the accepted project convention for this driver family.

## Adjudication (author sign-off pending)

F4 and F5 are accepted as cheap defensive fixes to apply within the stage if the author approves; neither blocks the gate.
F6 is declined beyond a clarifying comment (the surrounding checks already cover it); F7 is the accepted convention; F1-F3 require no action.
