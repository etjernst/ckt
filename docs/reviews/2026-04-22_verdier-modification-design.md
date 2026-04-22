# Verdier (2020) modification of the CKT model: design memo

**Date:** 2026-04-22
**Branch:** `worktree-verdier` (CKT worktree at `C:/git/ckt/.claude/worktrees/verdier/`)
**Inputs:** Verdier (2020) JAE main paper + online appendix + replication package; CKT_2026 manuscript; scripts/0_programs.do (run_grc); scripts/5_GrRC.do.
**Purpose:** Scope what it would mean to integrate Verdier's CRC-stayer-ATE machinery into the CKT pipeline, map VV to CKT notation, identify concrete implementation touchpoints, and rank implementation variants. No code edits in this pass.

---

## 1. TL;DR

Verdier (2020) is the formal econometric foundation of exactly what we do in CKT: a two-step CRC/GRC estimator that extrapolates mover/switcher returns to stayers/non-migrants via a linear restriction. Compared against our current pipeline, VV adds four things we don't have:

1. **A generalized ("robust") extrapolation** that allows baseline heterogeneity to depend on an observed indexing variable $v_i$ (e.g., village, district, hukou status) through cluster fixed effects in the second-step IV regression.
2. **A formal overidentification test of the LCA restriction** (not just of the CRC model), with explicit degrees of freedom $|S|-1$ where $S$ is the set of switcher trajectory profiles.
3. **Analytical cluster-robust standard errors** derived via a two-step influence function representation (Propositions 5--8 of the online appendix).
4. **A diagnostic via an observed cost-shifter** (VV adds distance-to-nearest-seed-seller as an exogenous covariate; testing its significance in the LCA equation is a direct test of the simple-extrapolation assumption).

The headline result from VV's own application is that the simple extrapolation gave $\widehat{ATE}_{\text{non-hybrid stayer}}=66\%$, rejected by the overid test at $p<0.01$; the robust village-FE extrapolation gave $\widehat{ATE}_{\text{non-hybrid stayer}}=37\%$, not rejected ($p=0.26$), and matched the 41% RCT benchmark (Carter et al., 2017). The implication for us: the current CKT $\widehat\Delta_{d_N}$ estimates rest on an untested assumption that Suri (2011)'s own data violated. At minimum we should test the restriction. At maximum we should estimate the robust version.

**Primary recommendation (variant A below):** implement a robust GRC estimator that partials village (or district/hukou) fixed effects out of the second-step moments and interprets $\widehat\Delta_{d_N}$ as the average return for always-rural workers in locations with at least one switcher. This is a targeted augmentation of `run_grc` in `0_programs.do` and can reuse most of our trajectory machinery.

**Secondary recommendation (variant B):** replace our pooled Hansen $J$ with VV's explicit overid test of the LCA line. Would likely reclassify the CHN $J$-rejection into something diagnosable (a specific trajectory profile breaks linearity) rather than a monolithic failure that forces the hukou split.

---

## 2. What Verdier actually proposes

