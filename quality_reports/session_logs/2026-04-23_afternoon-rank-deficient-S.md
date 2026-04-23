# Session log: 2026-04-23 afternoon — sparse-moment / S-rank diagnosis + LCA inversion plan

**Mode:** Review (diagnostic) → Implementation (planning) → Maintenance (commits, worktree).
**Continuation of:** `docs/session_logs/2026-04-23_se-phi-diagnostic.md` (this morning).
**Spec:** none (exploration-fast-track in `explorations/python-grc/`).
**Plan written:** `docs/plans/2026-04-23-lca-inversion-ci-ckt.md` (approved end of session, ready to implement).

## Goal

Pick up the simulation work track. Resolve the SE(phi) divergence (Python iterated 0.20 vs Stata twostep 0.07 on IDN/cons/urban/unb) so the Python GMM port can credibly serve as the simulation engine. In parallel, diagnose whether the Python port has a real bug versus inheriting the weak-identification problem honestly.

## What we did, in order

### 1. Context-monitor cache fix

Status line read "ctx: 90%+" on a brand-new session. Traced to `~/.claude/hooks/context-monitor.py:get_session_dir()` keying the cache on `md5(CLAUDE_PROJECT_DIR)` — not on the Claude Code session id. So every new session in this project inherited the prior session's `tool_calls` counter forever.

Fix: added `reset_if_new_session(session_id)` in `run_context_monitor()` that compares `hook_input["session_id"]` to the cached session id and writes `{"session_id": session_id}` (zeroing the counter) on mismatch. Verified the next tool call reset the cache correctly.

### 2. test_stata_theta1.py finally ran (~5 min)

