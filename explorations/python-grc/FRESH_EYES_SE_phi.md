# Fresh-eyes review of the SE(phi) divergence

**Date:** 2026-04-23
**Author:** second pass after re-reading FINDINGS_SE_phi.md and the dump logs.
**Context:** Python GRC port matches Stata point estimates to 3-4 decimals on
IDN/cons/urban/unb but reports SE(phi) = 0.199 vs Stata's 0.0705 (2.8x).
Existing diagnosis pins the gap on Python's L-BFGS-B finding a "lower" step-1
minimum than Stata's `gmm`; proposed remedy is a `match_stata=True` mode that
loosens Python's tolerance to mimic Stata.

This memo argues that diagnosis is **mechanically correct but misses the deeper
issue**, and that the proposed remedy is a hack that will hide a real
weak-identification problem in the simulations downstream.

## 1. A discrepancy in the Stata log itself

`dump_stata_step1.log` reports two different Q values from a *single* `gmm
onestep` call on the same data:

```
line 3011:  Final GMM criterion Q(b) = .0013302
line 3088:  step 1 Q(b) = .00194988
```

The first is what Stata prints right after optimization; the second is `e(Q)`
(the value in `stata_step1_meta.csv`). The ratio is 1.466, which is neither
`n` nor `m` nor any obvious dof factor.

`FINDINGS_SE_phi.md` quoted **0.00195 as Stata's Q**. That comparison is what
made it look like "Stata stops higher than Python." If the operative comparison
is instead **0.0013302 (Stata) vs 0.00133 (Python), they are essentially
identical at the optimum.** Two stopping points with the same Q but different
parameter vectors is a flat ridge / multiple local minima, not a tolerance gap.

Action item: trace what `e(Q)` actually computes vs the printed criterion.
Stata's `gmm` does post-optimization re-evaluation of `g` and may apply a
different normalization to `e(Q)`. Until we know which Q is the true
step-1 objective, every subsequent comparison rests on a wobbly premise.

## 2. The eigenstructure already told us this

`FINDINGS_SE_phi.md` line 73-87 shows that 97% of Var(phi) loads on a single
eigenvector with eigenvalue 2.22e-04 (vs the next-strongest 1.06e-03). phi
loads 79% on that direction; no other parameter does.

That is the textbook signature of weak identification of phi: the GMM
objective is nearly flat in one direction, and phi is the parameter that
direction picks up. Under weak ID:

- The sandwich SE is fragile by construction. It is `(G'WG)^{-1}` flavoured
  by W; small changes in W tilt the inverse along the weak direction and
  swing the variance.
- Different reasonable choices of W (iterated fixed point, two-step, even
  re-evaluating S at a slightly different theta) give materially different
  SEs. None is "wrong."
- Optimizers may legitimately stop at distinct points along the flat ridge
  and report different theta with comparable Q.

The 2.8x SE(phi) difference is **the symptom we should expect** when an
estimator with this eigenstructure is computed via two-step GMM in a
finite sample. The "match Stata" framing implicitly treats Stata's number
as ground truth. It is not. It is one of many defensible numbers.

## 3. Why the proposed `match_stata=True` is a hack we should refuse

The session log's Step 2 proposes:

> Use Stata-style initial values, do 2-step with a looser step-1 tolerance
> chosen to match Stata's stopping behavior, report sandwich SE.

What this does:

- Hand-tunes Python's optimizer to land on Stata's step-1 stopping point.
- Computes `W_2 = S^{-1}(that_theta_1)` and reports the sandwich SE.

What it doesn't do:

- Justify why Stata's stopping point is preferable to Python's.
- Address the underlying weak-identification problem.
- Survive into the simulation. In Monte Carlo, "loosen Python's tolerance
  to mimic Stata's tolerance" is undefined --- there is no Stata in the
  loop. We would either bake the looser tolerance in for all replications
  (biased toward producing low SEs) or report the iterated SE and have
  the simulation contradict the empirical paper.

The user is right to dislike this. **Drop it.**

## 4. Fresh-eyes diagnostic ideas not yet tried

Listed in priority order (cheapest first).

### 4a. Reconcile Stata's own Q discrepancy (cheap, high information)

Add to `dump_stata_step1.do`:

```stata
mata
  b1 = st_matrix("e(b)")
  Z  = st_data(., "all_instruments_in_order")
  // ... rebuild g(b1) and W_1 in Mata, compute g'W_1 g, n*g'W_1 g, etc.
end
di e(Q), e(N)*e(Q), e(Q)/e(N)
```

This pins down which formula `e(Q)` uses. Once we know that, we can either
revise FINDINGS or confirm the "step 1 Q" was actually 0.00195 for some
defensible reason.

### 4b. Both step-1 stopping points: are they stationary? (cheap)

At each of the two theta_1 vectors (Stata's and Python's), evaluate
`||grad(Q)||` analytically. If both have ||grad|| approximately 0, both are
local minima. If Stata's has nonzero grad, Stata stopped before reaching
the FOC and Python's is the better step-1 point. ~30 seconds in Python.

### 4c. Multistart on step 1 (~10 min)