See [VV main summary](file:///C:/git/ckt/.claude/worktrees/verdier/papers/summaries/verdierAverageTreatmentEffects2020.md) and [VV appendix summary](file:///C:/git/ckt/.claude/worktrees/verdier/papers/summaries/verdierAverageTreatmentEffects2020appendix.md) for full details. Condensed:

### 2.1 VV's CRC model

$$y_{it}=a_i+f_t+b_i x_{it}+u_{it},\qquad E(u_{it}|X_i)=0,\qquad x_{it}\in\{0,1\}.$$

Workers ("movers") with $0<\sum_t x_{it}<T$ have returns identified by difference-in-differences; stayers do not. This is isomorphic to our CRC:

$$y_{it}=\beta^R+\theta_i+\tau_i+(\beta+\phi\theta_i)D_{it}+x_{it}'\gamma+\varepsilon_{it},$$

with $a_i\equiv\beta^R+\theta_i+\tau_i$ (baseline), $b_i\equiv\Delta_i=\beta+\phi\theta_i$ (return), $f_t\equiv$ period effects, $u_{it}\equiv\varepsilon_{it}$.

### 2.2 Simple extrapolation ("Lemieux--Suri" = what CKT currently does)

VV's identifying assumption (2.11):
$$E(a_i\mid b_i,x_{i1},\ldots,x_{iT})=E(a_i\mid b_i)=\alpha_0+\alpha_1 b_i.$$

In our notation this is exactly the LCA restriction $\Delta_i=\beta+\phi\theta_i$ turned upside down:
$$a_i=\alpha_0+\alpha_1 \Delta_i+e_i,\qquad \alpha_1\equiv 1/\phi\ \ (\text{up to sign conventions}).$$

The stayer-ATE plug-in for always-rural ("untreated stayer"):
$$\widehat{ATE}_{d_N}=\frac{\bar a_{d_N}-\hat\alpha_0}{\hat\alpha_1}=\hat\beta+\hat\phi\,(\hat\mu_{d_N}-\hat\mu_{\underline d_0})+\hat\Delta_{\underline d_0},$$
which after rearrangement is the same plug-in we already compute in `run_grc` at [C:\git\ckt\scripts\0_programs.do:1610](file:///C:/git/ckt/scripts/0_programs.do) (the `nlcom Delta_never` statement).

### 2.3 Generalized ("robust") extrapolation (what CKT does NOT do)

VV relaxes (2.11) to:
$$E(a_i\mid b_i,x_{i1},\ldots,x_{iT},v_i)=m(v_i)+\alpha_1 b_i,$$

where $v_i$ is an observed indexing variable capturing factors of selection into treatment that are correlated with $(a_i,b_i)$ at the cluster level. The implementation is a **fixed-effects IV** regression of $\hat a_i$ on $\hat b_i$ with $v$-cluster dummies, using treatment history as instruments. The stayer-ATE plug-in changes to
$$\widehat{ATE}_{d_N,v}=\frac{\bar a_{d_N,v}-\hat m(v)}{\hat\alpha_1},$$
averaged over $v$-clusters that contain at least one switcher. This is what reduced Suri's 100% to 37% in Kenya.

### 2.4 Overidentification test of the LCA line (testable for $T\ge 3$)

VV shows that with $T=2$, the LCA is just-identified and untestable. With $T\ge 3$, additional switcher-trajectory profiles generate overidentifying moments, and a Wald test of the exactly-identifying nuisance parameters $(\eta_0,\{\eta_t\}_{t\in S})$ gives a $\chi^2(|S|-1)$ statistic. This is a **different test** from Hansen's J as currently computed by `estat overid` in `run_grc`: CKT's J tests the CRC moment restrictions *and* the LCA restriction jointly at the pooled level; VV's test isolates the LCA. Implementation: add exactly-identifying $\eta$ moments to the GMM system per switcher profile, jointly estimate, test.

All three CKT countries have $T\ge 3$: CHN $T=4$, IDN $T=5$, TZA $T=3$. All support VV's test.

### 2.5 Empirical diagnostic via an observed cost-shifter

VV's complement to the overid test: add $\bar d_i$ (average distance to seed seller) as an exogenous covariate and test $H_0:\alpha_2=0$ in $a_i=\alpha_0+\alpha_1 b_i+\alpha_2 \bar d_i+e_i$. Significant $\alpha_2$ ($p=2.8\%$ in Kenya) rejects the simple extrapolation. This is a directly usable falsification test and needs only one observed exogenous cost shifter per country.

---

## 3. Parameter map: VV $\leftrightarrow$ CKT

| Concept | VV | CKT |
|---|---|---|
| Baseline heterogeneity | $a_i$ | $\beta^R+\theta_i+\tau_i$ (approx. $\mu_{\underline d_i}$ at trajectory level) |
| Return to treatment | $b_i$ | $\Delta_i=\beta+\phi\theta_i$ |
| Time effects | $f_t$ | period FE inside $\beta^R$ |
| Treatment indicator | $x_{it}$ | $D_{it}$ |
| Controls | $z_{it}$ | $x_{it}$ |
| Movers / switchers | $M_n=\{0<\sum_t x_{it}<T\}$ | $\mathcal D_S$ |
| Untreated stayers / always-rural | $\{x_{it}=0\ \forall t\}$ | $d_N$ |
| Treated stayers / always-urban | $\{x_{it}=1\ \forall t\}$ | $d_T$ |
| LCA slope (identified from movers) | $\alpha_1$ in $a=\alpha_0+\alpha_1 b+e$ | $\phi$ in $\Delta=\beta+\phi\theta$ |
| LCA intercept | $\alpha_0$ | $\beta$ (after normalization by $\underline d_0$) |
| Cluster indexing variable | $v_i$ | not implemented (implicitly pooled) |
| Switcher trajectory profile | $(x_{i1},\ldots,x_{iT})\in S$ | $\underline d\in\mathcal D_S$ |
| Stayer-ATE estimand | $ATE_{S,0}=E(b_i|x_{it}=0\ \forall t)$ | $\Delta_{d_N}$ |

Axis flip: VV regresses $a$ on $b$, so his slope is $\alpha_1$; we regress $\Delta$ on $\theta$, so our slope is $\phi$. They carry the same information but with different standard errors after the axis flip. VV's choice (regressing $a$ on $b$) is the natural one when you want to *extrapolate the stayer return* because the unknown is $b$ and $a$ is observed for stayers.

### 3.1 Why the direction matters (nontrivial)

A subtle but important point: under the extrapolation assumption, $\alpha_1$ (regression of $a$ on $b$) and $1/\phi$ (inverse of regression of $b$ on $a$) are identical only if $e_i$ is homoscedastic and has zero conditional expectation. Under heteroscedasticity (which VV flags as "likely" in footnote 3 of the appendix due to measurement error in $\hat a_i,\hat b_i$), the two regressions identify different parameters. The CKT `run_grc` moment structure parameterizes $\phi$ as $\Delta_{\underline d}-\Delta_{\underline d'}=\phi(\mu_{\underline d}-\mu_{\underline d'})$ at the trajectory-mean level, which sidesteps the heteroscedasticity issue (trajectory means absorb idiosyncratic variance), but at the cost of losing cross-individual information. VV's individual-level IV regression has more moments but heteroscedasticity costs — hence VV's insistence on efficient GMM weighting over 2SLS (Hall & Inoue 2003 cost of misspecification).

**Verdict:** the CKT approach is the trajectory-aggregated analog of VV's individual-level IV. Moment-equivalence under LCA, but finite-sample behavior may differ.

---

## 4. Identification implications

### 4.1 What changes if we adopt the robust extrapolation

The LCA restriction becomes conditional on $v_i$:
$$\Delta_i=\beta(v_i)+\phi\theta_i,$$
with $\beta(v)$ a location-specific intercept that absorbs migration-cost heterogeneity at the $v$-level. This:

- **Relaxes the assumption** that rural-urban consumption gap is constant across locations (CKT's current assumption A3). $\phi$ is still the LCA slope, common across $v$.
- **Changes the estimand** for $\Delta_{d_N}$: we identify $\Delta_{d_N,v}$ for each $v$ and average over $v$-clusters containing at least one switcher. The population-level $\Delta_{d_N}$ is now a weighted average over this support.
- **Requires a support condition:** each always-rural $v$-cluster must contain at least one switcher. VV's Kenya data had 91% coverage. We should compute this by country; if coverage is <80%, the estimand is substantively different from the full-population stayer ATE.
- **Changes standard errors:** clustering at $v$ rather than at pid. VV's Proposition 8 supplies the analytical sandwich; cluster bootstrap (applied to both steps) is the safe alternative.

### 4.2 Hansen $J$ vs VV's LCA test: what the CHN rejection could mean

CKT currently reports a pooled Hansen $J$ that rejects in CHN (discussed in our CKT_2026 Section \ref{sec:hukou}). Splitting by hukou resolves it. Interpretation: institutional heterogeneity. VV's framework offers an alternative reading:

- The pooled $J$ tests CRC restrictions + LCA jointly. A rejection could be either.
- VV's test isolates LCA violations, with $|S|-1$ df. If we implemented it, we could see whether the CHN rejection is:
  - a CRC failure (strict exogeneity or time-constant effects; handled by the `footnote 31` diagnostic in VV — test $E(\Delta e_{it}|x_{it}=x_{it-1},m_i=m)=0$), or
  - an LCA failure localized to a specific trajectory profile (e.g., late urban-to-rural returnees systematically deviate from the LCA line).

The second diagnosis would *not* need the hukou split to resolve — we could instead add a profile-specific nuisance parameter. The hukou split is arguably a *particular* instance of the robust extrapolation with $v_i=\text{hukou}$.

### 4.3 Support / relevance conditions for a VV-style CKT

VV's Assumption 9.a--d maps to:

- 9.a (non-vanishing switcher mass on each profile): satisfied in IDN/CHN but **binding in TZA** where some trajectories have fewer than 30 individuals. TZA's limited switcher mass is already a known issue.
- 9.b (relevance: $E(b_i|\underline d)\ne E(b_i|\underline d')$ for distinct switcher profiles): this is the assumption underlying CKT's whole identification of $\phi$ from cross-trajectory variation. Already implicit.
- 9.c (regularity): satisfied.
- 9.d (no super-consistency): satisfied.

The robust-extrapolation extension tightens 9.a: instead of non-vanishing mass overall, we need non-vanishing *within-$v$* switcher mass. For CKT with $v=\text{village}$, this is much more restrictive: many villages will have zero switchers. Using $v=\text{province}\times\text{year}$ or $v=\text{district}$ is likely a better choice.

---

## 5. Estimation implications: specific touchpoints in the codebase

### 5.1 `0_programs.do::run_grc` (lines 1538--1664)

Current moment specification (line 1568--1578):
```
gmm (lndepvar - {mu: never `switcher_traj'} - {Delta_base}*choice
    - {phi=-1}*(`switcherpars') - ({kappa}+{phi}*({kappa}-{mu:switcher_`base'}))*(always#1.choice)
    - {xb: `covarlist'}),
    instruments(`covarlist' never `switcher_traj' choice always_choice switcher_*_choice, nocons)
    vce(cluster pid)
```

VV-robust analog would:

- Add $v$-cluster indicators to both the `mu` parameter set (allowing cluster-specific baselines) AND the `never` trajectory (allowing cluster-specific stayer baselines). These are mathematically absorbed into $\{\mu_{\underline d,v}\}$.
- Change the `nlcom` for `Delta_never` to average over $v$-clusters with switcher support rather than pool all always-rural observations.
- Change `vce(cluster pid)` to `vce(cluster v)` (or use two-way clustering at pid × v if panel-level correlation also matters).
- Add an `overid_eta` block with $|S|-1$ nuisance parameters and a post-estimation `test` of their joint zero-ness (VV's LCA overid test).

This is 40--80 lines of Stata additions to `run_grc`, plus a small wrapper that handles the choice of $v_i$ per country.

### 5.2 `define_switcherpars` (lines 1515--1537)

Currently hardcoded to `base(2)` for consumption specs (see CKT known-issues note). VV's estimator does not select a "base" trajectory — it runs an IV regression on the full switcher sample with all trajectory indicators as instruments. Adopting a VV-style estimator would **sidestep the base-hardcoding bug entirely** because there is no base. This is a nice side-benefit, but it changes the normalization: instead of $\Delta_{\underline d}-\Delta_{\underline d_0}$ being a parameter, we parameterize $\Delta_i=\alpha_0+\alpha_1\theta_i$ directly.

### 5.3 `initial_values` (lines 1412--1513)

VV's identification relies on non-zero mover-group differences in $E(b_i|\underline d)$. Our initial values machinery uses trajectory-specific mean consumption; VV's machinery would use individual-level $\hat b_i$ from a first-step Chamberlain-style regression (`areg outcome w*, absorb(pid*10+choice)` — see [VV's firststage_projection.do:127](file:///C:/git/ckt/.claude/worktrees/verdier/tmp/vv-replication/replication_archive/Table1/Code/firststage_projection.do)). For a hybrid approach (keep trajectory moments, add robustness terms), current `initial_values` would largely carry over.

### 5.4 Standard errors

Our current `vce(cluster pid)` is correct for the simple spec. For the robust spec, we need `vce(cluster v_i)`, and VV's Proposition 6/8 sandwich formula can be compared against the `gmm`-reported analytical SEs (they should coincide when correctly specified). A cluster-at-$v$ bootstrap applying both steps is the safe fallback.

---

## 6. Implementation variants, ranked

### Variant A — robust extrapolation with $v_i$ = geography (RECOMMENDED)

**What:** Extend `run_grc` so that the `mu` and `never` intercepts are $v$-specific, keeping the LCA slope $\phi$ common. Estimand becomes $\Delta_{d_N,v}$ averaged over $v$-clusters with switcher support. Choose $v_i$ per country:
- CHN: province or province × year
- IDN: kabupaten or kabupaten × year
- TZA: district (village has too little switcher mass)

**Why (priority):** This is the modification VV's paper is primarily about, and the one with the largest demonstrated empirical payoff in his application. Directly addresses the most plausible violation of LCA in a migration context (local labor-market conditions correlate with local productivity). Side benefit: subsumes the CHN hukou split as a special case.

**Cost/benefit:**
- + Addresses the exact bias VV documented in Suri (2011).
- + Sharper identification argument for the restricted GRC.
- + Subsumes CHN hukou split; can test whether hukou-only is enough or additional $v$-heterogeneity matters.
- + Sidesteps `define_switcherpars` base-hardcoding bug if we shift to individual-level IV (variant A-prime).
- -- Changes the estimand from population ATE to "support-restricted ATE" (need to show support fraction per country).
- -- Requires picking a $v_i$ for each country, with justification.
- -- Finite-sample efficiency may suffer if $v$-clusters are small.

**Implementation effort:** ~1--2 weeks. Mostly additions to `run_grc`, plus robustness tables.

### Variant B — VV's LCA overidentification test ($|S|-1$ df)

**What:** Replace pooled Hansen $J$ with VV's explicit $\eta$-augmented overid test of the LCA line. Adds $|S|-1$ nuisance parameters per regression, tests their joint zero-ness with `test` after `gmm`.

**Why (priority):** Diagnostic value independent of whether we adopt the robust extrapolation. Pinpoints *which* trajectory profile deviates from LCA, rather than reporting a single pooled $J$. Particularly useful for diagnosing the CHN $J$ rejection.

**Cost/benefit:**
- + Sharper diagnosis of $J$ rejections.
- + Complements rather than replaces the Hansen $J$ on CRC moments.
- + Low implementation risk (purely diagnostic, does not change point estimates).
- -- Does not by itself fix any bias.
- -- Current pooled Hansen $J$ tests both CRC + LCA; replacing loses information about CRC. Best to report both.

**Implementation effort:** ~2--3 days. A separate post-estimation block.

### Variant C — cost-shifter diagnostic

**What:** Add an observed exogenous cost shifter $\bar d_i$ (e.g., distance-to-nearest-city, travel time) per country as an additional covariate in the IV regression. Test $H_0:\alpha_2=0$.

**Why (priority):** Falsification test of the simple extrapolation. Cheap, direct, interpretable.

**Cost/benefit:**
- + Very cheap to implement.
- + Clear falsification logic.
- -- Requires a plausible exogenous cost shifter per country. IFLS distance-to-provincial-capital is candidate for IDN; unclear what works for CHN/TZA.
- -- A significant $\alpha_2$ is diagnostic but does not deliver an alternative estimate; must be followed by variant A.

**Implementation effort:** ~1 week per country, dominated by cost-shifter construction from raw data.

### Variant D — individual-level IV rewrite (Chamberlain-style)

**What:** Rewrite the first step of GRC estimation as VV's Chamberlain 1992 regression (`areg y w*, absorb(pid*10+D)`), construct individual-level $\hat a_i,\hat b_i$, and run a second-step IV regression of $\hat a_i$ on $\hat b_i$. This is what VV's replication code actually does.

**Why (priority):** Deepest restructuring; most faithful to VV; least reuse of our current moment machinery.

**Cost/benefit:**
- + Most directly comparable to VV's published results.
- + Delivers joint-step SEs via a single `gmm` call with `nocommonesample`.
- -- Major code restructuring — would essentially be a new estimator alongside the existing `run_grc`.
- -- Loses the trajectory-aggregated moment structure that CKT's identification argument is built around.

**Implementation effort:** ~3--4 weeks. Probably too ambitious for a first pass.

### Ranking

1. **A** (robust extrapolation with $v_i$ = geography). Primary modification.
2. **B** (VV's LCA overid test). Diagnostic; adopt regardless of A.
3. **C** (cost-shifter). Falsification; good robustness appendix addition.
4. **D** (full Chamberlain rewrite). Deprioritize unless reviewers ask.

---

## 7. How this interacts with known CKT issues

- **CHN Hansen $J$ rejection and hukou split:** variant A with $v=\text{hukou}$ formalizes what the current hukou split does ad hoc. Variant B pinpoints whether the rejection is LCA- or CRC-driven.
- **Pro-poor $\phi$ finding:** unchanged in direction, but the magnitude of $\Delta_{d_N}$ may change substantially under variant A (VV's Kenya case: $66\%\to 37\%$). If the robust spec kills the pro-poor result, that is important to know before submission; if it strengthens it, so much the better.
- **`define_switcherpars` base-hardcoding bug:** variant D would sidestep. Variant A would not; still needs to be fixed.
- **TZA switcher mass limits:** variant A with village-level $v$ likely infeasible; district-level is the most aggressive that will work. Confirm with support tabulation.

---

## 8. Open questions for the authors

1. **Which $v_i$ per country?** Preferred candidates: CHN province or prefecture (4 years of panel, can use province × year); IDN kabupaten; TZA district. If hukou is to be used for CHN, it enters as $v_i$ alongside (or instead of) geography. Which is the substantively right choice?
2. **Support tabulations.** What fraction of always-rural workers live in $v$-clusters containing at least one switcher, by country and by choice of $v$? This determines whether the robust-spec estimand is close to the population or a narrow subset.
3. **Cost-shifter candidates.** Are there country-specific travel-time, distance-to-city, or internal-migration-restriction variables we can use as exogenous cost shifters for variant C?
4. **Should variant A replace the baseline or supplement it?** If the robust and simple estimates agree, having both is a strong robustness check. If they diverge (VV's Kenya case), the paper's headline finding changes. Defer this decision until after running variant B's diagnostic on the current pipeline.
5. **Inference.** Analytical cluster-robust SEs from VV's Proposition 6/8 vs cluster bootstrap: do we implement the analytical version, or default to bootstrap? Bootstrap is safer but expensive; analytical requires more derivation.
6. **Scope for this revision.** Is variant A in scope for the current revision, or a follow-up paper? VV's main paper is short (35 pages) and could be a directly comparable referenced alternative.

---

## 9. Next steps (pending approval)

Per `rules/workflow.md`, this is an Implementation-mode design memo. Before any code changes:

1. **Decision from authors** on which variant(s) to implement and in what order.
2. **Spec document** at `docs/specs/YYYY-MM-DD-verdier-robust-grc.md` detailing the chosen variant's exact moment specification and estimand.
3. **Plan document** at `docs/plans/YYYY-MM-DD-verdier-robust-grc.md` with file-level changes.
4. **Support tabulation script** (fast, data-only) to establish feasibility of variant A's $v$ choice per country. Can be drafted as a small `.do` in `explorations/` without waiting for spec approval.

No `0_programs.do` or `5_GrRC.do` edits in this pass.

---

## Appendix: file references

- VV main summary: [file:///C:/git/ckt/.claude/worktrees/verdier/papers/summaries/verdierAverageTreatmentEffects2020.md](file:///C:/git/ckt/.claude/worktrees/verdier/papers/summaries/verdierAverageTreatmentEffects2020.md)
- VV appendix summary: [file:///C:/git/ckt/.claude/worktrees/verdier/papers/summaries/verdierAverageTreatmentEffects2020appendix.md](file:///C:/git/ckt/.claude/worktrees/verdier/papers/summaries/verdierAverageTreatmentEffects2020appendix.md)
- VV main PDF (extracted): [file:///C:/git/ckt/.claude/worktrees/verdier/papers/extracted/verdierAverageTreatmentEffects2020/paper.docling.md](file:///C:/git/ckt/.claude/worktrees/verdier/papers/extracted/verdierAverageTreatmentEffects2020/paper.docling.md)
- VV replication package: [file:///C:/git/ckt/.claude/worktrees/verdier/tmp/vv-replication/replication_archive/](file:///C:/git/ckt/.claude/worktrees/verdier/tmp/vv-replication/replication_archive/)
- VV first-step (Chamberlain): [file:///C:/git/ckt/.claude/worktrees/verdier/tmp/vv-replication/replication_archive/Table1/Code/firststage_projection.do](file:///C:/git/ckt/.claude/worktrees/verdier/tmp/vv-replication/replication_archive/Table1/Code/firststage_projection.do)
- VV second-step joint GMM: [file:///C:/git/ckt/.claude/worktrees/verdier/tmp/vv-replication/replication_archive/Table1/Code/robust.do](file:///C:/git/ckt/.claude/worktrees/verdier/tmp/vv-replication/replication_archive/Table1/Code/robust.do)
- VV extrapolation plot: [file:///C:/git/ckt/.claude/worktrees/verdier/tmp/vv-replication/replication_archive/Figure2/Code/graph_extrapolations.do](file:///C:/git/ckt/.claude/worktrees/verdier/tmp/vv-replication/replication_archive/Figure2/Code/graph_extrapolations.do)
- CKT model section: [file:///C:/git/ckt/explorations/CKT_2026.tex](file:///C:/git/ckt/explorations/CKT_2026.tex)
- CKT `run_grc` program: [file:///C:/git/ckt/scripts/0_programs.do](file:///C:/git/ckt/scripts/0_programs.do) (lines 1538--1664)
