# Monte Carlo simulations for CKT: a thinking-through memo

**Date:** 2026-04-22
**Purpose:** Sketch a simulation program that would provide "more meat" for the CKT migration paper without duplicating the Monte Carlos in the forthcoming GRC paper (Econometrica).
**Status:** Exploratory planning, not an approved implementation plan. No code yet.

---

## 1. What the GRC simulations already prove, and why CKT needs its own

The GRC paper's simulations (`explorations/GRC.tex` §Simulations; `7_1_SimulationsPhi.do`) are tightly focused:

- Two periods, four trajectories, one switcher pair $\{(0,1),(1,0)\}$.
- Trajectory shares calibrated to Suri (2011): $p_{00}=0.26, p_{01}=0.08, p_{10}=0.13, p_{11}=0.53$.
- Draws: $\alpha_i \mid \underline{h}_i \sim \mathcal{N}(\mu_{\underline{h}},\, 0.84^2)$; $\varepsilon_{it} \sim \mathcal{N}(0, 0.38^2)$.
- Sweep the identification gap $\eta \equiv \mu_{(1,0)} - \mu_{(0,1)}$ to move between strong and weak identification of $\phi$.
- Targets: bias of $\hat\phi$, SE vs. Monte Carlo SD, 95% coverage of CRC, restricted GMM, and a weak-ID-robust test-inversion CI.

**What this does for CKT is limited.** The GRC design delivers a general-purpose result about weak identification and the remedial CI. It does *not* speak to the regime CKT actually operates in: $T \in \{3,4,5\}$, $|\mathcal{D}| \in \{8,16,32\}$, 88--96% non-switcher mass, endogenous selection into migration on comparative advantage, covariates, unbalanced panels, and three country-specific calibrations. Running the same DGP for CKT would be at best redundant and at worst misleading, because the GRC design has majority adopters ($p_{11}=0.53$) --- the opposite of the CKT samples.

**What the CKT paper actually needs to demonstrate.** Three things, in order of headline importance:

1. **The extrapolated returns for never-movers ($\Delta_{d_N}$) and always-movers ($\Delta_{d_T}$) have the coverage the paper claims.** These are the objects that reconcile the OLS--FE--GRC gap in the literature. If their standard errors under-cover at CKT's $(N,T)$, the paper's central quantitative claim is at risk.
2. **Hansen's $J$ has the size and power the paper implicitly assumes.** The draft uses $J$ as a specification check and splits the CHN sample by hukou in response to $J$ rejection. That response is only interpretable if $J$'s null behavior is well-characterized in CKT's calibration and if it has power against the alternatives CKT cares about (nonlinear $\phi$, regime heterogeneity).
3. **Naive OLS/FE are biased by the amount the paper says they are, under CKT's selection rule.** The draft argues that divergent literature estimates are driven by selection on comparative advantage. A Monte Carlo that calibrates the selection mechanism to country data and recovers the OLS/FE/GRC gap observed empirically would be a *direct* quantitative validation of the paper's main theoretical contribution.

None of these is delivered by the GRC paper. All three are squarely in scope for a CKT simulation appendix.

## 2. Proposed DGP

The CKT decision rule (CKT_2026.tex eq. around the discussion of $D_{it}$) is:
$$
D_{it} = 1 \iff y_{it}^U - y_{it}^R > c_{it}, \qquad \Delta_i = \beta + \phi\theta_i.
$$
Trajectory shares are an *endogenous* function of $(F_\theta, F_\tau, F_\nu, \beta, \phi)$ and the cost process. This is the single biggest structural difference from the GRC DGP and it should be preserved in the simulation, not replaced with exogenous shares.

### 2.1 Primitives to draw

