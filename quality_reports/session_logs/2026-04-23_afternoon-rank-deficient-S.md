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

- Branch `main` at `9cf5100`. Stream B WIP lives here.
- Branch `lca-inversion` at `9cf5100` (worktree at `.claude/worktrees/lca-inversion/`). Stream A work happens here.
- Two other worktrees exist (`worktree-agent-ae662cde` locked; `worktree-unbalanced-panel-proof-review`); untouched this session.
- Verdier robust extrapolation track (P0 done, P1 pending) untouched and still awaiting P0 sign-off.
- The `define_switcherpars base(2)` bug (CLAUDE.md) remains; affects income specs only.
