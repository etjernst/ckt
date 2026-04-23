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

---

## 2026-04-22 afternoon: Verdier modification design

Mode: Implementation (design memo only; no code edits).
Worktree: `.claude/worktrees/verdier/` (branch `worktree-verdier`).

### Work completed

1. Paper-pipeline Stage A for Verdier (2020) JAE and its online appendix.
   Docling formula VLM segfaults on Windows (exit 139 on first run);
   retried with `--no-formulas`. Main paper: 91 KB / 739 lines /
   35 pages / 4 chunks. Appendix: 71 KB / 1156 lines / 67 pages /
   3 chunks. Appendix extraction silently dropped equations
   (0 formula tags); prose around equations is reliable,
   formal derivations must be read from PDF directly.
2. Manifest written and reshuffle run:
   `verdierAverageTreatmentEffects2020` and
   `verdierAverageTreatmentEffects2020appendix`.
3. Stage B summaries dispatched in parallel; both completed and
   written to `papers/summaries/` in the worktree with full
   verbatim-evidence blocks and BibTeX stubs.
4. VV replication package (`explorations/vv-files.zip`) unpacked;
   read `firststage_projection.do`, `robust.do`,
   `graph_extrapolations.do`. Parsed VV's GMM moment structure:
   Chamberlain (1992) first stage via
   `areg ..., absorb(hhid*10 + hybrid)`; second-stage IV of
   baseline on return with per-period treatment indicators;
   joint first+second-step GMM with `nocommonesample`;
   period-specific $\eta$ moments giving $T-1$ df overid;
   stayer ATE restricted to villages with at least one switcher.
5. Read CKT model + identification + GMM sections of
   `explorations/CKT_2026.tex` and `run_grc` in
   `scripts/0_programs.do` (lines 1538-1664).
6. Wrote design memo:
   `docs/reviews/2026-04-22_verdier-modification-design.md`.
   Ranked four implementation variants:
   A (robust extrapolation with $v_i$-clustered intercepts),
   B (LCA-specific $|S|-1$ df overid test),
   C (observed-cost-shifter diagnostic),
   D (individual-level Chamberlain rewrite). Recommended A primary,
   B as complementary diagnostic.
7. Addendum written after feedback:
   `docs/reviews/2026-04-22_verdier-modification-design-addendum.md`.
   Corrects the mechanical issue that "village" does not transfer
   from VV's single-village-per-farmer setting to CKT's
   migration-as-treatment setting. Proposes time-invariant
   origin/hukou indicators as the right $v_i$. Articulates the
   theoretical argument: CKT's Assumption A2
   (i.i.d.\ $\nu_{it}^l$) is strictly stronger than VV's
   exclusion restriction (2.18), so variant A amounts to
   relaxing A2 to allow region-level correlation in the
   non-pecuniary shock and only requiring the residual
   $\tilde\nu_{it}^l$ to be orthogonal to $(\theta_i,\tau_i)$.
   This is a defensible relaxation given the migration-cost
   literature (Bryan & Morten; Lagakos et al.).

### Unresolved

- Per-country choice of $v_i$: CHN hukou; IDN province-of-origin;
  TZA region-of-origin are the proposed defaults. Need support
  tabulation (fraction of never-migrants in $v$-clusters containing
  at least one switcher) before committing.
- For CHN, the robust extrapolation with $v_i=$ hukou pools $\phi$
  across hukou groups with hukou-specific intercepts; CKT's current
  hukou split estimates separate $\phi$ per group. These are
  different estimands and need to be distinguished in any
  implementation.
- Decision pending from authors: is variant A in scope for the
  current revision, or a follow-up?

### Pipeline/workflow notes

- Clickable file-link format in this user's terminal is
  `[label](file:///C:/abs/path)` with forward slashes. Plain
  `path:line` in backticks and bare `C:/path` markdown links do
  not render as clickable. Memory updated at
  `memory/feedback_file_links.md`.