For individual $i=1,\ldots,N$ and wave $t=1,\ldots,T$:
- $\theta_i \sim F_\theta$ (rescaled comparative advantage); baseline $\mathcal{N}(0,\sigma_\theta^2)$ calibrated to the empirical dispersion of switcher returns.
- $\tau_i \sim \mathcal{N}(0,\sigma_\tau^2)$ (absolute advantage, orthogonal to $\theta_i$).
- $x_{it}$ (age, education, household size, period). Age/period should be deterministic given birth cohort and wave; household size and education can be drawn from the empirical marginal and held fixed within $i$ where the data are time-invariant.
- $\nu_{it}^l \sim \mathcal{N}(0,\sigma_\nu^2)$ i.i.d., $l \in \{R,U\}$.
- $c_{it}$ a migration cost with a fixed component $c_i \sim F_c$ and an i.i.d. shock. $F_c$ is the lever that generates the observed non-switcher fraction.

### 2.2 Outcomes

$$y_{it}^R = \beta_t^R + x_{it}'\gamma^R + \theta_i + \tau_i + \nu_{it}^R$$
$$y_{it}^U = \beta_t^U + x_{it}'\gamma^U + (1+\phi)\theta_i + \tau_i + \nu_{it}^U$$
Observed: $y_{it} = (1-D_{it})y_{it}^R + D_{it}y_{it}^U$.

Under A4 ($\gamma^U = \gamma^R$) the covariates enter only as level shifters. The CKT paper imposes A4; simulations should generate data *under* A4 for the main design and *violate* A4 in a robustness arm.

### 2.3 Calibration

Per country, pick parameters so that the simulated data match the empirical moments the paper already reports:

| Moment | CHN | IDN | TZA |
|---|---|---|---|
| $N$ | 34,746 | 29,716 | 11,012 |
| $T$ | 4 (2010--2016) | 5 (1993--2015) | 3 (2008--2013) |
| Non-switcher share | 95.7% | 92.9% | 88.6% |
| $\hat\phi$ (consumption) | from Table X | from Table X | from Table X |
| $\hat\beta$ | from Table X | from Table X | from Table X |
| $\mu_{d_N}$ | from descriptive | from descriptive | from descriptive |
| Variance of switcher returns | from descriptive | from descriptive | from descriptive |

Fit $F_c$ to hit the non-switcher share. Fit $\sigma_\theta$ to match the cross-trajectory spread in $\mu_{\underline d}$ among switchers. Fit $\sigma_\nu$ from the time-varying component of the residual after removing $\theta_i + \tau_i$. Once calibrated, all three countries run the same code with different parameter vectors.

### 2.4 Attrition / unbalanced panel

Add a missingness process $\Pr(R_{it}=1 \mid \theta_i, D_{it}, x_{it})$ calibrated to each country's observed attrition pattern. Baseline: MCAR (replicates the balanced-panel robustness). MAR: attrition depends on observed $x_{it}, D_{it}$. MNAR: attrition loads on $\theta_i$ (correlated with comparative advantage). The three together map onto the balanced-panel robustness check in §\ref{sec:robustness} and tell us whether the gap between balanced and unbalanced estimates is consistent with MAR or requires MNAR.

## 3. Prioritized simulation exercises

Ordered by expected marginal credibility gain. Exercises 1--3 are probably sufficient for a referee-convincing appendix; 4--6 are defence against likely referee asks.

### Exercise 1 --- Finite-sample properties of $\hat\phi$ and $\hat\Delta_{\underline d}$ at CKT calibration

Under the baseline DGP for each country, report across 1,000 replications:
- Bias and RMSE of $\hat\phi$.
- Bias, RMSE, and 95% coverage for every $\hat\Delta_{\underline d}$ reported in the paper, including $\Delta_{d_N}$ and $\Delta_{d_T}$.
- SE vs. Monte Carlo SD ratio.

**Why this is the headline.** Nobody has done this for CKT's $(N, T, \pi_{\underline d})$. If coverage is right, the paper's quantitative claims are validated. If coverage is wrong (likely for $\Delta_{d_N}, \Delta_{d_T}$ which extrapolate beyond the switcher support), CKT should adopt the GRC paper's weak-ID-robust CI and say so.

### Exercise 2 --- Size and power of Hansen's $J$

