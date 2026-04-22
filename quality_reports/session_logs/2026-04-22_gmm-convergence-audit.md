# Session log: GMM convergence audit + junction migration

**Date:** 2026-04-22
**Mode:** Review (diagnostic) + light Maintenance (junctions, CLAUDE.md updates)

## Goal

Understand why several GrRC specifications aren't converging. Before diagnosing, also recreate the workspace junctions at the current replication-package version.

## Junctions: RP4 → RP6

- At session start, `c:/git/ckt/` had no `scripts/`, `data/`, or `output/` directories at all. Junctions from the previous workspace were gone.
- Previous session note (in MEMORY.md) captured the failure mode: Git Bash `ln -s` on Windows silently copies instead of symlinking; use `cmd /c mklink /J` instead.
- Co-authors don't use git and re-version the replication package each revision. User asked to point junctions at the newer `ReplicationPackage6/` rather than the stale `ReplicationPackage4/`.
- Ran PowerShell-wrapped `cmd /c mklink /J` (avoids Git-Bash path mangling on the space-containing Dropbox path) for all three junctions; verified each resolves into `ReplicationPackage6/scripts` | `data` | `output`.
- Updated paths in `CLAUDE.md`, `.claude/rules/source-of-truth.md`, and `MEMORY.md` to reference RP6 with a note flagging that the folder gets re-versioned.

## Convergence audit: mechanism and artifact

### Approach

- `run_grc` calls `gmm … quickderivatives nolog`, so the iteration trace is suppressed. Only the final "convergence not achieved" / "Warning: Convergence not achieved." messages appear, plus the final GMM criterion Q(b) and coefficient table.
- Wrote `explorations/audit_convergence.py` to parse all `scripts/logs/*GrRC*.log` files. For each `run_grc: base trajectory = N` echo in the log, we record: country, section, estname, base, Q(b), converged flag, and the final phi/kappa + SEs from the coefficient table that follows.
- Output: `docs/reviews/2026-04-22-gmm-convergence-audit.md` — includes per-country summary, per-spec ✓/✗ grid, failed-run detail table, and a diagnosis section.

### Numbers

- 21 of 286 GrRC runs failed to converge (7.3%).
- IDN: 0 / 100 failures.
- CHN pooled: 10 / 63. CHN hukou splits: 9 / 60 (rural-first and rural-only carry most failures; urban-only has 0).
- TZA: 2 / 63 (both in the no-covariates consumption spec).
- Failures concentrate in the least-saturated specifications (no covariates, or +time FE only, or +female only). Adding age² and/or education typically restores convergence.
- **Every failing run is at base = 2.**

## Diagnosis — evolution and corrections

This was the most error-prone part of the session. Logging the evolution so the reasoning is inspectable.

### First pass (wrong)

Initial reading of the failure signature — `phi ≈ −1`, `kappa` SE in thousands to millions, `Q(b)` ≈ 1e-3 — I attributed to **small always-urban subgroup**: "with a thin always-urban cell the moments that pin `kappa` have little power, the criterion is locally flat in `kappa`, gradient underflows, optimizer stalls."

### User pushback

User correctly pointed out: (a) always-urban is *not* small in pooled CHN — CFPS has plenty of urban residents; (b) if sample size were the issue, adding controls wouldn't help.

### Data check

