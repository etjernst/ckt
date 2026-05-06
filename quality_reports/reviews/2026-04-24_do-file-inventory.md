# Do-file inventory (RP7/scripts/)

## Overall pipeline flow

The pipeline is driven by `0_master.do`, which (per `c(username)`) sets `$dir`, sources `0_path_config.do` for sub-directory globals, installs dependencies via `0_setup.do`, loads the shared `0_programs.do`, and then includes the 18 analysis scripts in fixed numeric order.
Data flow is: `data/countries/*.dta` (raw) → `0_CHN_hukou_restrictions.do` creates four CHN hukou-filtered raws → `1_processData.do` calls `data_setup` / `data_setup_2waves` / `data_setup_3waves` to produce roughly 30 files in `data/processed/` (keyed on country × balance × outcome × trajectory-window × hukou restriction) → `1_summaryStats.do` emits summary-stat tables → `2_OLS_uGRC.do`, `7_OLS_uGRC_hukou.do`, and `9_learning.do` run OLS/FE regressions → `3_heterogeneity_plots.do` and `4_trajectory_bar_graph.do` build figures → `5_GrRC.do`, `6_GrRC_NonAg.do`, `8_GrRC_hukou.do`, `10`--`15` estimate GRC variants by calling `run_grc` / `run_grc_hukou` with different regressor vectors and write `.ster` files to `output/`, then call `grc_tex_table_trend*` table builders → `16_heterogeneity_tables.do` re-estimates the preferred consumption/urban/unbalanced spec and produces per-switcher $\Delta_{\underline{d}}$ and $\mu_{\underline{d}}$ tables via `het_table_delta` / `het_table_mu`.

## Duplication map

| Family | Files | Count | Natural parameterization axis |
|---|---|---|---|
| Infrastructure | `0_master`, `0_path_config`, `0_setup` | 3 | n/a (bootstrap) |
| Data prep | `0_CHN_hukou_restrictions`, `1_processData` | 2 | hukou restriction × (country × balance × depvar × window) |
| Summary stats / figures | `1_summaryStats`, `3_heterogeneity_plots`, `4_trajectory_bar_graph` | 3 | country × trajectory-window (none, 2waves, 3waves) |
| OLS / FE family | `2_OLS_uGRC`, `7_OLS_uGRC_hukou`, `9_learning` | 3 | sample (pooled vs hukou-filtered) / regressor set |
| Main GRC (urban) | `5_GrRC` | 1 | (country × balance × depvar) × covariate set |
| Non-ag GRC | `6_GrRC_NonAg` | 1 | covariate set (IDN only) |
| Hukou GRC | `8_GrRC_hukou` | 1 | hukou regime (rural_first, urban_first, rural_only, urban_only) × balance × depvar |
| Experience GRC family | `10_GrRC_experience`, `11_GrRC_max_experience`, `12_GrRC_experience_share`, `13_GrRC_max_experience_share` | 4 | experience-variant regressor (`exp`, `exp_max`, `exp_share`, `exp_max_share`) |
| Non-ag experience GRC | `14_GrRC_NonAg_experience` | 1 | experience-variant regressor (4 sections inlined, IDN only) |
| Birth GRC | `15_GrRC_birth` | 1 | balance × depvar (IDN only; regressor is `urbanbirth`) |
| Heterogeneity tables | `16_heterogeneity_tables` | 1 | country |

Total: 20 analysis/prep .do files plus `0_master`, `0_path_config`, `0_setup`, `0_programs` (audited separately).

---

## Per-file inventory

### 0_path_config.do
- **Purpose**: set sub-directory globals `$scripts`, `$dirdata`, `$logs`, `$output`, create logs/output/tables/figures/processed directories, and default `$overleaf` if unset.
- **Runs on countries**: n/a.
- **Outcomes estimated**: none.
- **Treatment variants**: n/a.
- **Specifications / covariate sets**: none.
- **Balance variants**: n/a.
- **Programs called from 0_programs.do**: none.
- **Inputs**: `$dir`.
- **Outputs**: directory creation; global macros.
- **Near-duplicate of**: none.
- **Unique logic**: hardcoded `$overleaf` fallback path points to `C:/Users/maand/Dropbox (Personal)/Apps/Overleaf/ReturnsToMigration-clean` — this is a user-specific fallback that should be overridden, not hardcoded here.

