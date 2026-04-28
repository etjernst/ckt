# GRC ster filename and stored-estimate naming convention

This note describes the M11 rename that landed in Phase 1a of the pipeline refactor.
Read this before editing any of the GRC do-files (`5_GrRC.do`, `6_GrRC_NonAg.do`, `8_GrRC_hukou.do`, `10`--`16_*.do`) or `0_programs.do`'s `run_grc*` programs and `grc_tex_table_trend*` programs.

## TL;DR

The change only affects `.ster` filenames on disk and the names used by `estimates store` / `estimates use` in memory.

The change does **not** affect:
- `.tex` output filenames in `output/tables/` (e.g. `GRC_IDN_consumption_urban_unb.tex` is unchanged).
- `.pdf` / `.png` figure filenames in `output/figures/`.
- Anything the paper's LaTeX `\input{}`s.
- The numerical results in any table or figure --- everything is bit-identical to the prior published replication.

## What changed and why

Each section in `5_GrRC.do` and `8_GrRC_hukou.do` used to write `.ster` files to the same disk filenames as the other sections in the same file.
For example, sections 1, 2, and 3 of `5_GrRC.do` (cons/urban/unbalanced, cons/urban/balanced, income/urban/unbalanced) all wrote `grc_<country>_urban_covs_<k>.ster`, so sections 1 and 2 got overwritten by the time section 3 finished.
The pipeline still produced correct LaTeX tables because each section ran its `grc_tex_table_trend` call immediately after its `run_grc` calls (before the next section overwrote), but the `.ster` files for sections 1 and 2 were lost.

That hurt:
- Cannot reload prior-section results from disk for ad-hoc analysis.
- Cannot inspect or reuse individual past fits.
- Per-fit runtime (M9) and Hansen-J p-values for sections 1 and 2 were not recoverable.

Separately, `8_GrRC_hukou.do`'s stored-estimate names like `grc_CHN_rural_first_ca_never` exceeded Stata's 32-character limit on the internal `_est_<name>` matrix that `estimates store` creates (limit becomes 27 chars when you account for the `_est_` prefix).
Earlier work papered over this with an "Option B" bridge that stored estimates under a short name (`grc_<c>_u_covs_X`) while keeping disk filenames verbose (`grc_<c>_urban_covs_X`).
The bridge worked but was confusing to read.

The M11 rename does both fixes at once:
- Each section gets a unique three-letter `spec3` token in its ster filename.
- Both disk filenames and stored-estimate names use the same shorthand. Option B bridge goes away.

## The naming convention

```
grc_<country>_<spec3>_<covs2>_<sfx1>
```

`country`: 3 chars `CHN | IDN | TZA`.

`spec3`: 3-char positional triplet `<depvar><choice><balance>`:

| spec3 | Meaning                              | Where it appears             |
|-------|--------------------------------------|------------------------------|
| `cuu` | consumption / urban / unbalanced     | `5_GrRC.do` section 1, smoke |
| `cub` | consumption / urban / balanced       | `5_GrRC.do` section 2        |
| `iuu` | income      / urban / unbalanced     | `5_GrRC.do` section 3        |
| `cnu` | consumption / nonag / unbalanced     | `6_GrRC_NonAg.do` (IDN-only) |

`covs2`: 2-char covariate-set abbreviation:

| covs2 | Meaning                                   | Was       |
|-------|-------------------------------------------|-----------|
| `c0`  | no covariates                             | `covs_0`  |
| `ct`  | trend (time FE only)                      | `covs_trend` |
| `c1`  | trend + female                            | `covs_1`  |
| `c2`  | trend + female + age$^2$                  | `covs_2`  |
| `ca`  | trend + female + age$^2$ + edu + edu$^2$  | `covs_all` |

The experience-family files (10/11/12/13/14) keep their own `c1/c2/c3/ca` covariate set, which is different from the c0/ct/c1/c2/ca set used in `5_GrRC.do`.
The two are documented at the top of `0_programs.do`.

`sfx1`: 0--1 char post-estimation marker:

| sfx1 | Subgroup                                          | Was       |
|------|---------------------------------------------------|-----------|
| (empty) | main GMM result                                | (same)    |
| `n`  | $\Delta_{\text{never}}$ extrapolation              | `_never`  |
| `a`  | $\Delta_{\text{always}}$ extrapolation             | `_always` |
| `d`  | per-trajectory $\Delta_d$ + joint test             | `_delta`  |
| `g`  | population-weighted average $\Delta$               | `_avg`    |

## Hukou variant (`8_GrRC_hukou.do`)

```
grc_<country>_<hukou>_<spec3>_<covs2>_<sfx1>
```

`hukou`: 2-char compressed subgroup:

| hukou | Meaning      | Was            |
|-------|--------------|----------------|
| `rf`  | rural first  | `rural_first`  |
| `uf`  | urban first  | `urban_first`  |
| `ro`  | rural only   | `rural_only`   |
| `uo`  | urban only   | `urban_only`   |

## Experience and birth families (`10`--`15_*.do`)

```
grc_<country>_<spec3>_<family>_<covs2>_<sfx1>
```

`family`: regressor-family token:

| family       | File                               |
|--------------|------------------------------------|
| `exp`        | `10_GrRC_experience.do`            |
| `maxexp`     | `11_GrRC_max_experience.do`        |
| `expsh`      | `12_GrRC_experience_share.do`      |
| `maxexpsh`   | `13_GrRC_max_experience_share.do`  |
| `exp` (cnu)  | `14_GrRC_NonAg_experience.do`      |
| `birth`      | `15_GrRC_birth.do`                 |

In `14_GrRC_NonAg_experience.do`, the four sections (Experience / Max Experience / Experience Share / Max Experience Share) all write to the same `grc_<c>_cnu_exp_<covs2>` filenames (preserves the prior collision behavior, in which only the last section's data survived on disk; each section's LaTeX table is correct because `grc_tex_table_trend_exp` runs immediately after each section's fits).
This will be cleaned up in Phase 1b's M1+M2 absorption when 14 is folded into 6_GrRC_NonAg.do with proper `exp_variant` disambiguation.

## Examples

| Old name                              | New name              | Length |
|---------------------------------------|-----------------------|--------|
| `grc_IDN_urban_covs_all`              | `grc_IDN_cuu_ca`      | 14     |
| `grc_IDN_urban_covs_trend_never`      | `grc_IDN_cuu_ct_n`    | 17     |
| `grc_CHN_rural_first_covs_all_avg`    | `grc_CHN_rf_cuu_ca_g` | 20     |
| `grc_IDN_birth_c1_avg`                | `grc_IDN_cuu_birth_c1_g` | 23  |

## Where the convention lives

- The locked-in mapping table is documented at the top of `0_programs.do` (right above `* List of programs`).
- The full spec is at `quality_reports/specs/2026-04-24_grc-pipeline-refactor.md`, section M11.
- This README is the friendly summary.

## If you need to add a new spec or covariate set

1. Pick a new `spec3` triplet (or `covs2` abbreviation, or `sfx1` marker) and add it to the table at the top of `0_programs.do`.
2. Update this README's tables.
3. Audit the constructed name: total length must fit in 32 chars after Stata adds the `_est_` prefix. The current worst case is `_est_grc_CHN_cuu_maxexpsh_ca_n` = 30 chars. You have 2 chars of headroom.
4. Run the Tier 1 grep audit (see Phase 1a docs) and the Tier 2 TZA replay smoke before committing.

## What the rename did NOT do

- It did not touch the regressor list inside `run_grc` --- estimation is unchanged.
- It did not touch `data_setup` or any data-construction code --- sample is unchanged.
- It did not touch the `.tex` output filenames --- the paper's `\input{}`s still work.
- It did not delete any do-files --- 10--15 still exist (deletion lands in Phase 1b).

## Verification

After Phase 1a:
- `python tests/regression_test.py` passes (9 reference tables bit-identical).
- Tier 2 TZA smoke (`RP7/scripts/_tier2_tza.do`) reproduces `GRC_TZA_consumption_urban_unb.tex` bit-for-bit and writes 25 sters under the new naming.
- Stored-estimate names fit Stata's 32-char limit with 2 chars of headroom.
