# Should the paper carry Monte Carlo simulations? A cost-benefit memo

2026-07-10.
Question from Emilia: would the paper benefit from simulations that "prove" the estimator is "correct," what does NOT having them do to referee composition and pr(reject), and is this a case where we deliberately leave the ask on the table for referees?
Inputs: the simulations worktree inventory, the existing coverage evidence on the lca-inversion side, the simulation-conventions standards (MCSE discipline, R sizing), and the journal profiles.

## What referees would actually be asked to believe

The exposure surface has three distinct pieces, and simulations speak to them very differently.

First, the GRC/GMM estimator itself.
Its consistency is inherited from published work (Suri 2011; the GRC companion paper), so a generic "the estimator recovers $\phi$" Monte Carlo proves nothing that a referee doesn't already grant.
A simulation aimed here is decoration; no referee at any of the plausible outlets rejects an applied paper for not re-deriving the finite-sample behavior of a published estimator.

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
If we want applied referees, the move is a compact methods footprint with the right citations, not a Monte Carlo showcase.

## Will not having simulations raise pr(reject)?

It depends almost entirely on the venue tier, so the target journal decision comes first.

At the Econometric Society journals (the draft is in ectaart, so ECMA or QE is at least on the table): yes, materially.
ECMA's screen is explicit ("are the asymptotic properties of the estimator established?"), and a nonstandard inference procedure with neither formal results nor finite-sample evidence is a genuine reject trigger there, not an R&R ask.
If ECMA/QE is the target, a coverage simulation is close to mandatory and belongs in the submitted draft.

At AER/QJE/ReStud/JPE: the missing simulation is an R&R demand with probability near one from the methods referee, but rarely the reject reason by itself.
Those referees reject on identification credibility and contribution; the calibration question is exactly the kind of bounded, deliverable ask that survives to a revision letter.

At REStat/EJ/JDE: the question and the identification carry the paper; JDE's editor is on record that a well-identified estimate does not by itself make a paper interesting, and no simulation buys interest.
A simulation appendix there is nice-to-have insurance, nothing more.

## The "leave something for the referees" logic, examined

The pocket-ask strategy is sound when the anticipated ask is predictable, cheap to deliver, and safe, meaning you already know that the answer comes out clean.
Here the first two conditions hold: the ask is foreseeable, the machinery mostly exists, and the old plan is a serviceable spec.
The third condition currently fails.
The $T=4$ generic synth says that the chi-squared inversion may under-cover at high $K$, and IDN sits at $K=27$.
If a referee-demanded simulation surfaces under-coverage mid-R&R, we would be repairing the paper's inference with the referee watching, and the headline intervals could widen in print.
That asymmetry is the decisive consideration: the simulation's main value right now is private information, not public persuasion.

## Recommendation

1. Run the empirically calibrated coverage check BEFORE submission, regardless of venue, and regardless of whether it ever enters the paper.
Scope it as the TODO already describes: per-country panels with empirical trajectory shares, the empirical unbalanced share, the production controls and sparse-switcher rule, LCA-true DGP at $(\hat\phi, \hat\beta)$; target the inversion CI for $\phi$, $\Delta_{d_N}$, and $\Delta_{\text{avg}}$.
Size it honestly: R=100 gives a coverage MCSE of $\pm 2.2$pp near 0.95, which cannot distinguish 0.93 from 0.95; R=500 ($\pm 1.0$pp) is the floor for a referee-grade number, R=1,000 comfortable.
Realistic cost: roughly half a day to a day extending the synthesizer, a pilot, then overnight-scale compute per country (the plan's "few hours" assumed R=100; scale by 5--10x and parallelize), plus a day of write-up.
Call it a focused week.
Budget one contingency: if under-coverage shows up, the Imbens-Kolesár F-adjustment is already spec'd as the fix and slots in as an additional table row, not a redesign.

2. Independently of any simulation, spend the free sentence: cite Stock and Wright (2000), Kleibergen (2005), and Dufour (1997) where the inversion is introduced, and cite the GRC companion paper's existing simulation for baseline calibration evidence.
This converts "trust us" into "standard weak-identification practice" at zero compute cost, and it is the single highest benefit-cost item on this list.
The CHN urban-first unbounded interval then reads as the Dufour-predicted signature of weak identification handled correctly, rather than as an anomaly.

3. Gate the publication decision on the target journal and on what the private run shows.
ECMA/QE target: include a short simulation appendix (one table: bias, empirical SE, coverage with MCSEs, per country).
AER/QJE/ReStud or the applied tier: keep it out of the submitted draft and hold it in the pocket---the referee ask is then genuinely welcome, because the answer is pre-verified and delivery is a one-week turnaround inside the R&R clock.
This preserves Emilia's leave-them-something instinct while deleting its downside.

4. Do not build the full four-exercise program now.
Exercises 2--4 (J-test size/power, OLS/FE/GRC selection-bias gap, LCA-violation robustness) are weeks of work that only pay at an Econometric Society venue or in a hostile second round; decide after the target journal and the first-round reports are known.
The already-run Verdier equivalence simulation stays in reserve for the "why not Verdier" question at no new cost.

## Bottom line

Simulations to "prove the estimator is correct" are not worth it at any venue---that question is settled by citation.
A calibrated coverage check on the inversion CI is worth running now for our own information, because we already have a warning sign at high $K$ and the worst place to learn its empirical relevance is inside an R&R.
Whether it appears in the submitted paper is then a venue decision, not a research one: in the draft for ECMA/QE, in the pocket everywhere else.