### 0_master.do
- **Purpose**: driver that configures `$dir` per user then includes all 18 pipeline scripts sequentially.
- **Runs on countries**: n/a (delegates).
- **Outcomes estimated**: none directly.
- **Treatment variants**: n/a.
- **Specifications / covariate sets**: sets `$copyOverleaf 0`.
- **Balance variants**: n/a.
- **Programs called from 0_programs.do**: loads `0_programs.do`.
- **Inputs**: none.
- **Outputs**: none.
- **Near-duplicate of**: none.
- **Unique logic**: per-user `$dir` branching; critical line for user `maand` points at the `lca-inversion` worktree and needs to be updated after merge — this is a known transition point.

### 0_setup.do
- **Purpose**: install SSC dependencies (estout, reghdfe, ftools, coefplot, unique, ietoolkit, sdecode) and schemepack style; toggle `ado update` via `$adoUpdate`.
- **Runs on countries**: n/a.
- **Outcomes estimated**: none.
- **Treatment variants**: n/a.
- **Specifications / covariate sets**: none.
- **Balance variants**: n/a.
- **Programs called from 0_programs.do**: none.
- **Inputs**: SSC net access.
- **Outputs**: installed ado files; sets `varabbrev off`.
- **Near-duplicate of**: none.
- **Unique logic**: interactive `window stopbox rusure` prompts would block batch mode; flagged as a friction point.

### 0_CHN_hukou_restrictions.do
- **Purpose**: derive four hukou-restricted CHN raw panels (rural-only, urban-only, rural-first, urban-first) from `CHN.dta`.
- **Runs on countries**: CHN only (four passes).
- **Outcomes estimated**: none.
- **Treatment variants**: defines the hukou sample splits used downstream.
- **Specifications / covariate sets**: none.
- **Balance variants**: n/a (applies to both balance variants downstream).
- **Programs called from 0_programs.do**: none.
- **Inputs**: `$dirdata/countries/CHN.dta`.
- **Outputs**: `$dirdata/countries/CHN_hukou_rural_only.dta`, `..._urban_only.dta`, `..._rural_first.dta`, `..._urban_first.dta`.
- **Near-duplicate of**: internally four near-identical blocks differing only in the keep rule (`min_hukou==1`, `max_hukou==0`, `first_hukou==1`, `first_hukou==0`).
- **Unique logic**: defines the hukou sampling rules; writing to `data/countries/` (typically reserved for raw) places derived files alongside raw, which is worth noting for governance.

### 1_processData.do
- **Purpose**: build all processed datasets used downstream by repeatedly calling `data_setup` / `data_setup_2waves` / `data_setup_3waves`.
- **Runs on countries**: IDN (9 blocks), CHN (9 blocks + 4 hukou variants × 3 balance/depvar combinations each), TZA (6 blocks).
- **Outcomes estimated**: none.
- **Treatment variants**: `urban`, `nonag` (IDN only).
- **Specifications / covariate sets**: none.
- **Balance variants**: both `unb` and `bal`.
- **Programs called from 0_programs.do**: `data_setup`, `data_setup_2waves`, `data_setup_3waves`.
- **Inputs**: `$dirdata/countries/{IDN,CHN,TZA,CHN_hukou_*}.dta`.
- **Outputs**: `$dirdata/processed/{country}_{balance}[.dta | _nonag.dta | _income.dta | _2waves.dta | _3waves.dta]`.
- **Near-duplicate of**: internally ~28 near-identical copy-paste blocks varying only in `(country, choice, depvar, balance, window)` locals.
- **Unique logic**: enumerates every country × balance × depvar × window × hukou combination consumed downstream; the CHN hukou section is the only part that uses the hukou-restricted raws created in `0_CHN_hukou_restrictions.do`.

### 1_summaryStats.do
- **Purpose**: produce summary statistics LaTeX tables per country × balance × trajectory-window.
- **Runs on countries**: IDN/CHN/TZA for each of 5 sections.
- **Outcomes estimated**: none (descriptive).
- **Treatment variants**: urban (all sections) plus nonag (IDN only, section 3).
- **Specifications / covariate sets**: none.
- **Balance variants**: both, in separate sections.
- **Programs called from 0_programs.do**: `country_summary_stats`, `country_summary_stats_nonag`, `country_summary_stats_2waves`, `country_summary_stats_3waves`, `sumstats_table`, `removeStringFromTex`, `copyOverleaf`.
- **Inputs**: `$dirdata/processed/{country}_{balance}[_nonag|_2waves|_3waves].dta`.
- **Outputs**: `$output/tables/summary_stats_{country}_{balance}[_nonag|_2waves|_3waves].tex`.
- **Near-duplicate of**: internally 15 near-identical blocks (5 sections × 3 countries, minus nonag being IDN-only).
- **Unique logic**: calls the dead-code `sumstats_table` program flagged in the programs audit; also hand-written note text per country that would collapse into a program option.