- **Size** under the null (LCA holds, constant $\phi$, A1--A5 satisfied), across country calibrations.
- **Power** against three alternatives:
  - **Nonlinear comparative advantage:** $\Delta_i = \beta + \phi\theta_i + \psi\theta_i^2$ for a grid of $\psi$.
  - **Regime heterogeneity:** two latent groups with $\phi_1 \ne \phi_2$, mixing share calibrated to the CHN hukou split. This *directly* validates the §\ref{sec:hukou} diagnostic.
  - **$\gamma^U \ne \gamma^R$** violation of A4.

**Why this matters.** The paper uses $J$ as a specification check without characterizing its size or power under the country-specific calibration. Power against regime heterogeneity is the formal justification for the hukou split.

### Exercise 3 --- Selection bias in OLS and FE

Under the baseline DGP, compute OLS and FE estimators alongside restricted GRC and report the full distribution of the OLS--FE--GRC gap. Show that the pattern observed empirically across the three countries is reproduced by the selection mechanism alone, without any data-generating artifact.

**Why this matters.** The paper's interpretive claim --- that OLS/FE bias in the migration literature arises from selection on comparative advantage --- is currently supported only by the GRC estimates themselves. A Monte Carlo that reproduces the gap *from first principles* turns that interpretation into a decisive argument.

### Exercise 4 --- Robustness to LCA violation

Generate data with $\Delta_i = \beta + \phi\theta_i + \psi g(\theta_i)$ for $g \in \{\theta_i^2, \operatorname{sign}(\theta_i)\}$, and report:
- Bias of $\hat\phi$ and $\hat\Delta_{d_N}$.
- Hansen $J$ rejection rate (ties to Exercise 2).
- Whether the direction of bias in $\hat\Delta_{d_N}$ is conservative or anti-conservative for the paper's claims.

### Exercise 5 --- Sensitivity to trajectory sparsity *(deferred)*

Vary $T$ from 2 to 6 holding $N$ fixed. Show how bias, coverage, and identification of $\phi$ change as cells thin. Inform the reader how much of the paper's performance is a free lunch from $T=5$ (IFLS) vs. $T=3$ (TZNPS). **Deferred per user decision 2026-04-22.**

### Exercise 6 --- Attrition *(deferred)*

