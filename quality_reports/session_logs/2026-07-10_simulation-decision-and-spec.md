# 2026-07-10 --- Simulation cost-benefit, ECMA framing edits, extension-study spec

## If you resume

One-line state: the extension-simulation plan is APPROVED (Emilia, 2026-07-10 evening, after the external-review dispositions were folded in), stage P0 is DONE and gate-passed on the new `extension-sims` worktree, and the open thread is stage P1.

Read first, in order:
1. The plan (approved, governs stages): [quality_reports/plans/2026-07-10-extension-simulation-study.md](file:///C:/git/ckt/quality_reports/plans/2026-07-10-extension-simulation-study.md).
2. The spec (amended same evening: M1-M5, M8, new D6, new MAY M-c): [quality_reports/specs/2026-07-10-extension-simulation-study.md](file:///C:/git/ckt/quality_reports/specs/2026-07-10-extension-simulation-study.md).
3. The external-review dispositions with Emilia's rulings: [quality_reports/reviews/2026-07-10_external-simulation-review-dispositions.md](file:///C:/git/ckt/quality_reports/reviews/2026-07-10_external-simulation-review-dispositions.md).

Next concrete action (P1, in the worktree): build `sims/src/calibrate.py` plus `sims/src/config.py`; read the hub `C:/git/ckt/RP7/data/processed/{IDN,TZA}_unb.dta` and `C:/git/ckt/RP7/output/counterfactual_inputs/{IDN,TZA}_e1_*.csv` READ-ONLY; snapshot design matrices to `sims/data/*.parquet` (gitignored); extract per-cell parameters INCLUDING the within-person residual autocovariance (the dependent-error baseline is now spec M2, not a disclosure); emit per-cell configs and a calibration report.
The P1 gate (a zero-noise simulated panel reproduces the calibration targets exactly) needs a minimal `dgp.py` stub, so start that alongside.
Mechanical extraction legs go to `model: "sonnet"` subagents per rules/model-routing.md; calibration design choices stay in the main thread.

Cached state:
- Worktree `C:/git/ckt/.claude/worktrees/extension-sims`, branch `worktree-extension-sims`, tip `0a1a307`; deliberately NO junctions into it (plan decision D), so the P1 hub reads are the only contact with shared state.
- P0 gate PASSED: headless import of `sims/src/grc_gmm.py` (md5 `d66dbac7d085b76ac06061f6a062b6b8`) and `sims/src/lca_inversion.py` (md5 `dbc5ba2f1115d0b948626f8043861378`), byte copies of `explorations/python-grc/`; joblib 1.4.2 and pyarrow 14.0.2 confirmed in the Anaconda env.
- Main-tree commits this evening: `7b7aab6` (dispositions memo), `7e43b56` (plan and spec amendments), `2f3bd4b` (MAY M-c), `84c5274` (plan approved), `a7091ad` (session log).
- Emilia's rulings on the three open decisions: fold in all adopted dispositions (done); the J-parity failure branch is decided AT the P2 gate, not pre-committed; server transfer is NOT a governance blocker (replication data fully public), with a moments-only config as the fallback if a host requires it.
- The next EMILIA DECISION POINT is P5a (full-run budget and venue); the P1-P4 gates are self-checking.

Carried-over items not on this thread: the hukou stub footnote in Overleaf `main-updated.tex` ~line 761 (her call), two stale `main-updated.tex.tmp.48680.*` files in the Overleaf root (flagged, not deleted), whether `11b_extrapolation_support_figure.do` gets wired into `0_master.do` (her call), and her server-compute access investigation (now feeding P5a).

Read first, in order:
1. The plan: [quality_reports/plans/2026-07-10-extension-simulation-study.md](file:///C:/git/ckt/quality_reports/plans/2026-07-10-extension-simulation-study.md) (commits e665460 draft, b2bc645 post-review, dc8f008 conventions audit).
2. The spec: [quality_reports/specs/2026-07-10-extension-simulation-study.md](file:///C:/git/ckt/quality_reports/specs/2026-07-10-extension-simulation-study.md); the plan's M/S/D references resolve only against this spec.
3. The review record: [quality_reports/reviews/2026-07-10_simulation-plan-review.md](file:///C:/git/ckt/quality_reports/reviews/2026-07-10_simulation-plan-review.md).

If Emilia wants to send the plan out for external review, the minimum packet is the spec plus the plan, since the plan's M/S/D references resolve only against the spec.
Optional additions are the cost-benefit memo ([docs/notes/2026-07-10_simulation-cost-benefit.md](file:///C:/git/ckt/docs/notes/2026-07-10_simulation-cost-benefit.md)) and the review record; a concatenated, self-contained packet was offered and she has not yet asked for it.

Four plan decisions she probed at length but has not formally confirmed:
1. Decision A, the fixed-design DGP.
2. Decision B, inversion-CI-first coverage with a time-boxed SE/J fix; she accepted this reluctantly ("not too excited but fine it's important").
3. Decision C, the arm-3 dial anchored to the CHN hukou-gap magnitude; China is not itself a simulation cell, only the dial's anchor, a distinction that needed clarifying.
4. Decision D, the pilot-first compute gate, which she endorsed.

Two side items from earlier today are fully done and need no further action.
The in-support figure and its robustness subsection are both in the paper, and the figure's canonical generator is now [RP7/scripts/11b_extrapolation_support_figure.do](file:///C:/git/ckt/RP7/scripts/11b_extrapolation_support_figure.do); the old explorations copy is deleted.
Any future figure tweak: edit that file, run it with `stata-mp -e do 11b_extrapolation_support_figure.do` from `RP7/scripts` (never `-b`, which pops a completion modal), then copy `RP7/output/figures/extrapolation_support_combined.pdf` to the Overleaf `figures/` folder.

Other open items, none blocking:
- The hukou stub footnote in `main-updated.tex` around line 761 is Emilia's decision to make; untouched.
- Two stale `main-updated.tex.tmp.48680.*` files sit in the Overleaf root; flagged, not deleted.
- Whether `11b_extrapolation_support_figure.do` gets wired into `0_master.do` is undecided; it changes the coauthor-facing pipeline, so it needs Emilia's call.
- Emilia's server-compute investigation (plan decision D4) is still open.

## Mode

Advisory (cost-benefit memo) then Implementation entry (spec written and approved; plan not yet written). Plus approved Overleaf paper edits (maintenance-sized, user-authorized each).

## Goals and what happened

Emilia asked whether the paper needs simulations to validate the estimator before ECMA submission, whether their absence changes referee composition or pr(reject), and whether to deliberately leave the ask for referees.
The answer evolved across three corrections and is fully recorded in the memo; the short version: TGMBLM (the comment on Suri 2011, ACCEPTED AT ECONOMETRICA) validates the base GrRC machinery at $T=2$ with one Wald restriction; CKT's claim is the extension (general $T$, many trajectories, unbalanced pooling, extrapolated estimands, counterfactual-aggregate inference), which has no finite-sample evidence anywhere and is exactly where the chi-squared inversion's documented failure mode (bias growing with $J_R$; generic-synth coverage 0.84 at $J_R=13$ vs IDN's 26) lives.
Decision: three-arm extension study in the submitted draft (appendix + main-text pointer); J-test power and OLS/FE-vs-GRC gap exercises deliberately left as referee asks.

## Paper and bib edits (all in the Overleaf folder, all user-authorized, all compiled clean)

- `CKT.bib`: `tjernstromCommentSuri2011` upgraded `@misc`/Working paper to `@article`, `journal={Econometrica}`, `note={Forthcoming}`; verified the bbl renders "\textit{Econometrica}, forthcoming."
- `main-updated.tex` lines ~97-99: the innovation claim now attributes the GRC cast to the comment paper and claims the EXTENSION (longer panels, more trajectories, unbalanced histories, weak-ID robust inference reaching trajectory-specific returns and counterfactual aggregates) as CKT's methodological contribution. Rationale: with the cast published at ECMA in the comment, claiming it reads as overreach to exactly the referee pool the team wants.
- `main-updated.tex` after the LCA-restriction sign paragraph (~line 405): new identification-plausibility paragraph. Emilia caught a real contradiction in my first draft ("selection operates through factors that do not enter returns" contradicts Roy sorting on $\theta$); the inserted version conditions on comparative advantage: given $\theta_i$, the REMAINING determinants of staying (costs, family ties, institutions) must not enter returns. The Suri-setting contrast was demoted to a softened footnote at her request (read as "backstabby" in the main text). Closing sentence frames the hukou J-test rejection as the framework detecting the boundary of the logic.
- Compile state after all edits: zero errors, zero undefined citations; the only undefined reference remains the hukou stub footnote (now line ~761), which is EMILIA'S OPEN DECISION (delete vs point at appendix hukou tables)---do not touch. Aux files swept.

## Decisions, with the why

- ECMA target + econometric-referee preference + TGMBLM acceptance all stated by Emilia today; recorded in [project_submission_target_ecma.md](file:///C:/Users/maand/.claude/projects/C--git-ckt/memory/project_submission_target_ecma.md).
- IDN+TZA cells only: Emilia judged the flat-$\phi$ CHN urban-first cell a poor simulation case; independently, LCA-true calibration is ill-posed there (unbounded empirical $\phi$ region makes any "true" value arbitrary).
- Two-regime violation family first because it converts the paper's pooled-China rejection into designed-and-demonstrated behavior.
- In-support diagnostic: NOT in the paper anywhere (checked). Artifacts: [docs/notes/2026-05-18_extrapolation_support_diagnostic.md](file:///C:/git/ckt/docs/notes/2026-05-18_extrapolation_support_diagnostic.md) + the exploration do-file; TODO entry exists to promote the figure. I argued for placing it where $\hat\Delta_{d_N}$ is first reported (identification support, not robustness); Emilia had guessed robustness section; NOT YET RESOLVED---she hasn't ruled.

## Open items

- Write the implementation plan (the handoff above).
- Emilia: server compute access investigation (D4).
- Emilia: hukou stub footnote decision (carried over).
- RESOLVED 12:26: the in-support figure goes in ROBUSTNESS, first thing next session (see the resume block).
- New TODO added: quadratic comparative-advantage restriction as an empirical robustness row (estimate quadratic GRC, test $\phi_2=0$, report $\Delta_{d_N}$ movement); Emilia confirmed the logic (if truly linear, $\hat\phi_2 \to 0$). Pairs with the in-support figure and the sim study's curvature arm.
- The two remaining pocket exercises stay deliberately unbuilt.

---

# Afternoon continuation (13:26-15:45): figure shipped, subsection inserted, plan drafted and reviewed

## State as of 15:45 (superseded by the top resume block)

Both morning handoff tasks are DONE.
The single open thread: the implementation plan for the extension simulation study is DRAFTED, fresh-context REVIEWED, amended, and AWAITING EMILIA'S APPROVAL at [quality_reports/plans/2026-07-10-extension-simulation-study.md](file:///C:/git/ckt/quality_reports/plans/2026-07-10-extension-simulation-study.md).
Do not start P0 (worktree scaffold) until she approves.
She may instead hand the plan to an external reviewer first; the packet is spec + plan (the plan's M/S/D references resolve only against the spec), optionally the cost-benefit memo and the review record; she was offered a concatenated self-contained version and has not yet asked for it.
Four plan decisions carry recommendations she has probed but not formally confirmed: A fixed-design DGP (she asked what endogenous would look like; explained), B inversion-CI-first coverage with time-boxed SE/J fix ("not too excited but fine it's important"), C arm-3 dial anchored to the CHN hukou gap magnitude (clarified China is NOT a cell, only the dial anchor; she thought this meant China was back in), D pilot-first compute gate (she endorsed).

## Task 1: in-support figure (DONE, five feedback rounds)

Final figure: [RP7/output/figures/extrapolation_support_combined.pdf](file:///C:/git/ckt/RP7/output/figures/extrapolation_support_combined.pdf), copied to Overleaf figures/ (additive).
Generator: [explorations/2026-05-18_extrapolation_support_diagnostic.do](file:///C:/git/ckt/explorations/2026-05-18_extrapolation_support_diagnostic.do) (main tree copy is canonical now; $dir fallback repointed to C:/git/ckt/RP7).
Design settled through Emilia's iterations: lumped densities + gray per-trajectory rug (chosen over the 27-density per-trajectory spaghetti; she asked what rug plots are, kept them once explained), cranberry/blue palette (she vetoed orange+blue), NO hull min/max lines (she leaned drop, rug carries it), solid transparent medthick never-migrant mean line, direct labels on EVERY panel (Never-migrants, Switchers, Never-migrant mean, two-line gray "Switcher trajectory means"), rug label side+offset now per-country driver args (IDN left; CHN right 0.05; TZA right 0.02), paper order IDN-CHN-TZA, Density ytitle leftmost only, common-grid kdensity evaluation (kills the IDN truncation cliff), tight integer x ticks.
Numbers unchanged from the 2026-05-18 memo (verified: 10.21/[9.82,11.31]; 11.83/[11.50,12.83]; 14.57/[14.51,15.35]).
Commits: 90ab111, 4ed9e25, eda8c09, ae4401b, 1cc69cf.
LESSON RE-LEARNED: run batch Stata with `stata-mp -e` (never `-b`, which always pops the completion modal); body wrapped in capture-noisily. Emilia caught two popups before I fixed it.

## Task 2: robustness subsection (DONE, Emilia approved the text verbatim)

New subsection "Support for the never-migrant extrapolation" (label subsec:extrapolation-support) + figure env (label fig:extrapolation_support) inserted at the END of the robustness section of Overleaf main-updated.tex, after the cluster-pooling subsection.
Text approved by Emilia 14:0x ("The text is quite nice feel free to insert it"); descriptive clauses were updated to the final figure (no hull lines, solid line) before insertion.
Compiled clean twice; only undefined ref remains the pre-existing hukou stub (line ~761, Emilia's open decision, untouched); aux swept.
Two stale `main-updated.tex.tmp.48680.*` files sit in the Overleaf root from an earlier session; flagged, she has not said delete.

## Task 3: simulation implementation plan (drafted, reviewed, amended; NOT yet approved)

Plan: [quality_reports/plans/2026-07-10-extension-simulation-study.md](file:///C:/git/ckt/quality_reports/plans/2026-07-10-extension-simulation-study.md) (commits e665460 draft, b2bc645 post-review, dc8f008 conventions audit).
Review record with per-finding dispositions: [quality_reports/reviews/2026-07-10_simulation-plan-review.md](file:///C:/git/ckt/quality_reports/reviews/2026-07-10_simulation-plan-review.md) (fresh-context critic, session-model tier, plan+spec only per the clean-prompt rule; verdict REVISE; all 13 findings adopted except its unverified claim that IDN $\hat\phi = -2.44$---the exporter CSV says $-0.5247$).
Load-bearing design facts discovered en route (Explore/sonnet code survey):
- The two grc_gmm.py copies (simulations vs lca-inversion worktrees) are byte-identical; ~16 min/fit at IDN full N; SE($\phi$) known broken (~2.75x Stata, pinv rank-deficiency, BLOCKER.md item A); Hansen J ALSO differs from Stata (97.74@29df vs 86.52@27df, collinear-column handling)---both go in the P2 time box.
- The inversion CIs (lca_inversion.py compute_all_inversion_cis) run entirely off a cheap auxiliary saturated OLS, never the GMM variance---this is what makes decision B safe. Five chi2.cdf call sites are the M9 F-adjustment plug-in points. Delta inversions are minimized-Wald, so the BMS df adjustment is not mechanical there.
- Delta_unb is NOT among the four inverted parameters (the review's CRITICAL); its CI comes from the auxiliary-OLS Wald on U_i x D_it.
- synth_overid.py configures via module globals (unusable as-is; refactor into config dataclass planned).
Plan cornerstones: fixed-design DGP (trajectories/patterns/X held at empirical design; only unobservables simulated; truths closed-form), truth-definitions section (lumped cell weighting-invariant by within-cell homogeneity; two-regime pooled truths regime-share-weighted), island-membership coverage, per-cell grid bounds + hit-bound flags, stages P0-P10 with hard gates at P2 (harness sanity vs production estimates) and P5 (R=20 pilot -> compute memo -> Emilia go/no-go; IDN arm 1 ~24-30h at R=1000 on 14 cores; full IDN matrix plausibly 4-5 days local, the server-option case).
Conventions audit (Emilia asked mid-session): plan checked against pedrohcgs simulation-conventions.md + simulation-study SKILL.md (the memo's "simulation-conventions standards" source); already compliant on the core contract; added estimand-alignment statement, P4b critic-python harness review gate, no-per-rep-printing + NaN/Inf hygiene.

## Mode

Maintenance (figure + approved insertion) and Implementation-planning (spec approved this morning; plan written, approval pending).

---

# Late afternoon (15:45-16:10): script promoted to the pipeline, final figure rounds, wrap-up

Emilia gave two more feedback rounds on the extrapolation-support figure after the 15:45 wrap-up point.
Round 6 fixed the China rug label, which needed a small rightward nudge; the fix is a per-country offset argument in the driver calls (IDN left, CHN right 0.05, TZA right 0.02), committed at 1cc69cf.
Round 7 vetoed a forced common y-axis across the three panels; panels now use free per-panel y-scales, which required making every direct-label y-coordinate peak-relative, anchored to each panel's own density maximum, so the labels stay inside the plot region.

At Emilia's request, the figure's generator moved from `explorations/2026-05-18_extrapolation_support_diagnostic.do` (deleted via `git rm`) to [RP7/scripts/11b_extrapolation_support_figure.do](file:///C:/git/ckt/RP7/scripts/11b_extrapolation_support_figure.do), named to sit beside `11_make_figures.do` per the existing 1b/5b/17b naming pattern.
The moved script uses namespaced globals (`xsup_proc`, `xsup_fig`, `xsup_log`, `xsup_cnever`, `xsup_cswitch`) because its old `$logs` global would otherwise clash with `0_path_config.do`'s `$logs` and repoint pipeline logging if the script ran inside a master run.
It runs standalone, setting `$dir` itself when empty, or after `0_master.do`, and I verified it from the new location; commit 60aa810.
It is deliberately not wired into `0_master.do`; that change touches the coauthor-facing pipeline and is Emilia's decision to make.

I answered her question about the external-review packet: the minimum is the spec plus the plan, the cost-benefit memo and the review record are optional additions, and a concatenated self-contained packet was offered but not yet requested.
An earlier `r(691)` PDF-export failure turned out to be a file lock rather than a script bug, because Emilia had the combined PDF open; closing it resolved the error, and the capture-noisily wrapper surfaced the lock cleanly with no popup, worth remembering for future exports.

Emilia deferred her feedback on the plan and spec to a fresh-context session and asked for a wrap-up, which produced this log.

---

# Late evening (21:20-22:40): external review folded in, plan approved, P0 done

Emilia brought an external review of the spec-plus-plan packet (verdict REVISE, six Reds, six Yellows, three Greens).
My assessment, with per-finding dispositions and the code checks I ran, is at [quality_reports/reviews/2026-07-10_external-simulation-review-dispositions.md](file:///C:/git/ckt/quality_reports/reviews/2026-07-10_external-simulation-review-dispositions.md).
The two catches that mattered: R1 (a two-regime mixture with regime membership independent of trajectory and theta is exactly LCA-true pooled, so the misspecification arm could have had nothing to detect) and R4 (score coverage by evaluating the test at the truth, not by grid membership).
I verified the reviewer's stale-source claim: `grc_gmm.py` now has `_drop_collinear` mirroring Stata's `_rmcoll`, so the recorded J discrepancy (97.74@29df vs 86.52@27df) predates the current port and P2 re-measures it.

Emilia's rulings: fold in all adopted dispositions (done, commits `7e43b56`, `2f3bd4b`); the R2 J-parity failure branch is decided at the P2 gate, not pre-committed; server transfer is NOT a governance blocker because the replication data are fully public, with a moments-only config as fallback.
She probed whether a moments-approximated design would be "more general"; resolution: fixed design stays primary (conditional coverage at the paper's own design is the referee-relevant claim and the closed-form truths depend on it), and an individual-resampling design-robustness sensitivity went into the spec as MAY item M-c, explicitly a maybe.

Plan APPROVED at 22:22 (`84c5274`).
P0 executed: worktree `extension-sims` (branch `worktree-extension-sims`, NO junctions into it per plan decision D), `sims/{src,configs,data,output,results}` layout, requirements pinned (joblib and pyarrow added), byte copies of `grc_gmm.py` and `lca_inversion.py` with md5 hashes recorded in the README, `sims/data/` gitignored (microdata snapshots).
P0 gate PASSED: headless import of both modules, `RestrictedGRC` and `compute_all_inversion_cis` exposed, all six pinned packages present in the Anaconda env.
Committed as `0a1a307` on the worktree branch.

Approaches rejected this evening, with the reason:
- A moments-only synthetic design as the PRIMARY DGP (Emilia asked whether approximating the design "seems more general").
Rejected because the referee-relevant claim is conditional coverage at the paper's own design, the closed-form truths and the empirical $J_R = 26$ depend on the fixed design, and regenerating designs from moments would require a trajectory-formation model, reintroducing the calibration layer decision A rejected.
Kept in two weakened forms: a moments-only config as the server-transfer fallback, and the individual-resampling design-robustness sensitivity as MAY M-c (resample individuals with trajectory labels, patterns, and covariate rows intact, so $J_R$ varies realistically without a design model).
- Pre-committing the J-parity failure branch (descope vs extend).
Rejected by Emilia: decide at the P2 gate with the measured gap in hand.
- The external review's Y5 (implement the F adjustment before the full run).
Adopted at half strength only: the mathematics is resolved on paper at P3, implementation stays contingent on the M9 coverage trigger, because full early implementation buys nothing if coverage is fine.
- The external review's G3 (make model routing portable for Codex).
Declined; the routing language targets this Claude Code setup.
- One pushback recorded against the review's R6: the $\Delta_{\text{unb}}$ weighting-invariance claim does hold under the homogeneity calibration (auxiliary-OLS weights are functions of $(X, D)$ only while $\theta_i$ has a common conditional mean), so the resolution is to write the derivation into the estimand registry and unit-test it at P3 rather than treat the claim as wrong.

Next: stage P1 (calibrate.py: read the hub `C:/git/ckt/RP7/data/processed/{IDN,TZA}_unb.dta` and `RP7/output/counterfactual_inputs/` READ-ONLY, snapshot design matrices to parquet, extract per-cell parameters including the within-person residual autocovariance for the dependent-error baseline, emit configs and the calibration report).
P1's gate needs a zero-noise simulated panel, so a minimal dgp stub comes with it.
Reminder for that session: the P1 data reads are the only contact with shared Dropbox-adjacent state; everything else lives inside the worktree.
