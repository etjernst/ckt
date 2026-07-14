# Plan review: front-load the pipeline, staged with a tiered equivalence gate

PLAN REVIEW -- front-load the pipeline, staged with a tiered equivalence gate
Reviewing as: data engineering and reproducibility specialist
Plan source: C:/git/ckt/quality_reports/plans/2026-07-14-pipeline-frontload-refactor.md
Mode: solo
Depth: quick (web research skipped)

## Strengths

1. Strong golden-master discipline: a frozen baseline, non-destructive per-stage verification, atomic one-change stages, and gate artifacts committed alongside the code. This is characterization/regression testing done properly.
2. The tiered gate is well-reasoned. Separating provenance (exact) from byte-identity from tolerance-adjudicated reorders correctly handles float non-associativity under vce(cluster) without either false alarms or sloppy acceptance, and it names in advance which stages are allowed to reach Tier 3.
3. It correctly diagnoses the stale-hub trap and rebases the baseline off a fresh refit rather than the pre-Change-A sters, with three checkable on-disk commit signatures as the characterization target.
4. Self-checking determinism probes are built in (IDN_unb byte-compare, double-fit of panel cells) rather than assumed.
5. Human gates are cleanly separated: mechanical consistency stages auto-gate; correctness, estimand, figure, and D-1/2/3 changes require author sign-off.
6. Raw immutability is respected: rebuild to a fresh location, junction to raw, and an explicit exclusion of the one do-file that writes into raw.
7. The single claim-affecting consequence of the per-capita rescaling (TZA 11b) is already probed and quantified up front (D-3), so no surprise at the end.

## Weaknesses and gaps

[Red] Reproducibility environment unpinned -- Byte-identity is undefined without a pinned Stata version/build, deterministic sort (Stata sorts are not stable on ties unless forced), and controlled RNG; a single Stata patch or an unstable sort silently breaks Tier 2 across every stage, and Stages 1-2 have no fallback path when byte-identity is required but unattainable. -> Fix: record and pin the Stata version and ado/package set, enforce `sort, stable`/`set sortseed`, audit the pipeline for any randomized step, and define the fallback (drop affected stages to Tier-3 tolerance) explicitly.

[Red] Determinism proof sequenced last -- The whole gate design rests on byte-reproducibility being attainable on the current machine, yet that proof is step five of Stage 0, after the full rebuild, characterization, re-runs, and sign-off are already sunk. If it fails there, the tiering premise collapses with maximum wasted work and no Plan B. -> Fix: promote the determinism proof plus a harness self-test to a fail-fast preflight before the rebuild; only proceed once byte-identity is confirmed on this machine, and branch the plan if it is not.

[Yellow] Common-mode baseline error uncatchable -- The entire gate validates against a self-generated Stage 0 baseline, and the only cross-check is "every old-vs-fresh difference matches one of three signatures." That catches unexpected differences but not an error present in BOTH hubs (a bug shared by the code both runs), so a systematic fault passes all stages and surfaces only in the paper. -> Fix: add an independent coefficient-level cross-check of the new baseline against the old sters modulo the three known changes, and require author review of the characterization diff, not just sign-off on promotion.

[Yellow] Correctness stages never exercise the new contract -- Stages 5 and 6 prove only that behavior is byte-identical today (zero missingness); they do not verify the changed logic does the right thing when the contract IS exercised, so they are unverified fixes dressed as no-ops. -> Fix: add a synthetic case that injects missingness/varying samples and asserts the new e(sample)-keyed and baseline-reset paths produce the intended result.

[Yellow] Panel-only adjudication -- Coverage and every Tier-3 "accept and record" decision are validated only on the fast gate panel; a reorder benign on the panel but material on the full population, or a regression in an unsampled path, ships undetected to the definitive run. -> Fix: measure panel path coverage rather than asserting it, and re-adjudicate all Tier-3 acceptances against the full-population sweep at the end.

[Yellow] Harness is load-bearing but unscheduled -- The %24.16e dump, provenance table, and diff tool are assumed to exist; building and validating them is unestimated, and a harness bug silently green-lights bad stages. -> Fix: schedule harness construction as an explicit Stage 0 sub-step and self-test it against a known-good and a deliberately-perturbed pair before trusting any gate result.

[Yellow] Tolerance undefined near zero -- "relative 1e-10" has no absolute floor, so coefficients near zero blow up relative error and either false-fail or mask real drift. -> Fix: specify a mixed criterion (max of absolute and relative, with a stated absolute floor).

[Yellow] Total delivery freeze with no contingency -- Nothing ships to coauthors or Overleaf across all ten stages until the final definitive run; there is no interim checkpoint and no timeline fallback if Stage 0 characterization fails to reconcile. -> Fix: define a delivery checkpoint after Stage 0 plus the scale/Change-A definitive update so corrected current tables can ship, and communicate the freeze window.

[Green] Stage 8 sequenced against Stage 0's workaround -- Stage 0 explicitly works around CHN_hukou writing into raw, but the raw/processed separation that fixes that is deferred to Stage 8, and late reader-repointing risks invalidating the frozen baseline's paths. -> Fix: consider relocating the derived CHN_hukou files before or with the Stage 0 rebuild.

[Green] Not executable by an unfamiliar operator -- Anchor strings ("the hand-redeclarations", "the central one in run_grc_with_extra_regressor"), the concrete gate-panel cell list, and the $dirdata driver are described by property, not enumerated. -> Fix: attach an appendix with the exact anchors, the explicit panel cells (including the named switcher-sparse cell), and the driver/junction commands.

[Green] Per-stage rollback unspecified -- Recovery beyond "commit with gate artifact" is undefined for a mid-stage hard-stop, especially any promoted artifact. -> Fix: adopt branch-per-stage and document the revert path, including promoted hubs/outputs.

## Verdict: REVISE

The strategy is above average and the tiered golden-master design is the right tool for this job, so this is a revise-and-proceed, not a redesign. But two gaps are genuinely blocking for a plan whose entire value proposition is byte-equivalence: the reproducibility environment is unpinned (version, sort stability, seeds), and the one experiment that proves byte-identity is even attainable is buried at the end of the riskiest stage instead of run first. Both are cheap to fix and convert the plan to an approve. Alongside them, close the common-mode baseline check, make the two "correctness" stages actually exercise their new contracts, and pin down the harness and tolerance definitions before Stage 0 begins.
