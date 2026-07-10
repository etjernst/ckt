# Should the paper carry Monte Carlo simulations? A cost-benefit memo

2026-07-10.
Question from Emilia: would the paper benefit from simulations that "prove" the estimator is "correct," what does NOT having them do to referee composition and pr(reject), and is this a case where we deliberately leave the ask on the table for referees?
Inputs: the simulations worktree inventory, the existing coverage evidence on the lca-inversion side, the simulation-conventions standards (MCSE discipline, R sizing), and the journal profiles.
Settled the same morning: the target is Econometrica, the estimator is not Suri's (2011), and econometric referees are preferred over applied-micro referees.
Those three facts drive the recommendation below.

## What referees would actually be asked to believe

The exposure surface has three distinct pieces, and simulations speak to them very differently.

First, the GRC/GMM estimator itself.
It builds on Suri's (2011) CRC framework but is not the same estimator: the trajectory-based GRC cast, the unbalanced-cell pooling, the LCA restriction with extrapolation to non-switchers, and the GMM implementation are this paper's own.
No published Monte Carlo covers this estimator at this design; the GRC companion paper's simulation is $T=2$, Suri-calibrated, and a related but distinct estimator, so a referee cannot be pointed to existing validation.
At Econometrica that makes finite-sample evidence on bias, RMSE, and coverage at CKT-calibrated designs part of establishing the contribution, not decoration.

Second, the LCA inversion confidence intervals, including the joint 3D $(\phi, \beta, \Delta_{\text{unb}})$ region behind the counterfactual table.
This is nonstandard inference, and the draft currently justifies it in one sentence (the identification boundary at $\phi = -1$ makes asymptotic standard errors unreliable) with zero citations to the weak-identification literature and zero finite-sample evidence.
The natural referee question is "how do I know that your inversion CI actually covers at 95% at your $(N, T, K)$?", and this question IS simulation-answerable.
The entire decision lives here.

