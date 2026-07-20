# Plan: Stage 7, rebuild the extrapolation-support figure on the per-capita outcome

Date: 2026-07-20.
Spec: [2026-07-20-stage7-11b-figure-scale.md](file:///C:/git/ckt/quality_reports/specs/2026-07-20-stage7-11b-figure-scale.md), approved 2026-07-20 (author: "do the rebuild").

## Steps

1. Branch `stage7-11b-figure-scale` off main.
2. Edit [RP7/scripts/11b_extrapolation_support_figure.do](file:///C:/git/ckt/RP7/scripts/11b_extrapolation_support_figure.do): source every mu quantity from `logpc_consumption` (M1), key the defensive missingness drop to it (M2), say per capita in the x-axis title (M3), and correct the orphaned levels-transform comments (S1).
3. Shadow root `RP7/tests/stage0/stage7_root`: data junction to `RP7/data`, real copy of the post-fix scripts, empty output tree (M4).
4. Driver `gate_stage7_figure.do` in `RP7/tests/stage0` following the Stage 6 leg pattern: set `$dir` to the shadow root, run the figure script, write `gate_stage7_rc.txt` (S2).
5. Run via `stata-mp -e`; read the log for $\mu_{d_N}$ and the switcher support per country; check against the D-3 probe numbers (M5).
6. Report the manuscript-facing numbers (per-country $\mu_{d_N}$, support endpoints, percent into range or gap below) and show the author the combined figure (M6).
7. Author sign-off, critic pass, then commit; nothing ships to Overleaf (M7).

## Author additions, 2026-07-20 afternoon (M8-M10)

8. Add the support test to `11b_extrapolation_support_figure.do`: per country, regress the pid-level rural-mean outcome on an edge-trajectory dummy over never-migrants plus the lowest-mean switcher trajectory, robust SEs; post results to `extrapolation_support_test.csv`.
9. Rerun in the shadow root, read the TZA p-value, then run in the RP7 root so `RP7/output/figures` carries the shipped per-capita figure and test CSV.
10. Update subsec:extrapolation-support in main-updated.tex with the verified numbers (percentages, TZA gap, test result) and copy the combined PDF to the Overleaf figures folder; compile check, then sweep aux files.

## Expected outcome

TZA's $\mu_{d_N}$ about 0.055 log points below the switcher support; IDN and CHN inside; any departure from the probe is a surfaced finding.
