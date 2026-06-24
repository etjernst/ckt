# 2026-05-08 --- Verdier slide deck overhaul and VV-CKT parameter mapping

## Context

Separate session from this morning's [2026-05-08_vanilla-vv-loc-residualization-tail.md](file:///C:/git/ckt/.claude/worktrees/worktree-vanilla-vv/quality_reports/session_logs/2026-05-08_vanilla-vv-loc-residualization-tail.md).
Different thread: substantial overhaul of [paper/slides/verdier-modification.tex](file:///C:/git/ckt/.claude/worktrees/worktree-vanilla-vv/paper/slides/verdier-modification.tex) after user found multiple errors and wanted a careful walkthrough of how Verdier's procedure maps to CKT's.

## Goals

The user opened by saying they needed better oversight on the vanilla VV work and asked for a section on the Verdier deck explaining the issues we hit.
After my first attempt dropped four broken empirical slides into the deck, they pushed back hard on five separate items:

- Slide 9 ("Verdier identifies $\alpha_1$ at the worker level"): the equation does not show how $a_i$, $a_i + b_i$ come out; Step 2 is shown as OLS but is actually IV; the alert block references cluster-demeaning that the equations do not contain.
- "$\alpha_1 = \phi$" claim on slide 12 is wrong.
- "Cluster index" and "instruments" referenced on my new slides without ever appearing in equations.
- "Many CKT clusters hold only a handful of workers" was an unverified empirical claim.
- "Covariate column" and "location residualization" used without definition.

Mid-session course corrections that drove most of the work:

- After the parameter-mapping memo, the user asked to focus only on what each procedure does, not the smoke results, because the current run's numbers may be wrong.
- The user wanted the bridge slide that explains how VV's IV reduces to a Wald estimator on trajectory-bin means, and how that is the same operation CKT does directly.
- The user asked me to disambiguate "CKT-main" vs "CKT-vv" everywhere (the deck conflated them in slides 12 and 13 and in the appendix table).
- The user asked me to verify (not assume) that CKT data has only one geographic level.
- The user asked for an empirical hint of A3.

## What got built or changed

### Memo

[quality_reports/reviews/2026-05-08_vv-to-ckt-parameter-mapping.md](file:///C:/git/ckt/.claude/worktrees/worktree-vanilla-vv/quality_reports/reviews/2026-05-08_vv-to-ckt-parameter-mapping.md):
First draft documented what VV's procedure does, what our port does, the parameter-mapping issues, the slide-deck punch list, and an empirical cluster-size table.
After user feedback ("only what he does, what we do, how they compare"), rewrote to drop all empirical results and reorganize around procedure-only.
Final form has 7 sections: VV's procedure (model, Step 1, Step 2 simple, Step 2 robust), our port (`_vv_firststage_projection`, `run_vv_vanilla` phases), side-by-side mapping, the $\alpha_1$ vs $\phi$ conceptual issue, slide-deck issues, conceptual fragility, and questions for the user.

### Slide deck

[paper/slides/verdier-modification.tex](file:///C:/git/ckt/.claude/worktrees/worktree-vanilla-vv/paper/slides/verdier-modification.tex):
Substantial rewrite.
Edits applied in roughly this order:

- Slide 2 title from "is Verdier's simple" to "corresponds to Verdier's simple" with a footer noting they are not literally the same procedure.
  Settled on "corresponds to" rather than the more accurate "Verdier classifies our approach as a simple extrapolation" because all the more-precise alternatives I proposed were too long for the slide.
- Slide 6 ("In practice: the LCA gets a cluster-specific intercept"): switched from "province-specific" to "cluster-specific" with a footer explaining $\vii$ is generic in VV and resolves to village in his Suri-Kenya application.
- Slide 9 split into 9a (Step 1) and 9b (Step 2 IV).
  9a writes VV's CRC equation $y_{it} = a_i + b_i \D_{it} + f_t + x'\gamma + u_{it}$ with the OLS regression on $n$ worker indicators plus $n$ worker-by-treatment interactions written out, and the within-$i$ regime-mean recovery.
  9b writes the IV moment with the trajectory pattern as instrument, then the cluster-FE robust version with LHS, RHS, and instrument all demeaned within $\vii$ (intercept drops out).
- Bridge slide added: "Both procedures collapse to the same trajectory-level moments".
  Shows VV's IV reduces to a Wald estimator $\hat\alpha_1 = (\bar a_{(0,1)} - \bar a_{(1,0)})/(\bar b_{(0,1)} - \bar b_{(1,0)})$, then notes CKT computes the same trajectory-level points directly via GMM.
- Slide 12 ("VV's $\alpha_1$ and CKT's $\phi$ target different population scalars"): reframed.
  The two-skill structure is now described as "CKT's structural model interprets $\Delta_i$ in terms of two skills $(\theta_i^U, \theta_i^R)$; VV is agnostic about that structure.
  Both target the same scalar empirically; CKT's two-skill structure buys interpretation, not identification."
  Sign-vs-magnitude clarification added: same sign is automatic when both target the same correlation; reciprocal magnitude only in the deterministic-LCA limit.
- Slide 13 ("Three estimators, three assumption regimes") replaced the old "each consistent for own scalar" frame.
  Now has a 3-row table (CKT-main / CKT-vv / VV) with what each needs (A1, A2 vs A1, A2', A3 vs A1, A2') and what each targets ($\phicoef$ vs $\phicoef$ vs $\alpha_1$).
- Province-vs-village slide: substantially corrected after the data audit.
  The original slide claimed CKT had only one geographic level.
  Replaced with the corrected story: we have CHN `cid` ($\sim 4{,}066$), IDN `keca` ($\sim 1{,}669$), TZA `ward` ($\sim 135$), and we currently use first-wave province only because of a misreading of VV.
- Appendix split into three slides: parameters and LCA structure, geographic structure and estimator, slope coincide.
  The geographic-and-estimator table now has separate CKT-main and CKT-vv columns.
  The slope-coincide slide gained plain-English intuition at the top.
- Within-province TikZ figure: rewritten with negative slopes ($\phicoef = -0.5$) to match CKT's pro-poor finding.
  Province B's cloud relocated to low-$\theta$, high-$\Delta$ region (high-return types under pro-poor are low-$\theta$).
  Pooled OLS slope verified analytically at $-0.861$ via numpy; line endpoints chosen to pass through the joint centroid.

### TODO list

[docs/TODO.md](file:///C:/git/ckt/.claude/worktrees/worktree-vanilla-vv/docs/TODO.md): three new active items.

- Switch vanilla VV implementation from `vfirst` to fine-grained sub-province cluster (`cid` / `keca` / `ward`).
- Counterfactual experiments leveraging CKT's two-skill structure (urban skill premium, rural skill upgrading, differential migration costs, asymmetric education).
- Empirical hint of A3 (Hansen J test, trajectory-by-cluster F-test, visual scatter).

## Decisions, with the why

1. Stop slide edits until the parameter-mapping memo is written.
   Why: user said "I don't feel like I can trust you at all" after I propagated $\alpha_1 = \phi$ from the existing slide 12 into my new content.
   The memo was the only path back to trust.

2. Confirmed VV's regression direction is $a$ on $b$ (slide 9b) and is unambiguous.
   Why: VV §3.2 (p.16) verbatim quote "$\hat a_i$ is the dependent variable, $\hat b_i$ is the endogenous covariate".
   Footnote 19 (p.10) gives the explicit alternative form $a_i = \alpha_0 + \alpha_1 b_i + e_i$.

3. Keep the deck deliberately silent on whether $\alpha_1 = 1/\phicoef$ is the right reciprocal in CKT's setup.
   Why: under deterministic LCA AND single skill, yes.
   With LCA noise, the slopes are reciprocal only when $|\mathrm{Corr}(a_i, b_i)| = 1$.
   With CKT's two skills ($\theta_i = b_R(\theta_i^U - \theta_i^R) \ne a_i$), even the deterministic case does not give exact reciprocity.
   So the special-case identity is a heuristic anchor, not a load-bearing claim.

4. The two-skill structure is interpretive, not identifying.
   Why: VV is agnostic about structural origin; his framework is consistent with one, two, or more underlying skills.
   Both procedures use the same empirical moments (trajectory-level $(\mu_d, \Delta_d)$ in CKT, trajectory-bin means $(\bar a_g, \bar b_g)$ in VV) and recover the same LCA slope (modulo direction convention).
   The two-skill structure buys CKT counterfactual decompositions that VV cannot run; it does not buy additional identification power.
   This needs to be the line of defense if a referee asks "why not just use Verdier's estimator?"

5. The vanilla VV port should switch from `vfirst` to `cid` / `keca` / `ward`.
   Why: data audit showed all three countries have sub-province geographic identifiers in the processed `.dta` files at granularity directly comparable to VV's village ($\sim 16$, $\sim 22$, $\sim 152$ workers per cluster vs VV's $\sim 12$).
   Our `vfirst` choice came from a misreading: we saw "province" in VV's Step 1 covariates and missed that his $v_i$ in Step 2 is the village.
   Tracked as a TODO item rather than fixed in this session.

6. Drop "CKT main is asymptotically the same as VV simple" to "corresponds to" framing on slide 2.
   Why: user accepted "corresponds to" as adequately mushy for an internal deck.
   The more precise framings I proposed ("Verdier classifies our approach as a simple extrapolation", "Our current estimator instantiates Verdier's simple-extrapolation framework") were all too long for a slide title and the user explicitly asked for the shorter version.

7. The within-province TikZ figure draws the actual OLS pooled slope ($-0.861$ from the 11 data points) rather than a round $-0.8$.
   Why: user trust required honesty.
   Drawing $-0.8$ when an OLS computation would give $-0.861$ would have been a small but real misrepresentation.

8. Append a separate session-log file rather than appending to this morning's `_vanilla-vv-loc-residualization-tail.md`.
   Why: that earlier log is about a specific empirical thread (the loc-resid smoke results decision).
   This session is about a substantively different effort (slide-deck overhaul, parameter-mapping correction, geographic-structure correction).
   Separating keeps both logs scannable for the right "pick back up" trigger.

## Approaches rejected

1. Patch the broken diagnostics slides in place rather than reverting and rewriting.
   Reason: too many cascading errors ($\alpha_1 = \phi$ conflation, unverified empirical claims, undefined terminology, brittle slide cross-references).
   Cleaner to revert and rebuild from the memo.

2. Keep the empirical results section in the slide deck (the smoke convergence table for TZA / CHN / IDN).
   Reason: user said "I really don't care about the results from the current run, only what he does, what we do, how they compare, what the issues are".
   The smoke numbers are not yet trustworthy and are out of scope for the conceptual deck.

3. Use longer / more accurate slide-2 title alternatives like "Verdier classifies our approach as a 'simple extrapolation'".
   Reason: user said all my suggested rewrites were too long and to leave "corresponds to" alone for an internal deck.

4. Claim "CKT has only one geographic level".
   Reason: data audit overturned this.
   We have community / kecamatan / ward in all three countries; we just chose to use province.

5. Claim "VV admits only one skill".
   Reason: VV is agnostic about structural origin; his framework is consistent with any underlying skill structure.
   The right framing is "CKT has a structural model that VV does not" rather than "VV does not allow more than one skill".

6. Bake numerical point estimates ($-1.09$, $-0.49$, etc.) into the new diagnostics slide.
   Reason: user explicitly said current numbers are not trustworthy and the slide deck should describe procedure rather than results.

## Open items

1. Confirm option C (drop location residualization for V1) carried over from this morning's session.
   Empirical recommendation is unaffected by the parameter-mapping work, but the user has not yet signed off on A/B/C.

2. Switch vanilla VV cluster from `vfirst` to `cid` / `keca` / `ward`.
   Tracked as TODO; affects all V1 sweep results and may invalidate the smoke numbers entirely.

3. Counterfactual decomposition exercises for the paper, using CKT's two-skill structure to do things VV's framework cannot.
   Tracked as TODO.
   Potentially a major paper-level contribution if developed.

4. Empirical A3 hint.
   Tracked as TODO.
   The alpha-pooling diagnostic at [docs/reviews/2026-04-24_alpha-pooling-diagnostic-results.md](file:///C:/git/ckt/.claude/worktrees/grc-pipeline-refactor/docs/reviews/2026-04-24_alpha-pooling-diagnostic-results.md) probably already covers part of this; surface it onto a slide / appendix section.

5. Memo formula errors.
   The 2026-05-08 mapping memo has $\sigma(b)/\sigma(a)$ where it should be $\sigma(a)/\sigma(b)$ in §1.5, §4.1, §4.2 (slope of $a$ on $b$ is $\mathrm{Corr}(a,b) \cdot \sigma(a)/\sigma(b)$, not $\sigma(b)/\sigma(a)$).
   The slides have been corrected; the memo has not.

6. Two minor 7--8pt hbox overfulls on the appendix tables (lines 580, 604).
   Cosmetic; visually invisible.

## Picking back up

**If you resume:**
Read [quality_reports/session_logs/2026-05-08_verdier-slides-and-parameter-mapping-rewrite.md](file:///C:/git/ckt/.claude/worktrees/worktree-vanilla-vv/quality_reports/session_logs/2026-05-08_verdier-slides-and-parameter-mapping-rewrite.md) (this file) and [quality_reports/reviews/2026-05-08_vv-to-ckt-parameter-mapping.md](file:///C:/git/ckt/.claude/worktrees/worktree-vanilla-vv/quality_reports/reviews/2026-05-08_vv-to-ckt-parameter-mapping.md).

Open thread: the vanilla VV V1 sweep is still on hold pending a decision on cluster granularity (use `vfirst` as before, or switch to `cid` / `keca` / `ward` per the TODO).

Next concrete action: decide cluster granularity, then rewire `_vv_firststage_projection` and `run_vv_vanilla` (in [RP7/scripts/0_programs.do](file:///C:/git/ckt/.claude/worktrees/worktree-vanilla-vv/RP7/scripts/0_programs.do)) to take a cluster-variable argument so it can be set per country.
After that, rerun the smokes and the V1 sweep at the corrected granularity.

State to know:

- 28-page [verdier-modification.pdf](file:///C:/git/ckt/.claude/worktrees/worktree-vanilla-vv/paper/slides/verdier-modification.pdf) is the current deck.
- The .tex source has all session edits applied; .pdf is freshly compiled.
- Working tree has uncommitted changes to the slide deck and the TODO list.
- The morning's session log ([2026-05-08_vanilla-vv-loc-residualization-tail.md](file:///C:/git/ckt/.claude/worktrees/worktree-vanilla-vv/quality_reports/session_logs/2026-05-08_vanilla-vv-loc-residualization-tail.md)) covers the loc-resid smoke results and the A/B/C decision; that thread is still open and is orthogonal to the slide-deck rewrite covered here.
