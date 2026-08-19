# Stage 6 endpoint check: WCR11 phi regions at both grid edges

Date: 2026-07-26.
Scope: the 20 mainline WCR11 cells ({IDN, TZA, CHN, CHN_rf, CHN_uf} x {ct, c1, c2, ca}, all cuu, B = 999, phi grid [-5, 1]).
Evidence: [endpoint_check.csv](file:///C:/git/ckt/.claude/worktrees/wcr11-inversion-port/explorations/wcr11-stage6/logs/endpoint_check.csv), produced by [endpoint_check.do](file:///C:/git/ckt/.claude/worktrees/wcr11-inversion-port/explorations/wcr11-stage6/endpoint_check.do) reading all 80 attached sters (4 suffixes per cell).

## Contract checks

Every one of the 80 sters carries `e(inv_method) = wcr11`, B = 999, zero insufficient-draw grid points, and a fully scrubbed delta-inversion family.
Within every cell the four suffix sters (parent, `_n`, `_g`, `_a`) agree exactly.

## Per-cell 95% regions

| Cell | $\phi$ at Wald min | 95% region | Islands | Edge contact |
|---|---|---|---|---|
| IDN ct | -0.36 | [-0.86, 0.39] | 1 | none |
| IDN c1 | -0.36 | [-0.86, 0.41] | 1 | none |
| IDN c2 | -0.37 | [-0.92, 0.35] | 1 | none |
| IDN ca | -0.58 | five islands, hull [-4.15, 0.84] | 5 | none |
| TZA ct | -0.55 | [-0.75, -0.38] | 1 | none |
| TZA c1 | -0.56 | [-0.76, -0.35] | 1 | none |
| TZA c2 | -0.57 | [-0.78, -0.38] | 1 | none |
| TZA ca | -0.73 | [-1.30, -0.42] | 1 | none |
| CHN ct | -0.24 | [0.36, $+\infty$] | 1 | upper |
| CHN c1 | -0.24 | [-0.35, -0.14] $\cup$ [0.41, $+\infty$] | 2 | upper |
| CHN c2 | -0.28 | [-0.30, -0.28] $\cup$ [-0.25, -0.25] $\cup$ [0.48, $+\infty$] | 3 | upper |
| CHN ca | -0.33 | [-0.53, -0.18] $\cup$ [0.28, $+\infty$] | 2 | upper |
| CHN_rf ct | -0.04 | [-0.88, $+\infty$] | 1 | upper |
| CHN_rf c1 | -0.04 | [-0.77, $+\infty$] | 1 | upper |
| CHN_rf c2 | -0.14 | [-0.53, $+\infty$] | 1 | upper |
| CHN_rf ca | -0.16 | [-0.59, $+\infty$] | 1 | upper |
| CHN_uf ct | -5.00 | [$-\infty$, -0.52] $\cup$ [0.26, $+\infty$] | 2 | both |
| CHN_uf c1 | -5.00 | [$-\infty$, -0.50] $\cup$ [0.34, $+\infty$] | 2 | both |
| CHN_uf c2 | -5.00 | [$-\infty$, -0.54] $\cup$ [0.30, $+\infty$] | 2 | both |
| CHN_uf ca | -3.23 | [$-\infty$, -0.65] $\cup$ [0.37, $+\infty$] | 2 | both |

An endpoint printed as $\pm\infty$ means the accept region reaches that grid edge; whether it closes beyond the edge is unknowable without a wider grid.

## Findings

IDN and TZA are final: every region is interior to both edges at 95% and 90%, so the -5 lower widening fully contained them and no rerun is needed.
The IDN ca five-island region is interior on both sides; union-versus-hull presentation goes to the author with the movement memo.

CHN (pooled) and CHN_rf touch the +1 upper edge at 95% in all eight cells, so the upper-side truncation flagged in the 2026-07-25 handoff is real, not a rendering artifact.
Per the port plan's endpoint-check rule, these eight cells trigger a widened-grid rerun; the `phihi` override now exists (port branch commits ffdc03c, df097d3) and three rerun workers are staged at phi grid [-5, 5].

CHN_uf shows the weak-identification pattern the port plan's Stage 7 predicted: two half-open islands reaching both edges at 95% and 90%, in all four specs.
The honest report is the region as-is; presentation wording is the author's.

Two pooled-CHN anomalies for the movement memo and author attention.
First, the 90% region is empty in all four pooled CHN cells: at the 10% level every $\phi$ on the grid rejects, consistent with the Hansen J rejection in the pooled sample (the known institutional-heterogeneity issue that motivates the hukou split).
Second, in CHN ct and c1 the Wald-minimizing point (about -0.24) lies outside the 95% region, again a symptom of joint-test misfit in the pooled sample rather than of the bootstrap.
Neither anomaly appears in any hukou-split cell.

## Rerun proposal (pending author go)

Rerun the eight CHN and CHN_rf cells at phi grid [-5, 5], B = 999, reusing the Stage 6 detached-worker pattern (Minimized windows, full exe path, CPU-delta progress checks):

- [worker_chnhi1.do](file:///C:/git/ckt/.claude/worktrees/wcr11-inversion-port/explorations/wcr11-stage6/worker_chnhi1.do): CHN ct + c1, roughly 12 h.
- [worker_chnhi2.do](file:///C:/git/ckt/.claude/worktrees/wcr11-inversion-port/explorations/wcr11-stage6/worker_chnhi2.do): CHN c2 + ca, roughly 12 h.
- [worker_rfhi.do](file:///C:/git/ckt/.claude/worktrees/wcr11-inversion-port/explorations/wcr11-stage6/worker_rfhi.do): CHN_rf all four specs, roughly 7 h.

Timing basis: the Stage 6 run priced CHN at about 3.5 h and CHN_rf at about 1 h per 601-point cell; the 1001-point grid scales those by about 1.67.
CHN_uf is excluded per Stage 7 (report as-is); including it would add about 7 h and can only relabel where the open regions truncate, not close them.
The affected tables rebuild once, after the rerun lands, to avoid shipping intermediate CI strings.

## Addendum 2026-08-19: upper-widened rerun on [-5, 5]

The three rerun workers (CHN ct+c1, CHN c2+ca, CHN_rf all four; B = 999, phi grid [-5, 5]) completed between 08:17 and 10:59 on 2026-08-19 with zero failures, and the endpoint check was rerun on all 80 sters with the upper edge set to +5 for CHN and CHN_rf ([endpoint_check.csv](file:///C:/git/ckt/.claude/worktrees/wcr11-inversion-port/explorations/wcr11-stage6/logs/endpoint_check.csv); the [-5, 1] version is kept as `endpoint_check_grid_-5_1.csv`).
IDN, TZA, and CHN_uf are unchanged.

| Cell | 95% region on [-5, 5] | Islands | Edge contact |
|---|---|---|---|
| CHN ct | [0.36, $+\infty$] | 1 | upper (+5) |
| CHN c1 | [-0.35, -0.14] $\cup$ [0.41, $+\infty$] | 2 | upper (+5) |
| CHN c2 | [-0.30, -0.28] $\cup$ [-0.25, -0.25] $\cup$ [0.48, 4.00] | 3 | none |
| CHN ca | [-0.53, -0.18] $\cup$ [0.28, 3.85] | 2 | none |
| CHN_rf ct | [-0.88, $+\infty$] | 1 | upper (+5); 90% closes at 4.04 |
| CHN_rf c1 | [-0.77, $+\infty$] | 1 | upper (+5); 90% closes at 2.89 |
| CHN_rf c2 | [-0.53, $+\infty$] | 1 | upper (+5); 90% closes at 0.71 |
| CHN_rf ca | [-0.59, $+\infty$] | 1 | upper (+5); 90% closes at 0.55 |

Two pooled-CHN cells (c2, ca) close inside the widened grid, at 4.00 and 3.85.
The other six still reach +5 at 95 percent, while all four CHN_rf 90 percent regions are now interior; the pooled-CHN 90 percent regions remain empty.
Widening from +1 to +5 moved the CHN_rf 90 percent endpoints from open to interior but left the 95 percent regions open, which is the signature of a weak-identification upper tail rather than of a grid too narrow by a small margin.
Lean, for the author: report these six cells as open above the grid edge, as CHN_uf is reported, and stop widening; a further widening (say to +20) would cost roughly 3.5 h per CHN cell and 1 h per CHN_rf cell per 601-point grid equivalent and can only relabel where an open region truncates.
The table rebuild proceeds on these sters; the rendering of an edge-touching endpoint as $+\infty$ does not depend on the edge value.
