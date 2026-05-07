# Audit action plan (2026-04-29)

Tracks user decisions on every finding in [quality_reports/reviews/2026-04-28_pipeline-best-practices.md](file:///C:/git/ckt/.claude/worktrees/grc-pipeline-refactor/quality_reports/reviews/2026-04-28_pipeline-best-practices.md).
Status legend: NOW = do this session; POST-T3 = do after Tier 3 finishes; TODO = backlog; WAIT = needs user input; SKIP = won't do.

## RP7 pipeline findings

| ID | User decision | Status | Notes |
|----|--------------|--------|-------|
| C1 (run_grc_hukou timer) | Crash imminent (~30 min); user to decide kill-vs-let-crash | WAIT | Surface explicitly when 8_GrRC_hukou nears |
| C2 ($lnsize undefined) | Kill it everywhere | POST-T3 | Already in cleanup queue |
| M1 (no version 17) | Add to 0_master.do | NOW | Single line, top of master |
| M2 (set more off) | Add to 0_master.do; master-log idea retracted | NOW | Already in TODO; master log dropped |
| M3 (merge nogen) | Write `assert_merge_clean` helper, drop `nogen`, use it; helper prints diagnostic and drops `_merge` | DONE 2026-04-29 | Helper in 0_programs.do (commit f2f392c); retrofit at all 3 trajectory-group merge sites with `allow(1 3)` (commit ac8f3f6) |
| M4 (doubled mu loop) | Investigate: write a test on simulated data to check whether it actually doubles the string or overwrites | DONE 2026-04-29 | Test ran; macro doubles 1.88x, gmm fits identical with same-value duplicates. Cleanup of second loop deferred to Implementation-mode commit |
| M5 (run_grc_hukou no phistart) | Add `phistart` option | TODO | Mirror `run_grc` syntax |
| M6 (summary_stats CSV in cwd) | CSV is one-trip iebaltab intermediate. Fix: save to a logical repo path AND erase via Stata after import delimited. Potential rewrite of country_summary_stats* programs deferred. | NOW (path + erase) + TODO (rewrite) | iebaltab is CSV-only; no clean way around the round-trip without a different package |
| M7 (ugrc_regressions shadow eststo) | Very very important, fix it | NOW | Two fix options to surface (A: rename first eststo; B: also add `if regression_sample` to col-7) |
| M8 (initial_values in make_tables) | Keep---needed for freestanding `make_tables.do` (in case ster results exist but we haven't run setup) | SKIP | User clarified: this is intentional |
| m1 (cd "$logs" everywhere) | Fix everywhere; should always be `log using "$logs/..."` | NOW (partial) | Tier 3 still uses 5/6/8/GRC_extras---defer those until run finishes |
| m2 (cap vs capture) | Genuinely minor; convert all to `capture` | DONE 2026-04-29 | Bulk pass over 0_programs.do; 34 occurrences (commit ac8f3f6) |
| m3 (magic 5) | Set as a global in master (set once) | NOW | `global grc_min_switchers_per_wave 5` in 0_master.do |
| m4 (magic 100 iterations) | Set as a global in master (always set once) | NOW | `global grc_max_iter 100` in 0_master.do |
| m5 (deprecated grc_tex_table) | Get rid of it | NOW | Delete ~80 lines from 0_programs.do |
| m6 (2waves/3waves hardcoded enumeration) | Investigated: _2waves/_3waves variants drive distinct descriptive outputs (trajectories_2waves.pdf, trajectories_3waves.pdf), not vestigial. Trajectory string encoding will never change so brittleness concern is moot. SKIP brittleness fix; possible future TODO: unify all three under parameterized `handle_trajectory_groups_window(n_waves)` | SKIP (+ future TODO) | User confirmed leave for now |
| m7 (set obs 19) | No big deal | SKIP |  |
| m8 (graph save in cwd) | Use tempfile but keep .gph for re-runs (some runs take long); ambivalent | TODO | Defer; not urgent |
| m10 (label define mega_trajectories) | Add `replace` | NOW | 9 occurrences in make_figures.do |
| m11 (make_tables.do header) | Update | NOW | Replace with concise header |
| m12 ($overleaf fallback) | Move into user-specific blocks (everyone has different overleaf paths) | NOW | Move from 0_path_config.do fallback into per-user blocks in 0_master.do |
| m13 (data_path_override expansion) | Don't understand---explain better | NOW | Re-explain; below |
| m14 (schemepack install bug) | Add to TODO list | TODO |  |
| m15 (trajectory PDFs no PNG) | Good catch; add | NOW | 3 graph export lines in make_figures.do |
| m16 (panel headers hardcoded) | Add to TODO list | TODO |  |
| m17 (Kleemans dual `global dir`) | Her problem not mine | SKIP | She probably comments one out |

## Out-of-scope cleanups landed during the audit close-out

These came up while working through the audit findings, were either bug fixes or refactor opportunities, and got committed alongside the audit work even though they were not on the original audit list.

| Item | Status | Notes |
|------|--------|-------|
| Two `_smoke_full.do` crash bugs (escape sequence, globals scope) | DONE 2026-04-29 | `\"<path>\"` escape in 0_path_config.do; `$grc_max_iter` / `$grc_min_switchers_per_wave` set in 0_master.do but smoke driver bypasses master. Both fixed in commits `3959874` and `cc94d3e`. |
| Stata timer slot 1-100 limit hit at slot 101 (Tier 3 #3 crash) | DONE 2026-04-30 | Wrap counter at 100 in `run_grc` / `run_grc_onestep` / `run_grc_hukou`; `timer clear` before reuse since `timer on` accumulates. Commit `5c21224`. |
| `run_grc_hukou` merged into `run_grc` | DONE 2026-04-30 | Folded the four-ster duplicate program into `run_grc` with `capture noisily` wrappers around the joint mu test and Δ_d block (Option B per user). Commit `5c3308b`. Verified end-to-end via `_smoke_hukou_only.do` on 30 ro+uo cells: 150 sters, zero capture fires, 50 min wall. |

## Data-creation findings (Dropbox)

User: come back to the pipeline review for the sections on data construction since I don't have time now.

All five major and seven minor findings deferred to a future review session.
Key reminders for that session:

- DC-M1, DC-M2: real data-quality risks (TZA inner join silent attrition; IDN hhsize unconditional replace).
- DC-M3: undocumented deflation base year for IDN/CHN.
- The real-vs-nominal divergence appendix is the practical input for the planned "collapse two parallel scripts into one with a switch" refactor.

## Open questions waiting on user

1. C1 timing.
Tier 3 will crash on `run_grc_hukou` timer in ~30 min.
Kill now or let it crash and resume?

2. M6.
What's the destiny of `summary_stats_<country>_<balance>.csv`?
Becomes a LaTeX table?
Intermediate?
Discardable?

3. M7 fix flavor.
A: rename the first sample-defining `eststo` to `tmp_<country>` so reg7 keeps the trajectory-decomposed result, but col 7 runs on full sample (not `regression_sample`).
B: same rename PLUS add `if regression_sample` to the second eststo so col 7 matches cols 1-6 sample.
The original comment "Run col 7 first as it has the smallest sample, then use e(sample)" suggests B.

4. m6.
Why do `_2waves` / `_3waves` variants of `handle_trajectory_groups` exist?
Are they fundamentally different, or could they be unified now that the string encoding is stable?

## Reminder pile

- After Tier 3 finishes: kill `$lnsize` everywhere (5_GrRC, 8_GrRC_hukou, run_grc_with_extra_regressor's KEEPLNsize option).
- After Tier 3 finishes: flip `_smoke_full.do` default to `skip_if_exists 0`; create `_smoke_resume.do` for resume mode.
- After Tier 3 finishes: m1 cd-pattern fixes for 5/6/8/GRC_extras.
- Come back to data-construction audit findings (DC-M1 through DC-M5, DC-m1 through DC-m7).
- Investigate m6 rationale (2waves/3waves variants) before proposing a fix.