Confirmed: Stata and Python step-1 land at essentially the **same Q value** (0.00133024 vs 0.00133014). The 0.00195 in `stata_step1_meta.csv` was an artifact in `e(Q)` (different normalization than what Stata's iteration reports). They differ in *theta* coordinates: phi differs by 0.038, mu_switcher_2 by 8e-4. This is a flat-ridge / multiple-optima case, not a tolerance gap.

Path A in the same script (use Stata's theta_1 to compute W_2, then Python step 2 + sandwich VCE) gave a third SE: phi = -2.084, SE = 0.039. So even with Stata's theta_1 input, Python's step 2 lands at a substantially different theta_2 and gives a still-different SE. Indicated the issue lives in the W computation, not the optimizer.

### 3. test_skip_nm.py: speed-win NEGATIVE result

Tested skipping Nelder-Mead polish after outer iter 0 of iterated GMM. Result:

```
iter 0 (NM): obj = 2e-1
iter 1-7 (no NM): obj bounces 89-116, theta oscillates wildly, never converges
final phi = -2.205, max |coef diff| = 11.3 vs baseline
```

NM polish is load-bearing — L-BFGS-B alone cannot navigate the phi-mu_base curved valley. **Don't drop it.** Recorded for future-us not to retry.

### 4. compare_S.py: false alarm on S formula difference

Element-wise diff of Python's S(theta_1_stata) vs `inv(stata_W.csv)`. Top diffs concentrated entirely on the switcher_11_choice row/col: Python had 2.95e-6 diagonal, "Stata" had ~0. All other 4095 entries matched to 1e-9. Initial conclusion: Python's `_cluster_S` formula has a bug at switcher_11_choice.

But also flagged `||W_stata @ inv(W_stata) - I|| = 1.0` — Stata's saved e(W) was numerically rank-deficient and `inv(W_stata)` produced garbage on that one row/col. The "S_stata = 0 at switcher_11" reading was an artifact of inverting a singular matrix, not a real Stata fact.

### 5. Mata-direct dump of Stata's S(theta_1)

Wrote `dump_stata_S_mata.do` — at Stata's saved theta_1, builds `g_it = z_it * eps_it`, sums within pid, builds outer-product, divides by n. Bypasses `e(W)` entirely. Took ~5 min in batch.

Result (`stata_S_diag.csv`):
- Stata's S diagonal at switcher_11_choice = **2.95409709988898e-6** — matches Python's 2.95e-6 exactly.
- `n_clusters_nonzero` for switcher_11 = **1**. Only 1 unique pid in the IDN sample is in switcher trajectory 11. The corresponding moment is rank-1 (one observation contributing).

So **Python's `_cluster_S` is correct**. S agrees with Stata to machine precision, including at switcher_11_choice. The discrepancy was never in the moment formula.

### 6. The actual diagnosis: rank-deficient S, different generalized-inverse tolerances

Web searches confirmed Stata's documented behavior: when the cluster-S is singular, `gmm` uses a **generalized inverse** (Moore-Penrose) with some tolerance for the W matrix (Stata gmm manual; Roodman 2009; Statalist threads).

So the picture:
- S agrees between Python and Stata.
- S is rank-deficient at switcher_11_choice (1 contributing cluster).
- Stata's pinv tolerance drops the rank-deficient direction → effectively zero W entry there.
- Python's `_robust_inv` uses `np.linalg.pinv(S, rcond=1e-10)` — too lax. Keeps the small singular value, producing a huge W entry (~10^5) on a moment with 1 observation.
- That single inflated weight cascades through step 2 and the sandwich VCE, producing the 2.8x SE(phi) inflation.

Decision (`docs/TODO.md`): bump Python's rcond to ~1e-5 to mirror Stata. Decided over the alternative (pre-drop sparse moments by cluster count) on the grounds that rcond more closely matches Stata's documented behavior, and rcond is what Stata effectively does internally.

### 7. Stata results are correct

Important conclusion to call out: the published Stata phi = -2.45 and SE = 0.07 are **right**. Stata applies a documented generalized inverse. We owe the reader a sentence in the inference subsection acknowledging that S is rank-deficient at sparse switcher trajectories and Stata applies a pseudo-inverse, but no Stata fix is needed.

### 8. Read and analyzed grc_weak_id_inference.ado

User added the GRC paper's LCA test-inversion ado (`explorations/python-grc/grc_weak_id_inference.ado`). Confirmed it implements exactly the kind of weak-ID-robust CI we want for phi. Mechanism:

1. Saturated OLS auxiliary with cluster-robust SE.
2. Grid loop over phi, Wald test of LCA restriction `(beta_i - beta_{i-1}) = phi * (i - (i-1))`.
3. Invert: CI = `{phi : p >= alpha}`.

Original ado's restriction assumes adjacent trajectories' theta-difference = 1 (sequential integer encoding). **CKT's `define_switcherpars` uses (mu_s - mu_base) as the theta-encoding**, where mu's are estimated. So the restriction in CKT is nonlinear in coefficients (phi multiplies estimated mu's). Adapting requires `testnl` instead of `test` and base-anchored instead of adjacent-pair restrictions.

### 9. Plan: LCA inversion CI for CKT (Python implementation)

Wrote `docs/plans/2026-04-23-lca-inversion-ci-ckt.md`. First draft was Stata-based; rewrote in place after deciding Python is the right language (statsmodels for cluster-OLS, numpy delta-method Wald, joblib parallel — fast and reusable for the cluster bootstrap planned in `docs/TODO.md`).

Approved decisions (§9 of the plan):
- Implementation in Python: `explorations/python-grc/lca_inversion.py`.
- Data-driven base from CKT's `initial_values` per spec.
- Grid `[-6, 2]` step 0.05 first pass; refine around endpoints.
- Output to parquet (curves) + csv (summary).
- Auxiliary OLS controls match the GMM column being inverted.
- Sparse-switcher threshold = 5 unique pids, same as Python `_robust_inv`'s sparse-moment pre-drop (per item in `docs/TODO.md`).
- Validation: synthesize T=2 dataset, run original `.ado` once for cross-check.
- Islands: deferred to `docs/TODO.md`.

### 10. Two streams of work, made explicit

Stream A: weak-ID inference (LCA inversion).
Stream B: Python GMM port → simulation engine.
They overlap on cluster-robust OLS infrastructure. The rcond fix (TODO) closes the SE divergence that motivated Stream A in the first place; both should be done.

### 11. Untracked `docs/`, committed everything, set up worktree

Discovered `docs/` was in `.gitignore` — 46 files of plans, reviews, session logs, and lit chunks were silently uncommitted. Updated `.gitignore` to track `docs/` except `docs/lit/*.pdf`.

Four atomic commits on main:
- `211d827` Track docs/ working notes
- `642be48` Python GRC port: SE(phi) diagnostic on IDN/cons/urban/unb
- `fe38304` Python GRC port: trace SE(phi) gap to rank-deficient cluster-S
- `9cf5100` Reference: GRC paper's grc_weak_id_inference.ado

Worktree at `.claude/worktrees/lca-inversion/` on branch `lca-inversion`, branched from main HEAD. Stream A work happens there; Stream B continues on `main`.

## Decisions logged

1. Option 1 (tighten Python `_robust_inv` rcond ~1e-5) over Option 2 (pre-drop sparse moments) for the SE(phi) fix. Rationale: closer mirror of Stata's documented behavior.
2. Python (not Stata) for the LCA inversion. Rationale: trivial implementation in numpy/statsmodels, fast, reusable for cluster bootstrap and simulation.
3. Worktree-based separation of Stream A and Stream B. Rationale: keep concerns separate; Stream A's plan is committed, Stream B's WIP stays in `main` worktree.
4. Untrack `docs/` from `.gitignore`. Rationale: 46 files of work product were silently uncommitted; the existing `docs/`-vs-`quality_reports/` convention was inconsistent. Single untracking commit cleaner than 40 file moves.
5. Same sparse-cluster threshold (5 unique pids) for both the LCA pre-drop and the GMM moment pre-drop. Rationale: same underlying degeneracy, same cutoff.
6. Defer island detection in LCA inversion CI. Rationale: keep v1 simple; CHN regime heterogeneity may surface multimodal curves but not in IDN/TZA.
7. Skip from commits: `.claude/scheduled_tasks.lock`, `settings.local.json`, `worktrees/`, `paper/main.pdf`, `paper/figures/`, `paper/tables/`, `paper/ectaart.cls`. Stale `python-grc-stale-ab154f37/` left in place (don't delete; might be useful later).

## Open / next steps

1. **Stage 8a (next):** in `lca-inversion` worktree, write `lca_inversion.py` (the auxiliary-OLS + Wald inversion). ~80 lines.
2. **Stages 8b-8f:** synthesize T=2 dataset, validate against original ado, IDN run, CHN/TZA rollout, writeup. Plan §8.
3. **TODO (separate effort):** port the rcond fix into `_robust_inv` and re-validate Python vs Stata SEs.
4. **TODO (separate effort, deferred):** island detection in LCA inversion.
5. **TODO (deferred from earlier):** cluster bootstrap for empirical paper headline objects.
6. **For the paper writeup:** add a sentence to the inference subsection acknowledging that S is rank-deficient at sparse switcher trajectories and we apply a generalized inverse.

## Workspace state

- Branch `main` at `b074655` (after log consolidation commit). Stream B WIP lives here.
- Branch `lca-inversion` at `9cf5100` (worktree at `.claude/worktrees/lca-inversion/`). Stream A work happens here. Several uncommitted files (`lca_inversion.py`, `synth_t2_validation.py/.do`, `run_idn_inversion.py`, output CSVs/parquets, critic review).
- Two other worktrees exist (`worktree-agent-ae662cde` locked; `worktree-unbalanced-panel-proof-review`); untouched this session.
- Verdier robust extrapolation track (P0 done, P1 pending) untouched and still awaiting P0 sign-off.
- The `define_switcherpars base(2)` bug (CLAUDE.md) remains; affects income specs only.

## Stage 8a: `lca_inversion.py` written and smoke-tested

In the lca-inversion worktree, wrote `explorations/python-grc/lca_inversion.py` with three components per plan §5.1:

- `drop_sparse_switchers(df, ...)` --- counts unique pids with `switcher_s == 1 & choice == 1`; drops switchers below threshold (default 5).
- `fit_auxiliary_ols(df, ...)` --- saturated OLS in trajectory dummies + (kept switcher) x choice interactions + unbalanced shifters; cluster-robust SE via statsmodels.
- `grid_lca_inversion(fit, base, phi_grid)` --- builds selector matrix $G(\phi)$, computes $\text{Wald}(\phi) = r' V_R^{-1} r$ at each grid point, returns `(phi, p_value)` curve and CI endpoints.

Smoke-tested on IDN/cons/urban/unb (covs_0, no covariates):

- 30 switcher candidates, 27 kept (dropped: 11, 19, 27 per the sparse rule).
- $J_R = 26$ restrictions. Aux OLS: 61 params, 92,450 obs, 29,697 clusters.
- **Wald min = 123 at $\phi = -2.30$. $\chi^2_{26}$ critical at 5% = 38.9. Rejects everywhere on grid $[-6, 2]$. CI empty.**

Wald curve is unimodal with minimum near the GMM's $\hat\phi \approx -2.45$ --- the right shape, but the test rejects everywhere.

## Stage 8b: T=2 validation against original `.ado` --- PASSED

Wrote `synth_t2_validation.py` (synthesizer + Python inversion) and `synth_t2_validation.do` (Stata driver running the original ado on the synthesized data).

Synthetic DGP: N = 5,000 individuals, T = 2, Suri-2011 trajectory shares, true $\phi = -1.5$, $\mu_d$ spaced so that integer-trajectory and $\mu$-difference encodings test identical restrictions. OLS recovered all coefficients to within 0.02 of truth. Both implementations produced **identical** CIs:

| Implementation | CI lower | CI upper |
|---|---:|---:|
| Original `grc_weak_id_inference.ado` | $-1.78$ | $-1.44$ |
| Python `lca_inversion.py` | $-1.78$ | $-1.44$ |

This validates the Python port at the 2-decimal-place plan tolerance.

## Critic review (econometrics-critic agent)

Launched in parallel with stage 8b. Nine findings (saved at `quality_reports/reviews/2026-04-23_lca-inversion-code-review.md` in the worktree):

| # | Severity | Status |
|---|---|---|
| 1 | MAJOR | **Refuted by T=2 validation.** Critic claimed $\hat\alpha_s = \mu_s + \pi_s \Delta_s$ (alpha contaminated by treated share); this would have shown up at T=2 and didn't. The OLS jointly identifies $\alpha$ and $\beta$ cleanly. |
| 2 | MAJOR | Real but small. statsmodels misses the $(N-1)/(N-K)$ factor in cluster correction. Empirical effect below 2-decimal precision at our N. Tracked. |
| 3 | MAJOR | Subset of #1; no issue. |
| 4 | MAJOR | Real. `pinv(V_R, rcond=1e-10)` could silently drop rank without adjusting $\chi^2$ dof when sparse switchers slip past pre-drop. Tracked. |
| 5 | MAJOR | Real. Sparse-switcher pre-drop is one-sided (only treated count). Should be symmetric. Tracked. |
| 6, 7 | MINOR | Robustness tweaks; tracked. |
| 8 | MINOR | Island detection deferred per plan. |
| 9 | INFO | Smoke-test interpretation. With #1 refuted, the IDN rejection is most plausibly real LCA failure, not implementation noise. |

## Stage 8c (covariate sweep on IDN): MAJOR FINDING

Wrote `run_idn_inversion.py` to test five covariate specs on IDN/cons/urban/unb. Result:

| spec | controls | Wald min | $\phi$ at min | $p$ | CI (5%) |
|------|---|---:|---:|---:|---|
| covs_0 | (none) | 123.6 | $-2.30$ | 0.000 | empty |
| covs_1 | + female | 123.2 | $-2.30$ | 0.000 | empty |
| covs_2 | + female + age² | 121.6 | $-2.30$ | 0.000 | empty |
| **covs_per** | + period FE | **32.9** | **$-0.35$** | **0.164** | **$[-0.60, -0.10]$** |
| covs_full | + female + age² + period FE | 33.9 | $-0.40$ | 0.139 | $[-0.60, -0.15]$ |

Three observations:

1. **Period dummies absorb enormous misfit.** Wald drops from 123 to 33 (below the $\chi^2_{26}$ critical of 38.9), and the CI opens up. Female + age² add essentially nothing on top of period FE.
2. **The $\phi$ point estimate shifts dramatically.** Wald minimum moves from $\phi = -2.30$ (no period FE) to $\phi = -0.35$ (with period FE). ~6x change in magnitude.
3. **The Python GMM port and `dump_stata_step1.do` we have been using all session do not include period FE.** Both reported $\hat\phi \approx -2.45$. The headline CKT spec likely DOES include period FE; we have not verified what the published $\phi$ is for the period-FE spec.

The covs_per CI of $[-0.60, -0.10]$ still implies $\phi < 0$ (pro-poor migration, consistent with the paper's qualitative claim) but the magnitude shift would substantially change the extrapolated returns $\Delta_{d_N}, \Delta_{d_T}$.

## Open / next steps (revised)

1. **Verify what the published CKT spec actually includes.** Check `5_GrRC.do` and the paper to confirm whether the headline spec uses period FE, and what $\hat\phi$ is reported for the period-FE spec on IDN/cons/urban/unb.
2. **Re-run the Python GMM port (and Stata GMM) with period FE** to get a comparable point estimate. If the GMM $\phi$ with period FE is $\approx -0.35$, the inversion CI corroborates the GMM. If it is still $\approx -2.45$, the GMM and inversion disagree even at the same spec, which is a much harder finding to swallow.
3. **Apply critic's fixes 4, 5, 2 (and minor 6, 7).** Particularly the symmetric sparse-switcher drop --- some kept switchers may have very few rural obs and could be destabilizing the Wald.
4. **Run on CHN and TZA** at the period-FE spec to see if the same dramatic absorption happens.
5. **Commit Stream A work in worktree** (currently uncommitted: `lca_inversion.py`, validation files, IDN run, critic review).

## Decisions logged this stage

8. Validation passes at T=2 to 2-decimal-place tolerance --- the Python implementation faithfully reproduces the original `.ado` on data it was designed for.
9. Critic finding 1 (alpha-contamination) refuted by validation; documented in the review file. Other findings (4, 5, 2, 6, 7) tracked as small fixes; not blocking the IDN/CHN/TZA rollout.
10. The published-spec discrepancy (period FE absorbed massive misfit) is a finding worth chasing before committing to any interpretation. Pause IDN rollout pending confirmation of the actual headline CKT spec.

## Stage 8c-extension: ster filename collision discovered

After confirming period FE absorbs misfit, checked the published table against current `.ster` files. Discovered the table `output/tables/GRC_IDN_consumption_urban_unb.tex` (mtime Apr 1 13:09) is OLDER than every `grc_IDN_covs_*.ster` file. Extracted phi from the current ster files via `extract_idn_ster_phi.do`:

| Spec | Current ster $\phi$ | $N$ | Sign vs urban table |
|---|---:|---:|---|
| covs_0 | $-2.225$ | 69,447 | --- |
| covs_trend | $+0.795$ | 69,447 | flipped |
| covs_1 | $+0.810$ | 69,445 | flipped |
| covs_2 | $+0.805$ | 69,445 | flipped |
| covs_all | $-0.526$ | 92,439 | matches table |

The first four have $N = 69{,}447$ (not the urban sample) and positive $\phi$ --- they are nonag estimates left over from `6_GrRC_NonAg.do`, which uses **the same ster filenames** as `5_GrRC.do`. Only `covs_all.ster` was re-run under urban (Apr 2 02:41) and matches the table.

Audited all `estname(grc_*)` calls across `scripts/`. Two collision families:

| Naming pattern | Scripts that overwrite each other |
|---|---|
| `grc_<country>_covs_{0,trend,1,2,all}` | `5_GrRC.do`, `6_GrRC_NonAg.do` |
| `grc_<country>_{c1,c2,c3,ca}` | `10_GrRC_experience.do`, `11_GrRC_max_experience.do`, `12_GrRC_experience_share.do`, `13_GrRC_max_experience_share.do`, `14_GrRC_NonAg_experience.do`, `15_GrRC_birth.do` |

`8_GrRC_hukou.do` uses `grc_<country_short>_*` and is contained.

Drafted email to coauthors at `docs/communications/2026-04-23_ster-filename-collision-email.md` proposing per-script suffixes (e.g., `grc_IDN_nonag_covs_0`, `grc_IDN_exp_c1`, etc.). User to edit and send.

## Stage 8d: rerun + side-by-side comparison

Rebuilt `rerun_idn_5gr.do` to write to a LOCAL `rerun_workdir/output/` instead of overwriting the Dropbox `output/` (per user instruction not to touch shared files). Redirection: `global dir = "."` plus `cd` into the workdir before invoking. Reads data and `0_programs.do` from Dropbox; writes ster files locally only.

Stata batch took ~1 hour; output in `rerun_workdir/idn_fresh_phi.csv`. Fresh phi values match the published table to 3-4 decimals:

| Spec | Published table $\phi$ (SE) | Fresh rerun $\phi$ (SE) |
|---|---:|---:|
| covs_0 | $-2.445$ (0.070) | $-2.4455$ (0.0705) |
| covs_trend | $-0.309$ (0.087) | $-0.3095$ (0.0870) |
| covs_1 | $-0.310$ (0.087) | $-0.3098$ (0.0868) |
| covs_2 | $-0.321$ (0.086) | $-0.3208$ (0.0862) |
| covs_all | $-0.526$ (0.102) | $-0.5256$ (0.1018) |

Confirms the published table is reproducible from the urban-spec data. The collision affects future runs but did not corrupt what was published.

Refined the LCA inversion to a 0.01 grid (from 0.05) and added 90% CIs alongside 95%. Final IDN comparison saved to `output/lca_inversion_idn_comparison.md`:

**95% CIs:**

| Spec | GMM $\hat\phi$ (SE) | GMM CI (sand.) | Inversion CI (LCA) | Width ratio |
|---|---:|---|---|---:|
| covs_0 | $-2.445$ (0.070) | $[-2.584, -2.307]$ | empty | --- |
| covs_trend | $-0.309$ (0.087) | $[-0.480, -0.139]$ | $[-0.640, -0.070]$ | 1.67 |
| covs_1 | $-0.310$ (0.087) | $[-0.480, -0.140]$ | $[-0.640, -0.070]$ | 1.68 |
| covs_2 | $-0.321$ (0.086) | $[-0.490, -0.152]$ | $[-0.630, -0.110]$ | 1.54 |
| covs_all | $-0.526$ (0.102) | $[-0.725, -0.326]$ | $[-1.230, -0.010]$ | 3.06 |

**Headline observations:**

- **Inversion CI is 1.5--3x wider than sandwich for covs_trend through covs_all.** Width ratio grows with controls, suggesting sandwich SE is most fragile in the headline (most-controlled) spec.
- **At covs_all, the 95% inversion CI ends at $\phi = -0.010$.** $\phi = 0$ is just barely excluded --- a meaningful difference from the sandwich (which excludes 0 with $t > 5$).
- **All non-empty inversion CIs still contain only $\phi < 0$** --- the pro-poor migration finding survives weak-ID-robust inference, but the margin at covs_all is razor-thin.
- **GMM and inversion point estimates differ by $\sim 0.06$--0.07 systematically** (more negative for inversion). Consistent with finite-sample difference between the joint GMM and the one-step min-Wald estimator. Reporting plan: GMM $\hat\phi$ as point, inversion as CI.

## Files added this session (worktree)

- `lca_inversion.py` --- the estimator
- `synth_t2_validation.py` and `.do` --- T=2 validation harness
- `synth_t2.dta`, `synth_t2_python_curve.csv`, `synth_t2_python_ci.csv`, `synth_t2_stata_curve.csv`, `synth_t2_stata_ci.csv` --- validation artifacts
- `compare_S.py`, `dump_stata_S_mata.do` --- earlier S-rank diagnostic (also in main worktree)
- `extract_idn_ster_phi.do`, `idn_ster_phi.csv` --- ster collision diagnostic
- `rerun_idn_5gr.do` --- local-output IDN rerun
- `rerun_workdir/output/grc_IDN_covs_*.ster` (and friends) --- 25 fresh local ster files
- `rerun_workdir/idn_fresh_phi.csv`, `rerun_workdir/rerun_idn_5gr.smcl` --- rerun artifacts
- `run_idn_inversion.py` --- driver across 5 covariate specs
- `output/lca_inversion_idn_*.parquet` (5 files) --- inversion curves
- `output/lca_inversion_idn_summary.csv`, `output/lca_inversion_idn_comparison.md` --- final summary
- `quality_reports/reviews/2026-04-23_lca-inversion-code-review.md` --- critic report + author response

## Files added (main repo)

- `docs/communications/2026-04-23_ster-filename-collision-email.md` --- coauthor email draft

## Open / next steps (revised again)

1. **Commit Stream A work** in the worktree branch (lots of files; one or two atomic commits).
2. **Apply critic fixes 4, 5, 2** (effective-rank dof in pinv; symmetric sparse drop; Stata-style cluster correction). Re-run IDN to see if the 0.06--0.07 phi gap closes.
3. **Run CHN and TZA** at all 5 covariate specs to complete the country panel.
4. **User decision:** when to send the email to coauthors. Consider also sending after the rename PR is prepared so they have the full picture.
5. **TODO from earlier (still open):** port rcond fix into Python `_robust_inv` for the GMM port (Stream B).
6. **Paper writeup item:** in the inference subsection, document the LCA inversion as the primary CI for $\phi$ and the sandwich SE as a sensitivity. Especially flag covs_all CI nearly touching $\phi = 0$.