- Docling formula enrichment segfaults on Windows on this setup.
  `--no-formulas` is the reliable fallback for now.
  The appendix extraction flagged 0 formula tags suggests Docling
  silently drops inline equations when formula enrichment is off
  rather than tagging them; visually inspect PDFs for
  equation-heavy sections when the extraction is relied on.

### Files created in worktree

- `papers/extracted/verdierAverageTreatmentEffects2020/`
- `papers/extracted/verdierAverageTreatmentEffects2020appendix/`
- `papers/summaries/verdierAverageTreatmentEffects2020.{md,bib,notes.md}`
- `papers/summaries/verdierAverageTreatmentEffects2020appendix.{md,bib,notes.md}`
- `papers/manifest.yaml`, `papers/config.yaml`
- `docs/reviews/2026-04-22_verdier-modification-design.md`
- `docs/reviews/2026-04-22_verdier-modification-design-addendum.md`
- `tmp/vv-replication/replication_archive/` (unpacked VV code)

No changes to `scripts/`, `paper/`, or any tracked CKT file.


## 2026-04-22 evening: feasibility survey + slides

Follow-up to the Verdier modification design work.

### Slides

Drafted `paper/slides/verdier-modification.tex` in the worktree.
Twelve slides in CKT notation with metropolis theme. Includes a
TikZ figure showing within-province vs pooled LCA fit. Compiles to
a 12-page PDF. Font warnings (Fira Sans substitution) are cosmetic.

Opening framing per user preference: "We implement Verdier's
robust extrapolation," with explicit attribution to Verdier (2020)
throughout.

### Feasibility survey

Two read-only .do files under `explorations/verdier_feasibility/`:

1. `0_inspect_vars.do` — ran successfully. Output at
   `var_lists.txt`. Catalogs geographic variables by country.
2. `1_cluster_support.do` — hung during run on log-file lock
   (four StataMP-64 processes in memory). User to investigate.
   Fix already applied: `describe` changed to `capture describe`
   so one missing variable does not abort the script.

### Geographic variables available (from 0_inspect_vars)

- **CHN:** `prov`, `provcd`, `hukou`, `birth_province`,
  `birth_county`, `locationbirth`. Birth-province is strictly
  better than first-wave province for $v_i$.
- **IDN:** `prov`, `kabu` (kabupaten), `keca` (kecamatan),
  `urbanbirth`, `migr` (indicator for not living at birth
  location). User-supplied context on `migr` / `urbanbirth`:
  `migr == 0` identifies a subsample where first-wave location
  equals birth location, so first-wave province is a clean
  origin measure for that subset.
- **TZA:** `region`, `district`.

### Implication

The original memo's "punt for later" item on province-of-origin
is partially resolved. CHN has birth-province directly. IDN can
restrict to `migr == 0` for a clean-origin robustness sample.
TZA has only current region/district — no origin variable
observed, so first-wave region stands as the default.

### Next actions when resumed

1. Kill the four stuck StataMP processes.
2. Re-run `1_cluster_support.do`. Inspect cluster counts and
   always-rural support per country.
3. On the basis of that output, decide $v_i$ per country and
   whether to switch CHN default from first-wave `prov` to
   `birth_province`.
4. Write the short feasibility memo summarizing everything.
5. Then draft the implementation spec.


## 2026-04-22 late: feasibility survey completed

Four stuck StataMP-64 processes cleared on their own. Re-ran the
cluster-support script; hit two successive bugs and fixed both:

1. Nested `preserve` triggered `r(621)` --- replaced the inner
   `preserve/restore` with an inline `firstincluster_` filter.
2. `capture drop` of a var-list aborts on the first missing
   variable and leaves everything else intact, so `first_obs_`
   was piling up across foreach iterations --- replaced with a
   loop of `foreach tmp ... capture drop` to handle each var
   independently.

After both fixes, `2_cluster_support_v2.do` ran clean.

### Results