Run Python step-1 from 50 random initial values. Tabulate the distinct
local minima. If there's only one, Stata-vs-Python is just convergence
tolerance. If there are several, this is a multimodal landscape and we
need to think much harder about which one to use.

### 4d. Tighten Stata and re-run (cheap, decisive)

```stata
gmm ..., onestep winitial(unadjusted) from(initial) ///
    tolerance(1e-12) nrtolerance(1e-12) iterate(2000)
```

If Stata moves toward Python's theta_1, single basin and Stata was just
stopping early. If Stata stays at its current theta_1, the two are in
different basins (or on separate parts of a flat ridge).

### 4e. Continuous updating estimator (CUE) (~16 min, one fit)

CUE solves `min_theta n * g(theta)' S^{-1}(theta) g(theta)` --- W and theta
move together at every step. CUE has the same asymptotic distribution as
two-step GMM and iterated GMM, but in finite samples its SE is invariant
to the W-vs-theta path because it uses the SAME theta in both. If CUE
gives SE(phi) close to either Python's or Stata's, that pins which
W-choice the data actually supports.

### 4f. Cluster-S formula audit (cheap)

Stata's `vce(cluster pid)` applies a finite-sample correction:
`(n-1)/(n-k) * G/(G-1)`, where G is the number of clusters and k the
number of estimated parameters. Confirm Python's `_cluster_S` applies
the same factor on every call (during W updates AND in the sandwich
meat). A missing factor on one of those would produce a small but
consistent W discrepancy.

The fact that Python matches Stata exactly when given Stata's W suggests
the dof factor is correct AT the W level. But two-step Stata uses W_2
computed from theta_1, where the dof correction may interact differently
than in iterated GMM where W is recomputed at theta_k. Worth checking
the small-sample correction is applied in both passes consistently.

### 4g. Anderson-Rubin / weak-ID-robust CI for phi (~30 min once coded)

For the phi parameter only, invert the Anderson-Rubin (or
Stock-Wright S) statistic over a grid in phi, holding nuisance
parameters at their profiled optima. The resulting CI:

- Is valid under weak identification.
- Does not require choosing a W matrix.
- Is the same kind of inference the GRC paper itself develops.

If the AR CI is asymmetric or one-sided, the standard sandwich SE was
masking the real story. If the AR CI is symmetric and width matches
either 0.07 or 0.20, we have an external check on which W choice the
data prefers.

This is the right inference for phi *regardless* of which two-step W
we settle on.

### 4h. Cluster bootstrap for phi (~1-2 hours, once coded)

Resample individuals (clusters) with replacement, re-fit on each. SE(phi)
from the bootstrap distribution is path-free: it doesn't depend on a
particular W. With B=500, expect Monte Carlo SE on the bootstrap SE
estimate of about 5%. This is the SE we would defend in the paper.

The bootstrap is also on the to-do list for the empirical tables, so
this work amortizes.

## 5. Recommended path forward

Two things to do in sequence.

**Step A (today, cheap):** Run 4a, 4b, 4c, 4f. Together they test whether
the gap is (i) a measurement error in our reading of Stata's Q, (ii) a
single-basin tolerance gap, (iii) a multi-basin problem, or (iv) a small-
sample-correction asymmetry. The answer determines what we say in the
paper about the SE for phi.

**Step B (this week, more work):** Implement CUE and a cluster bootstrap
in Python. For the empirical paper, report SE(phi) from three sources
side-by-side: iterated two-step (current default), CUE, cluster
bootstrap. For the simulation, use the bootstrap.

If 4a reveals that Stata's `e(Q)` is computed with a different
normalization that is also what Stata internally minimizes, the entire
"Python finds a lower minimum" story might be a phantom. The simulation
plan should not commit to a remedy until we know.

## 6. What to commit to the paper

Whatever we do, the paper should not present a single SE for phi as
ground truth. The honest summary of what we have learned:

> phi is weakly identified in this design (97% of its variance comes from
> a single weak eigendirection of the moment Jacobian). The standard
> sandwich SE is sensitive to which W matrix is plugged in: iterated GMM
> at the fixed point gives SE(phi) ~ 0.20; Stata's two-step recipe at
> theta_1 gives SE(phi) ~ 0.07. We report the bootstrap SE as the primary
> inference and present the iterated and two-step SEs as a sensitivity.

This is true, defensible, and reflects what the data actually supports.
It also pre-empts the referee question we will otherwise get: "your
Stata code reports SE 0.07 but your Python code reports 0.20 --- which
is right?" The honest answer is that the question is malformed.

## 7. Open question for the user

Before any more code: is **phi** a parameter we want to do precise
inference on, or is the headline really `Delta_{d_N}` and `Delta_{d_T}`?
phi enters the extrapolation linearly, so its SE feeds the extrapolated-
returns SEs by the chain rule. If those extrapolated returns turn out to
inherit phi's W-sensitivity, the simulation appendix will need to say so.

If the headline is the extrapolated returns, we should rerun the
W-sensitivity check on `Delta_{d_N}` and `Delta_{d_T}` SEs as well,
not just phi. (It might be that those are robust because they integrate
over the data and average out the weak direction --- in which case phi's
fragility is mostly internal plumbing and the paper claims are safe.)
