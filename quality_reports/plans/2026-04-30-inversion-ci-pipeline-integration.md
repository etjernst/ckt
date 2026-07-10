# Plan: Pipeline integration of weak-ID-robust inversion CIs

Date: 2026-04-30.
Branch: `lca-inversion`.
Spec: [`quality_reports/specs/2026-04-30-inversion-ci-pipeline-integration.md`](file:///C:/git/ckt/.claude/worktrees/lca-inversion/quality_reports/specs/2026-04-30-inversion-ci-pipeline-integration.md).

## Step 1: Add a single-call entry point in `lca_inversion.py`

Add `compute_all_inversion_cis(...)` to [`explorations/python-grc/lca_inversion.py`](file:///C:/git/ckt/.claude/worktrees/lca-inversion/explorations/python-grc/lca_inversion.py).
Signature: `(df, outcome, traj, choice, hhid, base, controls, min_phi=-3, max_phi=1, increment=0.01, threshold=5)`.
Internally builds the auxiliary OLS once, then calls `grid_lca_inversion`, `grid_delta_never_md_inversion`, `grid_delta_avg_md_inversion`, and `grid_delta_always_md_inversion`.
Returns a dict shaped as `{"phi": {"point": ..., "ci90": (lo, hi), "ci95": (lo, hi), "J_R": ..., "n_kept": ..., "islands": [...]}, "delta_never": {...}, "delta_avg": {...}, "delta_always": {...}}`.

Multi-island fields (`islands`) hold a list of `(lo, hi)` tuples; a single-interval CI is a length-1 list.
The Stata-side wrapper flattens this into `inv_<param>_island_count`, `inv_<param>_ci95_lo_1`, `inv_<param>_ci95_hi_1`, etc., capped at, say, three islands per param (sufficient for the Möbius case).

Verification: smoke test [`explorations/python-grc/smoke_compute_all_inversion_cis.py`](file:///C:/git/ckt/.claude/worktrees/lca-inversion/explorations/python-grc/smoke_compute_all_inversion_cis.py) (new) loads the IDN sample, calls `compute_all_inversion_cis` with `covs_all` controls, and asserts the four point estimates and CIs match the row already published in [`results/delta_inversion_three_countries.md`](file:///C:/git/ckt/.claude/worktrees/lca-inversion/explorations/python-grc/results/delta_inversion_three_countries.md) within `1e-6`.

## Step 2: Write `attach_inversion_ci` in `RP7/scripts/0_programs.do`

Insert immediately after `run_grc` (line 1850 area) so the program lives near its production peer.

Skeleton:

```stata
capture program drop attach_inversion_ci
program define attach_inversion_ci, eclass
    syntax , ESTname(string)                                     ///
             OUTcome(string) TRAJ(string) CHOICE(string)         ///
             HHID(string) BASE(integer)                          ///
             [CONTrols(varlist fv)]                              ///
             [MIN_phi(real -3)] [MAX_phi(real 1)]                ///
             [INCrement(real 0.01)]                              ///
             [THReshold(integer 5)]                              ///
             [STERdir(string)]

    * 1. restore the estimate so e()-scalars attach correctly
    if "`sterdir'" != "" {
        estimates use "`sterdir'/`estname'"
    }
    else {
        estimates restore `estname'
    }

    * 2. fv-expand controls for statsmodels
    local ctrl_list `controls'
    if "`controls'" != "" {
        fvexpand `controls'
        local ctrl_list = r(varlist)
    }

    * 3. inline python: block
    python:
    import sys, os
    proj = os.environ.get("CKT_PROJ", r"C:/git/ckt/.claude/worktrees/lca-inversion")
    sys.path.insert(0, os.path.join(proj, "explorations/python-grc"))
    from lca_inversion import compute_all_inversion_cis
    from sfi import Data, Macro

    out = compute_all_inversion_cis(
        df=Data.getAsDict(),               # current dataset
        outcome=Macro.getLocal("outcome"),
        traj=Macro.getLocal("traj"),
        choice=Macro.getLocal("choice"),
        hhid=Macro.getLocal("hhid"),
        base=int(Macro.getLocal("base")),
        controls=Macro.getLocal("ctrl_list").split(),
        min_phi=float(Macro.getLocal("min_phi")),
        max_phi=float(Macro.getLocal("max_phi")),
        increment=float(Macro.getLocal("increment")),
        threshold=int(Macro.getLocal("threshold")),
    )

    for key, prefix in [("phi", "inv_phi"), ("delta_never", "inv_dN"),
                        ("delta_avg", "inv_davg"), ("delta_always", "inv_dT")]:
        d = out[key]
        Macro.setLocal(f"{prefix}_at_waldmin", repr(d["point"]))
        for level in (90, 95):
            lo, hi = d[f"ci{level}"]
            Macro.setLocal(f"{prefix}_ci{level}_lo", repr(lo))
            Macro.setLocal(f"{prefix}_ci{level}_hi", repr(hi))
        Macro.setLocal(f"{prefix}_island_count", str(len(d["islands"])))
        for i, (lo, hi) in enumerate(d["islands"][:3], start=1):
            Macro.setLocal(f"{prefix}_isl{i}_lo", repr(lo))
            Macro.setLocal(f"{prefix}_isl{i}_hi", repr(hi))
        Macro.setLocal(f"{prefix}_J_R", str(d["J_R"]))
        Macro.setLocal(f"{prefix}_n_kept", str(d["n_kept"]))
    end

    * 4. ereturn the scalars
    foreach prefix in inv_phi inv_dN inv_davg inv_dT {
        ereturn scalar `prefix'_at_waldmin = ``prefix'_at_waldmin'
        ereturn scalar `prefix'_ci90_lo    = ``prefix'_ci90_lo'
        ereturn scalar `prefix'_ci90_hi    = ``prefix'_ci90_hi'
        ereturn scalar `prefix'_ci95_lo    = ``prefix'_ci95_lo'
        ereturn scalar `prefix'_ci95_hi    = ``prefix'_ci95_hi'
        ereturn scalar `prefix'_J_R        = ``prefix'_J_R'
        ereturn scalar `prefix'_n_kept     = ``prefix'_n_kept'
        ereturn scalar `prefix'_island_count = ``prefix'_island_count'
        forval i = 1/3 {
            capture ereturn scalar `prefix'_isl`i'_lo = ``prefix'_isl`i'_lo'
            capture ereturn scalar `prefix'_isl`i'_hi = ``prefix'_isl`i'_hi'
        }
    }

    * 5. re-save .ster
    if "`sterdir'" != "" {
        estimates save "`sterdir'/`estname'", replace
    }
    else {
        estimates store `estname'
    }
end
```

Two known issues to handle:

- `Data.getAsDict()` returns column-oriented dicts that can be fed to `pandas.DataFrame.from_dict`; do the conversion inside `compute_all_inversion_cis` to keep the Stata-side block thin.
- The 32-character `_est_<name>` limit is not violated: the longest scalar name is `inv_davg_island_count` (21 chars), well under 32.

Verification: a stand-alone test [`tests/test_attach_inversion_ci.do`](file:///C:/git/ckt/.claude/worktrees/lca-inversion/tests/test_attach_inversion_ci.do) (new) replays IDN/cons/urban/unb covs_all, calls `attach_inversion_ci` on each of the four `.ster` outputs, and reads back the scalars to confirm they match the smoke-test values from Step 1.

## Step 3: Write the driver `RP7/scripts/5b_inversion.do`

Modeled on the data-loading pattern at the top of `5_GrRC.do` (and the demo at [`explorations/python-grc/demo_lca_inversion_ci.do`](file:///C:/git/ckt/.claude/worktrees/lca-inversion/explorations/python-grc/demo_lca_inversion_ci.do)).
Standard CKT batch-script header, log open, `capture noisily { ... }` body, `exit, STATA clear` at the end.

Body structure:

```stata
foreach country in CHN IDN TZA {
    use "$dirdata/processed/`country'_unb.dta", clear
    replace lndepvar = log(consumption/hhsize_cube)
    setup_grc_estimation
    keep $keepvars
    tab period, gen(period_)
    local periodFE "period_2 - period_`r(r)'"
    drop if mi(lndepvar) | mi(choice)

    initial_values lndepvar, switchers($switchers_`country') ///
        balance(unb) estname(initial_`country')
    local base `r(base)'

    foreach spec in covs_0 covs_trend covs_1 covs_2 covs_all {
        local controls = cond("`spec'" == "covs_0", "", ///
                          cond("`spec'" == "covs_trend", "`periodFE'", ///
                          cond("`spec'" == "covs_1", "`periodFE' $covs_gmm", ///
                          cond("`spec'" == "covs_2", "`periodFE' $covs_gmm2", ///
                          "`periodFE' $covs_gmm_all"))))

        foreach suffix in "" "_never" "_avg" "_always" {
            local estname grc_`country'_urban_`spec'`suffix'
            attach_inversion_ci, ///
                estname(`estname') ///
                sterdir("$output") ///
                outcome(lndepvar) ///
                traj(trajectory) choice(choice) hhid(pid) ///
                base(`base') controls(`controls')
        }
    }
}
```

`${skip_if_exists}` guard: at the top of the inner-most loop, query `e(inv_phi_ci95_lo)` after a quick `estimates use` and skip if non-missing.

Verification: run the driver in batch mode, then load each of the 60 `.ster` files in a follow-up check script and confirm `e(inv_phi_ci95_lo) != .` everywhere.

## Step 4: Extend `grc_tex_table_trend`

Two changes, both esttab-native.

First change: pre-format the bracketed CI strings as `e()` macros in `attach_inversion_ci` (Step 2 addendum).
Each parameter gets two formatted-string macros: `e(inv_phi_ci90_str)`, `e(inv_phi_ci95_str)`, and likewise for `inv_dN_`, `inv_davg_`, `inv_dT_`.
Single-island CIs render as `[lo, hi]` with three-decimal precision (e.g., `[-0.547, -0.302]`).
Multi-island CIs render as the union with $\pm\infty$ endpoints flagged (e.g., `[-\infty, 0.040] \cup [0.660, +\infty]`).
The string formatting happens once, in Python, via a small helper alongside `compute_all_inversion_cis`; the Stata-side wrapper just passes the strings through to `e()`.

Second change: extend `grc_tex_table_trend` (lines 2712-2796 of `0_programs.do`) to consume those macros via esttab's `stats()` clause.
The existing program already has three `esttab` blocks per panel (Delta_never row, Delta_avg row, full-estimates block).
Each adds two extra rows via `stats(inv_<prefix>_ci90_str inv_<prefix>_ci95_str, labels("90\% LCA inv. CI" "95\% LCA inv. CI"))`, which esttab handles as string passthrough for `e()` macros.
The `<prefix>` is `dN` for the never block, `davg` for the avg block, and `phi` for the full-estimates block (which carries the model-level $\phi$ inversion CI).
The $\Delta_{d_T}$ inversion CI rides the never block (the existing `coeflabels` already handles both $\Delta_{\text{never}}$ and $\Delta_{\text{always}}$ in that block); confirm the existing `.ster` carries both coefficients before finalizing the layout, otherwise add a fourth `esttab` block reading the `_always.ster`.

Add a single tablenote at the bottom of the postfoot string: "Multi-island confidence intervals (where one endpoint is reported as $\pm\infty$) reflect the Möbius singularity at $\phi = -1$; see [`docs/notes/2026-04-30_mobius-singularity.md`](file:///C:/git/ckt/.claude/worktrees/lca-inversion/docs/notes/2026-04-30_mobius-singularity.md) for derivation."

Row order in each table cell:

- Coefficient (existing, e.g., $-0.42$)
- Standard error (existing, e.g., $(0.18)$)
- 90% LCA inversion CI (new, e.g., $[-0.55, -0.30]$)
- 95% LCA inversion CI (new, e.g., $[-0.62, -0.25]$)

Verification: rebuild the IDN/CHN/TZA consumption table from the new pipeline; eyeball the inversion-CI rows; confirm the multi-island IDN/covs_all and TZA/covs_all $\Delta_{d_T}$ cells render as $[-\infty, \cdot] \cup [\cdot, +\infty]$.

## Step 5: Re-run the mainline pipeline end-to-end

`5_GrRC.do` is unchanged; the mainline `.ster` files from the 2026-04-30 reruns already exist and are correct.
Run only `5b_inversion.do` against those existing `.ster` files.
Then regenerate the table (which currently lives at the end of `5_GrRC.do`'s table-building block; rerun just that block, or stub a small `5c_tables.do` that calls only `grc_tex_table_trend` for the three countries).

## Step 6: Verification gate

1. Smoke test from Step 1 passes (Python-side numerical match to existing markdown table).
2. Stand-alone `attach_inversion_ci` test from Step 2 passes (Stata-side scalars match Python smoke values).
3. Driver `5b_inversion.do` writes 60 updated `.ster` files; `e(inv_phi_ci95_lo)` non-missing on all of them.
4. Numerical-equivalence check: for each updated `.ster`, `e(b)` and `e(V)` are bit-identical to the pre-driver values (the GMM was not re-run).
5. Final table rebuild renders inversion-CI rows correctly, including the two multi-island Möbius cells.

## Step 7: Commit and session log

Atomic commits at each step boundary:

- C1: `lca_inversion.py` single-call entry point + smoke test.
- C2: `attach_inversion_ci` program in `0_programs.do` + stand-alone test.
- C3: `5b_inversion.do` driver.
- C4: `grc_tex_table_trend` extension + tablenote.
- C5: rebuilt tables.

Session log at [`quality_reports/session_logs/2026-04-30_inversion-ci-pipeline-integration.md`](file:///C:/git/ckt/.claude/worktrees/lca-inversion/quality_reports/session_logs/2026-04-30_inversion-ci-pipeline-integration.md) (new file or appended to the day's existing log).

## Risks and mitigations

- Python-Stata data transfer via `sfi.Data.getAsDict()` may be slow for 56k+ rows; if it becomes a bottleneck, switch to `sfi.Data.get()` returning a numpy array.
- The auxiliary OLS in `compute_all_inversion_cis` must use exactly the same sample as the GMM; we re-use `setup_grc_estimation`'s keepvars and `drop if mi(lndepvar) | mi(choice)` to avoid sample drift.
- Multi-island reporting: capping at three islands per parameter is a heuristic; the Möbius case currently shows two, but if a numerical artifact produces more, the cap clips silently.
Mitigation: warn (`di as text`) when `inv_<prefix>_island_count > 3`.

## Estimated cost

- Step 1 (Python entry point + smoke): 1-2 hours.
- Step 2 (`attach_inversion_ci` program): 2-3 hours, with `python:` block debugging.
- Step 3 (driver): 1 hour.
- Step 4 (table extension): 2-4 hours; the `file write` route is more code than a clean `esttab` solution would be.
- Step 5-6 (rerun and verify): 1 hour.

Total: roughly one working day if nothing surprising surfaces.
