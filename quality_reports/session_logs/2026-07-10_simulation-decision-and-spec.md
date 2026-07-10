# 2026-07-10 --- Simulation cost-benefit, ECMA framing edits, extension-study spec

## If you resume (handoff: write the implementation plan)

One-line state: the extension-simulation-study SPEC IS APPROVED with all five decisions resolved ([quality_reports/specs/2026-07-10-extension-simulation-study.md](file:///C:/git/ckt/quality_reports/specs/2026-07-10-extension-simulation-study.md)).

Next session runs TWO tasks in this order (Emilia's sequencing, 2026-07-10 12:26):
1. FIRST: promote the in-support figure into the paper's ROBUSTNESS section (her decision; do not relitigate the identification-adjacent placement I had argued for). Polish the figure per the TODO pre-reqs (thicker switcher min-max hull lines, choose lumped vs per-trajectory variant, match paper figure style; TZA needs a textual flag as the boundary case at 8% from the hull edge), regenerate via [explorations/2026-05-18_extrapolation_support_diagnostic.do](file:///C:/git/ckt/explorations/2026-05-18_extrapolation_support_diagnostic.do), write the accompanying description, and insert into `main-updated.tex`'s robustness section with per-edit approval. Numbers: $\hat\mu_{d_N}$ inside the switcher hull in all three countries (CHN 26%, IDN 24%, TZA 8% from the lower edge); memo at [docs/notes/2026-05-18_extrapolation_support_diagnostic.md](file:///C:/git/ckt/docs/notes/2026-05-18_extrapolation_support_diagnostic.md). Deliver this first so Emilia reviews it while task 2 proceeds.
2. THEN: write the implementation plan for the extension simulation study to `quality_reports/plans/` and get it approved before any code.

Read first, in order:
1. The spec (above). It is the contract; the MUSTs are non-negotiable and the Decisions section records Emilia's calls verbatim-adjacent.
2. The cost-benefit memo for the why: [docs/notes/2026-07-10_simulation-cost-benefit.md](file:///C:/git/ckt/docs/notes/2026-07-10_simulation-cost-benefit.md).
3. The old exploratory design (rich, never coded, user never formally approved it---mine it, don't inherit it): `explorations/SIMULATION_PLAN.md` on the `simulations` worktree (`C:/git/ckt/.claude/worktrees/simulations/`).
4. The machinery the plan builds on: `grc_gmm.py` (validated Python port of the production GMM, ~16 min/fit at IDN's real N; matches Stata $\hat\phi$ to 0.003) and its validation harness in `explorations/python-grc/` on the simulations worktree; `lca_inversion.py` + `synth_overid.py` in `explorations/python-grc/` on the lca-inversion worktree (synth_overid is the closest existing ancestor of the coverage harness: it produced the T=3 coverage 0.90 / T=4 $\Delta_{avg}$ 0.84 warning numbers).
5. `docs/TODO.md` entries "Empirically calibrated coverage test for the inversion CI" and "Imbens-Kolesár (2016)..." (the F-adjustment contingency M9 builds on the latter; a prior F-adjustment plan exists at `quality_reports/plans/2026-05-01-f-adjustment-inversion.md` on the lca worktree).

Plan-writing constraints and facts the fresh session must know:
- Two cells only: IDN and TZA (D1). CHN excluded; rationale in spec S1.
- Two-regime violation family primary, curvature time-permitting (D2); the quadratic-restriction pocket answer is in S2.
- Work happens in a NEW dedicated git worktree (D3), Python-only execution path (D4: server compute possible, Emilia investigating---design headless, no Stata at runtime), replication-package-ready structure from day one.
- WORKTREE SETUP DANGER: if the new worktree needs `RP7/data`, junction it to the hub `C:/git/ckt/RP7/data` with `cmd /c mklink /J` (never Git Bash `ln -s`), and never `git worktree remove --force` or `rm -rf` a worktree without checking junctions first (see [project_data_loss_2026-06-23.md](file:///C:/Users/maand/.claude/projects/C--git-ckt/memory/project_data_loss_2026-06-23.md)).
- Calibration inputs live in the MAIN tree now: 310 `.ster` files in `C:/git/ckt/RP7/output/` (merged + copied 2026-07-10) and the exporter CSVs in `RP7/output/counterfactual_inputs/`; processed data at the hub `C:/git/ckt/RP7/data/processed/`.
- Pilot gate (M5): R=20 per cell, measure wall time, PRESENT projected cost before any full run (command-safety: estimation runs over 60s need approval anyway). Target R=1,000; floor R=500.
- Seeding: numpy `SeedSequence.spawn` per M6, master seed 20260710-style.
- Run /review-plan (fresh-context critique) on the drafted plan before presenting it; the 2026-07-08 counterfactual plan review caught a coverage-vacuity Red this way.
- Mechanical implementation legs delegate to `model: "sonnet"` subagents (S5, rules/model-routing.md); DGP design, calibration choices, and results interpretation stay in the main thread.

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

## If you resume (supersedes the morning resume block)

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