Ran `explorations/check_trajectories.do` (uses Stata batch's own log rather than `log using` — the earlier version collided with the batch log and errored as "file read-only"; separate issue). Unique-pid always-urban shares:

| Sample | Always-urban unique pids | Failures? |
|---|---:|---|
| IDN_unb (consumption) | 2.69% | **0 / 100** |
| IDN_unb_income | 2.18% | 0 |
| CHN_unb (consumption) | 16.36% | yes (covs_0) |
| CHN_bal (consumption) | 39.98% | yes (covs_0) |
| CHN_unb_income | 1.80% | yes (c1, c2) |
| CHN hukou rural-first | 10.18% | yes |
| CHN hukou rural-only | 9.20% | yes |
| CHN hukou urban-first | 34.09% | rarely |
| TZA_unb (consumption) | 19.87% | yes (covs_0) |
| TZA_unb_income | 19.51% | 0 |

The correlation goes the opposite direction from my first diagnosis: the sample with the smallest always-urban group (IDN, 2.69%) never fails; pooled CHN at 16% does. Subgroup size is not the mechanism.

**Note on denominator:** the unique-pid counts above use all pids in the sample. A large share of CHN person-years have *missing* `trajectory` (e.g., 48% of CHN_unb, 94% of CHN_unb_income). Per user: missing-trajectory observations stay in the estimation and identify covariates, but do not identify any `Delta` — they don't belong to any `never` / `switcher_s` / `always` bucket.

### Second pass (current working hypothesis): φ = −1 critical-point trap

The GMM residual is

```
r_it = y - mu(traj) - Delta_base*choice - phi*switcherpars
       - (kappa + phi*(kappa - mu_base))*always*choice - xb*covars
```

At **φ = −1**, the always-urban correction simplifies:

```
(kappa + (−1)*(kappa − mu_base))*always*choice = mu_base*always*choice
```

`kappa` drops out entirely. ∂Q/∂κ ≡ 0 at φ = −1 for any κ. That is a structural degeneracy of the parameterization, not a numerical artifact — it explains the million-size SE on κ in every failed run.

The phi-gradient at φ = −1 is `(κ − μ_base) · always · choice`, which vanishes when `κ ≈ μ_base`. `initial_values` plants starting values at `κ = _b[always]` and `μ_base = _b[switcher_base]` from a preliminary OLS. Both are roughly the group mean of log-consumption, so at the start `κ − μ_base ≈ 0` → phi-gradient ≈ 0 → optimizer starts ~on the saddle with `{phi = −1}` nailing it there.

This also explains why adding covariates helps: covariates perturb the OLS that produces `_b[always]` and `_b[switcher_base]` by different amounts (they absorb variation differently across the two groups), which breaks the `κ ≈ μ_base` coincidence and lets phi move off −1.

Not yet directly confirmed (only consistent with the failure signature). The iteration log is suppressed by `nolog`; removing `nolog` would allow Stata's own "(not concave) / (backed up) / (flat region)" annotations to appear and confirm or refute.

## Base trajectory: walkthrough

User asked to walk through how `base` is chosen, and whether/why it matters.

### Picker algorithm (`initial_values`, `0_programs.do:1476–1507`)

- Default `base = 2`. Loop through switcher trajectories; compute t-stat on `switcher_s_choice` from the preliminary OLS; require `N_s / T > 5`; among qualifying switchers, pick the one with the largest |t|.
- For the failing specs, the preliminary OLS in TZA consumption shows |t| = 21.17 on `switcher_2_choice`, far above the others — so base = 2 was **data-picked**, not fallback. Same pattern in CHN (trajectory 2 = label "0001" = last-wave migrants, the most-populous CHN switcher at 1,764 person-years in CHN_unb).

### Should base matter? Theory says no

Under LCA, $\Delta_s = \Delta_b + \phi(\mu_s - \mu_b)$. Switching base from $b$ to $b'$ gives $\Delta_{b'} = \Delta_b + \phi(\mu_{b'} - \mu_b)$; all $\mu_s$, all $\Delta_s$, $\phi$, $\Delta_{\text{never}}$, $\Delta_{\text{avg}}$, $\Delta_{\text{always}}$ are unchanged. Only the label on the intercept moves.

### In practice, base matters through three numerical channels

1. **Starting values.** `initial_values` plants `μ_base` at the OLS coefficient for `switcher_base`. Which OLS coefficient gets planted changes with base.
2. **Interaction with the φ = −1 saddle.** As above, the degeneracy is about whether `κ_start ≈ μ_base_start` at the initial point. Base choice shifts `μ_base_start`.
3. **Conditioning.** Switcherpars is a sum of `(μ_s − μ_b)` differences; noisy `μ_b` makes it noisy. The `N_s / T > 5` guard already protects against this.

### Correction to an earlier claim

In the course of explaining (2) I wrote "using trajectory 2 as the LCA anchor means every other trajectory's return is *interpreted* as a deviation from late-migrant comparative advantage." User challenged this. The claim was wrong:

- Δ is a return, not a comparative-advantage level. θ is comparative advantage.
- $\Delta_s = \Delta_b + \phi(\mu_s - \mu_b)$ is algebra, not interpretation. φ and every Δ_s are base-invariant.
- My follow-up that "late-migrant selection makes the reference non-neutral — a substantive concern" was also wrong. Selection in the base trajectory can't contaminate other trajectories' Δ's through the base label alone. If trajectory 2 is positively selected, $\mu_2$ and $\Delta_2$ both reflect that, but $\phi$ and every $\Delta_s$ for $s \neq 2$ are unchanged.

Correct framing: base choice is economically a free reparameterization. The only way it moves estimates is through the numerical channels above, and those are bugs, not reparameterizations gone wrong.

## CLAUDE.md staleness found

CLAUDE.md still asserts:

> `define_switcherpars` in `0_programs.do` is hardcoded to `base(2)`. This is wrong for income specs with IDN (base=16) and TZA (base=5).

Reading the current `0_programs.do:1515–1531`, `define_switcherpars` uses the passed `base` argument correctly. `run_grc` calls it with an explicit `base(`base')`. The comment next to that call reads: `* Build switcherpars internally — guarantees same base everywhere`. The bug appears to have been fixed. The CLAUDE.md note is stale.

Not updating this in the session — flagging for the user to decide whether to remove the warning from CLAUDE.md after verifying against git history.

## Diagnostic gaps / offered next steps

Three exploration tasks offered but not yet executed (user hasn't picked):

1. **Remove `nolog` and rerun one failing spec.** Would confirm or refute the saddle story — Stata's own iteration annotations would appear.
2. **Remove `nolog` and `quickderivatives`, change `{phi = −1}` to `{phi = 0}` or `{phi = −0.5}`, rerun the six `5_GrRC.log` failures.** If the saddle diagnosis is right, this alone should resolve most failures.
3. **Base-invariance test.** Pick one converging CHN consumption spec, force `base = 2, 3, 7, 11` manually, confirm φ and all Δ's are identical across runs. If they drift, there's a second bug (e.g., initial values not updated consistently with base).
4. **`initial_values` diagnostic.** Add a `di` inside the picker to report qualifying switchers' N and |t| per spec, and whether the fallback was triggered. Cheap and informative.

## Files touched

- `CLAUDE.md` — RP4 → RP6 path references.
- `.claude/rules/source-of-truth.md` — RP4 → RP6 with note on re-versioning.
- `MEMORY.md` (auto-memory) — RP4 → RP6, added re-versioning note.
- `explorations/audit_convergence.py` — new parser.
- `explorations/check_trajectories.do` / `.log` — new trajectory tab.
- `docs/reviews/2026-04-22-gmm-convergence-audit.md` — new audit report.

## Not done / open questions

- [ ] User to pick which of the four next-step experiments to run first.
- [ ] Verify CLAUDE.md's stale `define_switcherpars` note against git history and update.
- [ ] If saddle hypothesis is confirmed, decide whether to fix via starting values (cheap) or reparameterize to kill the φ = −1 degeneracy structurally (more invasive but more principled).
- [ ] The `quickderivatives` option is also in `run_grc_hukou` — any fix needs both.

---

## Addendum: simulation planning and unbalanced-panel proposition

Session continued from the convergence audit into forward-looking planning.
Mode: planning / Maintenance (no production code touched).

### Simulation plan for CKT

- User added `GRC.tex`, `7_[012]_*.do`, `CKT_2026.tex`, and two older-version zips to `explorations/`, asking how to design Monte Carlos for CKT that would add credibility without duplicating the forthcoming GRC paper's simulations.
- Subagent did a comparative read of `GRC.tex`, `7_1_SimulationsPhi.do`, `7_2_SimulationCompile.do`, and `CKT_2026.tex`. Key findings: GRC design is $T=2$, four trajectories, exogenous trajectory shares with majority adopters (opposite of CKT); CKT has $T \in \{3,4,5\}$, up to 32 trajectories, 88--96% non-switcher mass, endogenous selection via the LCA decision rule.
- Drafted `explorations/SIMULATION_PLAN.md` proposing three credibility wins: (1) finite-sample coverage of $\hat\phi, \hat\Delta_{d_N}, \hat\Delta_{d_T}$ at the country-specific $(N, T, \pi)$; (2) size/power of Hansen's $J$ against nonlinear $\phi$ and regime heterogeneity (formalizes the hukou split); (3) reproducing the OLS/FE/GRC gap from the selection rule alone.

### Decisions locked in

- Scope: Exercises 1--4. Defer 5 (trajectory-sparsity sweep) and 6 (attrition).
- Calibration: empirical per country, grid over $\phi$ around $\hat\phi$.
- Covariates: hold $x_{it}$ at the empirical matrix (no $F_x$ to defend).
- CIs: default GMM in the simulation; panel bootstrap CIs ($B=500$) to be added to the empirical tables for $\hat\phi, \hat\Delta_{d_N}, \hat\Delta_{d_T}$ --- tracked in `docs/TODO.md`.
- Language: **pure Python**. User overrode the hybrid Python+Stata architecture in favor of a full Python reimplementation of `run_grc`, treating the cross-language replication as an independent credibility artefact. Validation against Stata `.ster` estimates is a hard gate before any simulation runs.
- Storage: `explorations/simulations/` local to the git repo, no Dropbox writes.
- Stage A1 (Python GMM + validation) added as a ~2--4 day stage with proposed tolerances: $10^{-4}$ absolute on $\hat\phi$, $10^{-3}$ relative on $\hat\mu, \hat\Delta$, $10^{-2}$ relative on SEs, $10^{-3}$ relative on $J$.

### Unbalanced-panel proposition

- User asked whether inclusion of unbalanced observers could be justified by a proof rather than a simulation.
- Short memo at `explorations/UNBALANCED_PANEL_ARGUMENT.md` argues the question is a consistency question, not an inference question --- proof-appropriate.
- Drafted proposition + proof at `explorations/unbalanced_proposition.tex` using an FWL orthogonality argument: balanced-length trajectory dummies are zero for partial observers by construction, so partial observers never touch the balanced-length $\Delta_{\underline d}$ score. Stronger than MAR consistency --- robust to MNAR in partial observers.
- User flagged that the trajectory-labeling convention should be obvious from the Stata code. Initial reading was wrong: I inferred from `handle_trajectory_groups_2waves` / `_3waves` that partial observers get shorter string trajectories and therefore occupy distinct trajectory cells. User corrected: those `_2waves` / `_3waves` programs are for alternative robustness specifications, not the main estimation. In the main GrRC, `handle_trajectory_groups` does `keep if !unbalanced` (0_programs.do:199), so only balanced observers get a trajectory. Unbalanced observers are pooled to `trajectory = 999` (line 1217) --- a single cell --- with $U_i$ and $U_i \times \text{choice}$ carrying their contribution.
- Correction propagated to `unbalanced_proposition.tex` (rewritten to reflect single-pooled-unbalanced structure; conclusion unchanged, cell-structure framing simplified), `UNBALANCED_PANEL_ARGUMENT.md` (correction note added pointing to the revised .tex), and `docs/TODO.md` (completion entry updated).

### Feedback memories saved

- `feedback_file_links.md`: after writing/editing a file, link to it as `path:line`, don't reprint contents in the terminal.
- Already had: `feedback_semicolons.md`, output-to-file preference.

### Process detours

- Wrote the simulation plan twice (first hybrid Python+Stata architecture, then pure Python after user preference). Second pass left a stale `## 6. Implementation path` section referencing `sim_ckt_dgp.ado` and `sim_ckt_run.do` --- found on user's prompt to scrub stale Stata mentions. Deleted, renumbered §7--§11 → §6--§10.

### Files touched in addendum

- `explorations/SIMULATION_PLAN.md` (created, then substantially rewritten twice)
- `explorations/UNBALANCED_PANEL_ARGUMENT.md` (created)
- `explorations/unbalanced_proposition.tex` (created; LaTeX drop-in for the paper)
- `docs/TODO.md` (created)
- `~/.claude/projects/C--git-ckt/memory/feedback_file_links.md` + `MEMORY.md` pointer

### Not done

- [ ] Stage A0 (scaffold): create `explorations/simulations/` directory layout, snapshot empirical $x$-matrices per country as parquet, stub Python modules.
- [ ] Stage A1 (Python GMM + validation against Stata): substantial implementation work.
- [ ] Panel bootstrap CIs for empirical tables (tracked locally in gitignored `docs/TODO.md`, execute after Stage A1).
- [ ] User reminder: `docs/TODO.md` is local-only (docs/ is gitignored) --- re-seed on other machines manually.

### Commits made end-of-session

1. Update workspace references: RP4 -> RP6
   (CLAUDE.md, .claude/rules/source-of-truth.md, .gitignore).
2. Add GMM convergence audit tooling
   (audit_convergence.py, check_trajectories.do).
3. Add reference materials for CKT simulation planning
   (GRC paper sources, CKT snapshot, response letters; binary
   attachments skipped).
4. Plan CKT Monte Carlo simulations (SIMULATION_PLAN.md).
5. Draft proposition justifying unbalanced-panel inclusion
   (UNBALANCED_PANEL_ARGUMENT.md, explorations/unbalanced_proposition.tex).
6. Integrate unbalanced-panel proposition into paper
   (paper/unbalanced_proposition.tex, paper/preamble.tex, paper/CKT.bib).
   `paper/main.tex` edits (section 5 intro + appendix \input) applied
   directly in Overleaf, not committed here.
7. This session log update.

`main.pdf` compiles to 56 pages with the integrated proposition. One
open stylistic note for the user: the proposition introduces a formal
Assumption~1 (MAR), while the paper's A1--A5 are stated in prose.
Retrofitting A1--A5 as `\begin{assumption}` blocks or dropping MAR's
formal assumption numbering are both viable; no action taken here.
