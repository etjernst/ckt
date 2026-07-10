# RP6 vs RP7 GRC ster equivalence check (CHN, IDN)

Date: 2026-07-01

## Question

Can the CHN and hukou covariate-sweep GRC fits that exist only in the coauthor RP6 output (old names, e.g. `grc_CHN_c1`, `grc_CHN_rural_first_ct`) be renamed into the RP7 post-refactor scheme and reused, so the main-results tables (CHN main, two hukou cells) render in the new 4-column + inversion-CI format without a multi-day GMM re-fit?

The switch is safe only if an RP6 fit equals what the current RP7 pipeline produces for the same cell.

## Test

Compare the all-covariates (`ca`) fit, which exists both as an RP7 re-run (`grc_<C>_cuu_ca`) and an RP6 old-name fit (`grc_<C>_ca`), for CHN and IDN.
Driver: `scratchpad/_cmp_rp6_rp7.do`; reads sters only, no GMM.

## Result

| Country | param | RP7 (new) | RP6 (old) | abs diff |
|---|---|---|---|---|
| CHN | phi | -0.2054980414 | -0.9864123676 | 0.78091433 |
| CHN | N | 109,535 | 41,406 | 68,129 |
| CHN | J-stat | 17.555425 | 3.110410 | 14.445015 |
| IDN | phi | -0.5246887749 | -0.5201130249 | 0.00457575 |
| IDN | N | 92,439 | 92,210 | 229 |
| IDN | J-stat | 28.172295 | 28.651744 | 0.479449 |

## Conclusion

The RP6 CHN fit is on a different sample (41,406 vs 109,535 observations, a 2.6x difference) and returns a completely different phi (-0.99 vs -0.21).
The RP6 `grc_CHN_ca` is not the same estimand as the RP7 pipeline re-run.
Reusing the RP6 CHN/hukou sweep fits would splice fits from a different sample into the main-results table.
Option 2 (rename + re-attach RP6 fits) is rejected for CHN.

IDN's RP6 and RP7 fits nearly agree (N off by 229, phi by 0.005), so the pipeline is broadly consistent for IDN but not bit-identical; there is minor sample-construction drift between the RP6 and RP7 vintages.

## Implication

To populate the CHN main table and the two main hukou tables in the new 4-column + inversion-CI format, the covariate sweep (c0/ct/c1/c2/ca) for CHN and the hukou cells must be re-fit under the current RP7 pipeline (option 1).
This is a GMM re-run and needs explicit approval before starting.
The CHN `ca` cell already exists in RP7 (`grc_CHN_cuu_ca`, N=109,535); only the intermediate-covariate cells (and the hukou sweep) are missing.