Third, the LCA extrapolation itself: the headline never-migrant returns, and hence the misallocation numbers, ride on extrapolating the comparative-advantage line to 90%+ of the sample.
A simulation cannot prove this; under an LCA-true DGP the extrapolation validates by construction, and referees see the circularity immediately.
The honest defenses are the ones already in or near the paper: the Hansen J-test, the in-support figure (TODO'd: $\hat\mu_{d_N}$ sits inside the switcher hull in all three countries), and, if we wanted to spend more, an LCA-violation robustness arm (Exercise 4 of the old plan) that quantifies degradation when the restriction fails.
That last one is the only simulation with real content for piece three, and it is a "how wrong could we be" exercise, not a validation.

## What already exists

Machinery: a validated Python port of the GMM (matches Stata's $\hat\phi$ to 0.003; ~16 min per fit at IDN's real $N$), the inversion module, and a thorough CKT-calibrated simulation plan (endogenous trajectory formation, per-country calibration, empirical x-matrices, attrition arms)---but the plan's scaffold was never coded, and Stream C never started.
The one Monte Carlo that ran end-to-end is the Verdier equivalence simulation (300 fits, 70 minutes): it answers "why not Verdier," not "is the inversion CI calibrated," though it is a ready-made appendix if the cluster-robustness section survives.

Evidence: the generic synthetic checks on the lca-inversion side are double-edged.
At $T=3$ ($K=6$) the inversion CI covers at 0.90 (MC SE 0.030, R=100)---fine.
At $T=4$ ($K=14$) coverage of $\Delta_{\text{avg}}$ is 0.84 against nominal 0.95, four MC SEs below, with the mechanism documented (chi-squared finite-sample bias growing with $J_R$).
IDN's empirical spec has $K=27$.
So we privately hold evidence that the exact object a referee would probe may under-cover at exactly the country where the gap should be largest.
The GRC companion paper's own $T=2$ simulation (1,000 reps, Suri-calibrated shares) shows that the inversion CI covers close to nominal, which is citable support but at the wrong $(T, K)$.

## Will not having simulations change which referees we get?

Essentially no.
Editors assign referees from the abstract, the introduction, and the author-topic match; they do not read appendices before choosing.
The inversion CI already guarantees at least one econometrics-literate referee at any outlet worth submitting to---that die is cast by the inference section, not by whether a simulation appendix exists.
The one composition effect runs the other way: a prominent simulation section makes the paper read more methods-forward, which can nudge an editor toward a second econometrician instead of a second applied-development referee.
Since econometric referees are the referees we want, that genre shift is a benefit rather than a risk: a visible simulation study, formally stated assumptions, and weak-identification citations are exactly how the paper signals its intended referee pool to the editor.

## Will not having simulations raise pr(reject)?

The target is Econometrica, and there the answer is yes, materially.
ECMA's screen is explicit ("are the asymptotic properties of the estimator established?"), and its bar for applied papers is that they bring a new estimator or identification argument---which is precisely how this paper must position itself for the econometric referees we want.
A partly novel estimator plus a nonstandard inference procedure, with neither formal finite-sample evidence nor a citable validation, is a genuine reject trigger at ECMA, not an R&R ask.
For calibration: at AER/QJE/ReStud the missing simulation would be a near-certain R&R demand but rarely the reject reason; at ECMA the referee pool is drawn to evaluate the methodological contribution itself, and an unvalidated estimator IS the contribution failing its own screen.

## The "leave something for the referees" logic, examined

The pocket-ask strategy is sound when the anticipated ask is predictable, cheap to deliver, and safe, meaning you already know that the answer comes out clean.
At Econometrica the core validation cannot be the pocket item: an ECMA methods referee treats missing finite-sample evidence on a new estimator as a screen failure at first reading, and there is no second reading.
The pocket items instead come from the second tier of the old plan: the Hansen J size/power study (Exercise 2) and the OLS/FE-vs-GRC selection-gap quantification (Exercise 3) are predictable, bounded, deliverable-in-a-revision asks that referees can feel good about extracting.
One more reason the core simulation must run before submission rather than during R&R: the $T=4$ generic synth says that the chi-squared inversion may under-cover at high $K$, and IDN sits at $K=27$.
If under-coverage is real, we want to adopt the Imbens-Kolesár F-adjustment and report adjusted intervals in the submitted draft, not repair the paper's inference with a referee watching while the headline intervals widen in print.

## Recommendation

1. Build the simulation study for the submitted draft, scoped in three arms and in this priority order.
Arm one, estimator validation (the old plan's Exercise 1): bias, empirical SE, RMSE, and coverage for $\phi$, $\Delta_{d_N}$, $\Delta_{\text{avg}}$, and $\Delta_{d_T}$ under an LCA-true DGP at per-country CKT calibration (empirical trajectory shares, empirical unbalanced share, production controls, the sparse-switcher rule).
Arm two, inference validation: coverage of the LCA inversion CI at the empirical $(N, T, K)$, which comes from the same replications at the cost of one extra metric, with the Imbens-Kolesár F-adjustment as the pre-planned fix if the $T=4$ warning sign materializes at IDN's $K=27$.
Arm three, misspecification (Exercise 4): an LCA-violation arm that quantifies how the estimates and the J-test behave when the linear restriction fails, because an ECMA referee will probe the identifying functional form as a matter of course and this arm converts that probe into a table we already printed.
Size it honestly: R=100 gives a coverage MCSE of $\pm 2.2$pp near 0.95, which cannot distinguish 0.93 from 0.95; R=1,000 ($\pm 0.7$pp) is the ECMA-grade target.
Realistic cost: the Python GMM port is validated and the old plan is a serviceable spec, so this is roughly two to three weeks of calendar work, with the compute overnight-scale per country once parallelized.

2. Simulations complement formal statements; they do not substitute for them.
ECMA expects the identifying assumptions and the estimator's asymptotic properties stated as propositions, and the inversion needs its formal footing: cite Stock and Wright (2000), Kleibergen (2005), and Dufour (1997), and state the conditions under which the S-statistic inversion delivers valid coverage.
The CHN urban-first unbounded interval then reads as the Dufour-predicted signature of weak identification handled correctly, rather than as an anomaly.
This formal pass is a separate work item from the simulations and probably the harder one.

3. Leave Exercises 2 and 3 in the pocket.
The Hansen J size/power study and the OLS/FE-vs-GRC selection-gap quantification are the referee asks we can welcome: predictable, bounded, safe, and deliverable inside an R&R clock.
The already-run Verdier equivalence simulation also stays in reserve for the "why not Verdier" question at no new cost.

## Bottom line

For Econometrica the question is no longer whether to add simulations but how to scope them: the estimator is the paper's methodological contribution, no published Monte Carlo covers it, and ECMA referees screen on exactly that gap.
Run the three-arm study (estimator validation, inversion CI coverage, LCA violation) before submission and put it in the draft; hold the J-test power and selection-gap exercises back as the deliberate referee asks.
The known $T=4$ under-coverage warning makes the pre-submission timing non-negotiable: if the F-adjustment is needed, we adopt it before a referee ever sees the intervals.