Three arms per country: balanced (no attrition), MAR, MNAR on $\theta_i$. Report $\hat\phi$ and $\hat\Delta_{d_N}$ across arms. The empirical balanced-vs-unbalanced gap sits in the interval defined by MAR and MNAR; the simulation tells us which. **Deferred per user decision 2026-04-22.** Partially covered analytically by the unbalanced-panel proposition (file:///C:/git/ckt/explorations/unbalanced_proposition.tex), which handles MAR; MNAR remains open.

## 4. What to drop or defer

- **Weak-ID sweep of $\eta$** (the GRC paper's headline exercise). The GRC paper owns this result; CKT should cite it, not replicate it. Only relevant as a sidebar if Exercise 1 finds coverage problems that motivate the inversion CI.
- **Comparison to CRC vs. restricted GrRC at the estimator level.** Same reason --- the GRC paper owns the estimator comparison. CKT's job is to show its preferred estimator performs adequately in the CKT calibration.
- **Income specifications.** Keep consumption as the primary outcome because the `define_switcherpars base(2)` bug affects income for IDN (base=16) and TZA (base=5). Simulating income requires either fixing the bug first or deliberately matching the buggy behavior (not recommended).

## 5. Pitfalls and implementation notes

1. **Mirror `run_grc`, don't mirror the GRC paper's simulation code.** The Python GMM should replicate the moment system used in the paper's empirical `run_grc` program (general $T$, up to 32 trajectories, switcher subset). The GRC paper's simulation do-file (`7_1_SimulationsPhi.do`, lines 495--541) is $T=2$ specific and a red herring.
2. **Generate trajectories from the decision rule, don't draw them from a multinomial.** The GRC paper's DGP draws trajectories from a categorical distribution. That is wrong for CKT because the whole point of the paper is that trajectories are selected on $\theta_i$. Simulate the migration choice.
3. **`define_switcherpars base(2)` bug.** Flagged in CLAUDE.md. Fine for consumption. If income simulations are ever run, fix the bug first and regenerate affected empirical results *before* treating them as calibration targets.
4. **Country calibration targets come from the validated Python GMM, not from `.ster` files.** After Stage A1 validation, the Python estimator produces the same point estimates as Stata but exposes them as clean Python objects. Use those as the simulation calibration targets; this avoids a fragile `.ster` parsing step.
5. **Replication count.** 1,000 reps per cell gives Monte Carlo SE of $\sim 0.007$ on a coverage estimate near 0.95. For Exercise 1 this is adequate. For Exercise 2 (power curves), 2,000 reps per design point is safer.
6. **Runtime budget.** Three countries $\times$ four exercises $\times$ multiple DGP arms $\times$ 1,000--2,000 reps. With pure-Python parallelism, this is tractable on a laptop overnight.
7. **Reproducibility.** Pin the seed at the master level; write all parameter vectors and estimates to parquet; commit the compiled result files alongside the paper. Use a deterministic seed policy: `seed = base_seed + arm_id * 1_000_000 + rep` so a single replication is reproducible by pulling its seed alone.

## 6. Decisions

1. **Scope.** Exercises 1--4 go in this revision. Exercises 5--6 deferred (6 is partly covered by the proof at `unbalanced_proposition.tex`).
2. **Calibration.** Empirical calibration per country for nuisance parameters (trajectory shares, $\sigma_\nu$, $\sigma_\theta$). **Grid over** $\phi$ around $\hat\phi$ and include $\phi=0$ as a placebo. This avoids the "inference works only at one point" critique while keeping the defensive surface area manageable.
3. **Covariates.** Hold $x_{it}$ at the empirical matrix --- do not simulate ages, education, household size. Only outcomes and migration choices are regenerated each replication. This is closer in spirit to a wild bootstrap, and it short-circuits any need to defend a parametric model of $F_x$ per country.
4. **Confidence intervals.** Default GMM CIs in the simulation. Panel bootstrap CIs ($B=500$, resample individuals, preserve within-person waves) to be added to the empirical paper for the headline objects: $\hat\phi$, $\hat\Delta_{d_N}$, $\hat\Delta_{d_T}$. Tracked as a to-do item in `docs/TODO.md`.
5. **Runtime.** Local laptop with multicore parallelization for now. Design for cluster-scalability later.
6. **Language.** Pure Python --- DGP, GMM estimation, orchestration, parallelism. No Stata in the simulation loop. The GMM estimator will be a Python reimplementation of `run_grc`, numerically validated against Stata point estimates on the real datasets before any simulation is run. Validation itself has independent value as a cross-language replication of the paper's main results.
7. **Storage.** All simulation artefacts (configs, code, temporary files, results) live under `explorations/simulations/` on the local git repo. No writes to Dropbox, no writes to `data/processed/`. Keeps the Dropbox junction clean and avoids cross-machine sync issues.

## 7. Note on calibrated Monte Carlos and what they do / don't establish

Calibrating a simulation DGP to one's own empirical estimates is standard practice in applied micro (see Cameron and Trivedi 2005 Ch. 12; Davidson and MacKinnon 2003 Ch. 4). It is not overfitting in the pejorative sense because the object of interest is different:

- **Estimation** asks: given these data, what are the parameters? The concern is bias and consistency of point estimates. Circularity ("use the data to calibrate, then check if we recover what we put in") would be fatal.
- **Calibrated Monte Carlo** asks: at a DGP consistent with our point estimates, does inference work? The question is the finite-sample distribution of the *estimator*, not whether the estimator identifies the right thing. Calibrating to the data is exactly what one wants --- it puts the simulation in the empirically relevant region of the parameter space.

The legitimate critique --- and one we should preempt --- is that a single-point calibration can hide inference failures that occur *near but not at* the point estimate. Exercise 1 addresses this by sweeping $\phi$ across a grid. Exercises 2 and 4 address it by generating data under violations of the estimated specification (nonlinear LCA, regime heterogeneity). The combination turns the calibration from "self-consistency check" into "inference under plausible worlds including the one we estimated."

What the Monte Carlo cannot do --- and should not claim to do --- is confirm that $\hat\phi$ is the true $\phi$. That is the job of identification, not simulation.

## 8. Python architecture

### Layout

```
explorations/simulations/
├── README.md
├── configs/
│   ├── chn.yaml         # country calibration parameters
│   ├── idn.yaml
│   └── tza.yaml
├── src/
│   ├── grc.py           # GMM estimator: moments, weight matrix, J-stat, SEs
│   ├── dgp.py           # simulate (y, D) panels given theta, x, nu, params
│   ├── selection.py     # migration decision rule D_it = 1{...}
│   ├── bootstrap.py     # panel bootstrap (for empirical tables; not MC)
│   ├── validation.py    # compare Python GRC to Stata .ster estimates
│   ├── run_one.py       # single (country, arm, seed) -> one result row
│   └── orchestrate.py   # joblib.Parallel across (arms, seeds)
├── data/                # empirical x-matrix snapshots (per country, small parquet files)
├── output/
│   ├── validation/      # Python-vs-Stata comparison reports
│   ├── results_raw/     # per-cell parquet files
│   ├── results_tidy.parquet
│   └── tables/
└── SESSION_LOG.md
```

All paths are local to the git repo. No writes to Dropbox junctions, no writes to `data/processed/`.

### Execution model

A single replication, end to end in one Python process:

1. Load country config and the frozen empirical $x$-matrix for that country.
2. Draw $(\theta_i, \tau_i, \nu_{it})$ from the calibrated distributions.
3. Generate $D_{it}$ from the decision rule in `selection.py`.
4. Construct observed $y_{it}$ given $\theta, \tau, \nu, \beta, \phi, \gamma, x$.
5. Fit restricted GRC via `grc.fit()`: two-step GMM, analytic moment gradients, clustered sandwich variance, Hansen $J$.
6. Return one row of results to the orchestrator.

`orchestrate.py` parallelizes step 1--6 across cores with `joblib.Parallel(n_jobs=n_cores-1, backend='loky')`. Results accumulate in an in-memory list that writes to parquet on completion. No disk IO per replication.

### Why pure Python

- **Replication is its own deliverable.** A Python implementation of the main GMM estimator is an independent cross-language check on the paper's results. Point estimates and SEs agreeing to tight tolerance across two codebases is a stronger claim than "run it in Stata twice."
- **Speed.** No process-startup cost, no disk serialization per replication. On a laptop this changes feasible run sizes from "hundreds of reps per hour" to "thousands."
- **Tractability.** The restricted-GRC moment system is algebraically simple: a stack of trajectory-conditional sample moments, a two-step weight matrix, and a minimization over $(\beta, \phi, \mu_{\underline d}, \gamma)$. The estimator itself is maybe 300--400 lines of numpy with `scipy.optimize.minimize`. The 92 KB of `0_programs.do` includes data setup, multiple variants, formatting, and diagnostics --- the core estimator is a small fraction.
- **Parallelism is clean.** No shared state, no file-handle contention, no Stata-license concerns about concurrent processes.

### The validation step is non-negotiable

Before any simulation result is reported, the Python GMM must be numerically validated against the Stata `.ster` estimates:

- On each country's real dataset, both Python and Stata point estimates for $\hat\phi$, $\hat\beta$, every $\hat\mu_{\underline d}$, every $\hat\Delta_{\underline d}$, clustered SEs, and the Hansen $J$ statistic must agree to a preset tolerance (absolute tolerance for near-zero coefficients, relative tolerance otherwise).
- Proposed tolerances: point estimates agree to $10^{-4}$ absolute for $\phi$, $10^{-3}$ relative for $\mu, \Delta$; SEs agree to $10^{-2}$ relative; $J$ agrees to $10^{-3}$ relative.
- Any gap larger than the tolerance triggers a diagnostic pass before proceeding. Likely culprits: moment ordering, weight-matrix inversion (pseudo-inverse vs ridge), starting values, scale of the objective.
- The validation report (`output/validation/*.md`) is a first-class artefact of the project: it substantiates the paper's main results in a way the Stata code alone cannot.

### Module sketch: `grc.py`

A rough outline, not final API:

```python
class RestrictedGRC:
    def __init__(self, y, D, x, trajectory, cluster, switcher_mask, ...):
        ...  # cache moment design matrices
    def moments(self, theta):
        ...  # return (n, k) matrix of individual moment contributions
    def weight_matrix(self, g):
        ...  # two-step efficient weight matrix with clustering
    def J(self, theta, W):
        ...  # objective
    def fit(self):
        ...  # returns ParamEstimates (beta, phi, mu, gamma, SE, J, pvalue)
```

Analytic gradients of the moment function are easy to code and make optimization much more stable than numerical differentiation. `scipy.optimize.minimize(method='L-BFGS-B')` or `trust-constr` with Jacobian, clustered sandwich variance via the standard GMM formula, Hansen $J$ from the objective at the second-step solution.

### Parallelism on a laptop

`joblib.Parallel(n_jobs=n_cores-1)` on a modern 8--16 core laptop. For a pilot run of 100 replications on one country-arm, expect minutes. For the full design (4 arms $\times$ 3 countries $\times$ 1,000 reps = 12,000 fits), expect a few hours, probably overnight at worst. Cluster scalability is automatic: `orchestrate.py` takes a seed range as a CLI argument, so a cluster scheduler can dispatch ranges across nodes without code changes.

### Scalability

- **Start:** 100 replications, single country (TZA), single DGP arm.
- **Scale out (same code):** 1,000--2,000 replications by widening the seed range.
- **Scale up (minor change):** dispatch seed ranges across cluster nodes.
- **Sideline use:** the same `grc.py` implementation powers the panel bootstrap CIs that `docs/TODO.md` tracks for the empirical tables.

## 9. Implementation path

**Stage A0 --- scaffold (local, ~0.5 day):**
- Create `explorations/simulations/` layout.
- Snapshot the empirical $x$-matrix per country to `data/` as parquet.
- Stub out `grc.py`, `dgp.py`, `selection.py`, `run_one.py`.
- End-of-stage check: smoke-test runs end to end with placeholder parameters.

**Stage A1 --- Python GMM implementation (local, ~2--4 days):**
- Code the moment system, weight matrix, clustered variance, and $J$-statistic in `grc.py`.
- Analytic gradients.
- Start-value logic (pull from the Stata `initial_values` program's behavior).
- Validate against Stata `.ster` estimates for CHN, IDN, TZA. Produce `output/validation/{country}.md` reports.
- **Hard gate:** cannot proceed to simulation until tolerances in §9 are met.

**Stage A2 --- Exercise 1 pilot (TZA, 100 reps):**
- Calibrate TZA from the validated Python replication.
- Parallelize with joblib.
- Check: empirical coverage of GMM CI, bias and RMSE of $\hat\phi$.

**Stage A3 --- Exercise 1 full (CHN, IDN, TZA, 1,000 reps):**
- All three countries, $\phi$-grid sweep.

**Stage B --- Exercises 2--4:**
- DGP arms: nonlinear LCA, regime heterogeneity, $A_4$ violation.
- OLS/FE alongside GRC.
- Power curves for Hansen's $J$.

**Stage C --- writeup:**
- Simulation appendix (~3--5 pages), one table per exercise.

## 10. Open questions resolved (2026-04-22)

1. **Bootstrap for the empirical paper.** → Tracked in `docs/TODO.md`, not in scope for simulation work. Execute after Stage A3 when the Python GMM is validated and available for $B=500$ bootstrap replications.
2. **Covariates.** → Hold at empirical $x$-matrix per country. Snapshot to parquet in `explorations/simulations/data/` during Stage A0.
3. **Storage.** → All artefacts in `explorations/simulations/` on local git. No Stata files written to disk --- the pure-Python decision makes this moot.

---

*Next step: proceed to Stage A0 scaffold. The exploration-fast-track rule allows implementation without a formal spec in `explorations/`. If results are promising, Stage A1 would naturally graduate into a formal spec + plan in `docs/specs/` and `docs/plans/`.*
