# Feasibility note: corrected `gen_vfirst` cluster diagnostics

**Date:** 2026-04-23
**Supersedes:** [2026-04-22 feasibility note](file:///C:/git/ckt/.claude/worktrees/verdier/docs/reviews/2026-04-22_verdier-feasibility-note.md). The original numbers were produced with a buggy `gen_vfirst` helper (`bysort pid: egen vfirst = min(cond(!missing(v), v, .))`) that returned the *smallest numeric value* of `v` per worker, NOT the value at the earliest year. The bug bites whenever a worker's first-wave province has a higher numeric ID than any subsequent province (~Case C of the [unit test](file:///C:/git/ckt/explorations/verdier/3_test_gen_vfirst.do)).

The corrected helper has been validated on a 5-row synthetic panel (test passed; buggy version mismatched 3 rows). `2_cluster_support_v2.do` was re-run with the corrected helper. Both logs exist side-by-side at `explorations/verdier/cluster_support_v2{,_BUGGY}.{txt,smcl}`.

## Summary table (corrected vs original)

| Country | $v_i$ | Metric | Original | Corrected | Δ |
|---|---|---|---:|---:|---:|
| CHN | `prov` (= `provcd`) | clusters $\geq 10$ sw | 22 | **18** | -4 |
| | | always-rural support | 99.99% | 99.36% | -0.6pp |
| **CHN** | **`birth_province`** | **clusters** | **27** | **32** | **+5** |
| | | clusters $\geq 10$ sw | 1 | **19** | **+18** |
| | | always-rural support | 99.19% | 99.50% | +0.3pp |
| IDN | `prov` | clusters $\geq 10$ sw | 13 | 13 | 0 |
| | | clusters $\geq 5$ sw | 15 | 14 | -1 |
| | | always-rural support | 99.65% | 99.31% | -0.3pp |
| IDN | `kabu` | clusters $\geq 10$ sw | 47 | 52 | +5 |
| | | always-rural support | 92.43% | 91.43% | -1.0pp |
| IDN | `keca` | clusters $\geq 10$ sw | 35 | 41 | +6 |
| IDN | `location` | clusters $\geq 10$ sw | 33 | 39 | +6 |
| TZA | `region` | clusters $\geq 10$ sw | 19 | **21** | +2 |
| | | clusters $\geq 5$ sw | 26 | 25 | -1 |
| TZA | `regdist` | clusters $\geq 10$ sw | 20 | 23 | +3 |
| | | always-rural support | 84.87% | 86.26% | +1.4pp |
| TZA | `location_detail` | clusters $\geq 10$ sw | 31 | 32 | +1 |

## What changes

### Recommendation-level (one finding)

**CHN `birth_province` is usable** --- the original feasibility note dismissed it because it allegedly concentrated all switchers in one cluster. That was a complete bug artifact. With the corrected helper, birth_province has 32 distinct values and 19 clusters with $\geq 10$ switchers, comparable in support to first-wave `prov`. Institutionally cleaner (it is the worker's actual origin, not just where they happened to be observed at the panel start).

**Decision (user, 2026-04-23):** add CHN `birth_province` as a **secondary robustness spec**, not a primary, because birth_province is more likely to be missing (drops some workers) and should not displace the better-supported first-wave `prov` as the default. Reflects the "smaller sample" caveat the user flagged.

The spec ([§2.2 S2](file:///C:/git/ckt/.claude/worktrees/verdier/docs/specs/2026-04-22-verdier-robust-grc.md)) gets a new robustness item for CHN: `vindex(birth_province)` alongside `vindex(hukou)`.

### Headline numbers, no recommendation change

- **CHN `prov`:** 18 well-supported clusters down from 22, and always-rural support drops from 99.99% to 99.36%. Still well above the "$\geq 10$ clusters in 15--50" target. No change to primary spec.
- **IDN `prov`:** 13 well-supported clusters, unchanged. Always-rural support 99.31%, down 0.3pp. No change.
- **TZA `region`:** 21 well-supported clusters, up from 19. Always-rural support unchanged at ~100%. No change.

The modest CHN drop is consistent with the bug bite mechanism: movers whose wave-1 prov had a larger ID than later waves were misclassified into low-ID provinces, inflating support in those clusters and depressing it elsewhere. With movers correctly assigned, several clusters lose just-enough switchers to fall below the 10-switcher threshold.

### Secondary specs --- tighter numbers, same direction

- **IDN `kabu`:** 52 clusters $\geq 10$ sw (was 47); always-rural support 91.4% (was 92.4%). Still the recommended finer-grain robustness for IDN.
- **TZA `regdist`:** 23 clusters $\geq 10$ sw (was 20); always-rural support 86.3% (was 84.9%). Still the recommended finer-grain robustness for TZA.

## Implication for the spec

| Spec item | Status |
|---|---|
| M1--M10 (primary specs, vindex(prov) for CHN/IDN, vindex(region) for TZA) | unchanged |
| S2 (CHN hukou, wild-cluster bootstrap) | unchanged |
| **S2$'$ (NEW): CHN `birth_province` as a third robustness spec** | added per this memo |
| S3 (IDN kabu) | unchanged |
| S4 (TZA regdist) | unchanged |
| S5 (IDN migr==0) | unchanged |
| S6, S7 | unchanged |

The plan ([§4 P2](file:///C:/git/ckt/.claude/worktrees/verdier/docs/plans/2026-04-22-verdier-robust-grc.md)) and verification gates remain unchanged in their numeric targets --- the corrected support numbers all exceed the gate thresholds. The CHN birth_province addition will land in P4 (secondary specs phase).

## Files touched

- `explorations/verdier/3_test_gen_vfirst.do` (NEW; main repo)
- `explorations/verdier/2_cluster_support_v2.do` (corrected; main repo)
- `explorations/verdier/cluster_support_v2_BUGGY.{txt,smcl}` (preserved original log)
- `explorations/verdier/cluster_support_v2.{txt,smcl}` (re-run with corrected helper)
- `docs/reviews/2026-04-22_verdier-feasibility-note.md` (link to this memo added at top)
- `docs/specs/2026-04-22-verdier-robust-grc.md` (S2$'$ added per §"Implication for the spec")
- `docs/reviews/2026-04-23_feasibility-comparison.md` (this file)

## Sign-off

- [ ] Comparison approved.
- [ ] Spec S2$'$ for CHN birth_province acknowledged.
- [ ] Original feasibility note marked as superseded.
