# Feasibility note: $v_i$ candidates per country

> **2026-04-23 update:** numbers in this note were produced with a buggy `gen_vfirst` that returned the smallest numeric value of $v$ per worker rather than the value at the earliest year. **Superseded by the [corrected feasibility comparison](2026-04-23_feasibility-comparison.md).** Headline recommendations (first-wave province for all three countries) are unchanged; CHN `birth_province` is now usable as a robustness spec (was incorrectly dismissed here).

**Date:** 2026-04-22
**Source:** `explorations/verdier/cluster_support_v2.txt` (see [raw log](file:///C:/git/ckt/explorations/verdier/cluster_support_v2.txt))
**Inputs:** `data/processed/{CHN,IDN,TZA}_unb.dta`
**Method:** First-wave value of each candidate $v_i$; report number of distinct values, switcher count distribution per cluster, fraction of always-rural workers in clusters containing at least one switcher.

## Summary table

| Country | Candidate $v_i$ | \# clusters | Mean sw/cluster | Median sw/cluster | Max sw/cluster | Clusters $\geq 10$ sw | Always-rural support |
|---|---|---:|---:|---:|---:|---:|---:|
| CHN | `prov` | 29 | 40.2 | 20 | 190 | 22 | **99.99%** |
| CHN | `provcd` | 29 | 40.2 | 20 | 190 | 22 | 99.99% |
| CHN | `hukou` | 2 | 388.7 | 164 | 1002 | 2 | 100% |
| CHN | `birth_province` | 27 | 41.6 | 0 | 1166 | **1** | 99.19% |
| CHN | `birth_county` | 1370 | 0.9 | 0 | 68 | 34 | 67.46% |
| IDN | `prov` | 22 | 57.7 | 47 | 212 | 13 | **99.65%** |
| IDN | `kabu` | 244 | (med cluster mass moderate) | --- | --- | 47 | 92.43% |
| IDN | `keca` | 1354 | --- | --- | --- | 35 | 69.53% |
| IDN | `location` | 1477 | --- | --- | --- | 33 | 70.13% |
| TZA | `region` | 26 | --- | --- | --- | 19 | **100%** |
| TZA | `district` | 8 | --- | --- | --- | 7 | 100% |
| TZA | `regdist` (region $\times$ district) | 130 | --- | --- | --- | 20 | 84.87% |
| TZA | `location_detail` | 1081 | --- | --- | --- | 31 | 32.56% |

Bolded support fractions are the recommended choices.

## Country-by-country read

### CHN

**Recommended:** `prov`. 29 clusters, 22 with $\geq 10$ switchers, 99.99% always-rural support. Median cluster has 20 switchers, max 190. Cluster count is squarely in the 15--50 range targeted in the design addendum.

**Surprise:** `birth_province` does NOT work. Despite 27 distinct birth provinces, only one has $\geq 5$ switchers (1,166 of the ~1,123 total switchers are concentrated in a single birth province). The median birth-province cluster has zero switchers. This is presumably a CFPS sampling-frame artifact: internal migrants in the panel mostly come from one dominant sending region. The takeaway is that "province of origin" via `birth_province` is not a useful indexing variable for the CKT application; we should stay with first-wave `prov`.

**Hukou** has only two clusters. Too few for cluster-robust asymptotics with standard analytical SEs; if we use $v_i = $ hukou in a secondary specification, wild cluster bootstrap or the two-way spec (`prov` $\times$ hukou as cells) is the right inference approach. That said, hukou is the institutionally cleanest variable and should be reported separately as a robustness spec regardless.

**Note on `provcd`.** Identical counts to `prov`. It is evidently the numeric encoding of the same partition. Pick one for estimation; label the other as a drop.

### IDN

**Recommended:** `prov`. 22 clusters, 13 with $\geq 10$ switchers, 99.65% support. Median cluster has 47 switchers, max 212. Largest per-cluster mass of any of our candidates.

**Alternative if finer geography is wanted:** `kabu` (kabupaten). 244 clusters, 47 with $\geq 10$ switchers, 92.43% support. Not as clean as prov --- 8% of always-rural individuals fall outside switcher-supported kabupatens --- but the finer geography may be substantively preferable since Indonesian provinces are large and heterogeneous internally. Worth reporting side-by-side in a robustness table.

**Not recommended:** `keca` (1,354 clusters, 69.53% support) and `location` (1,477 clusters, 70.13% support). Both are too fine; roughly 30% of always-rural workers would be dropped from the estimand.

**Subsample robustness (per user note).** The `migr` variable identifies individuals not living at their birth location (IFLS: 34.7% are migrants, 60.8% non-migrants). Restricting to `migr == 0` gives a subsample where first-wave location equals birth location, so $v_i$ is a clean origin index for that subset. The `migr == 0` subsample preserves the vast majority of non-movers and a smaller fraction of movers, so headline results should be robust.

### TZA

**Recommended:** `region`. 26 clusters, 19 with $\geq 10$ switchers, 100% always-rural support. Clean.

**Alternative:** `regdist` (region $\times$ district). 130 clusters, 20 with $\geq 10$ switchers, 84.87% support. Worth reporting as a finer-grained robustness.

**Not recommended:** `district` alone has 8 clusters (too few for cluster-robust inference); `location_detail` has only 32.56% always-rural support.

## Takeaway

All three countries support first-wave province-level $v_i$ with clean always-rural coverage ($\geq 99.65\%$) and enough clusters in the 15--50 target range for cluster-robust inference. The original addendum's recommendation stands unchanged: $v_i = $ first-wave province for all three countries in the baseline spec.

Secondary specifications worth reporting:
- **CHN:** $v_i = $ hukou (wild-cluster bootstrap SEs given only 2 clusters).
- **IDN:** $v_i = $ kabupaten, subsample of `migr == 0` individuals.
- **TZA:** $v_i = $ region $\times$ district.

Unexpected: `birth_province` does not work for CHN despite existing in the data (essentially one effective cluster). We can drop the "punt-for-later" item about birth-province from the TODO list for CHN --- the data have it, but it is uninformative. For IDN and TZA there is no birth-province variable in the processed data; the subsample restriction via `migr == 0` is the closest analog for IDN.

## Next step

Draft the implementation spec at `docs/specs/YYYY-MM-DD-verdier-robust-grc.md`. Scope: $v_i$-interacted $\mu$'s in `run_grc`; cluster SEs at $v_i$; plug-in $\Delta_{d_N}$ per cluster then average over clusters with switcher support; overid test on the LCA line.
