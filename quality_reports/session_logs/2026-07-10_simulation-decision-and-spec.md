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
