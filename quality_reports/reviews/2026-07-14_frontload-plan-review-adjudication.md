# Adjudication of the plan review: front-load refactor

Review adjudicated: [2026-07-14-pipeline-frontload-refactor-review.md](file:///C:/git/ckt/quality_reports/reviews/2026-07-14-pipeline-frontload-refactor-review.md).
Plan under review: [2026-07-14-pipeline-frontload-refactor.md](file:///C:/git/ckt/quality_reports/plans/2026-07-14-pipeline-frontload-refactor.md).
Adjudicator: session model, 2026-07-14 evening.

Overall: the review is high quality and the REVISE verdict is fair.
Both Reds are directionally right but overstate the blast radius; their fixes are cheap and worth folding in.
Of the eleven findings, I recommend accepting seven (some in part), rejecting two with reasons, and treating two as covered with a one-line tightening.

## Red 1, reproducibility environment unpinned: accept in part

The plan's current wording lost detail my earlier revision should have kept: the pre-revision Stage 0 pinned `version`, Stata flavor, MP core count, and the installed package set, and the rewrite compressed that to "StataNow 19.5 MP, 4 processors".
Restore the full pinning list.

The sort-stability point is technically correct but needs sharpening for this pipeline.
Stata's `sort` is not stable on ties, and tie order depends on the sortseed state.
Batch runs (`stata-mp -e`) reset that state identically at launch, which is why the April M4 verification observed bit-identical refits across runs; run-to-run determinism on unchanged code is therefore expected to hold without new settings.
The real exposure is different: a code change that alters the number or order of sorts executed before a tied sort can flip tie order and fire a spurious Tier 2 red on a benign edit.
Stages 1 and 2 remove no-op `replace`s and global redeclarations, which execute no sorts, so their byte-identity expectation stands.
Fix folded in: document the sortseed mechanism in the gate section, and state the Tier 2 failure path explicitly: stop, diagnose; if the diff traces to tie order alone (provenance exact, coefficients within the Tier 3 criterion), record it and adjudicate that stage at Tier 3 rather than abandoning the gate.

RNG: the mainline pipeline has no randomized step (no bootstrap, no simulation; GMM is deterministic given data and starting values).
Fix folded in: one sentence asserting this, checked once during Stage 0.

## Red 2, determinism proof sequenced last: accept in part

The sequencing logic is right and the fix is cheap, so accept the fix.
But the claimed blast radius is overstated: the rebuild and characterization are needed regardless of the gate design (the hub is stale relative to committed source no matter how we verify refactor stages), and both are minutes of machine time.
The only work genuinely contingent on the tiering premise is the gate itself.
Fix folded in: run a fail-fast determinism preflight, a double-fit of one fast GRC cell byte-compared against itself, before or in parallel with the rebuild.
Determinism is a property of machine plus code, not of which hub is loaded, so the preflight can run on the current hub immediately.
The April M4 result already gives one observed instance of byte-identical refits; the preflight makes it current rather than historical.

## Yellow, common-mode baseline error: accept in part

Correct as stated: a bug shared by both code generations passes every characterization check.
That limitation is inherent to golden-master testing and the five-reader consistency audit plus the correctness stages (5, 6, 7) are the compensating controls, so no new machinery is warranted.
Fix folded in: make the Stage 0 sign-off explicitly a review of the characterization artifact (the attributed cell-by-cell diff and the OLS movement table), not a bare approval to promote.

## Yellow, Stages 5 and 6 never exercise the new contract: accept

Correct, and the fix is cheap.
As written, both stages prove only byte-identity on data with zero missingness, which cannot distinguish the new code from the old.
Fix folded in: each stage adds a synthetic contract test, a scratch dataset with injected missingness (and, for Stage 6, a spec sequence where the `vfirst` drop would have persisted) asserting the `e(sample)`-keyed CI and the reset per-spec sample produce the intended result.
The synthetic tests live with the stage's gate artifact.

## Yellow, panel-only Tier 3 adjudication: accept in part

The plan already sends the full population through the end sweep; what it lacked is closing the loop on Tier 3 acceptances made along the way.
Fix folded in: the end sweep re-adjudicates every recorded Tier 3 acceptance against the full population, and any cell exceeding the tolerance there reopens the stage that accepted it.
Formal path-coverage measurement is rejected as overkill; the Green appendix fix (enumerate the panel cells) makes coverage inspectable by eye, which is proportionate.

## Yellow, harness unscheduled and untested: accept the self-test

The harness is already a scheduled Stage 0 deliverable (`gate_harness.do`, drafted), so the scheduling half is moot.
The self-test half is a good, cheap idea.
Fix folded in: before the harness gates anything, it must pass a two-case self-test, one known-good pair (a ster against itself) that must pass all tiers, and one deliberately perturbed pair (a coefficient nudged at the 12th decimal) that must fail Tier 2 and trip the tolerance check when the nudge exceeds it.

## Yellow, tolerance undefined near zero: accept

Technically correct: a relative-only criterion explodes for coefficients near zero.
Fix folded in: the Tier 3 criterion becomes mixed, pass iff |new - old| <= max(1e-12, 1e-10 x |old|) per element of `e(b)` and `e(V)`.

## Yellow, delivery freeze with no interim checkpoint: reject, surface to author

An interim ship after Stage 0 would send OLS tables on the new hub (per-capita, Change A) alongside GRC tables still fit on pre-Change-A samples, a mixed-generation set that is worse than the current internally-consistent stale set.
The freeze until the single definitive run is the coherent consequence of running the expensive GRC refit exactly once, late, which is the author's explicit cost decision of 2026-07-14.
The timeline itself is the author's call and is surfaced here rather than planned around.

## Green, relocate CHN_hukou files before the rebuild: reject

Moving the derived files out of `data/countries/` before Stage 0 means editing reader paths before the baseline exists, exactly the kind of unguarded pipeline edit the plan exists to prevent.
The Stage 0 workaround only reads the existing files, which is safe, and Stage 8 does the move under the gate.
The reviewer's concern about late repointing invalidating baseline paths does not bite: the gate compares estimation output, not path strings, and Stage 8 ends with a full clean run of the cleaning path.

## Green, not executable by an unfamiliar operator: accept

Fix folded in: an appendix enumerating the gate panel cells explicitly (including the named switcher-sparse CHN hukou cell), plus pointers to the committed driver and harness files once they exist; anchor strings for the Stage 1 and 2 edit sites already live in the Stage 0 no-op inventory, which the appendix references rather than duplicates.

## Green, per-stage rollback unspecified: accept, one line

Mostly covered: the old hub is kept as a backup until the definitive run, and branch-per-feature is the standing git convention.
Fix folded in: one sentence stating the revert path, each stage is a branch, a mid-stage hard-stop reverts the branch, and un-promoting the hub means repointing back to the retained backup.

## Disposition

Accepted fixes to fold into the plan: environment pinning restored in full plus sortseed documentation and the Tier 2 failure path (Red 1), the determinism preflight (Red 2), sign-off as characterization review (common-mode), synthetic contract tests for Stages 5 and 6, end-sweep re-adjudication of Tier 3 acceptances, the harness self-test, the mixed tolerance criterion, the executability appendix, and the rollback sentence.
Rejected: the interim delivery checkpoint (mixed-generation tables; timeline is the author's call) and pre-Stage 0 relocation of the CHN_hukou files (unguarded edit before a baseline exists).
