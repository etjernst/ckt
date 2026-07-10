# Weak-ID code review (Python + Stata)

**Date:** 2026-04-29
**Branch:** `lca-inversion`
**Scope:** All weak-identification (LCA inversion CI) code under `explorations/python-grc/`. Two critic agents (`python-critic`, `stata-critic`) ran in parallel; full reports below.

---

## Files reviewed

Python (4 files, ~770 lines):

- `explorations/python-grc/lca_inversion.py` (core: OLS, grid Wald, islands, curve stats)
- `explorations/python-grc/run_all_countries_inversion.py` (runner, comparison md)
- `explorations/python-grc/postprocess_islands.py` (today's addition)
- `explorations/python-grc/lca_inversion_ci_helper.py` (Stata-side helper)

Stata (4 files, ~525 lines):

- `explorations/python-grc/grc_weak_id_inference.ado` (canonical CI .ado)
- `explorations/python-grc/demo_lca_inversion_ci.do` (Stata wrapper from stage 8e)
- `explorations/python-grc/rerun_idn_5gr.do`
- `explorations/python-grc/rerun_chn_tza_5gr.do`

---

## Severity-ordered findings

### CRITICAL

None.

### MAJOR (8 total)

| # | File | Issue | Effect on paper CIs |
|---|---|---|---|
| P-M1 | `run_all_countries_inversion.py:147`, `lca_inversion.py:190--193` | Grid `[-3, 1]` step 0.01; CI is `accepted.min()` / `.max()`. If the non-rejected region runs to either edge, the reported endpoint is silently censored, no warning. | None of the published CIs hit either boundary (widest is IDN/covs_all `[-1.230, -0.010]`). Real risk if specs change or grid shrinks. |
| P-M2 | `run_all_countries_inversion.py:135--155` | `drop_sparse_switchers` runs once on full `df`, but per-spec `sub` drops additional rows when `education_max` etc. are required. A switcher with 5 treated pids on `df` may have <5 on `sub`. The keep-list is wrong for covs_2 / covs_all. | Could have shifted IDN / TZA covs_all CIs slightly. Need to recompute and confirm whether any published value changes. |
| P-M3 | `run_all_countries_inversion.py:41--85` | `_load_fresh_gmm` prints `[WARN]` and returns partial dict if a CSV is missing; downstream raises `KeyError` with no context. | None on this machine. Replication risk. |
| S-M1 | `grc_weak_id_inference.ado:185, 200, 216` | `if test_type == "joint"`---`test_type` is a string variable, evaluated as numeric (= 0), condition always false. All `r(min_phi32)` / `r(max_phi32)` returns silently never populated. Fix: `if "\`test_type'" == "joint"`. | None on the postfile path (which is what we use); breaks anyone reading the `.ado`'s `r()` return values. |
| S-M2 | `grc_weak_id_inference.ado:149, 171` | `separate` and `base` branches post scalars without `=` prefix and miss a column in `post`. Postfile p-values for those branches are all missing. | None on `joint` branch (which is what we use); breaks `separate` / `base` outputs. |
| S-M3 | `grc_weak_id_inference.ado:84` | `fvops` check uses `s(fvops)` with `&` / `\|` precedence ambiguity; logic is fragile if next caller passes factor variables. | Latent. |
| S-M4 | `demo_lca_inversion_ci.do:14`, also rerun do-files lines 15--16 | Hardcoded `C:/Users/maand/Dropbox (Personal)/...` path. | Replication only. |
| S-M5 | `grc_weak_id_inference.ado:97--101`, rerun do-files | No `set seed` documented. The `.ado`'s OLS path is deterministic; the rerun pipeline calls `run_grc` with a GMM optimizer whose convergence path could in principle depend on a seed. Not currently observed but undocumented. | Latent. |

### MINOR (10 total)

Spread across both reports. Highlights:

- `lca_inversion.py:213--218`: `find_islands` returns a degenerate `[phi[i], phi[i]]` point interval for a single accepted grid point (zero-width "island"). No downstream guard against zero-width intervals appearing in a paper table.
- `run_all_countries_inversion.py:217`: dead `z = 1.96 if ci_level == 95 else 1.645` (unused).
- `data_loader.py:33`: `FALLBACK_DATA_ROOT = Path("C:/git/ckt/data/processed")` hardcoded.
- `lca_inversion_ci_helper.py:60`: `df.abs()` applied to possibly-string columns (e.g., `hhid` if it ever became a string in Stata).
- No `requirements.txt` / `environment.yml` under `explorations/python-grc/`. Statsmodels' cluster correction has changed across versions; pinning matters.
- `grc_weak_id_inference.ado:128--130`: T=2 detection silently overwrites `test_type` from caller without a `di as text` notice.
- `grc_weak_id_inference.ado:153`: `if "basegroup" == ""` literal-string check, dead branch (always false).
- `demo_lca_inversion_ci.do:12`: log path is relative, will land at unpredictable cwd.
- Rerun do-files: no guard against running both files concurrently (interleaved `.ster` writes possible).
- Both .ado and Python: silent missing-CI behavior when grid runs off the edge; would benefit from explicit warning.

### Notable clean spots (critic explicitly cleared)

- The .ado's joint Wald path (`reg ... vce(cluster hhid)` followed by `test`) automatically uses Stata's cluster-robust VCE. The chi-square dof concern that applies to Python's `pinv(V_R)` does not apply on the Stata side---Stata's `test` builds the Wald with the right rank.
- The rerun CSV benchmarks (`idn_fresh_phi.csv`, `chn_tza_fresh_phi.csv`) are trustworthy: postfile writes and GMM extraction are clean, and values match the published `.tex` tables to 3--4 decimals.
- The demo's specification (sample, `lndepvar` construction, covariate sets) is consistent with what the `.tex` tables report for IDN/cons/urban/unb.

---

## Aggregate scores

| Domain | Raw | Threshold (explorations/) | Pass? |
|---|---|---|---|
| Python (all 4 files) | 75 | 60 | yes |
| Stata (.ado + 3 .do) | 69 | 60 | yes |

Both pass the exploration-track gate (60). Python misses the graduation gate (80). Neither has CRITICAL findings.

---

## Carryover from prior 2026-04-23 econometrics review

Three open items from the earlier review remain unfixed:

1. **Effective-rank dof in `pinv(V_R)`** (finding 4): when `V_R` loses rank, the Wald uses `df=J_R` instead of effective rank---chi-square test undersized.
2. **Symmetric sparse-switcher drop** (finding 5): currently drops switchers with too few treated pids; should also drop with too few untreated pids.
3. **Stata-style cluster correction** (finding 2): `statsmodels` cluster correction may differ from Stata's `(N-1)/(N-K) \cdot G/(G-1)`. Code currently passes `use_correction=True` (`lca_inversion.py:125`); needs verification this matches Stata exactly.

These were not re-litigated by today's critics; they remain on the action list.

---

## Action priority (recommended)

The critics' findings collapse into four buckets, ordered by how directly they affect numbers that could land in the paper:

1. **Per-spec switcher keep-list (P-M2).** Could have shifted CHN / IDN / TZA covs_all and covs_2 results. Recompute on `sub`-based counts, see whether any published CI moves. ~1 hour.
2. **Effective-rank dof + symmetric sparse drop (carryover 1, 2).** Same surface as P-M2; do them together. ~2--3 hours including a rerun and comparison against current values.
3. **Grid-boundary guard (P-M1) + island zero-width guard (m1).** No current value affected, but hardens the code before any future spec change. Pair with a `di as error` warning in the .ado for the same situation (S-minor 5). ~1 hour.
4. **`grc_weak_id_inference.ado` r() return bug (S-M1) + post-column bug (S-M2).** Latent because we use the postfile path; matters if anyone (us or a coauthor) reads `r()`. Worth fixing before the .ado leaves explorations or before sharing the demo. ~30 min.

The `_load_fresh_gmm` silent-failure (P-M3) and the hardcoded path issues (P-m3, S-M4) are replication hygiene, low priority.

---

## Full critic reports

### Python critic (verbatim)

[Full Python critic report---75/100---saved here.]

#### CRITICAL

None found.

#### MAJOR

**M1. Grid-boundary truncation silently produces censored CI endpoints**

Files: `run_all_countries_inversion.py:147`; `lca_inversion.py:190--193`.

`phi_grid = np.arange(-3.0, 1.0001, 0.01)`. The CI lower bound is `accepted.min()` and the upper bound is `accepted.max()`. If the non-rejected region runs to the edge of the grid---if the p-value is still above the level at phi = -3.0 or phi = 1.0---the reported interval is censored and the code emits no warning. The reader (and any paper table) will see, e.g., `[-3.000, -0.450]` and have no indication that the true lower bound extends further left. `grid_lca_inversion` should check whether `ci_low == phi_grid[0]` or `ci_high == phi_grid[-1]` and either raise or return a flag. The helper `lca_inversion_ci_helper.py` has the same exposure: min_phi/max_phi come from Stata locals and there is no post-inversion boundary check.

**M2. `drop_sparse_switchers` called once on full df, but per-spec `sub` can differ materially**

File: `run_all_countries_inversion.py:135--155`.

`kept` is computed from the full `df` (all rows with non-missing outcome and choice). Inside the spec loop, `sub = df.dropna(subset=cols_needed, ...)` drops additional rows for specs that require `education_max` or `education_max2` (covs_all, covs_2). A switcher with exactly 5 treated-cluster pids on the full df may have fewer than 5 in `sub`. That switcher passes the `drop_sparse_switchers` gate but is included in the Wald statistic on sparser data, inflating the effective restriction. The Stata helper `lca_inversion_ci_helper.py` does not have this bug because `drop_sparse_switchers` is called on the already-subsetted `df`.

**M3. `_load_fresh_gmm` fails silently; downstream KeyError is cryptic**

File: `run_all_countries_inversion.py:41--85`.

If either CSV is absent, the function prints `[WARN]` and returns a partial dict. `_run_one_country` then raises `KeyError: 'IDN'` with no context. Should raise after logging.

#### MINOR

m1. `lca_inversion.py:213--218`: `find_islands` returns a degenerate `[phi[i], phi[i]]` for single-point acceptance.
m2. `run_all_countries_inversion.py:217`: dead `z` variable.
m3. `data_loader.py:33`: hardcoded fallback path.
m4. `lca_inversion_ci_helper.py:60`: `.abs()` on possibly-string column.
m5. No environment specification under `explorations/python-grc/`.

#### Score breakdown

| Lens | Weight | Raw | Weighted |
|---|---|---|---|
| Structure | 15% | 80 | 12 |
| Data handling | 25% | 72 | 18 |
| Estimation | 30% | 82 | 24.6 |
| Output | 15% | 78 | 11.7 |
| Reproducibility | 15% | 60 | 9 |
| **Total** | | | **75** |

#### Verdict

Acceptable for continued exploration; M1 (grid-boundary truncation) and M2 (per-spec switcher keep-list) must be fixed before any CI from this code appears in a paper table.

---

### Stata critic (verbatim)

#### CRITICAL

None.

#### MAJOR

**M1.** `grc_weak_id_inference.ado:185, 200, 216`. Bare `if test_type == "joint"` evaluates a string variable as numeric (= 0); all three conditions silently false. `r(min_phi32)` / `r(max_phi32)` and other CI bounds never populated. Fix: `if "\`test_type'" == "joint"`. The Python validation does not catch this because Python uses its own OLS + Wald (not this .ado's `r()` returns); the grid loop and postfile writes are unaffected, only the `r()` extraction at the end is broken.

**M2.** `grc_weak_id_inference.ado:149, 171`. `separate` branch posts six positional args but the `postfile` declaration takes seven numeric + two string columns; `p_val_joint` position is missing. Scalars `p_v_3` through `p_v_7` referenced as `(p_v_3)` not `(\`=p_v_3')`---Stata writes empty strings, p-values in the output `.dta` are missing. Same scalar-reference error in `base` branch at line 171.

**M3.** `grc_weak_id_inference.ado:84`. `local fvops = "\`s(fvops)'" == "true" | _caller() >= 11 & "\`controls'" != ""`---operator precedence ambiguity (`&` binds tighter than `|`). Recommend explicit `capture fvexpand` block.

**M4.** `demo_lca_inversion_ci.do:14`, rerun do-files lines 15--16. Hardcoded Dropbox path.

**M5.** No `set seed` documented in `.ado` or rerun pipeline. OLS path is deterministic; GMM optimizer convergence path could in principle depend on seed.

#### MINOR

m1. `grc_weak_id_inference.ado:128--130`: T=2 detection silently overwrites caller's `test_type`.
m2. `grc_weak_id_inference.ado:153`: `if "basegroup" == ""` literal-string check, dead branch.
m3. `demo_lca_inversion_ci.do:12`: log path relative, lands at unpredictable cwd.
m4. Rerun do-files: no guard against concurrent runs interleaving `.ster` writes.
m5. Grid endpoint behavior undocumented when CI runs off the edge.

#### Notable clean spots

- The .ado's joint Wald path uses Stata's `test` after `reg ... vce(cluster hhid)`---automatically cluster-robust, dof handled internally. The Python `pinv(V_R)` rank concern does not apply on the Stata side.
- Rerun CSV benchmarks (`idn_fresh_phi.csv`, `chn_tza_fresh_phi.csv`) are trustworthy: postfile writes and GMM extraction are clean, values match `.tex` tables to 3--4 decimals.
- Demo's specification (sample, `lndepvar`, covariates) consistent with the `.tex` tables.

#### Score breakdown

| Lens | Weight | Raw | Weighted |
|---|---|---|---|
| Reproducibility | 25% | 65 | 16.3 |
| Inference | 30% | 58 | 17.4 |
| Data quality | 20% | 82 | 16.4 |
| Output | 10% | 85 | 8.5 |
| Code quality | 15% | 72 | 10.8 |
| **Total** | | | **69.4** |

#### Verdict

Rerun CSV benchmarks are trustworthy. `grc_weak_id_inference.ado` has two MAJOR bugs (M1 string-`if` and M2 postfile scalar-reference) that must be fixed before any caller reads its `r()` returns or `separate`/`base` postfile output as authoritative.
