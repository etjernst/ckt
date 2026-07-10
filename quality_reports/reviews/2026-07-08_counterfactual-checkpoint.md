# Checkpoint: refreshed E1/E2 counterfactual numbers (pending decisions)

Date: 2026-07-08.
State: Phases 1--2 of [the fix plan](file:///C:/git/ckt/.claude/worktrees/lca-inversion/quality_reports/plans/2026-07-08-counterfactual-fixes.md) implemented and committed (`7ae1ae1`, `555eb6b`); baseline NOT regenerated; paper (Phase 3) untouched.
All acceptance checks pass: exporter filters reproduce the GMM $e(N)$ exactly in all four cells; CHN_uf runs on its true base (trajectory 4) end to end; the $\Delta_{d_N}$ self-check holds at 0.01 for IDN/TZA/CHN_rf; the unrestricted-vs-LCA-line switcher cross-check moves the gap by less than 0.05pp in every cell (the D1 validation sentence for the paper).

## Old vs new headline numbers (P3 gap, variant 1; percent of geometric-mean consumption)

| Cell | Old interval | Old point | New interval | New point | Value of migration old $\to$ new (point) |
|---|---|---|---|---|---|
| IDN | $[+5.7, +6.1]$ | $+5.7$ | $[+7.9, +10.8]$ | $+9.3$ | $+5.1 \to +0.8$ |
| TZA | $[+14.7, +22.8]$ | $+17.9$ | $[+18.6, +33.2]$ | $+23.5$ | $+4.4 \to +0.2$ |
| CHN rural-first | $[+9.9, +11.7]$ | $+10.6$ | $[+13.6, +17.2]$ | $+15.2$ | $+4.0 \to +0.8$ |
| CHN urban-first | $[+0.9, +1.2]$ | --- | $[+2.0, \infty)$ | $+2.5$ | $+5.2 \to +0.3$ |
| CHN national | $[+7.5, +8.8]$ | --- | $[+10.4, \infty)$ | $+11.7$ | $+4.3 \to +0.7$ |

E2 (essentially final): $\Delta_{d_N}^{rh} = +11.1\%$ with inversion CI $[+9.4\%, +13.9\%]$ (the point moves from the grid-snapped $+11.6\%$ to the `_n`-ster value, now consistent with the RF GRC table); economy-wide floor $+2.1\%$, CI $[+1.8\%, +2.7\%]$.

## What moved the numbers (decomposition, IDN as the worked example)

1. Lumped-return bug fix, the largest driver (+3.1pp on IDN): the old code fed `xb:unbalanced_choice` alone ($0.116$) as the unbalanced cell's return, but in the GMM unbalanced individuals carry no trajectory dummy, so their urban premium is $\Delta_{base} + $ `unbalanced_choice` $= 0.183$.
   Verified: this sum matches the auxiliary-OLS coefficient to the fourth decimal in all four cells, so the two estimators agree and there is no source ambiguity.
   This is a fourth bug the 2026-07-08 review missed.
2. The $\mu$ units fix (+0.2pp IDN, +2.1pp TZA): the never-migrant piece now uses model-consistent per-capita $\mu$'s.
3. Interval widening: switcher returns and the lumped return now vary inside the confidence region instead of being frozen (IDN width $0.4 \to 2.9$pp); the old tightness was an artifact.
4. Value of observed migration collapsed everywhere: under the stay-at-first-observation baseline (decision D3), the urban time of people already urban when first observed no longer counts; most of the old 4--5% was pre-panel migration.
   This sharpens the paper's pro-poor story: observed within-panel migration delivers under 1% while 8--33% sits unrealized.

## New finding: the CHN urban-first region is unbounded

The S-statistic accepts arbitrarily large $|\phi|$ for CHN_uf (min-over-$\beta$ Wald plateaus at $\approx 7.4$ against a critical value of $12.6$; verified at $\phi = \pm 10^4, \pm 10^5$): a Dufour-type unbounded weak-identification confidence set.
$\phi^{uf}$ is effectively unidentified, and along the accepted rays the LCA-line switcher returns diverge, so the UF gap's 95% upper bound is $+\infty$ --- and the national upper bound with it.
The old $[+0.9\%, +1.2\%]$ was a grid-truncation artifact (the lattice ended at $\phi = -3.5$; the 5b inversion's UF $\phi$ CI hits its own grid edge at $-3$ the same way).
The paper's "an order of magnitude smaller" contrast survives only as a statement about points and lower bounds, not about intervals.

## Decisions needed

D-a. Coverage variant: v1 (joint 3D region, honest $\ge 95\%$) vs v2 (2D region + $\Delta_{unb}$ CI fold, $\ge 90\%$ joint).
Empirically they differ by under 0.5pp everywhere (e.g., IDN $[7.9, 10.8]$ vs $[8.2, 10.7]$), so honesty costs nothing.
RECOMMENDED: v1.

D-b. UF/national unboundedness reporting: (i) report the open intervals as computed, with a footnote explaining that the UF sample cannot bound the LCA slope (RECOMMENDED: honest, and the RF-vs-UF contrast still reads off the points and lower bounds); (ii) switch UF's switcher returns to the unrestricted-fixed convention, which bounds the interval but deviates from D1 in one cell and needs disclosure; (iii) a disclosed a priori truncation of $\phi$ (arbitrary; not recommended).

D-c. Approve baseline regeneration once D-a/D-b are settled (plan item 12), after which `12_counterfactuals.do` runs strict.

D-d. Still open from before: the dispersion-envelope go/no-go ([its spec](file:///C:/git/ckt/.claude/worktrees/lca-inversion/quality_reports/specs/2026-07-08-dispersion-envelope.md)).

Phase 3 (paper edits in `main-updated.tex`, approved) starts once D-a and D-b are settled, since the quoted numbers and the interval-description prose depend on both.
