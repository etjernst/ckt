# Plan: E2 hukou-wedge counterfactual, lower bound (Version 1) — REVISED

Date: 2026-06-25 (revised after econometrics plan review)
Spec: [quality_reports/specs/2026-06-25-e2-hukou-bound.md](file:///C:/git/ckt/.claude/worktrees/lca-inversion/quality_reports/specs/2026-06-25-e2-hukou-bound.md)
Confirmed decisions: C1 = conditional $\pi^{rh}$ (`w_rf_cond`, 74%); C2 = new separate table.

## What changed from v1 of this plan (and why)

A fresh-context econometrics review caught that imaging the joint $(\phi,\beta)$
region for the bound would produce a CI that DISAGREES with the profiled
$\Delta_{d_N}^{rh}$ inversion CI the paper already reports (the `inv_dN`
inversion CI). The bound is a positive-constant rescaling of a SINGLE functional
$\Delta_{d_N}^{rh}$, so its CI should be the canonical profiled inversion CI for
that functional, scaled. That CI already lives on the CHN_rf ster:

- `e(inv_dN_at_waldmin)` = 0.11 (point), `e(inv_dN_ci95_lo/hi)` = [0.09, 0.13],
  one island, strictly positive (verified 2026-06-25 via MCP).

So the revised design SCALES the ster-exported $\Delta_{d_N}^{rh}$ inversion CI
by the constant $\pi^{rh}\pi_{d_N}^{rh}$. This is:
- internally consistent with the paper's reported $\Delta_{d_N}^{rh}$ CI (matches by construction),
- tighter than the joint-region image (profiled chi^2_{K-1} vs joint chi^2_2),
- much simpler: NO `run_cell` refactor, NO fresh CI construction for E2.

The joint-region machinery stays in place for E1 (the aggregate genuinely mixes
multiple $\Delta_d$ that share $(\phi,\beta)$); a single functional does not need it.

Provisional headline (using 0.74; final from the harness run): const = 0.74 x
0.27214 = 0.2014; bound point ~ +2.2%, 95% CI ~ [+1.8%, +2.7%] in geometric-mean
consumption. (Gai 2025's GE figure is 2.04 log pts, a loose external reference,
not corroboration: different population, partial vs general equilibrium,
consumption vs GDP.)

## Resolutions from review round 2 (meaning, not arithmetic)

A second fresh-context econometrics review pressed on what the number MEANS. The
headline is unchanged; the following are documentation/reporting resolutions.

- Population identity (must be written out, not assumed). The bound is
  per-defined-hukou-capita, matching E1's national base:
  const x Delta_dN = w_rf_cond x (within-RF never share) x Delta_dN
  = (RF-never share of the defined-hukou population) x per-never-migrant return.
  w_rf_cond pairs with the WITHIN-RF never share by construction; the ~0.7%
  undefined-hukou pids are excluded from the base in both E1 and E2. Use
  `w_rf_cond` (confirmed C1), and state the identity in the table note + prose.
- Report BOTH magnitudes. The economy-wide floor (~+2.2%) averages a sizable
  per-worker gain over the whole population, which is why it reads low. Also
  report the per-RF-never-migrant return Delta_dN^rh itself (~+11.6%, 95% CI
  [+9.4%, +13.9%]) so the within-group magnitude is visible. Both go in the table
  and the prose.
- Object labeling. This is a partial-equilibrium FLOOR on the barrier-removal
  gain (gain from relocating RF never-migrants at the estimated uniform return),
  a lower bound by the Jensen/suppressed-sorting argument the paper already
  makes. Label it as such; do not call it "the" hukou-removal magnitude (that is
  V2). Gai 2025 is a loose reference, not validation.
- Fixed-share assumption, quantified. pi_rh and pi_dN_rh are held at point
  estimates because their sampling variance is an order of magnitude smaller than
  the Delta_dN inversion width: binomial SE on pi_dN ~ 0.0028 (2% relative,
  N_rf = 25,491) vs Delta_dN halfwidth ~ 0.02 (18% relative). Endpoint-scaling is
  then the exact inversion CI for const x Delta_dN (equivariance under a monotone
  transform by a known positive constant). State this in one quantified sentence.
- No hardcoded numbers. The table note and prose must take every printed value
  from `counterfactual_results.csv` / the harness output, never a literal, so a
  recomputed CI cannot silently disagree with the printed note.

## Design

$$\text{gain (lower bound)} = \underbrace{\pi^{rh}\,\pi_{d_N}^{rh}}_{\text{const}}\;\cdot\;\Delta_{d_N}^{rh}.$$

- const $= \pi^{rh}\cdot\pi_{d_N}^{rh}$, both fixed scalars.
- $\Delta_{d_N}^{rh}$ point and 95% CI come from the CHN_rf inversion already on
  the ster. Bound point $=$ const $\times$ point; bound CI $=$ const $\times$
  [lo, hi] (monotone in $\Delta_{d_N}^{rh}$ under const $> 0$).
- "Lower bound" has two senses, both reported honestly: the economic floor logic
  (uniformity vs suppressed sorting) makes the point a floor; the CI is sampling
  uncertainty around it. Quote "lower bound ~ +2.2% (95% CI [+1.8%, +2.7%])".

## Steps

### 1. Export the inv_dN CI from the hukou export do-file (2 lines)

In [_export_e1_inputs_hukou.do](file:///C:/git/ckt/.claude/worktrees/lca-inversion/RP7/scripts/_export_e1_inputs_hukou.do),
the scalars block already writes `inv_dN` (the point). Add two lines:

```stata
scalar inv_dN_ci95_lo = e(inv_dN_ci95_lo)
scalar inv_dN_ci95_hi = e(inv_dN_ci95_hi)
...
file write `scalars_handle' "inv_dN_ci95_lo," (inv_dN_ci95_lo) _n
file write `scalars_handle' "inv_dN_ci95_hi," (inv_dN_ci95_hi) _n
```

This is a harness export file we authored for exactly this purpose; the addition
is two scalar writes, no data processing. (The original spec listed export
do-files as out of scope; this minimal, review-motivated addition is the cleanest
way to keep the bound CI identical to the paper's reported $\Delta_{d_N}^{rh}$ CI.
Approve as part of this plan.)

### 2. E2 bound functions (new, in counterfactuals.py)

No `run_cell` refactor. New, self-contained:

- `hukou_bound_point(pi_rh, pi_dN_rh, delta_dN_rh) -> float`: the product.
- `run_hukou_bound(inputs_dir, data_dir, weights) -> HukouBoundResult`:
  - `inp = load_cell_inputs("CHN_rf", inputs_dir)`,
  - `pi_dN_rh` = `pi_d` at `traj_for_agg == 1` (the never row; = 0.27214),
  - `pi_rh` = `weights["w_rf_cond"]`,
  - `delta_point` = `inp["scalars"]["inv_dN"]`,
    `delta_lo/hi` = `inp["scalars"]["inv_dN_ci95_lo"/"hi"]`,
  - `const = pi_rh * pi_dN_rh`,
  - `point = const * delta_point`, `hull = (const*delta_lo, const*delta_hi)`,
  - guard: require `delta_lo <= delta_hi` and all three finite; if `delta_lo < 0`
    flag a non-positive floor for the reporting layer (here it is positive).
  - Return `HukouBoundResult(pi_rh, pi_dN_rh, delta_dN_rh_point, delta_dN_rh_ci,
    point_bound, hull_bound, floor_positive)`. Both the economy-wide bound and
    the per-never-migrant return (delta_dN_rh) are first-class outputs.

### 3. Wire into run_all_cells

Add `hukou_bound = run_hukou_bound(inputs_dir, data_dir, weights)` to the dict
(`weights` already computed there). E1 path completely untouched.

### 4. Persist + self-check

- `results_dataframe`: append TWO rows, reusing the existing `row()` shape:
  - `cell="CHN_hukou_bound", quantity="hukou_consumption_gain", version="bound"`
    (the economy-wide floor; hull log+pct, point log+pct),
  - `cell="CHN_hukou_bound", quantity="delta_dN_rural_hukou", version="inversion"`
    (the per-RF-never-migrant return Delta_dN^rh and its 95% inversion CI, so the
    within-group magnitude is persisted and self-checked too).
- Existing `_self_check` covers it via the outer join on cell/quantity/version.
- Regenerate the golden baseline once (`regenerate_baseline=True`) after
  hand-verifying; commit the updated `counterfactual_results_baseline.csv` as a
  reviewable diff. Confirm the E1 rows are byte-identical in that diff (they must
  be — E1 code is untouched this time).

### 5. New table

- `write_hukou_bound_table(res, table_path)`: self-contained float, two reported
  quantities for China rural-hukou: (i) per-RF-never-migrant return
  $\Delta_{d_N}^{rh}$ with its 95% inversion CI, and (ii) the economy-wide
  consumption gain (lower bound) with its 95% CI. The note (a) writes the
  population identity (const $= \pi^{rh}\cdot\pi_{d_N}^{rh}$, per-defined-hukou
  base), (b) states the shares are held at point estimates with the quantified
  justification, (c) labels the object a partial-equilibrium floor. ALL numbers
  (including the ingredient values in the note) are formatted from the computed
  `res`, never hardcoded (Y3). Label `tab:hukou_bound`. Path
  `$output/tables/hukou_bound.tex`.
- `run_counterfactuals_for_stata`: new `table_path_hukou` parameter; write it.

### 6. Driver

[12_counterfactuals.do](file:///C:/git/ckt/.claude/worktrees/lca-inversion/RP7/scripts/12_counterfactuals.do):
add `table_path_hukou=...hukou_bound.tex` to the single-line python call, a
`confirm file` for it, and extend the header Output list.

### 7. Run + verify

- `cd RP7/scripts && stata-mp -e do 12_counterfactuals.do`.
- One-off run with `regenerate_baseline` on to mint the E2 row; hand-check the
  number against const x [0.09, 0.11, 0.13]; flip back; confirm self-check passes
  AND all E1 rows unchanged.
- Confirm both tables + the results CSV on disk.

### 7b. Base-robustness check (optional, recommended)

Recompute the CHN_rf $\Delta_{d_N}^{rh}$ inversion CI under 2-3 alternative base
trajectories (Python `grid_delta_never_md_inversion` over the same auxiliary fit,
~seconds each, no re-estimation). If the implied bound is stable across bases,
report that one line and keep the conditional-on-base caveat. If it moves
materially, report the range. This pre-empts the base-sensitivity concern that
the paper otherwise defers to V2. Write the check to a short memo, not the paper.

### 8. Paper prose (S1)

In `results_counterfactuals.tex`, replace the Version 1 subjunctive sentences
(the paragraph around `eq:hukou-bound`, ~lines 118-126) with:
- the economy-wide consumption-gain floor and its 95% CI, AND the per-RF-never-
  migrant return $\Delta_{d_N}^{rh}$ and its CI, so the reader sees both the
  population-averaged floor and the within-group magnitude (R3 / "sounds low"),
- one sentence writing the population identity in words (the floor averages the
  RF-never-migrant gain over the defined-hukou population),
- `\input{tables/hukou_bound.tex}`,
- a one-clause caveat that the bound is conditional on the estimated CHN_rf base
  (do NOT touch the line-142 base-range text; that is a V2 promise),
- a footnote that $\pi^{rh}, \pi_{d_N}^{rh}$ are treated as fixed population
  quantities, with the quantified justification.
Keep the partial-equilibrium-floor framing; do not call it the hukou-removal
magnitude. Leave Version 2 (lines ~128-146) subjunctive and untouched. One
sentence per line. Read voice.md + manuscript-writing.md first (hook-enforced).
Commit separately from the code.

### 9. Review

critic-python on the counterfactuals.py diff; critic-stata on the 2-line export
edit; critic-writing on the prose. Route approved fixes through fixers; re-run
the self-check after any code fix.

## Risk / guardrails

- E1 is not touched at all this time (no refactor), so the drift surface is
  smaller than v1 of the plan. The self-check still runs as belt-and-suspenders.
- The bound CI equals the paper's reported $\Delta_{d_N}^{rh}$ CI times a
  constant, so it cannot disagree with the paper.
- No sters re-estimated, no data touched. One harness export file gains two
  scalar writes.

## Files touched

- `explorations/python-grc/counterfactuals.py` (E2 functions, no refactor)
- `RP7/scripts/_export_e1_inputs_hukou.do` (+2 scalar exports)
- `RP7/scripts/12_counterfactuals.do` (new table path + confirm)
- `RP7/output/counterfactual_results_baseline.csv` (regenerated, +1 E2 row)
- `RP7/output/counterfactual_results.csv`, `RP7/output/tables/hukou_bound.tex` (generated)
- `paper/results_counterfactuals.tex` (V1 prose + \input)
```