See [feasibility note](file:///C:/git/ckt/.claude/worktrees/verdier/docs/reviews/2026-04-22_verdier-feasibility-note.md).

First-wave province is viable for all three countries, with
99.65-100% always-rural support and 13-22 clusters with
$\geq 10$ switchers. Recommended baseline $v_i$:
- CHN: `prov`
- IDN: `prov` (secondary `kabu`; robustness on `migr == 0`)
- TZA: `region` (secondary `regdist`)

Unexpected: `birth_province` exists for CHN but fails as $v_i$
because essentially all switchers concentrate in one birth province
(CFPS sampling-frame artifact). The "province-of-origin" TODO
item is effectively dead --- stay with first-wave province.

### Stata popup fix

Added `exit, STATA clear` convention to user-level rules at
[stata-conventions.md](file:///C:/Users/maand/.claude/rules/stata-conventions.md)
so Claude runs don't leave blocking completion dialogs open.
Applied to `0_inspect_vars.do` and `2_cluster_support_v2.do`.

### Open

1. Implementation spec at `docs/specs/2026-04-22_verdier-robust-grc.md`
   not yet drafted. Awaiting approval to proceed.
2. Old feasibility file `1_cluster_support.do` (broken program version)
   superseded by `2_cluster_support_v2.do`. Safe to delete after
   spec is drafted.


## 2026-04-22 evening: implementation spec drafted

Drafted the spec for variant A (robust extrapolation) at
`docs/specs/2026-04-22-verdier-robust-grc.md` in the worktree.

Structure: 10 MUST / 7 SHOULD / 3 MAY requirements with
MUST / SHOULD / MAY framework and clarity-status flags (C / A / R).

Key decisions made in the spec:
- New program `run_grc_robust` alongside the existing `run_grc`;
  the existing program is preserved and usable unchanged.
- $v_i$ = first-wave province for all three countries per
  the feasibility note. Secondary specs use hukou (CHN),
  kabupaten (IDN), regdist (TZA).
- Always-rural return averaged over $v$-clusters with at
  least one switcher, weighted by cluster always-rural mass.
- Reviewer-input items (manuscript headline, CHN hukou
  replacement) deferred until we have results; defaults:
  report simple and robust side-by-side, run hukou spec
  alongside the current hukou split rather than replacing.

After first draft, user approved promoting variant B
(LCA overid test on simple spec) from MAY to SHOULD so we
can compare overid p-values between simple and robust
and produce the Verdier-style diagnostic (simple rejects,
robust passes → confirms the modification fixes the bias).
Updated S1 to cover both specs and adjusted §6.1 accordingly.

### Open

- Plan document not yet drafted at
  `docs/plans/2026-04-22-verdier-robust-grc.md`. Awaiting
  spec sign-off before proceeding.
- No code changes yet. Any touch of `scripts/` or `paper/`
  requires the plan to be approved first.


---

## Session continuation: unbalanced proposition + Python GRC port

### Mode: Implementation + Review

### Manuscript work (completed this session)

Applied methods-review fixes to `paper/unbalanced_proposition.tex`
and `paper/main.tex:455` (unbalanced-pool footnote). Two rounds:

Round 1 (CRITICAL/MAJOR from v1 review):
- F1: MAR assumption now includes $\varepsilon_{it}$
- F2: proposition equation matches the paper's restricted GRC
  verbatim with $\alpha U_i + \pi U_i D_{it}$ appended
- F3: conditioning set changed to baseline $w_i$ observed for
  everyone
- F4: main.tex:455 footnote rewritten to reference the proposition
- F5: FWL language removed, replaced with NLGMM argument using
  block-orthogonality of switcher moments
- F6: efficiency via partitioned-information matrix
- F7: common-$\gamma$ stated as Assumption 2 with inline
  testability note
- F8: $\theta_0$ and $\vartheta^{\text{bal}}$ defined explicitly
- Writing fixes: residualised→residualized, mis-spec→misspec,
  two-steps→three/four-steps, \emph{Step 1}→\textit{Step 1}

Round 2 (fresh-eyes v2 review, 6 MAJOR):
- F_v2_1: Step 3's "algebraically identical" → "asymptotically
  equivalent up to $o_p(n^{-1/2})$" with Newey-McFadden cite
- F_v2_2 + F_v2_5: MAR now includes $(x_{it}, \varepsilon_{it})$
  on observed waves
- F_v2_3: individual-stacked moment formulation with cluster-robust
  note
- F_v2_4: rank condition on $\mu_{\underline d}$ stated explicitly
- F_v2_6: attrition literature cited (Rubin 1976, Wooldridge 2010)

Added bib entries: `neweyMcFadden1994`, `rubin1976inference`,
`wooldridge2010econometric`.

All changes verified with two-pass xelatex; 57-page output,
no undefined references.

Reviews saved:
- `docs/reviews/2026-04-22-unbalanced_proposition-methods.md`
- `docs/reviews/2026-04-22-unbalanced_proposition-writing.md`
- `docs/reviews/2026-04-22-unbalanced_proposition-humanizer.md`
- `docs/reviews/2026-04-22-unbalanced_proposition-followup.md`
- `docs/reviews/2026-04-22-unbalanced_proposition-methods-v2.md`

### Python GRC port (in progress)

Agent v1 (worktree `agent-ab154f37`) failed — stalled on the
Monitor tool, committed nothing. Worktree removed.

Agent v2 (worktree `agent-ae662cde`) succeeded through all 5
milestones with commit-after-each-milestone protocol. Final
commit `4bde995` + `984816b`.

Blockers diagnosed and fixed inline:
1. `Converged: False` — `gtol=1e-10` too tight for $n \cdot g'Wg$
   objective scale. Relaxed to $10^{-8}$, added Nelder-Mead
   polish, judge convergence by outer-iteration fixed point.
2. `se=0` for $\phi$ and a few switchers — `np.linalg.inv` on
   near-singular $(G'WG)$ caused by collinear
   `switcher_31_choice` (Stata drops it explicitly). Replaced
   with `_robust_inv` = `np.linalg.pinv(rcond=1e-10)` throughout.

Iterated GMM implemented to remove finite-sample first-step
sensitivity. Converges in 5 outer iterations, ~12 min on IDN
unbalanced (91,862 obs, 31 trajectories).

Iterated-GMM point estimates on IDN consumption/urban/unb:
  phi         = -2.454 (SE 0.196)
  Delta_base  =  0.853 (SE 0.048)
  Delta_never =  0.315 (SE 0.054)
  Hansen J    = 97.83 (df 29)

Stata verify_stata.do rewritten as a standalone conforming
to project Stata conventions (version 19, header block,
`exit, STATA clear`). Python wrapper (`verify_idn_consumption.py`)
now calls the standalone file instead of generating inline.

### Open

- Stata reference run is currently in progress (PID 9430 at
  21:27 local) on the `agent-ae662cde` worktree. Monitor
  `bt0aucvkx` will emit on CSV-appears or Stata-exits-early.
- Once Stata CSVs land: run
  `SKIP_STATA=1 python verify_idn_consumption.py` for the
  coefficient/SE/J-stat diff.
- If Python and Stata disagree: numerical-vs-analytic gradient
  check on `_gradient_of_g` is next.
- Graduate port to `scripts/python/` once verification passes.


---

## Session close: Stata-Python diff completed, merged to main

### What's committed on main (new today)

Four commits beyond the original session:

```
bb46be6  Sequential Gram-Schmidt collinearity drop (match Stata _rmcoll)
f2675b5  Merge Python GRC GMM port (worktree-agent-ae662cde)
50866a6  Apply methods-v1 and v2 review fixes to unbalanced_proposition
99b9bcd  Drop collinearity trim, finalize Stata-Python verification  (on worktree)
984816b  Add iterated GMM, standalone verify_stata.do, doc refresh   (on worktree)
4bde995  Fix two numerical blockers in GRC GMM estimator              (on worktree)
```

Worktree `agent-ae662cde` is now merged; the stale files from the
earlier failed agent (`ab154f37`) were cleaned up and the branch
`worktree-agent-ae662cde` no longer exists as a live worktree (the
branch itself is still present in git history if needed).

### Stata ran successfully

Version: StataMP-64 at `C:/Program Files/StataNow19/` (user's install
is **19.5**; `verify_stata.do` was updated from `version 17` to
`version 19`). Wall time for `run_grc` on IDN consumption/urban/unb:
**616.9 s** (~10 min). Python `.fit()` on the same sample: **928.9 s**
with the collinearity drop, ~1.5x slower than Stata.

### Verification state

**Coefficients match well** (IDN consumption/urban/unb, no covs):

| Quantity          |  Stata   | Python   |  delta    |
|-------------------|---------:|---------:|----------:|
| phi               | -2.4455  | -2.4639  |  1.8e-02  |
| Delta_base        |  0.8483  |  0.8538  |  5.5e-03  |
| mu:never          | 11.3511  | 11.3511  |  1.9e-06  |
| kappa             | 11.2875  | 11.2958  |  8.3e-03  |
| xb:unbalanced     | 11.3715  | 11.3715  |  3.8e-09  |
| xb:unb*choice     | -0.4712  | -0.4767  |  5.5e-03  |
| J-stat            |    86.52 |    98.12 | +11.60    |
| J df              |       27 |       28 |           |

N = 92,450, N_clust = 29,697, base = 2 on both sides. `mu:switcher_11`
finally returned a sensible estimate (11.38 with SE 1.89) after the
collinearity drop; previously it was 419 with essentially-zero SE.

### The one remaining diagnostic: SE(phi) inflated ~2.8x

Every SE except phi's matches Stata to 3+ decimals:

| Param               | Stata SE | Python SE |
|---------------------|---------:|----------:|
| mu:never            |   0.01584|    0.01584|
| Delta_base          |   0.04727|    0.04774|
| kappa               |   0.02914|    0.02897|
| xb:unbalanced       |  0.005027|   0.005027|
| xb:unbalanced_choice|   0.04783|    0.04830|
| **phi**             |  **0.07046** | **0.19909** |

phi SE is ~2.8x too big. Coefficient matches fine. Only phi's SE is
off, which points to something phi-specific in the variance formula.

### Next-pick-up diagnostics (in priority order)

Document these so we can dive right back in.

1. **Numerical-vs-analytic Jacobian check on the phi column.**
   Compute `_gradient_of_g[:, phi_col]` analytically (already done
   in `grc_gmm.py::_gradient_of_g`) and via scipy finite-differences
   at the converged `theta_hat`. If they disagree, the analytic phi
   derivative is wrong. The non-trivial analytic term is
   `sum_{j != base} (mu_j - mu_base) * sw_d[:, j] * D_it +
    (kappa - mu_base) * always_d * D_it`.
   Script location: write a one-off in
   `explorations/python-grc/check_gradient.py` that imports
   `RestrictedGRC._gradient_of_g` and compares.

2. **Sandwich vs. efficient variance.** Python currently computes
   `V = (G'WG)^{-1} / n`, which is the asymptotic variance **only if**
   `W = S^{-1}` at the converged theta. Iterated GMM returned
   `Converged: False`, meaning the outer fixed point was not reached
   within the 8-iteration cap. If W != S^{-1} at `theta_hat`, the
   correct variance is the sandwich
   `(G'WG)^{-1} G'WSWG (G'WG)^{-1} / n`. This could produce a smaller
   SE(phi). Diagnostic: compute both formulas and report.

3. **Outer fixed point.** Bump `max_outer` from 8 to 15 in
   `grc_gmm.py::fit` and re-run. If `Converged: True` then the
   sandwich formula should collapse to the efficient one and SE(phi)
   might drop on its own. If still False, the iterated GMM is cycling
   and needs a different outer-iteration strategy (e.g., dampening).

4. **Stata-side VCE verification.** Add `vce(cluster pid)` explicitly
   to the `run_grc` call in `0_programs.do`, or check whether
   `e(vce)` reports cluster or robust or something else. Make sure
   Python and Stata agree on *what kind* of variance they are
   reporting. The Stata log shows `vce(cluster pid)` is used; Python
   matches. This is likely fine but worth a 5-minute confirm.

### Files and where they are

- Python port: `explorations/python-grc/` on `main` (post-merge).
- Stata driver: `explorations/python-grc/verify_stata.do`,
  invoked via `stata-mp -b do verify_stata.do`.
- Verification entrypoint: `verify_idn_consumption.py`. Env vars:
  `SKIP_STATA=1` (re-use cached CSVs), `STATA_TIMEOUT=<sec>`
  (default 1800), `STATA_EXE=<path>` (default finds StataNow19).
- Persisted Stata results:
  `stata_out_idn_cons_urb_unb.csv`, `stata_out_idn_cons_urb_unb_jstat.csv`,
  `stata_sample_idn_cons_urb_unb.csv`, `stata_sample_idn_cons_urb_unb_traj.csv`.
- Persisted Python results:
  `python_out_idn_cons_urb_unb.csv`, `python_sample_idn_cons_urb_unb.csv`.

### Decisions made (and their why)

- **Kept the full Z, then reverted, then re-added a principled drop.**
  First attempt (QR-with-pivoting, tol=1e-10) was too aggressive:
  dropped 2 columns and moved the optimizer to a worse local min.
  Reverted to pinv-only. Then replaced with sequential Gram-Schmidt
  matching Stata's `_rmcoll` (Goodnight 1979 sweep operator).
  Sequential G-S drops exactly 1 column (`switcher_31_choice`) across
  tolerances 1e-11 through 1e-5, matching Stata. This is the version
  committed.

- **Iterated GMM over plain two-step.** Two-step gave different
  estimates depending on the particular first-step optimum
  (phi in {-0.95, -1.45, -2.20, -2.44} across early attempts).
  Iterated GMM updates W = S^{-1}(theta) until theta stabilizes,
  which removes that finite-sample sensitivity. Converges in 5
  outer iterations before the collinearity drop; 8-iter cap was
  not hit then but was with the drop.

- **Standalone Stata .do file.** The first implementation embedded
  the Stata code as a Python string literal that wrote a .do file
  at runtime. Replaced with `verify_stata.do` as a proper
  standalone, version 19 header, with `exit, STATA clear`. Can be
  launched manually for long runs; Python wrapper then reads the
  cached CSVs via `SKIP_STATA=1`.

- **Sample-count cosmetic mismatch fixed.** Python's `data_loader`
  drops the 588 rows with missing outcome/choice before the sample
  dump. Stata now does the same (`drop if mi(lndepvar) | mi(choice)`
  before the summary dump) so the per-trajectory counts are apples
  to apples.

### Open items (beyond the SE(phi) diagnostics)

- CHN and TZA not yet verified. Should replicate the IDN procedure
  before promoting the port out of `explorations/`.
- Income specification out of scope (`define_switcherpars` base-hardcode
  bug flagged in CLAUDE.md).
- Hukou-split and experience-split GRC out of scope.
- Python is ~1.5x slower than Stata. Not blocking; potential wins
  from JIT (Numba/JAX) or trust-region + analytic Hessian. Not a
  priority unless blocking Monte Carlo.
- The `\textbf{[X\%]}` / `\textbf{[Y\%]}` placeholders in
  `paper/unbalanced_proposition.tex` still need real
  unbalanced-observer share numbers. The non-switcher share numbers
  (88.6 and 95.7) were the wrong statistic and should NOT be
  reused; compute proper unbalanced-observer shares from the
  summary-stats tables or code them up.

