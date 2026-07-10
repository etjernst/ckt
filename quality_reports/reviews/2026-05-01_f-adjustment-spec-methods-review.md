# Methods review: F-adjustment for finite-sample bias of LCA inversion CIs

Paper: [`quality_reports/specs/2026-05-01-f-adjustment-inversion.md`](file:///C:/git/ckt/.claude/worktrees/lca-inversion/quality_reports/specs/2026-05-01-f-adjustment-inversion.md) and accompanying plan [`quality_reports/plans/2026-05-01-f-adjustment-inversion.md`](file:///C:/git/ckt/.claude/worktrees/lca-inversion/quality_reports/plans/2026-05-01-f-adjustment-inversion.md)
Date: 2026-05-01
Review type: self-review (pre-implementation methods check)

The "paper" here is a specification plus implementation plan for adding a Bell-McCaffrey-Pustejovsky-Tipton-Satterthwaite F adjustment to weak-ID-robust inversion CIs in [`lca_inversion.py`](file:///C:/git/ckt/.claude/worktrees/lca-inversion/explorations/python-grc/lca_inversion.py).
Methodological lenses (Assumptions & Setup, Identification, Estimation & Asymptotics, Monte Carlo Design, Internal Consistency) apply directly; Empirical Application, Literature Positioning, and Exposition lenses are not applicable to a project planning document.

## Summary tally

| Severity | Count |
|----------|-------|
| CRITICAL | 0     |
| MAJOR    | 4     |
| MINOR    | 3     |

The plan is methodologically sound on its core claim.
The major findings are gaps in scope and risk-management around the implementation, not errors in the underlying methodology.

## Priority action list

1. F1---synth coverage at $K=14$ does not probe IDN-scale $J_R = 26$; add a high-$J_R$ synth case to Step 4.
2. F4---cross-check F-adjusted empirical CI widths against Stata `nlcom` $\pm 1.96 \cdot SE$ as a sanity ceiling; flag any cell that widens by more than $\sim 30\%$.
3. F2---OLS anchor test cases lack a rank-deficient design; add a fourth case (Case D: dropped sparse switchers, pseudo-inverse path).
4. F3---Pustejovsky-Tipton CR2 has memory complexity that could bite on large $N$ (IDN $\sim 30{,}000$); budget for cluster-streaming if a one-shot computation does not fit.

## Detailed findings

### Assumptions & setup

#### F1: Synth coverage scope does not probe largest empirical $J_R$
- Severity: MAJOR
- Confidence: HIGH
- Problem: The chi-squared finite-sample bias scales with $J_R$ (memo lines 36--39).
The synth coverage runs cap at $T=4, K=14, J_R=13$, but the empirical IDN sample has $J_R=26$ (memo line 21).
The under-coverage at $J_R=26$ is plausibly larger than at $J_R=13$, and there is no guarantee the F adjustment closes the gap proportionally.
The plan claims (Step 6) the F-adjusted empirical inversion will "produce non-empty CIs", which is a much weaker check than verifying coverage.
Recommendation: add a synth case at $T=5$ or $T=6$ targeting $K=27$, $J_R=26$, run at $R=100$ (sufficient given MC SE $\approx 0.022$) before committing to Step 6 on IDN.
- Files: spec MUST.3, MUST.8; plan Step 4

---

#### F2: OLS anchor test cases lack rank-deficient design
- Severity: MAJOR
- Confidence: HIGH
- Problem: The Step 2 anchor cases (A: balanced, B: unbalanced, C: CKT-like panel) all assume full-rank designs.
Our auxiliary OLS can become near-rank-deficient when sparse switchers drop and the remaining `alpha[d]` dummies have small support, particularly under the `--threshold 5` filter.
`clubSandwich` handles this via `MASS::ginv` with a tolerance; our pure-NumPy port needs to handle it identically to anchor.
Recommendation: add Case D with $G = 30$ clusters, $J_R = 5$, but two of the dummy regressors having $< 3$ active clusters (forcing pseudo-inverse).
The relative-tolerance criterion ($10^{-4}$) may need to relax for this case.
- Files: plan Step 2

---

### Identification

#### F7 (lens-shifted to Notation): "MD Wald" label is imprecise
- Severity: MINOR
- Confidence: MEDIUM
- Problem: Both the spec and the chi-squared memo refer to `grid_md_inversion` as a "minimum-distance Wald" with $J_R = K - 1$.
Standard MD on $K$ moments with 2 parameters profiled has $\chi^2_{K-2}$; the memo argues the base-equation moment ($m_{base} = \hat\beta_{base} - \beta$) pins $\beta = \hat\beta_{base}$ exactly, reducing effective DOF to $K - 1$.
This is correct in the special case where the base equation is a pure pinning constraint, but only when the MD weight matrix gives the base moment infinite weight relative to the others, or when the profile-out step is implemented as a hard substitution.
The code in [`lca_inversion.py`](file:///C:/git/ckt/.claude/worktrees/lca-inversion/explorations/python-grc/lca_inversion.py) actually does the GLS-style profile (see lines 257--277), so $J_R$ may be slightly closer to $K - 2$ in practice depending on the weight matrix.
Recommendation: either rederive cleanly in the derivation memo or run a small simulation that compares the two DOF choices' empirical Wald distribution under H0.
The numerical impact is minor (one DOF in $J_R = 13$ shifts the 95th percentile by $\sim 1\%$), but the methodological claim should be precise.
- Files: spec context section, chi-squared memo lines 7--13

---

### Estimation & asymptotics

#### F3: Pustejovsky-Tipton CR2 memory complexity at large $N$
- Severity: MAJOR
- Confidence: MEDIUM
- Problem: The PT 2018 implementation in `clubSandwich` builds a per-cluster adjustment matrix $A_g = (I_g - H_{gg})^{-1/2}$ that scales as $O(N_g^2)$ per cluster.
For balanced cluster sizes our worst case is small ($N_g \le 5$ in the empirical panels), so cluster-level matrices are tiny.
The challenge is the Satterthwaite df computation: PT 2018 builds an $N \times N$ matrix or its eigenvalues to compute $\widehat{\nu}$, scaling $O(N^2)$ memory.
For IDN ($N \sim 30{,}000$ obs in the unbalanced panel), this is roughly 7 GB at double precision.
clubSandwich avoids the explicit $O(N^2)$ matrix by computing $\mathrm{tr}(G)$ and $\mathrm{tr}(G^2)$ via cluster-block products; we need to mirror that.
Recommendation: state explicitly in plan Step 1 that the implementation must compute traces cluster-by-cluster, never form the $N \times N$ G-matrix; add a memory budget check on a 30k-row toy before running on IDN.
- Files: plan Step 1, Step 6

---

#### F4: Empirical sanity check against Stata `nlcom` $\pm 1.96 \cdot SE$
- Severity: MAJOR
- Confidence: HIGH
- Problem: The plan verifies the F adjustment via two channels: OLS anchor (Step 2) and synth coverage (Step 4).
Neither catches an implementation bug that scales the variance correctly on synth but mis-handles a feature specific to the empirical data (e.g., the unbalanced indicator's interaction with cluster leverage).
Stata's published `nlcom` $\pm 1.96 \cdot SE$ already gives a known-magnitude reference point on each empirical cell; it is not weak-ID-robust, but the F-adjusted CI should not differ from it by orders of magnitude on well-identified cells where weak-ID concerns are minimal.
Recommendation: as part of Step 6, compare F-adjusted CI widths against the published Stata `nlcom` widths.
A widening of 5--30% is consistent with the F adjustment's purpose; a widening of 50%+ on IDN/covs_trend (the most well-identified cell) would indicate a scaling bug.
- Files: plan Step 6

---

### Monte Carlo design

#### F5: F-adjustment monotonicity claim is approximate
- Severity: MINOR
- Confidence: HIGH
- Problem: The plan asserts (risks section) that "F adjustment widens CIs; we want to confirm it doesn't over-correct".
The mathematical fact is that $J_R \cdot F_{1-\alpha}(J_R, \nu) \ge \chi^2_{J_R, 1-\alpha}$ for all finite $\nu$, with equality at $\nu \to \infty$.
But $\widehat{\nu}$ is computed per grid point and can in principle vary widely.
At a grid point with very large $\widehat{\nu}$ (e.g., near a moment singularity where one cluster's leverage is near-zero), the F critical value can be effectively equal to the chi-squared one.
At a grid point with very small $\widehat{\nu}$, the F critical value can be much larger.
Per-grid CI changes are therefore non-monotone in shape, even if the integrated CI always weakly widens.
Recommendation: in Step 6's diagnostic output, log the per-grid $\widehat{\nu}$ distribution and flag any cell where $\widehat{\nu}$ varies by more than 5x across the grid (indicates one extreme cluster dominates leverage and the F adjustment may be unstable).
- Files: plan Step 3, Step 6

---

#### F6: Coverage threshold anchoring is partially circular
- Severity: MINOR
- Confidence: MEDIUM
- Problem: Plan locked decision 4 cites Pustejovsky-Tipton 2018 §4 for the $\ge 0.935$ threshold.
PT's tolerance is for *their* CR2-Satterthwaite test on OLS; using it as the bar for our F-adjusted GMM-MD inversion presumes the two procedures inherit similar finite-sample calibration, which is not established in the literature.
A more defensible anchor would be the F-adjusted $T=3, K=6$ result (where chi-squared was already at 0.90, so F should land near nominal); use that as the empirical gold standard, then ask whether $T=4, K=14$ F-adjusted matches.
Recommendation: re-frame Step 5 as a calibration check before Step 4's headline judgment, rather than a regression check after.
The order does not need to change; the framing does.
- Files: spec MUST.3, plan locked decision 4

---

### Internal consistency

No issues found.
The spec and plan are internally consistent.
The plan's MUST/SHOULD list maps cleanly to the spec's MUST/SHOULD/MAY.
The decision tree in Step 4 reflects the contingencies named in the spec's failure-modes section.

## Positive observations

P1 (Estimation & asymptotics): The plan correctly identifies that Bell-McCaffrey/CR2 applies directly because the LCA inversion is OLS-based in its variance treatment, not GMM-based.
The chi-squared memo's "GMM J-test" framing is technically true for the published GRC pipeline but slightly misleading for the inversion machinery; the plan resolves this implicitly by routing through the auxiliary OLS, which is the right call.

P2 (Monte Carlo design): The plan correctly uses the same MC seeds (2000--2199) as the chi-squared baseline at $T=4$, allowing direct paired comparison without MC-noise contamination.
This is important; without paired seeds, distinguishing a genuine F-adjustment effect from sampling variability requires several times the runtime.

P3 (Estimation & asymptotics): The OLS anchor against `clubSandwich` (Step 2) is the right load-bearing checkpoint, and the plan correctly stops if the anchor fails rather than proceeding to GMM application.
This is the kind of implementation discipline that a sharp referee would expect for a methods contribution.

P4 (Monte Carlo design): The decision tree at Step 4 is appropriately tiered with concrete actions per outcome ($\ge 0.935$ closes, $0.92$--$0.935$ documents, $< 0.92$ escalates to Hall-Horowitz).
The thresholds are debatable (see F6) but the tiering structure prevents the kind of post-hoc reframing where a partial improvement gets sold as a full success.

P5 (Assumptions & setup): The cluster unit choice is verified against the existing auxiliary OLS implementation rather than asserted.
Locked decision 1 in the plan grounds the choice in actual code rather than convention.

## Lenses with no issues found

- Identification: the F adjustment does not change the identification argument; it changes the critical value of an already-identified test.
- Internal consistency: spec, plan, and existing code paths align.

## Lenses not assessable

- Empirical application: not applicable to a planning document.
- Literature positioning: spec and plan cite the right primary sources (IK 2016, BM 2002, PT 2018, HHY 1996, HH 1996) per the chi-squared memo. The claim that F adjustment is "the cheapest principled correction" tracks the pragmatic ranking in the chi-squared memo but is a forward-looking choice rather than a literature claim that can be verified against external sources here.
- Exposition & notation: the spec and plan are well-structured for their purpose; standard prose-quality review applies and is not the methods reviewer's job.

## Recommended actions before implementation

1. Add F1: a high-$J_R$ synth case ($K=27, J_R=26$, $R=100$) before Step 6 in the plan.
2. Add F2: a rank-deficient OLS test case in Step 2.
3. Add F3: a memory-streaming requirement to plan Step 1; budget a 30k-row memory-profile check before Step 6.
4. Add F4: a Stata `nlcom` width-comparison check to Step 6's success criteria.
5. Add F5: per-grid $\widehat{\nu}$ logging to Step 6's diagnostic output.
6. Optional F6: re-order Step 4 / Step 5 framing so the smaller-$J_R$ run anchors the calibration target before the headline $T=4$ judgment.
7. Optional F7: precise rederivation of $J_R$ for `grid_md_inversion` in the derivation memo, or a small simulation establishing empirical DOF.

None of these blocks proceeding to Step 0; F1, F2, F3, and F4 should be folded into the plan before Step 4 lands so the gates are calibrated correctly.