### 2_OLS_uGRC.do
- **Purpose**: run OLS/FE regressions (uGRC) and emit multi-panel LaTeX tables.
- **Runs on countries**: IDN/CHN/TZA pooled for sections 1, 2, 4; IDN only for section 3.
- **Outcomes estimated**: consumption (sections 1--3), income (section 4).
- **Treatment variants**: urban (sections 1, 2, 4); nonag (section 3, IDN only).
- **Specifications / covariate sets**: 7 columns fixed per call (none / time FE / + female / + age$^2$ / + education, education$^2$ / migrants only / + individual FE); no estname suffixes.
- **Balance variants**: `unb` (section 1, 3, 4), `bal` (section 2).
- **Programs called from 0_programs.do**: `reghdfe_regressions`, `create_panel_tex_table`, `data_setup`, `copyOverleaf`.
- **Inputs**: `$dirdata/processed/{country}_{balance}[.dta | _income.dta]`.
- **Outputs**: `$output/tables/OLS_{depvar}_{choice}_{balance}.tex`.
- **Near-duplicate of**: sections 1 and 4 are structurally identical modulo `depvar` and dataset suffix; section 2 duplicates section 1 with `balance=bal`; section 3 is the IDN-only nonag copy.
- **Unique logic**: calls `data_setup` on the balanced section (instead of reading the pre-built processed file), which is an asymmetry with sections 1/4; table captions and notes are written out per section.

### 3_heterogeneity_plots.do
- **Purpose**: build coefplot heterogeneity panels per country and combine into 3-way figures (Delta/mu × Fcovars/Fnocovars).
- **Runs on countries**: IDN/CHN/TZA.
- **Outcomes estimated**: consumption (figures keyed on stored GRC estimates).
- **Treatment variants**: urban only.
- **Specifications / covariate sets**: relies on whatever `heterogeneity_plots` reads from `.ster`; no estname option here.
- **Balance variants**: `unb` only.
- **Programs called from 0_programs.do**: `setup_grc_estimation`, `heterogeneity_plots`, `copyOverleaf`.
- **Inputs**: `$dirdata/processed/{country}_unb.dta` and corresponding `.ster` files from `5_GrRC.do`.
- **Outputs**: `$output/figures/hetplot{Delta,mu}_consumption_urban_unb_{Fcovars,Fnocovars}.{pdf,png}` plus per-country `.gph` temp files.
- **Near-duplicate of**: three near-identical country blocks (only `local country` differs), then four near-identical `graph combine` blocks (Delta × Fcovars, Delta × Fnocovars, mu × Fcovars, mu × Fnocovars).
- **Unique logic**: the `graph combine` calls with specific column layout and per-country `.gph` naming.

### 4_trajectory_bar_graph.do
- **Purpose**: bar graphs of the 6-category "mega_trajectories" distribution per country and trajectory-window (none / 2waves / 3waves).
- **Runs on countries**: IDN/CHN/TZA.
- **Outcomes estimated**: none (descriptive).
- **Treatment variants**: urban only.
- **Specifications / covariate sets**: none.
- **Balance variants**: `unb` only.
- **Programs called from 0_programs.do**: none direct — uses base `graph bar` and `graph combine`.
- **Inputs**: `$dirdata/processed/{country}_unb[.dta | _2waves.dta | _3waves.dta]`.
- **Outputs**: `$output/figures/trajectories{,_2waves,_3waves}.pdf`, plus per-country `.gph` temp files.
- **Near-duplicate of**: nine near-identical country blocks (3 windows × 3 countries), each enumerating the trajectory codes that map to the six mega-categories; the mapping logic is the only difference.
- **Unique logic**: the hardcoded `inlist` and string-match trajectory-to-mega mappings are country-specific (CHN up to 4 waves → trajectory codes 1--14; IDN up to 5 waves → 1--32; TZA 3 waves → 1--8) and ad hoc.

