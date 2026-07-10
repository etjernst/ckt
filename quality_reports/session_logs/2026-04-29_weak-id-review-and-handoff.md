# Session log: 2026-04-29 weak-ID review, Stream B handoff, simulations worktree

Mode: Review (critic agents on weak-id code) + Implementation (TODO + handoff doc + worktree promotion).
Branch: `lca-inversion` (Stream A) and `main`/`simulations` (Stream B handoff).

## What we did

### 1. Code review on weak-ID surface

Ran python-critic and stata-critic in parallel on the LCA-inversion-CI code (Stream A) plus the legacy `grc_weak_id_inference.ado`.
Findings written to [`quality_reports/reviews/2026-04-29_weak-id-code-review.md`](file:///C:/git/ckt/.claude/worktrees/lca-inversion/quality_reports/reviews/2026-04-29_weak-id-code-review.md).
Both critics passed the exploration gate (Python 75/100, Stata 69/100); no CRITICAL findings.
8 MAJOR findings split between Python and Stata.

Notable findings worth knowing:

- **`grc_weak_id_inference.ado` vs `lca_inversion_ci.ado`** are different files: the former (250 lines) is the legacy CI .ado from a prior paper, the latter (103 lines) is the active production wrapper that delegates to Python via `lca_inversion_ci_helper.py`.
The two MAJOR Stata findings (string-`if` evaluating numeric, post scalar-reference bug) are real but **moot under archive** because nothing in the current pipeline calls the legacy file.
- **statsmodels' `use_correction=True` matches Stata's $(N-1)/(N-K) \cdot G/(G-1)$ exactly** (confirmed by reading statsmodels 0.14.2's `cov_cluster` source); the carryover finding from 2026-04-23 is closed.
- **Per-spec switcher keep-list (P-M2)** could in principle have shifted some IDN/TZA covs_all CIs because `drop_sparse_switchers` is called on `df` rather than on the per-spec `sub`. Postponed per user---at $N \approx 90{,}000$ this is unlikely to move CIs at the third decimal.

### 2. Stream B handoff doc

Wrote [`explorations/python-grc/HANDOFF_streamB.md`](file:///C:/git/ckt/explorations/python-grc/HANDOFF_streamB.md) on `main` and committed it (commit `34f6238`).
Then `git worktree add C:/git/ckt/.claude/worktrees/simulations -b simulations main` to create a dedicated worktree for Stream B / Stream C work.
The new worktree carries the handoff at [`explorations/python-grc/HANDOFF_streamB.md`](file:///C:/git/ckt/.claude/worktrees/simulations/explorations/python-grc/HANDOFF_streamB.md).

The handoff captures:

- The original SE($\hat\phi$) divergence story (Stata 0.0705, Python 0.1943; weighting-matrix convention difference, Python's variance formula correct).
- The failed rcond=1e-5 attempt (broke `mu:switcher_27` identification, drifted $\hat\phi$ by 50%).
- The pivot to `_drop_sparse_moments(threshold=2)` in `grc_gmm.py`.
- The 33% point-estimate gap on covs_all (separate, later finding) tentatively interpreted as basin-switching.
- File:// links to all the working notes ([BLOCKER.md](file:///C:/git/ckt/explorations/python-grc/BLOCKER.md), [FINDINGS_SE_phi.md](file:///C:/git/ckt/explorations/python-grc/FINDINGS_SE_phi.md), [FRESH_EYES_SE_phi.md](file:///C:/git/ckt/explorations/python-grc/FRESH_EYES_SE_phi.md), the 2026-04-24 session log).

### 3. Reframed the basin-switching narrative (after user pushback)

User correctly noted that the original divergence was the standard error on covs_0, not the point estimate, and that the basin-switching diagnosis rests on a single data point (IDN covs_all element-wise diff).
Updated handoff and TODO to:

- Clarify the SE-was-headline framing.
- Soften the basin-switching claim to "tentatively interpreted as basin-switching, not yet independently tested."
- Drop the "memo justifying weak-ID inference" item.
The justification leans on the LCA inversion machinery itself + the Tjernström Econometrica precedent + the simulation coverage check.
Python's GMM point estimates are not reported in the paper.

### 4. Restructured TODO around the simulation deliverable

Active items now include:

- **Per-replication LCA inversion CI in the simulation** (Stream C headline deliverable).
- **Profile $Q(\phi)$ on real data** (cleanest test of "flat ridge").
- **Multistart on Python step 1** (sanity check on whether basin-switching is real or tolerance gap).
- Panel bootstrap CIs scoped to $\hat\Delta_{d_N}$ and $\hat\Delta_{d_T}$ only (dropped $\hat\phi$ since the inversion CI already serves the weak-ID purpose for $\phi$).

Low-priority items:

- Critic findings 4, 5, 2 in `lca_inversion.py` (postponed; sample sizes make these unlikely to move CIs).
- Per-spec switcher keep-list (postponed).
- Smoke-test the .ster rename (deferred indefinitely; full pipeline is 30+ hours).
- Send the coauthor email about ster collision (pending small update).
- Archive `grc_weak_id_inference.ado` (~5 min when convenient).

## State at end of session

- Branch: `lca-inversion` at commit `c0909d6` (island detection).
- New branch: `simulations` at commit `34f6238` (Stream B handoff doc).
- Working tree changes pending commit on `lca-inversion`: TODO updates, weak-ID review report, this session log.
- Working tree changes pending commit on `simulations`: HANDOFF revision (post-pushback reframing).

## Open questions / next steps

- Eventually decide which branch hosts the bootstrap-for-$\Delta$ work---most natural fit is the simulations worktree since the bootstrap engine is the Python GMM port that lives there.
- The simulations worktree's HANDOFF reflects the post-pushback framing; main's HANDOFF still has the original (slightly stronger) framing.
That'll catch up next time the simulations branch merges back.
- The actual Stream C scaffolding (`SIMULATION_PLAN.md` update, runner) is unstarted.

## Files touched this session

- [docs/TODO.md](file:///C:/git/ckt/.claude/worktrees/lca-inversion/docs/TODO.md) (lca-inversion).
- [quality_reports/reviews/2026-04-29_weak-id-code-review.md](file:///C:/git/ckt/.claude/worktrees/lca-inversion/quality_reports/reviews/2026-04-29_weak-id-code-review.md) (new).
- [quality_reports/session_logs/2026-04-29_weak-id-review-and-handoff.md](file:///C:/git/ckt/.claude/worktrees/lca-inversion/quality_reports/session_logs/2026-04-29_weak-id-review-and-handoff.md) (this file).
- [explorations/python-grc/HANDOFF_streamB.md](file:///C:/git/ckt/explorations/python-grc/HANDOFF_streamB.md) (main; new).
- [.claude/worktrees/simulations/explorations/python-grc/HANDOFF_streamB.md](file:///C:/git/ckt/.claude/worktrees/simulations/explorations/python-grc/HANDOFF_streamB.md) (simulations; revised after user pushback).
