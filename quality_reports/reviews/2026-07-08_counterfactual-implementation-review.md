# Implementation review: aggregate consumption gap (E1) and removing-hukou (E2) counterfactuals

Date: 2026-07-08.
Scope: the two counterfactual experiments the paper will keep --- the aggregate consumption gap (`tab:counterfactual_misallocation`) and the removing-hukou bound (`tab:hukou_bound`) --- as implemented in `RP7/scripts/12_counterfactuals.do`, `RP7/scripts/_export_e1_inputs.do`, `RP7/scripts/_export_e1_inputs_hukou.do`, and `explorations/python-grc/counterfactuals.py`, checked against the counterfactual subsection of the Overleaf `main-updated.tex` (lines 781--920).
The 2026-06-24/25 review rounds covered prose only (critic-writing); everything below is new.
No fixes applied; script changes require approval per the script-safety rule.

## Verdict

The inference machinery (joint $(\phi,\beta)$ inversion region, hull projection, endpoint scaling for the hukou bound) is correctly built, and every number in the paper traces exactly to `counterfactual_results.csv`.
But the E1 aggregate feeds the LCA extrapolation with the wrong $\mu_{\underline{d}}$ objects (raw household-level log consumption instead of the model's per-capita, covariate-consistent $\mu$), which materially understates the Tanzania headline, and three further design choices (the lumped unbalanced cell, the fixed "unrestricted" switcher deltas, the zero-migration baseline) do not match what the paper says the exercise does.
The hukou bound (E2) is essentially sound; its issues are minor consistency points.
Several of the "weird results" the user noticed are mechanical consequences of these items; a reading guide is at the end.

## Critical

### C1. E1 uses raw household-level $\mu_{\underline{d}}$, not the model's per-capita $\mu_{\underline{d}}$; Tanzania headline materially understated

The exporters compute `mu_d` as the trajectory mean of individual rural-period `ln(consumption)` ([_export_e1_inputs.do](file:///C:/git/ckt/.claude/worktrees/lca-inversion/RP7/scripts/_export_e1_inputs.do) lines 134--152, same in the hukou exporter).
That is household-level log consumption: no division by `hhsize_cube` and no covariate adjustment.
The LCA line $\Delta_{d_N} = \beta + \phi(\mu_{d_N} - \mu_{\underline{d}_0})$ lives in log per-capita, covariate-consistent units; the GRC sters carry those $\mu$'s (`mu:never`, `mu:switcher_k`), and the inversion module uses the equivalent auxiliary-OLS $\alpha$ differences.
Because household size varies systematically by trajectory, the differences do not cancel; for IDN the sign of $\mu_{d_N} - \mu_{\underline{d}_0}$ even flips (raw $+0.099$ vs model $-0.008$).

Verified against the sters (read directly, 2026-07-08):

| Cell | $\mu_{d_N}-\mu_{base}$ raw (used) | model | $\Delta_{d_N}$ used | model-consistent | ster `inv_dN` |
|---|---|---|---|---|---|
| IDN | $+0.0989$ | $-0.0081$ | $0.015$ | $0.071$ | $0.07$ |
| TZA | $-0.1157$ | $-0.1885$ | $0.218$ | $0.270$ | $0.27$ |
| CHN_rf | $+0.0031$ | $-0.0243$ | $0.105$ | $0.106$ | $0.11$ |
| CHN_uf | $+0.1866$ | $+0.1880$ (base 4) | $0.007$ | $0.006$ | --- |

The model-consistent values reproduce the sters' own inversion points (`inv_dN`), confirming the raw-data construction is the outlier.
Impact runs through $\pi_{d_N}$: TZA ($\pi_{d_N}=0.41$) point gap moves from $0.1645$ to $\approx 0.1860$ log points ($17.9\% \to 20.4\%$), and the published interval $[+14.7\%, +22.8\%]$ shifts up by roughly $0.41 \times 0.073 \times |\phi|$ at each accepted grid point (one to three log points); IDN moves by only $+0.2$ log points ($\pi_{d_N}=0.039$); both CHN cells are negligible ($\phi^{rf}$ tiny; $\pi_{d_N}^{uf}$ tiny).
Beyond the magnitudes, E1's never-migrant return is currently inconsistent with the paper's own $\Delta_{\text{never}}$ in the GRC tables (IDN: 0.015 here vs 0.07 there).

Root cause: the exporters' step 3 tried to pull `mu:switcher_k` off the ster but matched against `local b_names : colnames b`, which strips equation prefixes, so the loop silently matched nothing (the log shows "switcher trajectory codes from parent ster:" empty) and step 5's raw-data fallback became the de facto source.
Fix: extract the ster $\mu$'s with `coleq`+`colnames` pairs (or reuse the auxiliary-OLS $\alpha$'s already fitted inside `counterfactuals.run_cell`), then regenerate and re-baseline (`regenerate_baseline=True`).

### C2. The with-$d_T$ variant mixes two consumption scales; the quoted no-fallback numbers are not meaningful

`compute_alpha_dT_obs` returns the mean of `lndepvar` (per-capita) for always-urban urban observations, but `lca_delta_dT` differences it against `mu_base` from the raw household-level CSV ([counterfactuals.py](file:///C:/git/ckt/.claude/worktrees/lca-inversion/explorations/python-grc/counterfactuals.py) lines 474--482 and 327--341).
For IDN that makes $\alpha_{d_T} - \mu_{base} \approx -0.8$ where the model-consistent difference is positive, so $\Delta_{d_T}$ at the point is $\approx +0.9$ against the ster's `inv_dT` $= -0.14$.
The headline P3 numbers are immune (they zero $d_T$), but the paper's caveat sentence quotes the with-$d_T$ upper bounds ($+58.0\%$ IDN, $+145.0\%$ TZA, "several orders of magnitude" CHN-uf, main-updated.tex line 864); those numbers are driven by the unit mismatch as much as by the $\phi=-1$ pole and should not be quoted until $\alpha_{d_T}$ and $\mu_{base}$ are on the same scale (the covariate-adjusted per-capita construction `grid_delta_always_md_inversion` already uses).

## Major

### M1. The "unrestricted" switcher returns are actually restricted LCA-fitted values, held fixed while $(\phi,\beta)$ vary

The `_d` ster is produced by `nlcom` on the restricted fit: $\Delta_s = \Delta_{base} + \phi(\mu_s - \mu_{base})$ ([0_programs.do](file:///C:/git/ckt/.claude/worktrees/lca-inversion/RP7/scripts/0_programs.do) lines 2181--2201).
Verified numerically: IDN `Delta_3` in the CSV ($-0.053685$) equals $\beta + \phi(\mu_3 - \mu_2)$ from the parent ster to machine precision, and `Delta_base` equals the base's `Delta_k` exactly in every cell.
Two consequences.
First, the paper's identification narrative ("The unrestricted GRC identifies the switcher returns $\Delta_{\underline{d}}$ ... non-parametrically", line 820) does not describe the implementation; the switcher deltas feeding equation (1) sit on the restricted LCA line at the point estimates.
Second, the CI propagation is internally inconsistent: if the switcher deltas are LCA objects they should move with $(\phi, \beta)$ across the accepted region, but `delta_at` holds them fixed at the point-estimate line while only $\Delta_{d_N}$ and $\Delta_{d_T}$ vary.
Fix: either feed genuinely unrestricted returns (the auxiliary-OLS `beta[s]` coefficients, already computed in the same function) held fixed, or recompute $\Delta_s(\phi,\beta) = \beta + \phi(\mu_s - \mu_{base})$ at each lattice point; then align the paper sentence with whichever convention is chosen.
Numerically small either way (switcher $\pi$'s are tiny), but a referee reading code against the paper will catch it.

### M2. The lumped unbalanced cell drives the headline gaps under an undisclosed and selection-inconsistent assumption

`traj_for_agg = -1` collects every unbalanced individual --- movers and stayers alike --- and `delta_at` assigns them all the GMM coefficient on `unbalanced_choice` ($\hat\Delta_{unb}$: IDN $0.116$, TZA $0.370$, CHN_rf $0.183$, CHN_uf $0.098$), which is identified from unbalanced movers only.
Optimal sort then sends the whole cell urban.
Decomposing the published points: the lumped cell is $\approx 96\%$ of the IDN gap ($0.0535$ of $0.0558$), $\approx 70\%$ of CHN_rf, $\approx 42\%$ of TZA, and essentially all of every "value of observed migration" number.
This contradicts the paper's own selection logic: balanced never-migrants (IDN: 3.9\% of pids) get careful LCA extrapolation, while unbalanced stayers inside the 89\% lumped cell get the raw mover return with no comparative-advantage correction.
The paper discloses the cell's existence (lines 837--839) but not the return assumption.
Relatedly, no uncertainty in $\hat\Delta_{unb}$ (or in the fixed switcher deltas, $\pi$'s, $\bar D$'s) enters the CI --- only $(\phi,\beta)$ vary --- which is why the IDN interval is implausibly tight ($[+5.7\%, +6.1\%]$) around a number that is $96\%$ lumped-cell: the dominant term carries zero inference.
The paper's sentence "All three intervals are convex hulls of the joint $(\phi,\beta)$ confidence region" is literally accurate but a reader will misread the tight IDN interval as high precision about the counterfactual rather than as "the varying part is small".
Fix options (needs a user decision): disclose the assumption and propagate the `unbalanced_choice` sampling variance into the interval; or LCA-extrapolate unbalanced stayers from their observed rural means; or restrict the E1 population to the balanced panel and say so.

### M3. Zero-migration baseline: prose and equation (1) disagree, and the value column silently excludes $d_T$ everywhere

The prose defines $W_{\text{zero}}$ as workers staying in "the location of their initial trajectory observation" and claims the scenario "does not undo extensive-margin migration that already occurred before the panel begins" (lines 800, 804).
Equation (1)'s value term $\sum_{\underline{d}} \pi_{\underline{d}} \Delta_{\underline{d}} \bar D_{\underline{d}}$ --- which the code implements exactly --- is instead the everyone-starts-rural baseline: it credits urban-first switchers and the urban time of the lumped cell (IDN $\bar D_{lump} = 0.48$, CHN_uf $0.86$) as "value of observed migration" even where no within-panel move occurred.
Under the stated initial-location convention those workers should contribute $\Delta_{\underline{d}}(\bar D_{\underline{d}} - D^{init}_{\underline{d}})$, much of it zero or negative.
Separately, `point_wms_p3` zeroes the $d_T$ contribution in every cell --- including CHN_rf, whose region never crosses $\phi = -1$ --- and the paper's fallback paragraph (lines 858--864) describes the drop as applying to the gap in the boundary-crossing cells only; the table does not say the value column is a no-$d_T$ variant everywhere.
Fix: pick one baseline convention, state it, and make the equation, the code, and the $d_T$ handling of the value column consistent with it.

### M4. CHN_uf point estimate mixes base-4 and base-2 coordinates; no guard verifies the ster base

The CHN_uf ster's base trajectory is 4 (`Delta_base` $= 0.18880 =$ `Delta_4` in the `_d` ster, and $\ne$ `Delta_2` $= 0.06508$), while the Python driver hardcodes base 2 for the joint CI and for `mu_base` (`BASE_TRAJECTORY = 2`, [counterfactuals.py](file:///C:/git/ckt/.claude/worktrees/lca-inversion/explorations/python-grc/counterfactuals.py) line 356).
The hull is internally consistent (grid $\beta$ and $\mu_{base}$ both in base-2 coordinates), but the plug-in point `delta_at(phi_hat, beta_hat)` combines the ster's base-4 $\hat\beta$ with the base-2 $\mu$, which is wrong whenever the two bases differ.
Numerically forgiving here ($\Delta_{d_N}^{uf}$ is $0.007$ vs $0.006$ done correctly, and $\pi_{d_N}^{uf} = 0.047$), but nothing in the code would catch a case where it is not: add an exported base code (or assert `beta_hat` matches the base's `Delta_k`) before trusting any refreshed run --- especially relevant because the CHN sweep-refit plan will regenerate exactly these sters.

### M5. The CHN national 95\% label overstates coverage

`combine_national` sums the endpoints of two independent per-regime 95\% hulls with fixed weights.
Simultaneous coverage of the two regions is only guaranteed at $\ge 90\%$ (Bonferroni), so the combined interval labeled 95\% is honestly a $\ge 90\%$ statement.
Fix: build the per-regime regions at 97.5\% for the national row, or relabel.

## Minor

1. The paper promises a second E1 magnitude --- the Gaussian dispersion envelope swept over $c \in [0,1]$ (lines 827--832) --- but no code implements it; only the floor exists. Either build it or cut the paragraph before submission.
2. The four-way decomposition the paper says "we also report" (line 837) is not in the table, the CSV, or any artifact; the TZA-never/IDN-lumped dominance claims (line 839) check out against my recomputation (TZA never $\approx 54\%$ of the gap, IDN lumped $\approx 99\%$ of the value), but a reader cannot verify them. Persist per-trajectory contributions (already computed in `AggregateResult`) to the results CSV.
3. Hukou bound: the reported $+11.6\%$ per-never-migrant return is the grid-snapped inversion point (`inv_dN` $= 0.11$; grid step 0.01), while the RF GRC table's $\Delta_{\text{never}}$ shows the `nlcom` point ($0.106$, i.e. $+11.1\%$). Same object, two values in the same paper; use the `_n` ster point with the inversion CI, and note the CI endpoints ($[0.09, 0.13]$) are also grid-snapped, so "$[+9.4\%, +13.9\%]$" carries false precision at the tenths digit.
4. $\pi_{d_N}^{rh} = 0.27$ counts balanced-panel never-migrants only; the lumped RF cell (58\% of RF pids) contains further stayers. Fine for a floor (it only shrinks the population treated), but the prose "never-migrant share within the rural-hukou subsample" (line 888) invites the wrong reading; say "balanced-panel never-migrant share". The footnote's binomial-SE argument checks out (SE $\approx 0.0028$ on $n = 25{,}491$).
5. No check that the accepted joint-CI region stays interior to the $(\phi,\beta)$ lattice ($\phi \in [-3.5, 1]$ hukou / $[-2, 1]$ else, $\beta \in [-0.5, 0.5]$); a truncated region silently narrows the hull. Also `marginal_phi`/`crosses_boundary` are computed but never persisted, so this cannot be audited from outputs. Note the UF ster's `inv_phi` $= -3$ sits exactly at the 5b grid edge, so $\phi^{uf}$ is effectively unbounded below --- consistent with the CELLS comment, but worth persisting.
6. $\pi_d$ and $\bar D_d$ are computed on the drop-if-missing(consumption, choice) sample while the auxiliary OLS drops further rows (controls); and `hukou_population_weights` uses unfiltered dta pids. The 74/26 split reproduces either way; harmless, but one sample definition would be cleaner. The paper's "urban time shares are deterministic functions of trajectory definitions" (line 819) is false for the lumped cell, whose $\bar D$ is estimated.
7. `pi_helper` in both exporters is created and never used.

## Verified correct

- Equation (1) is implemented exactly (`evaluate_aggregate`), $\pi_d$ sums to 1, the NaN-delta guard is sound.
- The joint $(\phi,\beta)$ region is a proper Stock-Wright-type S-statistic (dof $= K$, base moment included), weak-ID valid; flood-fill and hull projection are correct.
- P3's zeroing of $d_T$ is a genuine lower bound for the gap (per-trajectory gap contributions are non-negative), and CHN_rf's with-$d_T$ hull equals its P3 hull exactly, as theory predicts when $\Delta_{d_T} \ge 0$ over the region.
- E2 hukou bound: $\pi^{rh} \cdot \pi_{d_N}^{rh} = 0.7386 \times 0.2721 = 0.2010$; endpoint scaling by a positive constant is the exact test-inversion CI; `floor_positive` holds; every table/prose number ($+11.6\%$, $[+9.4\%, +13.9\%]$, $+2.2\%$, $[+1.8\%, +2.6\%]$, $0.74 \times 0.27 \approx 0.20$, "four in five") reproduces from the inputs.
- The Jensen/floor argument (line 826) and the "bound not magnitude" argument for equation (2) (line 889) are correct as stated.
- All paper numbers match `counterfactual_results.csv`; the baseline self-check harness fails loudly on drift; `prepare_data` correctly retains unbalanced individuals (the 2026-05-20 sample bug stays fixed).
- The E2 inputs (`inv_dN`, `inv_dN_ci95_*`) come from the 5b inversion, whose $\Delta_{\text{never}}$ construction is base-invariant, so the UF base quirk does not contaminate E2.

## Why the results look weird: a reading guide

- IDN's tight interval $[+5.7\%, +6.1\%]$: 96\% of the IDN gap is the lumped-cell term $\pi \hat\Delta_{unb} (1 - \bar D)$, which is constant across the $(\phi,\beta)$ region, so almost nothing varies (M2). The value-of-migration "interval" is exactly degenerate for the same reason (the CSV stores lo $=$ hi $=$ point).
- CHN rural-first ($\approx 10\%$) vs urban-first ($\approx 1\%$): largely composition mechanics rather than pure sorting efficiency. UF is 34\% always-urban (zeroed by P3), 60\% lumped with $\bar D = 0.86$ (little room for $\Delta(1-\bar D)$), and a 4.7\% never pool with $\Delta_{d_N} \approx 0$; RF's gap is 70\% lumped-cell extrapolation plus 28\% never-migrants at $\Delta_{d_N} \approx 0.105$. The qualitative story survives (the RF never-pool piece is real and E2 rests on it), but "workers are sorted close to optimum" (line 851) is stronger than what the P3-zeroed, lumped-dominated arithmetic shows.
- TZA the largest: genuinely never-migrant-driven, and currently understated by C1 (point $17.9\% \to \approx 20.4\%$ with model-consistent $\mu$'s).
- Round hukou CI endpoints ($0.09, 0.11, 0.13$): inversion grid resolution 0.01, not coincidence (Minor 3).

## Suggested order of fixes (all need approval before script edits)

1. C1: extract ster $\mu$'s with `coleq:colnames` (or reuse auxiliary-OLS $\alpha$'s); rerun; re-baseline; refresh the TZA/IDN numbers in the paper.
2. C2: rebuild $\alpha_{d_T}$ on the per-capita covariate-adjusted scale or drop the quoted no-fallback numbers.
3. M4: export/assert the base trajectory per ster (blocks the CHN sweep refit from silently breaking E1).
4. M1/M2/M3: decisions on the switcher-delta convention, lumped-cell treatment plus its disclosure, and the $W_{\text{zero}}$ convention; then align equation, code, and prose.
5. M5 and minors alongside the same regeneration pass.