### 5_GrRC.do
- **Purpose**: main restricted GRC regressions and headline LaTeX tables (the paper's flagship specification).
- **Runs on countries**: IDN/CHN/TZA.
- **Outcomes estimated**: consumption (sections 1, 2) and income (section 3).
- **Treatment variants**: urban only.
- **Specifications / covariate sets**: five estnames per country × section — `covs_0` (no covariates), `covs_trend` (time FE), `covs_1` (+ female), `covs_2` (+ age$^2$), `covs_all` (+ education, education$^2$).
- **Balance variants**: `unb` (sections 1, 3), `bal` (section 2).
- **Programs called from 0_programs.do**: `setup_grc_estimation`, `initial_values`, `run_grc`, `grc_tex_table_trend`, `copyOverleaf`.
- **Inputs**: `$dirdata/processed/{country}_{balance}[.dta | _income.dta]`.
- **Outputs**: `$dir/output/grc_{country}_{covs_0|covs_trend|covs_1|covs_2|covs_all}.ster` plus `_never.ster` and `_avg.ster` siblings; `$output/tables/GRC_{country}_{depvar}_{choice}_{balance}.tex`.
- **Near-duplicate of**: three near-identical country blocks per section, three near-identical sections (differ only on depvar/balance and the dataset suffix); the per-country table wrapper blocks are also near-duplicates modulo caption/label/htb.
- **Unique logic**: replaces `lndepvar` with `log(consumption/hhsize_cube)` explicitly in consumption sections; the core pattern (load → `setup_grc_estimation` → `keep $keepvars` → `tab period` → `initial_values` → five `run_grc` calls) is the template every other file in the GRC family repeats.

### 6_GrRC_NonAg.do
- **Purpose**: restricted GRC with non-agricultural employment as the treatment, IDN only.
- **Runs on countries**: IDN only.
- **Outcomes estimated**: consumption.
- **Treatment variants**: nonag only.
- **Specifications / covariate sets**: same five as `5_GrRC.do` (`covs_0`, `covs_trend`, `covs_1`, `covs_2`, `covs_all`).
- **Balance variants**: `unb` only.
- **Programs called from 0_programs.do**: `setup_grc_estimation`, `initial_values`, `run_grc`, `grc_tex_table_trend`, `copyOverleaf`.
- **Inputs**: `$dirdata/processed/IDN_unb_nonag.dta`.
- **Outputs**: `$dir/output/grc_IDN_{covs_*}.ster` and `.tex` as per family pattern (note: ster names collide with `5_GrRC.do` IDN urban names — same `grc_IDN_covs_0.ster` etc., so run order matters).
- **Near-duplicate of**: identical in template to `5_GrRC.do` section 1 restricted to IDN and with the `_nonag` dataset suffix.
- **Unique logic**: the only GRC file whose treatment switch is `nonag` (requires the `_nonag.dta` processed file); `coeflabels(choice "Non-Ag")` in table. Shares ster namespace with urban runs — a real collision risk.

### 7_OLS_uGRC_hukou.do
- **Purpose**: OLS/FE regressions on the four CHN hukou subsamples.
- **Runs on countries**: CHN hukou subsets only (rural_first, urban_first, rural_only, urban_only).
- **Outcomes estimated**: consumption (sections 1, 2 in each hukou block) and income (section 3 in each).
- **Treatment variants**: urban only.
- **Specifications / covariate sets**: same 7-column uGRC layout as `2_OLS_uGRC.do`; no estname suffixes.
- **Balance variants**: `unb` (sections 1, 3) and `bal` (section 2), repeated four times.
- **Programs called from 0_programs.do**: `reghdfe_regressions`, `create_panel_tex_table`, `copyOverleaf`.
- **Inputs**: `$dirdata/processed/CHN_hukou_{rural_first,urban_first,rural_only,urban_only}_{bal,unb}[.dta | _income.dta]`.
- **Outputs**: `$output/tables/OLS_CHN_hukou_{regime}_{depvar}_{choice}_{balance}.tex`.
- **Near-duplicate of**: four near-identical hukou blocks, each itself three near-identical balance × depvar sub-blocks — structurally the CHN-hukou cross product of `2_OLS_uGRC.do`.
- **Unique logic**: none beyond the hukou regime switch; the LaTeX caption text is the only content that meaningfully changes.

### 8_GrRC_hukou.do
- **Purpose**: restricted GRC on the four CHN hukou subsamples using the `run_grc_hukou` program.
- **Runs on countries**: CHN hukou subsets only (rural_first, urban_first, rural_only, urban_only).
- **Outcomes estimated**: consumption (sections 1, 2 per regime) and income (section 3 per regime).
- **Treatment variants**: urban only.
- **Specifications / covariate sets**: five estnames per block — `c0`, `ct`, `c1`, `c2`, `ca` (same semantic columns as `5_GrRC.do` but different suffix convention).
- **Balance variants**: `unb`, `bal`, repeated four times.
- **Programs called from 0_programs.do**: `setup_grc_estimation`, `initial_values`, `run_grc_hukou`, `grc_tex_table_trend_hukou`, `copyOverleaf`.
- **Inputs**: `$dirdata/processed/CHN_hukou_{regime}_{balance}[.dta | _income.dta]`.
- **Outputs**: `$dir/output/grc_CHN_{rural_first,urban_first,rural_only,urban_only}_{c0,ct,c1,c2,ca}[.ster | _n.ster | _avg.ster]`; `$output/tables/GRC_CHN_hukou_{regime}_{depvar}_{choice}_{balance}.tex`.
- **Near-duplicate of**: twelve near-identical (regime × balance × depvar) blocks, each structurally the same as `5_GrRC.do` but calling `run_grc_hukou` instead of `run_grc`, with `_n` suffix instead of `_never` and `c0/ct/c1/c2/ca` instead of `covs_*`.
- **Unique logic**: the only file to call `run_grc_hukou`, which hardcodes $\phi=-1$ per the audit — so this entire file's content is tied to that hardcoded restriction; the per-regime `local country_short` bridging device is a bespoke workaround for long file names in ster storage.

### 9_learning.do
- **Purpose**: OLS/FE regressions testing whether returns to urban location accumulate with periods-since-migration ("learning").
- **Runs on countries**: IDN and CHN only (no TZA).
- **Outcomes estimated**: consumption.
- **Treatment variants**: urban only (decomposed into 1st/2nd/3rd/4th urban-period and rural-period indicators post-migration).
- **Specifications / covariate sets**: 4 columns set inside the per-country `reghdfe_regressions_learn_*` program; no estname suffixes.
- **Balance variants**: `bal` only.
- **Programs called from 0_programs.do**: `reghdfe_regressions_learn_IDN`, `reghdfe_regressions_learn_CHN`, `create_panel_tex_table_learn_IDN`, `create_panel_tex_table_learn_CHN`, `copyOverleaf`.
- **Inputs**: `$dirdata/processed/{IDN,CHN}_bal.dta`.
- **Outputs**: `$output/tables/OLS_{IDN,CHN}_consumption_learning_bal.tex`.
- **Near-duplicate of**: IDN and CHN blocks are near-identical; IDN has 4 urban periods + 4 rural periods, CHN has 3 of each.
- **Unique logic**: inline construction of `urban_1period`--`urban_4period` and `rural_1period`--`rural_4period` indicators from `first_period_urban` and cumulative `urban_periods` / `rural_periods` sums — this generation logic is not in `0_programs.do`; the per-country programs in `0_programs.do` duplicate layout purely because of the 3-vs-4 period count.

### 10_GrRC_experience.do
- **Purpose**: restricted GRC with experience (`exp`) added as an extra regressor.
- **Runs on countries**: IDN/CHN/TZA.
- **Outcomes estimated**: consumption (sections 1, 2) and income (section 3).
- **Treatment variants**: urban only.
- **Specifications / covariate sets**: four estnames per country × section — `c1` (time FE + `exp`), `c2` (+ female), `c3` (+ age$^2$), `ca` (+ education, education$^2$); no `c0` variant since the experience control is the headline addition.
- **Balance variants**: `unb` (sections 1, 3), `bal` (section 2).
- **Programs called from 0_programs.do**: `setup_grc_estimation`, `initial_values`, `run_grc`, `grc_tex_table_trend_exp`, `copyOverleaf`.
- **Inputs**: `$dirdata/processed/{country}_{balance}[.dta | _income.dta]`.
- **Outputs**: `$dir/output/grc_{country}_{c1,c2,c3,ca}[.ster | _never.ster | _avg.ster]`; `$output/tables/GRC_{country}_{depvar}_{choice}_{balance}_exp.tex`.
- **Near-duplicate of**: `11_GrRC_max_experience.do`, `12_GrRC_experience_share.do`, `13_GrRC_max_experience_share.do` — all four differ only in the experience regressor variable (`exp` vs `exp_max` vs `exp_share` vs `exp_max_share`), the `covs_gmm*_exp*` globals, the `keepvars`, and the output filename suffix; the ster estnames `c1/c2/c3/ca` are identical across all four, so sequential runs overwrite each other's ster files.
- **Unique logic**: baseline experience variant (`exp`).

### 11_GrRC_max_experience.do
- **Purpose**: same as `10_GrRC_experience.do` but with `exp_max` as the experience regressor.
- **Runs on countries**: IDN/CHN/TZA.
- **Outcomes estimated**: consumption and income.
- **Treatment variants**: urban only.
- **Specifications / covariate sets**: `c1`, `c2`, `c3`, `ca` (using `covs_gmm*_exp_max` globals built from `exp_max`).
- **Balance variants**: `unb` and `bal`.
- **Programs called from 0_programs.do**: same as `10`: `setup_grc_estimation`, `initial_values`, `run_grc`, `grc_tex_table_trend_exp`, `copyOverleaf`.
- **Inputs**: `$dirdata/processed/{country}_{balance}[.dta | _income.dta]`.
- **Outputs**: `$dir/output/grc_{country}_{c1..ca}.ster` (overwrites `10`'s output), LaTeX filename suffix `_exp_max`.
- **Near-duplicate of**: identical to `10_GrRC_experience.do` except:
  - regressor variable `exp` → `exp_max`
  - globals `covs_gmm*_exp` → `covs_gmm*_exp_max`
  - filename suffix `_exp` → `_exp_max`
- **Unique logic**: none.

### 12_GrRC_experience_share.do
- **Purpose**: same as `10_GrRC_experience.do` but with `exp_share` (share of periods spent in urban/nonag) as the regressor.
- **Runs on countries**: IDN/CHN/TZA.
- **Outcomes estimated**: consumption and income.
- **Treatment variants**: urban only.
- **Specifications / covariate sets**: `c1`, `c2`, `c3`, `ca` (using `covs_gmm*_exp_sh` globals).
- **Balance variants**: `unb` and `bal`.
- **Programs called from 0_programs.do**: same as `10`.
- **Inputs**: `$dirdata/processed/{country}_{balance}[.dta | _income.dta]`.
- **Outputs**: `$dir/output/grc_{country}_{c1..ca}.ster` (overwrites `10`, `11`), LaTeX filename suffix `_exp_sh`.
- **Near-duplicate of**: identical to `10_GrRC_experience.do` with `exp` → `exp_share` and `_exp` globals → `_exp_sh`.
- **Unique logic**: none.

### 13_GrRC_max_experience_share.do
- **Purpose**: same as `10_GrRC_experience.do` but with `exp_max_share` as the regressor.
- **Runs on countries**: IDN/CHN/TZA.
- **Outcomes estimated**: consumption and income.
- **Treatment variants**: urban only.
- **Specifications / covariate sets**: `c1`, `c2`, `c3`, `ca` (using `covs_gmm*_exp_m_sh` globals).
- **Balance variants**: `unb` and `bal`.
- **Programs called from 0_programs.do**: same as `10`.
- **Inputs**: `$dirdata/processed/{country}_{balance}[.dta | _income.dta]`.
- **Outputs**: `$dir/output/grc_{country}_{c1..ca}.ster` (overwrites `10`--`12`), LaTeX filename suffix `_exp_m_sh`.
- **Near-duplicate of**: identical to `10_GrRC_experience.do` with `exp` → `exp_max_share` and `_exp` globals → `_exp_m_sh`.
- **Unique logic**: none. Files 10/11/12/13 form an essentially perfect 4-way clone across a single variable-name axis.

### 14_GrRC_NonAg_experience.do
- **Purpose**: non-agricultural-treatment GRC with the same four experience variants as files 10--13.
- **Runs on countries**: IDN only.
- **Outcomes estimated**: consumption.
- **Treatment variants**: nonag only.
- **Specifications / covariate sets**: each of four inlined sections uses `c1`, `c2`, `c3`, `ca` (so 16 estimations in one file).
- **Balance variants**: `unb` only.
- **Programs called from 0_programs.do**: `setup_grc_estimation`, `initial_values`, `run_grc`, `grc_tex_table_trend_exp`, `copyOverleaf`.
- **Inputs**: `$dirdata/processed/IDN_unb_nonag.dta`.
- **Outputs**: `$dir/output/grc_IDN_{c1..ca}.ster` (four times overwritten within this single file — each of the four experience variants clobbers the last), LaTeX filenames `GRC_IDN_consumption_nonag_unb_{exp, exp_max, exp_sh, exp_m_sh}.tex`.
- **Near-duplicate of**: essentially files 10--13 collapsed into one file but restricted to IDN + nonag. Each of its four sections is the IDN block of the corresponding file.
- **Unique logic**: demonstrates the only existing "collapsed" form — four experience variants iterated in one file — but still clobbers ster output because estname `c1..ca` is not parameterized by variant.

### 15_GrRC_birth.do
- **Purpose**: restricted GRC with `urbanbirth` (an indicator for being born in an urban area) as a covariate, to test whether selection on birthplace drives the phi estimates.
- **Runs on countries**: IDN only.
- **Outcomes estimated**: consumption (sections 1, 2) and income (section 3).
- **Treatment variants**: urban only.
- **Specifications / covariate sets**: `c1`, `c2`, `c3`, `ca` using `covs_gmm*_birth` globals built from `urbanbirth`.
- **Balance variants**: `unb` (sections 1, 3), `bal` (section 2).
- **Programs called from 0_programs.do**: `setup_grc_estimation`, `initial_values`, `run_grc`, `grc_tex_table_trend_birth`, `copyOverleaf`. Per the programs audit `grc_tex_table_trend_birth` is byte-identical to `grc_tex_table_trend_exp`.
- **Inputs**: `$dirdata/processed/IDN_{balance}[.dta | _income.dta]`.
- **Outputs**: `$dir/output/grc_IDN_{c1..ca}.ster` (same namespace as 10--14 — collision!); `$output/tables/GRC_IDN_consumption_urban_{unb,bal}_birth.tex`, `GRC_IDN_income_urban_unb_birth.tex`.
- **Near-duplicate of**: structurally identical to `10_GrRC_experience.do` restricted to IDN, with `exp` → `urbanbirth`, `covs_gmm*_exp` → `covs_gmm*_birth`, filename suffix `_exp` → `_birth`, and `grc_tex_table_trend_exp` → `grc_tex_table_trend_birth`.
- **Unique logic**: only file whose covariate is a time-invariant birthplace indicator; the econometric question ("is $\phi$ robust to conditioning on birthplace?") is the real content, but the implementation is a clone of file 10.

### 16_heterogeneity_tables.do
- **Purpose**: re-run the headline (consumption / urban / unbalanced / all-covariates) GRC spec and emit per-switcher heterogeneity tables for $\Delta_{\underline{d}}$ and $\mu_{\underline{d}}$.
- **Runs on countries**: IDN/CHN/TZA.
- **Outcomes estimated**: consumption only.
- **Treatment variants**: urban only.
- **Specifications / covariate sets**: one estname per country — `covs_all` (time FE + female + age$^2$ + education + education$^2$).
- **Balance variants**: `unb` only.
- **Programs called from 0_programs.do**: `setup_grc_estimation`, `initial_values`, `run_grc`, `het_table_delta`, `het_table_mu`.
- **Inputs**: `$dirdata/processed/{country}_unb.dta`.
- **Outputs**: `$dir/output/grc_{country}_covs_all.ster` (also written by `5_GrRC.do` — re-estimation here is redundant if section 1 of `5_GrRC.do` ran); `$output/tables/hetDelta_table_{country}.tex`, `hetmu_table_{country}.tex`.
- **Near-duplicate of**: three near-identical country blocks, each a stripped-down `5_GrRC.do` block that runs only the `covs_all` spec; then three near-identical table-writing blocks.
- **Unique logic**: builds `keep_list_delta` / `coeflabs_delta` / `keep_list_mu` / `coeflabs_mu` via `decode trajectory` and loops over `$switchers` — the trajectory-to-row-label mapping logic lives here, not in `0_programs.do`; per the programs audit, `het_table_delta` and `het_table_mu` hardcode the `grc_${country}_covs_all` estname, so this file cannot currently produce heterogeneity tables for any other spec.

---

## Refactor targets

Observations feeding the spec, in rough priority order:

1. **Collapse 10/11/12/13 into one file with an `exp_variant()` loop.** Files 10--13 differ only in the experience regressor name and the output filename suffix. An extended `run_grc` that accepts `exp_variant(exp|exp_max|exp_share|exp_max_share)` (plus a tag that flows into estname and into the LaTeX filename) would replace ~4800 lines of near-identical Stata with one loop. Pairs naturally with the ster-rename work documented in context (`grc_<c>_exp_c*`, `grc_<c>_maxexp_c*`, etc.) because the current source still writes `grc_{country}_c*` — meaning sequential runs currently clobber each other's ster output. Fixing the clone and the rename is one motion.

2. **Collapse the three GRC table-builder programs and files 5/6/8 into one spec-parameterized call.** `grc_tex_table_trend`, `grc_tex_table_trend_exp`, `grc_tex_table_trend_hukou`, and the byte-identical `grc_tex_table_trend_birth` all read the same structure from memory but differ in estname prefixes and suffixes (`covs_*` vs `c0/ct/c1/c2/ca` vs hukou `_n` suffix). With the `spec()` option mentioned in context, the four table builders collapse to one; per-file call sites in 5, 6, 8, 10--15 become uniform; file 16's hardcoded `grc_${country}_covs_all` becomes a parameter.

3. **Unify `run_grc` and `run_grc_hukou` behind a single estimator with `phi_restrict()` and `never_suffix()` options.** `run_grc_hukou` differs from `run_grc` only in hardcoding $\phi=-1$ and using `_n`/`_a` suffixes per the audit; promoting these to options eliminates file 8's reliance on a separate program and means the 12-block hukou file collapses in the same way files 10--13 collapse, driven by a `hukou_regime()` axis.

4. **Parameterize `1_processData.do` and `0_CHN_hukou_restrictions.do` as nested loops.** `1_processData.do`'s ~28 blocks enumerate (country × balance × depvar × window × hukou) explicitly; a double loop over country and balance with branches on window/hukou yields the same processed files in 50 lines. The hukou file's four blocks collapse to one loop over `{rural_only, urban_only, rural_first, urban_first}` with the keep rule passed as an option.

5. **Collapse `2_OLS_uGRC.do` + `7_OLS_uGRC_hukou.do` into a single loop over (sample × balance × depvar).** The four hukou variants are copy-paste of `2_OLS_uGRC.do` with a different processed-file stem and a different caption; a table-metadata map keyed on sample name would eliminate ~600 lines. Same pattern recurs in `1_summaryStats.do` (15 blocks → one loop with a `window()` option on `country_summary_stats`).

6. **Collapse `3_heterogeneity_plots.do` to a country loop and a figure-assembly loop.** The four `graph combine` calls differ only in Delta vs mu and Fcovars vs Fnocovars; a 2 × 2 loop over `{Delta, mu}` × `{Fcovars, Fnocovars}` trivially produces all four PDFs.

7. **Move the trajectory-to-mega-category mapping out of `4_trajectory_bar_graph.do` into a named program in `0_programs.do`.** The mapping is ad hoc and country-specific; once extracted, the nine blocks become a 3 × 3 loop over (country × window) with a call to `mega_trajectories_build`.

8. **Move the learning-indicator construction in `9_learning.do` into a named program.** The `first_period_urban` / `urban_Nperiod` / `rural_Nperiod` block is generated inline twice; extracting it with a `max_periods()` option collapses the two country blocks and pairs with an extension of the learning-regression programs (which are already per-country clones).

9. **Fix the ster-namespace collisions that the current clone pattern masks.** Files 6 (nonag), 10--13 (experience variants), 14 (nonag experience), and 15 (birth) all write to `grc_{country}_{c0|c1|c2|c3|ca}.ster` without any spec prefix. Downstream programs (`het_table_delta`, `het_table_mu`, `heterogeneity_plots`) read from fixed estname patterns, so whichever file ran last wins. Propagating the `spec()` argument mentioned in the context memo is a prerequisite, not an afterthought, to any collapse.

10. **Retire the dead / redundant programs during the collapse.** `sumstats_table`, `ugrc_regressions`, `run_grc_onestep`, `grc_tex_table`, and `grc_tex_table_trend_birth` (byte-identical to `_exp`) flagged in the programs audit can be dropped in the same pass; otherwise they'll re-accumulate callers under the refactor.
