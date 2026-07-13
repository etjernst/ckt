# Full pipeline review: consolidated findings (2026-07-13)

This report aggregates an adversarial code-versus-paper audit of the full CKT Stata/Python estimation pipeline.
Fifteen agents each audited one script against the compiling manuscript (`main-updated.tex` in the Overleaf-Dropbox folder), the switcher-inclusion-consistency spec and plan dated 2026-07-13, and the underlying data.
This document is a pure aggregation of their `result` findings: nothing has been re-judged, added, dropped, softened, or re-scored.
Across the 15 units, the agents returned 67 findings: 14 CRITICAL, 30 MAJOR, 23 MINOR.

## Cross-script themes

- Per-capita definition drift. Several scripts compute the outcome as raw log household consumption (`lndepvar = ln(depvar)`) and never divide by `hhsize_cube`, even though the paper states the dependent variable is always log per-capita consumption.
This hits `11_make_figures.do` (unit figures), `3_OLS_uGRC.do` (unit ols-fe), and `6_OLS_uGRC_hukou.do` (unit ols-hukou), while the sibling GRC/GMM drivers (`4_GrRC.do`, `7_GrRC_hukou.do`) do perform the division, producing two different outcome scales across parallel tables that both claim to measure the same thing.

- Stale 5-column-versus-4-column GRC tables. The `c0` (no-covariate) GRC specification was deliberately dropped from the default column set in a 2026-07-01 commit ("table regeneration to follow; no GRC re-run"), but that regeneration never happened.
The committed tables in the Overleaf `tables/` folder, the paper's column-numbered narrative, and the caption-note macros all still describe 5 columns including a trend/education column that the current code cannot produce.
This surfaces independently in units grc-main, tables, grc-hukou, and nonag, and in every case the specific point estimates quoted in the prose also fail to match the on-disk tables.

- Drop-instead-of-lump violations of the pipeline's own never-discard principle. The switcher-inclusion-consistency spec explicitly rejects silently dropping individuals with missing classifying data, but that failure mode recurs upstream of the scope the spec/plan currently cover: `0_CHN_hukou_restrictions.do` silently drops individuals with missing hukou (unit chn-hukou-setup), `set_covariates` unconditionally drops ~9,000 CHN individuals missing `education_max` (unit data-construction), and the unbalanced-panel "non-switchers" statistic silently recodes unbalanced individuals as switchers instead of excluding them (unit summary-stats).

- Switcher-inclusion-consistency (Change B) is not yet implemented on most paths that need it. `setup_grc_estimation` keeps every switcher trajectory with no minimum-size threshold, while the Python inversion (`lca_inversion.py`) and the VV/Verdier robustness path already apply their own, differently-defined thresholds.
This produces mismatched switcher populations and mismatched `Delta_avg` weight vectors attached to the same `.ster` file, confirmed independently in units inversion, verdier, grc-main, grc-hukou, and extras.

- Orphaned pipeline output. A large share of generated tables and figures are never `\input` or `\includegraphics`'d anywhere in the compiling manuscript: the hukou OLS/FE tables (ols-hukou), the experience/birth-cohort robustness tables (extras), the heterogeneity Delta/mu tables (tables), the learning tables (learning), and several rank-diagnostic macros (rank-diagnostic).
Because these artifacts are invisible to a reader of the compiled PDF, bugs inside them (mislabeled panels, wrong outcome definitions) go undetected until someone opens the replication package directly.

- The switcher-inclusion-consistency spec/plan's own regeneration checklist (S-2) is incomplete. Multiple units flag that S-2 names only the main-path `.ster`, the hukou GRC path, the inversion attach, the VV path, and the E1 exporter CSVs, while omitting scripts that call the same shared programs Change A/B will modify: `9_GRC_extras.do` (extras), `5_GrRC_NonAg.do` (nonag), `2_summaryStats.do` (summary-stats), `11_make_figures.do` (figures), and the four hukou subsamples inside `7_GrRC_hukou.do` (grc-hukou, chn-hukou-setup).

## Critical findings (14)

### 1. figures: heterogeneity figure computed on raw consumption, not per-capita

Location: `RP7/scripts/11_make_figures.do:43-46,59-62,75-78` (calls `heterogeneity_plots`) and `RP7/scripts/0_programs.do:1500-1517` (`heterogeneity_plots` body, `reg lndepvar i.trajectory ...`).

Description: `heterogeneity_plots` regresses on `lndepvar` without first converting it to per-capita consumption.
`lndepvar` is baked into the processed `.dta` by `handle_depvar` as `gen lndepvar = ln(depvar)` (`0_programs.do:302`), i.e., log of raw total household consumption (`depvar` = `consumption`, cloned unchanged).
Every other GRC driver that uses this same processed `.dta` explicitly overwrites it immediately after loading, e.g., `4_GrRC.do:62 replace lndepvar = log(consumption/hhsize_cube)` (also `4_GrRC.do:138,214,317,393,469`; `5b_inversion.do:75`; `7_GrRC_hukou.do`; `8_learning.do`; `17_verdier_robust.do`; `10_make_tables.do`).
`11_make_figures.do` contains no such `replace` anywhere in the file (confirmed by grep) before calling `setup_grc_estimation`/`heterogeneity_plots`.
So Figure \ref{fig:heterogeneity} (`hetplotDelta_consumption_urban_unb.pdf`) and the companion `hetplotmu_*` figures, plus the reported F-statistics for equality of the $\Delta$'s and $\mu$'s, are computed on log(raw household consumption), not log(per-capita consumption).

Paper reference: `main-updated.tex:632` states "The dependent variable in all regressions is the log of per capita consumption, which is defined as total household-level consumption divided by the number of household members," and Figure \ref{fig:heterogeneity} (caption at `main-updated.tex:692-697`, "Consumption Returns to Urban Location by Country") is presented as a direct continuation of that same regression framework, immediately following the OLS section that used per-capita consumption.
No text signals a different, un-scaled outcome for this figure.

Confidence: HIGH.

### 2. figures: migration-patterns chart silently restricted to the balanced-only sample

Location: `RP7/scripts/11_make_figures.do:176-201` (IDN `mega_trajectories` block; pattern repeats for CHN and TZA at `215-242` and `256-283`) and `RP7/scripts/0_programs.do:334-391` (`handle_trajectory_groups`, esp. line 337 `keep if !unbalanced` and the comment at ~line 373 "missing indicates unbalanced observations").

Description: the migration-patterns bar chart (`trajectories.pdf`) loads `{country}_unb.dta` (the full/unbalanced-eligible sample) but then does `keep if pid_first_obs == 1 & mega_trajectories != .` (line 192 and analogues).
`mega_trajectories` is only non-missing where `trajectory` is non-missing, and `trajectory` itself is generated inside `handle_trajectory_groups` by first restricting to `keep if !unbalanced` (`0_programs.do:337`) before encoding the trajectory string; unbalanced individuals get `trajectory` merged back in as missing (documented by the code's own comment).
So despite being built from the `_unb.dta` file with `local balance unb`, the resulting bar chart silently represents only the balanced sub-population: every individual not observed in all waves is dropped.
The script itself later builds more-inclusive alternatives (`trajectory_2waves`/`trajectory_3waves`, requiring only two or more, or three or more, waves via `handle_trajectory_groups_2waves`/`_3waves`, `0_programs.do:397-450`) but those outputs (`trajectories_2waves.pdf`, `trajectories_3waves.pdf`) are never used in the paper (grep of `main-updated.tex` finds zero references), while the balanced-only `trajectories.pdf` is the one actually included.

Paper reference: `main-updated.tex:500-502` states ">90% of individuals always stay in their rural or urban area" for the full sample per Table \ref{tab:data_overview}, versus a much lower balanced-panel non-migrant share (59.6% Indonesia, 91.8% China, 85.5% Tanzania).
`main-updated.tex:504-509` then introduces Figure \ref{fig:migration-patterns} (`trajectories.pdf`, caption at `519-526`) as examining "these migration patterns in more detail"/"the proportion of the sample" with no balanced-only qualifier, so a reader would expect it to elaborate the >90% full-sample statistic just discussed, not the smaller balanced-only figures.
For Indonesia in particular the always-rural + always-urban share the figure would actually show (~59.6%, balanced) is starkly different from the >90% claimed for "all three countries" in the immediately preceding sentence.

Confidence: HIGH.

### 3. ols-hukou: hukou OLS/FE tables print "Panel A: Indonesia" for every country

Location: `C:/git/ckt/RP7/scripts/0_programs.do:1115`.

Description: `create_panel_tex_table` hardcodes `local table_posthead "\textbf{Panel A: Indonesia} \\"` for the i==1 branch (also line 1123); only i==2 gets "China" (line 1128) and i==3 "Tanzania" (line 1133).
Every call in `6_OLS_uGRC_hukou.do` uses `panels(1) countries(CHN)` (e.g., lines 64-71), so it always hits the i==1 branch.
Verified directly in the generated output: `OLS_CHN_hukou_rural_first_consumption_urban_unb.tex` and the `urban_only` sibling both literally print `\textbf{Panel A: Indonesia} \\` above CHN estimates (N=80,742 obs/25,491 individuals and N=26,155/8,366 respectively, plausible CHN subgroup sizes, confirming the underlying regression is correctly CHN and only the printed panel label is wrong).
All 12 tables this script generates carry the same mislabel.

Paper reference: not applicable to a specific paper sentence; the mislabel is in the generated table artifact itself.

Confidence: HIGH.

### 4. ols-hukou: hukou OLS/FE table notes claim per-capita consumption but the outcome is raw household total

Location: `C:/git/ckt/RP7/scripts/6_OLS_uGRC_hukou.do:58`.

Description: every `table_notes` string in this script asserts "The dependent variable is the log of total consumption per capita" (or "log income per capita"; repeated at lines 105, 152, 198, 245, 292, 338, 385, 432, 478, 525, 572), but the regression's `lndepvar` is built by `handle_depvar` (`0_programs.do:296-309`) as `gen lndepvar = ln(depvar)` where `depvar` is `clonevar depvar = consumption`, the raw household-total consumption variable (labeled "total family consumption" at `C:/git/ckt/RP7/databuild/2_build_CHN.do:106`), with no division by `hhsize_cube` or any other equivalence scale anywhere in the path `data_setup -> handle_depvar -> set_covariates -> reghdfe_regressions`.
`set_covariates` (`0_programs.do:548-575`) generates `loghhsize = log(hhsize)` (line 550) but it is never added to `$covs_1`/`$covs_2`/`$covs_all` and never enters `reghdfe_regressions` (`0_programs.do:1280-1299`); `hhsize_cube` does not appear anywhere in `1_processData.do`, `0_CHN_hukou_restrictions.do`, or `reghdfe_regressions`.
The generated table's own column header prints the literal string "log(consumption)" (from `textdepvar(log(`depvar'))`), not "per capita," so the header and the notes already disagree with each other before checking against the data.

Paper reference: `table_notes` text in `6_OLS_uGRC_hukou.do` line 58: "The dependent variable is the log of total consumption per capita."

Confidence: HIGH.

### 5. verdier: two uncoordinated scripts overwrite the same cluster-comparison table; paper numbers contradict the table they cite

Location: `RP7/scripts/17_verdier_robust.do:218` and `RP7/scripts/17b_cluster_summary.do:85-86`.

Description: `17_verdier_robust.do` (line 218) and the separate, un-included-in-`0_master.do` script `17b_cluster_summary.do` (lines 76-86) both re-estimate the identically-named `.ster` stems `vv_IDN_os_covs_all`/`vv_CHN_os_covs_all`/`vv_TZA_os_covs_all` and both write to the same output file `$output/tables/cluster_comparison_consumption_unb.tex`, with no shared source of truth and no run-order guard (`17b` does not set `global skip_if_exists`, so it silently re-optimizes and overwrites `.ster` files `17_verdier_robust.do` already wrote).
File timestamps confirm `17b` ran an hour after `17_verdier_robust.do` on 2026-07-01 (13:36 vs. 14:42) and clobbered the shared filename.
The result, verified by direct reads of the live Overleaf tables: the compiled paper's own numbers now disagree with each other.
`main-updated.tex:1016-1017` quotes `phi_cluster = -0.334` (Indonesia) and -0.155 (China), matching the per-country appendix tables `17_verdier_robust.do` itself produced (`tables/GRC_IDN_consumption_urban_unb_cluster.tex` line 16, col 5 = -0.334**; `tables/GRC_CHN_consumption_urban_unb_cluster.tex` line 16, col 5 = -0.155).
But the actual table the prose is describing, \ref{tab:verdier-robust} (`tables/cluster_comparison_consumption_unb.tex`, produced later by `17b_cluster_summary.do`), reports -0.329 for Indonesia and -0.157/Delta_never=0.096 (vs. 0.095) for China instead.
The paper's in-text numbers therefore contradict the very table they cite.
Because `0_master.do` (line 128) only includes `17_verdier_robust.do` and never `17b_cluster_summary.do`, a documented full-pipeline re-run for the planned Change A/B sample fix will regenerate the per-country tables and reset the shared `.ster` stems, but will not regenerate the 5-row `cluster_comparison_consumption_unb.tex` (which needs `17b`'s CHN rural-first/urban-first rows) unless someone manually re-runs `17b` afterward, reproducing this exact mismatch on the corrected sample unless flagged.

Paper reference: `main-updated.tex:1016-1017` versus `tables/cluster_comparison_consumption_unb.tex` (\ref{tab:verdier-robust}).

Confidence: HIGH.

### 6. ols-fe: OLS/FE baseline table outcome is raw consumption, not per-capita

Location: `RP7/scripts/0_programs.do:296-309` (`handle_depvar`) and `RP7/scripts/3_OLS_uGRC.do` (no per-capita conversion anywhere in the file).

Description: the OLS/FE table's dependent variable is raw log(total household consumption), not log(per-capita consumption), contrary to what both the paper and the table notes claim.
`handle_depvar` (`0_programs.do:296-309`) sets `lndepvar = ln(depvar)` with `depvar` cloned directly from the raw `consumption` variable, which the databuild scripts label "total family consumption" (CHN, `databuild/2_build_CHN.do:106`)/"nominal annual consumption" (TZA, `databuild/3_build_TZA.do:105`)/the renamed `cons_tot` (IDN, `databuild/1_build_IDN.do:196`), i.e., total household consumption, not divided by household size.
`3_OLS_uGRC.do` calls `reghdfe_regressions` (which uses `lndepvar` as-is) with no intervening per-capita adjustment.
By contrast, the GRC/GMM driver `4_GrRC.do` explicitly converts to per-capita before estimation: `replace lndepvar = log(consumption/hhsize_cube)` (`4_GrRC.do:62,138,214,317,393,469`), where `hhsize_cube = hhsize^(1/3)` is the adult-equivalence scale (`databuild/1_build_IDN.do:151` and siblings).
`3_OLS_uGRC.do` has no analogous line.
Verified live: loading `RP7/data/processed/IDN_unb.dta` and computing `lndepvar = ln(consumption)` exactly reproduces the `reghdfe_regressions` logic with no household-size division anywhere.
Note also that the paper's own definition ("divided by the number of household members," i.e., plain `hhsize`) differs from what `4_GrRC.do` actually divides by (`hhsize_cube`, cube-root equivalence scale), so even a corrected version of this script would need to match the GRC convention, not the paper's literal prose, to be internally consistent.
This also has a forward implication for Change A: because this script currently never references `hhsize_cube`, Change A's individual-level strict-spec exclusion (missing `hhsize_cube`) does not currently apply here; fixing this per-capita bug would pull this script into Change A's scope for the first time.

Paper reference: `main-updated.tex:632` ("dependent variable ... is the log of per capita consumption"); `RP7/output/tables/OLS_consumption_urban_unb.tex` tablenotes ("dependent variable is the log of total consumption per capita").

Confidence: HIGH.

### 7. ols-fe: code produces 6 columns; paper narrates a 7-column progression

Location: `RP7/scripts/3_OLS_uGRC.do:101-109` (`create_panel_tex_table` call, `columns(6)`) and `RP7/scripts/0_programs.do:1280-1298` (`reghdfe_regressions`).

Description: the paper narrates a seven-column progression: column (1) raw/no controls, column (2) adds time fixed effects, column (3) adds female, column (4) adds age squared, column (5) adds education, column (6) restricts to migrants, column (7) adds individual fixed effects (`main-updated.tex:635-656`), but the code and the generated table have only six columns (`3_OLS_uGRC.do:102`, `columns(6)`; footer "Covariates & & Female & \& Age$^2$ & All & All & All" lists exactly six slots).
In `reghdfe_regressions` (`0_programs.do:1280-1298`), reg1 (the code's column 1) already absorbs `period`, i.e., time fixed effects are baked into column 1 from the start; there is no separate "no covariates, no time FE, unrestricted sample" column and no separate "adds time FE" step.
The generated table's own note says "All columns include time (survey wave) fixed effects," directly contradicting the paper prose's claim that column (2) is what "adds time fixed effects" (implying column 1 lacks them).
Every subsequent column reference in the paper's Observational Returns discussion (education in "column (5)," migrants-only in "column (6)," individual FE in "column (7)") is therefore off by one relative to what the actual code computes (education is code col4, migrants-only is code col5, individual FE is code col6).

Paper reference: `main-updated.tex:635-656`, Section 5.1 "Observational Returns" (`sec:observational-returns`).

Confidence: HIGH.

### 8. grc-main: paper narrates a 5-column GRC table with education/trend columns the code cannot produce

Location: `RP7/scripts/4_GrRC.do:93-98,169-174,245-250` (recurs at `350-353,426-429,502-505,598-603,669-674,740-745`); `RP7/scripts/0_programs.do:3276-3278`; `RP7/scripts/10_make_tables.do:50`.

Description: the paper narrates a 5-column GRC results table ending in an education column (4) and a "linear time trend" column (5), but the code that generates that table cannot produce it.
In `4_GrRC.do` the no-covariate spec (`c0`) is commented out for every country and balance ("c0 (no covariates) no longer estimated (2026-07-01): dropped from the tables and often non-convergent"), leaving four active `run_grc` calls per cell (`ct`, `c1`, `c2`, `ca`).
None of those `covars()` arguments ever includes a linear trend variable; `covars()` is built only from `periodFE` plus `$covs_gmm`/`$covs_gmm2`/`$covs_gmm_all` (female, age2, education_max, education_max2); the trend variable (`gen_time_trend`) is only ever added in the OLS uGRC path (`ugrc_regressions`, `0_programs.do:1766-1787`), never in `run_grc`'s covariate list.
Consistent with this, `grc_tex_table_trend`'s default `covs2set` is `ct c1 c2 ca` (4 columns, no `c0`), and every call in `10_make_tables.do` passes `columns(4)` explicitly.
Yet the table currently in the Overleaf `tables/` folder (`tables/GRC_IDN_consumption_urban_unb.tex`, `tables/GRC_CHN_consumption_urban_unb.tex`, `tables/GRC_TZA_consumption_urban_unb.tex`) is a 5-column table with a populated column (1), identical in structure and numbers to the archived `tables/archive/.../GRC_IDN_consumption_urban_unb_2026-02.tex` from before `c0` was disabled.
A fresh run of the current `4_GrRC.do` plus `10_make_tables.do` would produce a 4-column table (education entering column 4, no trend column at all), so the on-disk table the paper cites is stale and not reproducible from the assigned script as currently written.

Paper reference: `main-updated.tex:705-722`, subsection "Estimates from Restricted GRC Model" (`sec:grc-returns`), esp. "When we add controls for education and education squared in column (4)..." and "when we additionally control for a linear time trend in column (5)..."

Confidence: HIGH.

### 9. grc-main: Delta_never numbers in the results prose do not match the on-disk GRC tables

Location: Overleaf `tables/GRC_IDN_consumption_urban_unb.tex:5`, `tables/GRC_CHN_consumption_urban_unb.tex:5`, `tables/GRC_TZA_consumption_urban_unb.tex:5` (Delta_never row).

Description: independent of the column-count issue, the specific Delta_never magnitudes quoted in the Results prose do not match the values in the on-disk tables the prose cites.
IDN: the paper claims "column (4) ... drops to 20.6 log points" and "column (5) with a linear time trend ... 12 log points"; the actual table shows column (4) [Age$^2$] = 0.091 (9.1 log points) and column (5) [All covariates] = 0.071 (7.1 log points), neither number appears anywhere in the row.
CHN: the paper claims column (5) = 10.7 log points; the table shows 0.098 (9.8 log points).
TZA: the paper claims column (1) [no covariates] = 78 log points and column (5) = 37 log points; the table shows column (1) = 0.652 (65.2 log points) and column (5) = 0.270 (27.0 log points), both well outside plausible rounding.
This also breaks a downstream comparison: the paper argues the IDN GRC non-migrant return is "78 percent larger than the 6.7 log points estimated using individual fixed effects" (12 vs. 6.7), but the current column-5 value is 7.1, essentially the same magnitude as 6.7; the "78 percent larger" claim does not survive on the numbers the current pipeline (or even the stale on-disk table) actually produces.

Paper reference: `main-updated.tex:713-717` (IDN), `728-731` (CHN), `737-739` (TZA).

Confidence: HIGH.

### 10. summary-stats: "non-switchers" percentage miscounts unbalanced individuals as switchers

Location: `RP7/scripts/0_programs.do:378-384,820` (called from `RP7/scripts/2_summaryStats.do:36,66,96` via `0_programs.do:712 sumstats_combined_table`).

Description: the "Non-switchers" percentage reported in every `*_unb` summary-stats table is computed over all individuals (`summarize non_switcher if pid_first_obs==1`, `0_programs.do:820`), but `non_switcher` is built from `trajectory` (`0_programs.do:378-384`), which is missing for every genuinely-unbalanced/incomplete-panel individual (`handle_trajectory_groups` builds `trajectory` only on `keep if !unbalanced` rows, then merges back with `allow(1,3)`, `0_programs.do:337,370-371`).
Because `non_switcher_temp = (trajectory==1)|(trajectory==max_trajectory)` evaluates to 0 (not missing) when `trajectory` is missing, every unbalanced individual is silently counted as "not a non-switcher" instead of being excluded.
This mechanically deflates the statistic to exactly (# balanced non-switchers)/(total unb individuals): verified algebraically against the actual generated tables, IDN 1,957/29,716=6.59%≈6.6%, CHN 13,048/34,746=37.55%≈37.6%, TZA 6,705/11,012=60.90%≈60.9%, matching the printed "Non-switchers" row in `tables/summary_stats_combined_unb.tex:23` to the digit.
These values directly contradict the paper's own prose describing the identical table/sample (same Individuals=29,716/34,746/11,012 and Observations=93,038/109,535/29,864 counts): `main-updated.tex:583` states IDN is "92.9 percent... never switch"; line 605 states CHN has "only 4.3 percent of individuals engaging in such moves" (implying ~95.7% non-switchers); line 619 states TZA has "11.4 percent of individuals... observed in both a rural and an urban area" (implying ~88.6% non-switchers).
The corresponding balanced-panel table (`tables/summary_stats_combined_bal.tex:23`, where by construction no individual has a missing `trajectory`) shows plausible values (IDN 59.6%, CHN 91.8%, TZA 85.5%), confirming the bug is confined to the `unb` path.
This is not a stale-artifact issue: `RP7/output/tables/summary_stats_combined_unb.tex` (regenerated 2026-07-10) has byte-identical Non-switchers figures to the Overleaf-committed copy, so the bug is live in the current pipeline.

Paper reference: `main-updated.tex:583,605,619` versus `tables/summary_stats_combined_unb.tex:23`.

Confidence: HIGH.

### 11. grc-hukou: rural-first hukou table's stale column rejects the J-test, contradicting the paper's "neither subsample rejects" claim

Location: `C:/git/ckt/RP7/output/tables/GRC_CHN_hukou_rural_first_consumption_urban_unb.tex:1-21` (identical copy at the Overleaf `tables/` folder); root cause at `C:/git/ckt/RP7/scripts/7_GrRC_hukou.do:95-100`.

Description: the paper states, unqualified, "Neither subsample rejects the J-test at conventional significance levels, yet the estimated slope estimates differ substantially" (`main-updated.tex:763`).
The rural-first hukou GRC table that is actually `\input`'d into the compiled paper via `\GRChukoutable{CHN}{consumption}{urban}{unb}{rural_first}` (`main-updated.tex:786`) currently has five data columns (1)-(5), not the four (`ct,c1,c2,ca`) that `7_GrRC_hukou.do` now produces.
Column (1) has blank Time FE and blank Covariates: it is the deprecated "c0" (no-covariates) specification that `7_GrRC_hukou.do:95-100` explicitly comments out ("c0 ... no longer estimated (2026-07-01): dropped from the tables and often non-convergent").
That stale column-1 fit shows phi=-0.893***, J-stat=86.0, J-stat p-value=0.000, a clear rejection of the overidentifying restrictions, directly contradicting the prose's unqualified "Neither subsample rejects." (The urban-first table's stale c0 column happens not to reject, J=3.8, p=0.585, so the contradiction is specific to the rural-first cell but sits in the very table the paper cites for this claim.)
This table also has no "95% inv. CI" rows despite `10_make_tables.do` passing `invci` for this cell, confirming the artifact predates both the c0 removal and the inversion-CI feature: it is stale, not merely mislabeled.
Regenerating it is not a simple table-only rerun: on disk in `C:/git/ckt/RP7/output/` only `grc_CHN_rf_cuu_ca*.ster`, `grc_CHN_uf_cuu_ca*.ster`, `grc_CHN_ro_cuu_ca*.ster`, and `grc_CHN_uo_cuu_ca*.ster` exist for the hukou cells; the `_ct`, `_c1`, `_c2` sters that `7_GrRC_hukou.do` currently defines are entirely absent for all four hukou subgroups, so `10_make_tables.do`'s hukou table section (`grc_tex_table_trend`'s file-existence guard at `0_programs.do:3344-3349`, keyed on the first `covs2set` element "ct") would silently skip the cell rather than regenerate it if run today.
`7_GrRC_hukou.do` itself must be re-run to produce fresh `_ct`/`_c1`/`_c2` sters before the stale, prose-contradicting table can be replaced.

Paper reference: `main-updated.tex:763` ("Neither subsample rejects the J-test at conventional significance levels..."); table macro call at `main-updated.tex:786`.

Confidence: HIGH.

### 12. data-construction: set_covariates unconditionally drops (not lumps) ~9,000 CHN individuals missing education_max

Location: `RP7/scripts/0_programs.do:594-596` (`set_covariates`).

Description: `set_covariates` contains two unconditional row-level restrictions, `drop if mi(education_max)` and `drop if mi(age)` (`0_programs.do:594-595`), that run after `handle_balance`/`handle_trajectory_groups` and literally delete every row of an individual missing that covariate, rather than lumping them into the unbalanced cell.
`education_max` is a time-invariant per-person variable built by `egen max` in databuild (e.g., `databuild/1_build_IDN.do:203`), so its missingness is an all-or-nothing person-level event, and this drop deletes complete individuals outright.
Verified directly on the raw country data by replicating the choice/depvar/education_max/age/obs_per_individual filter sequence in Stata: for CHN, 9,000 of 49,398 individuals (18.2%) are missing `education_max` and are deleted this way, accounting for 14,275 of 129,466 pre-education-filter individual-year rows; the resulting final counts (109,535 rows / 34,746 individuals) exactly match the paper's reported CHN sample.
Age contributes a much smaller additional deletion (5 CHN rows, 2 IDN, 2 TZA, all confirmed directly).
This is the same "strict-column-regressor missingness silently removes people from the sample" defect the spec diagnoses for `hhsize_cube` (29 IDN individuals) and that motivated decision DA3 ("never discard, only lump," because a full drop "contradicts the never-discard principle in D3"), but it already exists today at roughly two orders of magnitude larger scale for `education_max` in CHN, and the Change A plan does not touch it: plan step A-2 only inserts a new completeness check inside `handle_balance` and never modifies or removes the pre-existing `drop if mi(education_max)`/`drop if mi(age)` lines in `set_covariates`.
Even after Change A ships exactly as scoped, `set_covariates` will keep unconditionally deleting (not lumping) the ~9,000 CHN individuals missing `education_max`, directly violating the same never-discard principle the spec invokes to justify Change A's own design, at far greater scale than the case Change A's own acceptance test (A2: "TZA is unaffected... CHN is untouched by inspection") is built to catch.

Paper reference: `quality_reports/specs/2026-07-13-switcher-inclusion-consistency.md` decisions DA3/D3 (never-discard principle); `quality_reports/plans/2026-07-13-switcher-inclusion-consistency.md` step A-2.

Confidence: HIGH.

### 13. tables: default GRC table column count (4) contradicts committed 5-column tables and the paper's column-numbered narrative

Location: `RP7/scripts/0_programs.do:3264-3278` and `RP7/scripts/10_make_tables.do:50,69,88,114,132,150,175,193,211,250,301,344,369,412`.

Description: `grc_tex_table_trend`'s docstring says the default `covs2set` is "c0 ct c1 c2 ca" (5 covariate columns), but the actual code default at `0_programs.do:3277` is "ct c1 c2 ca" (4 columns, `c0` dropped).
Every one of `10_make_tables.do`'s 22 `grc_tex_table_trend` calls uses `columns(4)` and never passes `covs2set()`, so every main/hukou GRC table this script produces inherits the 4-column default.
Yet every currently-committed `.tex` table in the Overleaf `tables/` folder (`GRC_IDN_consumption_urban_unb.tex`, `GRC_CHN_...`, `GRC_TZA_...`, the two CHN hukou main tables, `GRC_IDN_consumption_urban_bal.tex`, `GRC_IDN_income_urban_unb.tex`, `GRC_IDN_consumption_nonag_unb.tex`, etc.) is still 5-column (`\begin{tabular}{l ccccc}`), and the paper's own note macros `\GRCnotesIDNcanonical`/`\GRCnotesIncomeShared` (`preamble.tex:230-238`) explicitly describe 5 columns ("Columns~(2) to~(5)...column~(5) adds education...").
Git history confirms this is not a coincidence: commit `c1a55ba` (Jul 1 2026, "Restructure OLS/GRC tables: drop no-covariate column...") deliberately dropped `c0` from the default and switched `10_make_tables.do` to `columns(4)`/4-col footers, with the commit message stating "Table regeneration to follow; no GRC re-run"; that regeneration never happened.
The `c0` `.ster` files still exist on disk (`RP7/output/grc_IDN_cuu_c0*.ster`), so the estimation output is available but currently orphaned from the table generator's default path.
Because the Change A/B plan's S-2 step requires regenerating the main-path `.ster` and downstream artifacts (which routes through `10_make_tables.do`), running this script as part of that re-run will silently shrink every GRC table in the paper from 5 to 4 columns, breaking the standing caption notes and the column-numbered prose narrative (`main-updated.tex:707-739`) with no error raised anywhere in the pipeline.

Paper reference: `preamble.tex:237` (`\GRCnotesIDNcanonical`: "Columns~(2) to~(5) include time...column~(5) adds education...") and `main-updated.tex:707-739` (the IDN/CHN/TZA results narrative, which numbers columns 1 through 5).

Confidence: HIGH.

### 14. tables: GRC results narrative numbers and column descriptions do not match currently-committed tables

Location: `main-updated.tex:713-717` (IDN), `:729-730` (CHN), `:738-739` (TZA) versus `tables/GRC_IDN_consumption_urban_unb.tex`, `tables/GRC_CHN_consumption_urban_unb.tex`, `tables/GRC_TZA_consumption_urban_unb.tex`.

Description: the main-text narrative describing the IDN/CHN/TZA GRC results (the tables this script generates) does not match the currently-committed table content, on both column semantics and point estimates.
IDN (`main-updated.tex:713-717`): the text says "column (1) at 30 log points" (table col1 Delta_never = 0.304, roughly matches), "add controls for education and education squared in column (4)... drops to 20.6 log points" (table column 4 is actually the `c2` spec = female+age$^2$, not education, and its value is 0.091 = 9.1 log points, not 20.6), and "additionally control for a linear time trend in column (5)... 12 log points" (table column 5 = `ca`, i.e., all covariates including education/education$^2$, not a separate time-trend add-on, and its value is 0.071 = 7.1 log points, not 12).
The follow-on claim that this is "78 percent larger than the 6.7 log points estimated using individual fixed effects" (line 717) also fails against the actual current value: 0.071 vs. 0.067 is about a 6 percent difference, not 78 percent.
CHN (line 729-730): "without any controls in column (1) are 43 log points" (table = 0.424, roughly matches) but "all controls and a linear time trend...10.7 log points" (table column 5 = 0.098 = 9.8 log points).
TZA (line 738-739): "Without covariates, the returns are 78 log points" (table column 1 = 0.652 = 65.2 log points, a 13-point gap) and "control for all our covariates and a time trend in column (5)...remain high at 37 log points" (table column 5 = 0.270 = 27.0 log points, a 10-point gap).
The prose's column-4/column-5 content description also directly contradicts the table's own caption note (`\GRCnotesIDNcanonical`, `preamble.tex:237`), which says column (4) adds age squared and column (5) adds education and its square, i.e., two parts of the same paper disagree about what columns 4 and 5 even contain, independent of which numeric values are correct.

Paper reference: `main-updated.tex:707` ("Tables \ref{tab:GRC_IDN_consumption_urban_unb}... report results from the restricted GRC model").

Confidence: HIGH.

## Major findings (30)

### 15. chn-hukou-setup: individuals with missing classifying-wave hukou are silently dropped

Location: `RP7/scripts/0_CHN_hukou_restrictions.do:53-59,69-75` (rural-first/urban-first) and `:25-29,37-43` (rural-only/urban-only).

Description: individuals whose hukou value is missing at the classifying wave(s) are silently dropped from the hukou-restricted samples, with no diagnostic count and no lumping into an "unbalanced"-style catch-all cell.
For rural-first/urban-first: `first_hukou_temp = hukou if obs==1` is missing whenever hukou is missing in an individual's first observed wave; `first_hukou = min(first_hukou_temp)` over the group then collapses to missing (only one non-missing candidate exists per person, namely the obs==1 row); `keep if first_hukou==1` and `keep if first_hukou==0` both evaluate false for a missing value, so that individual is dropped from both the rural-first and urban-first datasets, not lumped into either.
For rural-only/urban-only: if hukou is missing in every wave for an individual, `egen min`/`max` returns missing, and `rural_hukou = min_hukou==1`/`urban_hukou = max_hukou==0` both evaluate to 0 (not missing) for that person, again silently excluding them from both "only" datasets.
No `di` diagnostic, no count, and no reconciliation check (e.g., asserting rural_first union urban_first covers the full CHN estimation sample) exists anywhere in the file to surface how many individuals this affects.
This is the same failure mode, silent exclusion of individuals with partially missing classifying data, that the switcher-inclusion-consistency spec explicitly rejects elsewhere in the pipeline (spec DA3/D3: "A full drop was rejected because it discards roughly four valid person-waves each and contradicts the never-discard principle").
This script sits upstream of the scope explicitly covered by Change A/B (which target `1_processData.do`'s `handle_balance` and `setup_grc_estimation`), so it is not fixed by that spec/plan as currently scoped, and the paper's framing that rural-first and urban-first jointly explain the pooled China J-test rejection implicitly assumes they partition the estimation sample; any silently dropped individuals break that partition without disclosure.
Magnitude is unverified since actual hukou missingness rates in CHN.dta were not run through Stata to check.

Confidence: MEDIUM.

### 16. chn-hukou-setup: hukou path never actually adds hukou as a regressor, contrary to a load-bearing plan premise

Location: `RP7/scripts/0_programs.do:561,572-575,589-592` versus `RP7/scripts/7_GrRC_hukou.do:44-46` (and repeated at every subsequent block) and `RP7/scripts/0_programs.do:1280-1298` (`reghdfe_regressions`).

Description: the switcher-inclusion-consistency plan (`quality_reports/plans/2026-07-13-switcher-inclusion-consistency.md`, Risk R-5, and spec review resolution m2) states as a load-bearing fact that "the hukou path adds hukou" as an additional strict-column regressor beyond `{hhsize_cube, female, age, education_max}`, and instructs the implementer to extend Change A's strict-regressor missingness predicate for the hukou path accordingly.
Tracing the actual code shows this premise is false for the code as it currently runs.
`set_covariates` in `0_programs.do` does define hukou-augmented covariate globals (`covs_1_hukou`, `covs_2_hukou`, `covs_3_hukou`, `covs_all_hukou`, `covs_gmm_hukou`, `covs_gmm2_hukou`, `covs_gmm3_hukou`, `covs_gmm_all_hukou`) gated on all four CHN hukou country strings (line 561), and these do include `hukou` as the first regressor.
But neither of the two scripts that actually run hukou-path estimation ever references these `_hukou`-suffixed globals: `7_GrRC_hukou.do` locally redefines `global covs_gmm "female"`, `covs_gmm2 "$covs_gmm age2"`, `covs_gmm_all "$covs_gmm2 education_max education_max2"` at the top of every one of its blocks (lines 44-46, identically repeated for all four subsamples x three outcomes), which shadows and overrides whatever `set_covariates` set; and `6_OLS_uGRC_hukou.do` calls the shared `reghdfe_regressions` program (`0_programs.do:1280`), which hardcodes `$covs_all`/`$covs_1`/`$covs_2` (never `$covs_all_hukou` etc.) regardless of the `country` argument passed in.
So the strictest hukou-path GRC/OLS column uses exactly the same regressor set as the pooled CHN main-text specification: `hukou` is never itself a regressor in any executed hukou-path estimation.
If Change A's implementation follows the plan's R-5 assumption literally, it will over-restrict the CHN hukou samples on missingness of a variable (`hukou`) that plays no role in the estimated specification, which is inconsistent with DA2's stated rule ("the correct sample definition for the estimand") since the estimand here does not condition on non-missing hukou beyond the classification step in `0_CHN_hukou_restrictions.do` itself.

Confidence: HIGH.

### 17. rank-diagnostic: unbalanced-rank diagnostic reads the base .dta before switcher lumping and will go stale under Change B

Location: `RP7/scripts/1b_unbalanced_rank_diagnostic.do:108,121`.

Description: this diagnostic loads `$dirdata/processed/{country}_unb.dta` directly (script runs at `0_master.do:105`, right after `1_processData.do:101` and well before `4_GrRC.do:109`) and restricts to `unbalanced == 1` as read off that file.
Under the approved Change B design, sub-threshold switcher trajectories are not lumped into `unbalanced` in the processed `.dta`: Design 2 explicitly says "Keep the original trajectory column intact in the .dta... The main GMM (`setup_grc_estimation`) lumps non-kept switchers to 999 at estimation setup" (plan lines 50-52, B-3 at lines 101-105).
Since `setup_grc_estimation` is called from `4_GrRC.do`, which runs strictly after this diagnostic in the pipeline, this script structurally cannot see the post-Change-B $U_i$ stratum.
Once Change B ships, the GMM's actual $U_i=1$ population (attrition-unbalanced individuals plus lumped thin-switcher individuals) will differ from the $U_i=1$ population this script measures (attrition-unbalanced individuals only), so `\unbUrbanRateXXX`, `\unbResidShareXXX`, `\unbShareXXX`, and the (a)/(b)/(c) counts will silently characterize the wrong stratum.

Paper reference: `main-updated.tex:1215` states Proposition `prop:pooling`'s rank condition as holding "among unbalanced observations ($U_i = 1$)"; `main-updated.tex:1236-1240` reports `\unbUrbanRateXXX`/`\unbResidShareXXX`/`\unbShareXXX` as the empirical diagnostics supporting that same rank condition for the estimator actually run.
Neither the spec nor the plan lists `1b_unbalanced_rank_diagnostic.do`, `unbalanced_rank_macros.tex`, or the `app:pooling` appendix among the files/artifacts Change B touches (spec "Scope" section, lines 12-15), so this staleness is currently unaddressed by the shipping plan.

Confidence: HIGH.

### 18. extras: IDN "cnu + birth" cell silently runs on the urban-choice dataset, not the nonag dataset it is named for

Location: `RP7/scripts/9_GRC_extras.do:117-121`.

Description: the IDN `cnu` (non-agricultural choice) x urban-birth cell passes `data_path_override("$dirdata/processed/IDN_unb.dta")` instead of the nonag dataset `IDN_unb_nonag.dta` that every other `cnu` call in this file uses.
In `run_grc_with_extra_regressor` (`0_programs.do:2330-2341`) the override is honored verbatim, so `use` loads `IDN_unb.dta`.
Per `1_processData.do:14-23` and `:29-38`, `IDN_unb.dta` is built with `local choice urban` (`handle_choice` clonevars `choice = urban`, `0_programs.do:284-286`) while `IDN_unb_nonag.dta` is built with `local choice nonag`.
So the entire GRC machinery downstream, trajectory, `switcher_*`, never/always dummies, mu/Delta/phi, for this one cell is computed on urban-vs-rural switching, not sector switching, even though the estname (`grc_IDN_cnu_birth_c1..ca`) and the corresponding table filename produced by `extras_tex_table` (`GRC_IDN_consumption_nonag_unb_birth.tex`, `0_programs.do:3778`) both say "nonag."
The header comment in `9_GRC_extras.do` calls this "faithful replication of historical behavior" from the now-deleted file 15, i.e., a known quirk is deliberately preserved rather than corrected.
Currently invisible in the compiled paper only because `grc_robustness_coefplot` (`0_programs.do:1646-1747`) reads exclusively `spec3=cuu` stems and the paper does not `\input` any of the 44 extras tables, but the `.ster` and `.tex` artifact on disk misrepresent what was estimated, and would mislead if pulled into an appendix or the replication package as-is.

Confidence: HIGH.

### 19. extras: extra-regressor covariate ladder can drop switcher trajectories that the once-computed keep-list already validated

Location: `RP7/scripts/0_programs.do:2351` (`setup_grc_estimation` call) and `:2374-2403` (`covs1`..`covsall`).

Description: the switcher-inclusion-consistency spec's coupling argument (`quality_reports/specs/2026-07-13-switcher-inclusion-consistency.md`, "Coupling between the two changes" and MUST 5) claims that after Change A protects `{hhsize_cube, female, age, education_max}`, a single switcher keep-set computed once per (country, path) is automatically valid across every covariate-restricted spec, because "the only regressors those specs add are exactly the protected ones."
That premise is false for this script: `run_grc_with_extra_regressor`'s `covs1`/`covs2`/`covs3`/`covsall` locals (`0_programs.do:2375-2378`) all include the extra regressor itself (`exp`, `exp_max`, `exp_share`, `exp_max_share`, or `urbanbirth`), none of which is in the protected set, and `setup_grc_estimation` (which will host the planned keep-list computation per plan B-2/B-3) is called exactly once per stem (`0_programs.do:2351`), before all four progressively covariate-laden fits run.
These regressors are demonstrably capable of being missing for individual-waves: `g exp = .`/`g exp_share = .` are initialized to missing and only conditionally replaced in `RP7/databuild/2_build_CHN.do:356-357`, and `RP7/databuild/1_build_IDN.do:49-50` constructs `exp_share = exp / elig_years`, which is undefined whenever `elig_years` is 0 (an `egen anycount` over an all-missing employment history).
So a switcher trajectory that clears the both-states threshold on the base sample used to author the keep-list once per stem can still fall below it once the GMM's listwise deletion over the `ca` covariate set (which additionally requires the possibly-missing extra regressor) drops individuals, reproducing, inside this single script, exactly the kind of silent per-column sample mismatch that Change A/B are designed to eliminate on the main path.
Neither the spec nor the plan mentions `9_GRC_extras.do` or the extras/robustness family at all, so this gap is currently unaddressed by the planned design.

Paper reference: `quality_reports/specs/2026-07-13-switcher-inclusion-consistency.md` MUST 5 and "Coupling between the two changes."

Confidence: MEDIUM.

### 20. figures: switcher-inclusion-consistency plan's regeneration checklist omits the figures pipeline

Location: `quality_reports/plans/2026-07-13-switcher-inclusion-consistency.md`, section S-2 ("Regenerate: the main-path .ster (4_GrRC.do, and hukou 7_GrRC_hukou.do), the inversion attach (5b_inversion.do), the VV path (17_verdier_robust.do), and the E1 exporter CSVs.").

Description: S-2's regeneration checklist does not mention `11_make_figures.do` at all, yet `heterogeneity_plots` calls `setup_grc_estimation` directly on the (post-Change-A) processed `.dta` and will inherit Change B's switcher-lumping once `setup_grc_estimation` is patched per plan step B-3 (drop-and-lump before building `$switchers`).
That means Figure \ref{fig:heterogeneity} and the `grc_robustness_coefplot` figures (which read `.ster` files produced by drivers not listed in S-2 either, e.g., the experience/max-experience/birth robustness variants referenced at `0_programs.do:1653-1658`) will change silently under Change A/B but are not flagged for mandatory re-run and re-inspection in the plan, risking stale committed figures inconsistent with the corrected tables after the pre-submission re-run.

Paper reference: spec/plan MUST 7 and S-2/S-3 require "regenerate every affected .ster, the E1 exporter CSVs, and any downstream artifact, and re-quote every paper number that moves"; the figures pipeline is a downstream artifact of the same corrected processed `.dta` and switcher-inclusion rule but is omitted from the explicit regeneration list.

Confidence: MEDIUM.

### 21. ols-hukou: GRC hukou path performs the per-capita division that the OLS hukou path skips

Location: `C:/git/ckt/RP7/scripts/7_GrRC_hukou.do:64`.

Description: the sibling hukou GRC script that the paper actually cites (via `\GRChukoutable`, sourced from `7_GrRC_hukou.do`) explicitly performs `replace lndepvar = log(consumption/hhsize_cube)` before estimation (`7_GrRC_hukou.do:64,168,372,476`), confirming the codebase's own convention that per-capita consumption requires this division.
`6_OLS_uGRC_hukou.do`'s `reghdfe_regressions` never performs this division (see CRITICAL finding 4 above), so the OLS/FE hukou tables and the GRC hukou tables use different definitions of the outcome variable (household-total vs. per-capita) despite both claiming to measure the same "log consumption per capita" object and both being framed as parallel robustness checks for the same hukou subgroups.

Confidence: HIGH.

### 22. ols-hukou: none of the 12 generated hukou OLS/FE tables is referenced anywhere in the compiling paper

Location: `C:/git/ckt/RP7/scripts/6_OLS_uGRC_hukou.do:1`.

Description: the paper's hukou subsection (`\subsubsection{Hukou Restrictions in China}`, `sec:hukou`, `main-updated.tex:742-787`) and the appendix "Additional Results: Hukou Status" (`main-updated.tex:1131-1137`) cite only `\GRChukoutable{...}` (the restricted-GRC hukou split, sourced from `7_GrRC_hukou.do`); a project-wide grep for "OLS_CHN_hukou" and for any macro (e.g., an `\OLShukoutable` analogous to `\GRChukoutable`) that could `\input` the OLS tables this script produces returns zero matches anywhere in the compiling Overleaf project.
The script's own header comment ("This code: runs OLS & FE regressions for the four CHN hukou subgroups...") implies paper-facing output, but none of the 12 generated `OLS_CHN_hukou_*.tex` tables (copied to the Overleaf tables/ folder via `copyOverleaf`) are referenced by the manuscript that compiles to `main-updated.pdf`.
The paper never makes an OLS/FE hukou claim for this script's output to contradict; the tables are orphaned pipeline output that would surface the two CRITICAL bugs above (findings 3-4) only if a coauthor or referee opened the replication package directly.

Confidence: HIGH.

### 23. inversion: the GMM's switcher set and the attached inversion CI are computed over two different switcher populations

Location: `C:/git/ckt/.claude/worktrees/lca-inversion/explorations/python-grc/lca_inversion.py:74-79`.

Description: the GMM (`setup_grc_estimation`, `0_programs.do:1489-1492`) keeps every switcher trajectory that exists, with no thin-cell drop.
The inversion this script attaches (`attach_inversion_ci` at `5b_inversion.do:139-147`, which never passes `threshold()` so the default of 5 applies) -> `attach_inversion_for_stata` -> `compute_all_inversion_cis` -> `drop_sparse_switchers` drops any switcher trajectory with fewer than 5 unique individuals contributing a treated (`choice==1`, urban) observation only, a one-sided count that never checks the rural side (`lca_inversion.py:53-79`).
So for every (country, spec) cell this script processes, the GMM's `phi` and `Delta_avg` are computed over the full switcher set while the attached inversion CI is computed over a strictly smaller, one-sided-filtered switcher set, two different estimands over two different switcher populations attached to the same `.ster`.
This is precisely the defect the spec calls "the current inconsistency" (spec Change B) and MUST 3 of the spec explicitly requires the GMM to adopt the symmetric both-states rule to close this gap; as read, this script has not yet been updated for Change B.

Paper reference: `main-updated.tex:827` implies a GMM-side drop the code does not yet perform; `main-updated.tex:831-833` describes the inversion propagating uncertainty for the same `Delta_avg` object the GMM reports, which requires a shared switcher set.

Confidence: HIGH.

### 24. inversion: the GMM and inversion weight vectors for Delta_avg have different denominator populations

Location: `C:/git/ckt/RP7/scripts/0_programs.do:2220-2221`.

Description: the GMM's `Delta_avg` weight is `local num_s = r(mean)` from `sum 1.switcher_s if e(sample) & switcher==1` (`0_programs.do:2220-2221`), a person-period share over `switcher==1`, i.e., every balanced switcher-trajectory row (unfiltered, since the GMM drops nothing today).
The inversion's weight is `pi_within = {s: (sub[trajectory]==s).sum()/n_sw for s in kept}` (`lca_inversion.py:805-806`), a person-period share over only `kept`, the threshold-5 one-sided-filtered set.
Both are person-period-weighted shares (the weighting form matches, per the plan's C1 resolution), but the denominator population differs today because the underlying switcher sets differ.
`attach_inversion_ci` re-saves the inversion's `inv_davg` CI macros onto the exact same `.ster` that already carries the GMM's own `Delta_avg` point estimate (`0_programs.do:3991-4010`, suffix `_g`), so the resulting table cell pairs a GMM point estimate over all switchers with a CI computed over a strict subset, a different estimand attached to the same coefficient.
This is the open item the plan itself flags unresolved: "Assert the average-return weight vector (num_s for the GMM, pi_within for the inversion) ... match across the two estimators (review finding M1)" (plan S-3), now confirmed by direct trace through the code this script executes.

Paper reference: `main-updated.tex:824-833`; plan.md S-3 / review finding M1 in `2026-07-13-switcher-inclusion-consistency.md`.

Confidence: HIGH.

### 25. inversion: a single mismatched-threshold cell can silently abort the entire multi-country inversion run

Location: `C:/git/ckt/RP7/scripts/5b_inversion.do:33,85-90,139-147,156-158`.

Description: `5b_inversion.do` recovers `base` via `initial_values` (lines 85-89) "so the inversion's auxiliary OLS pivots on the same switcher reference as the GMM."
`initial_values` selects `base` from `$switchers` (every switcher, unthresholded) using `N_s / T > $grc_min_switchers_per_wave` (`0_programs.do:1875`, threshold=5 set in `0_path_config.do:51`), a strict inequality on a person-period row count.
The inversion's own filter, `drop_sparse_switchers` (`lca_inversion.py:46-80`), uses a different unit (unique treated-pid count) and a non-strict inequality (>=5).
These two "5"-labeled thresholds are not the same test, so the GMM-mirroring base is not guaranteed to survive Python's filter; when it does not, `compute_all_inversion_cis` raises `ValueError` (`lca_inversion.py:775-778`), which propagates as a Stata error from the `python:` call inside `attach_inversion_ci`.
`5b_inversion.do` wraps its entire body (all countries x all specs) in one `capture noisily { ... }` (lines 33-155) with no per-cell capture around the `attach_inversion_ci` call (lines 139-147), so a single mismatch in any one cell halts the remaining block: every subsequent spec and country is silently skipped, with failure only reported after the fact (lines 156-158).
This is grounded in the exact file audited; the paper itself documents near-threshold switcher configurations (e.g., "the urban-hukou-first subsample's six small switcher cells," `main-updated.tex:858` footnote) where a >5-vs->=5, row-count-vs-treated-pid mismatch is most likely to bite.

Paper reference: mechanism verified directly in code; whether it has actually fired on production data is not established from static reading alone.

Confidence: MEDIUM.

### 26. verdier: the Verdier/VV robustness path imposes no switcher-inclusion threshold at all, conflicting with planned Change B item 6

Location: `0_programs.do:2904-3016` (`run_grc_robust_vv`) and `0_programs.do:1469-1494` (`setup_grc_estimation`).

Description: `run_grc_robust_vv`, as called by `17_verdier_robust.do` (`switchers($switchers)` at lines 106-142), imposes no switcher-inclusion threshold at all: it consumes the raw `$switchers` list built by `setup_grc_estimation` from `tab trajectory` with zero drop (`0_programs.do:1471,1489`), i.e., the same unfiltered set as the main GMM.
This directly conflicts with the planned Change B item 6 / decision D7 (`quality_reports/specs/2026-07-13-switcher-inclusion-consistency.md:73-77`; `quality_reports/plans/2026-07-13-switcher-inclusion-consistency.md:116-119`), which requires the VV path to drop switcher trajectories with fewer than 2 clusters contributing both an urban and a rural observation.
The concrete failure mode the spec anticipates already exists in the code: for TZA's single-person trajectory 3 (named explicitly in the spec's MUST-3 acceptance criterion), the within-cluster residualization loop at `0_programs.do:3004-3016` regresses `switcher_3_choice` on `i.vfirst` within a subsample that spans exactly one cluster value (one person = one province/region), so the demeaning collapses to a within-person deviation rather than a genuine within-cluster-across-workers deviation.
That is not what the paper's Equation (`eq:residualized-instrument`) (`main-updated.tex:998-1002`) describes, "the within-cluster mean of $D$...taken among trajectory-$d$ workers [plural] in cluster $v_i$."
The code already contains a precedent for catching exactly this kind of degeneracy (the deliberate, documented drop of the `always_choice` instrument at `0_programs.do:3032-3047` because single-level demeaning is identically zero) but does not apply an analogous check to thin switcher trajectories.

Confidence: HIGH.

### 27. verdier: the VV robustness check drops the always_choice instrument entirely, an undisclosed second change to the moment system

Location: `0_programs.do:2103-2113` (`run_grc` baseline instruments) versus `0_programs.do:3104-3120` (`run_grc_robust_vv` instruments).

Description: the paper describes the robustness check as replacing only the switcher-treatment instruments with their cluster residuals: "We re-estimate $\phi$ from the moment system of Equation (`eq:restricted-GRC`) after replacing the switcher-treatment instruments...with their cluster residuals" (`main-updated.tex:997`) and states explicitly that "the check...varies only how the switcher-treatment instruments enter" (`main-updated.tex:1023`).
The code does more than that: `run_grc`'s baseline instrument list includes `always_choice` alongside `switcher_*_choice` (`0_programs.do:2112`: "`always_choice switcher_*_choice, nocons`"), but `run_grc_robust_vv`'s instrument list drops `always_choice` entirely: it is not present at all, demeaned or otherwise (`0_programs.do:3110-3114`: "`never `switcher_traj' choice `swd_list', nocons`").
This is a second, undisclosed change to the moment system beyond switcher-instrument residualization; a reader following the paper's stated procedure would not know an instrument was removed outright, only that switcher instruments were residualized.

Confidence: HIGH.

### 28. verdier: a non-converged TZA GMM column reports starred coefficients with no disclosure

Location: `tables/GRC_TZA_consumption_urban_unb_cluster.tex:16,24` (Tanzania, produced by `17_verdier_robust.do` via `grc_tex_table_trend_robust`).

Description: column (1) of the Tanzania Verdier-robust table (no covariates, no time FE) reports `Converged = N` (line 24) yet the same column reports a fully starred point estimate and SE for `phi` (-0.992***, SE 0.145) and for `Delta_never` and Average Delta, with no visual flag or table-note caveat distinguishing it from the converged columns (2)-(5).
`run_grc_robust_vv` computes `e(converged)` and stores it as `converged_str` (`0_programs.do:3152-3153`) purely for the "Converged" display row; nothing in the program or in `grc_tex_table_trend_robust` suppresses, greys out, or footnotes the coefficient/SE/stars when convergence failed.
Presenting significance stars from a GMM fit the code itself flags as non-converged, with no disclosure in the table notes or the surrounding paper prose, is a reporting-integrity gap likely to draw a referee objection.

Confidence: HIGH.

### 29. ols-fe: column-1 raw urban-rural gap in the table does not match the paper's quoted values

Location: `RP7/output/tables/OLS_consumption_urban_unb.tex` (Urban row, column 1, all three panels) versus `main-updated.tex:636`.

Description: the paper states the column-(1) "raw" urban-rural consumption gap is "39 log points in Indonesia, 44 log points in China, and 66 log points in Tanzania."
The actual column-1 coefficients in the cited table (which per finding 7 already includes time FE and the col-6-derived sample restriction, not a truly raw regression) are 0.338 (33.8), 0.422 (42.2), and 0.669 (66.9) for IDN/CHN/TZA respectively.
IDN diverges by about 5 log points from the paper's claim; CHN and TZA are closer but still not exact matches.
This is consistent with finding 7: the paper's narrated "column (1)" corresponds to an unconditional, unrestricted regression that no longer exists as a distinct column in the current 6-column code.

Paper reference: `main-updated.tex:636` ("This gap is 39 log points in Indonesia, 44 log points in China, and 66 log points in Tanzania").

Confidence: MEDIUM.

### 30. ols-fe: individual-FE column values in the paper do not match the table, and the direction of the China gap is reversed

Location: `RP7/output/tables/OLS_consumption_urban_unb.tex` (Urban row, column 6, all three panels) versus `main-updated.tex:653-656`.

Description: the paper claims the individual-FE ("column 7") consumption gap is "modest in Indonesia and Tanzania, at 8.8 and 7.2 log points, respectively, but larger in China at 17.2 log points," and that "the gap reduces another 6 to 9 log points" from the migrants-only column to the individual-FE column for Indonesia and China.
The actual column-6 (individual FE) values in the cited table are IDN 0.072 (7.2), TZA 0.094 (9.4), CHN 0.105 (10.5) log points, none of which match 8.8/7.2/17.2.
The IDN and TZA figures appear transposed (table has IDN=7.2/TZA=9.4, text says IDN=8.8/TZA=7.2), and the CHN figure (17.2 claimed vs. 10.5 in the table) is far off.
Moreover, for China the table shows the coefficient going from 0.018 (migrants-only, column 5) to 0.105 (individual FE, column 6), an increase of 8.7 log points, directly contradicting the paper's claim that the gap "reduces" by 6-9 log points for China with the addition of individual FE.

Paper reference: `main-updated.tex:653-656`.

Confidence: HIGH.

### 31. ols-fe: the committed OLS/FE table does not reproduce under the current code and current data

Location: `RP7/output/tables/OLS_consumption_urban_unb.tex` versus `RP7/scripts/0_programs.do:1280-1298` (`reghdfe_regressions`) executed on `RP7/data/processed/IDN_unb.dta`.

Description: the checked-in generated table does not reproduce under the current code and current data.
Faithfully re-running the exact `reghdfe_regressions` logic (reg6 first to fix `regression_sample`, then reg1-reg4 restricted to that sample) on `RP7/data/processed/IDN_unb.dta` gives Urban coefficients of 0.3382, 0.3385, 0.3359, and 0.1899 for columns 1-4, versus the table's 0.338/0.338/0.338/0.338 (identical across all four columns to three decimals).
Column 4 alone diverges by roughly 0.15 log points (about 15 percentage points), far beyond rounding.
The sample size also differs: fresh execution gives N=93,026 (after reghdfe drops one singleton) versus the table's reported N=93,037.
This means the committed table, and every paper number derived from it (e.g., the 6.7/14.5/etc. log-point comparisons cited in the GRC results discussion), is stale relative to the current pipeline and would change materially on a fresh full-pipeline re-run, independent of the two planned Change A/B modifications.

Paper reference: `main-updated.tex:717,730,739` (numbers cited from Table `tab:OLS_cons_urb_unb`, e.g., "6.7 log points estimated using individual fixed effects").

Confidence: HIGH.

### 32. grc-main: setup_grc_estimation still applies zero threshold to the switcher trajectory set (Change B not implemented)

Location: `RP7/scripts/0_programs.do:1489-1492` (`setup_grc_estimation`).

Description: `setup_grc_estimation` builds a `switcher_s`/`switcher_s_choice` moment for every trajectory code strictly between "never" (1) and "always" ($always) with no minimum-size check at all, confirmed directly from the foreach loop, which has no threshold or drop logic.
This matches the spec's own diagnosis of the Change B defect ("The GMM keeps every switcher trajectory that exists... with no thin-cell drop").
As read, this code is unchanged: the GMM's switcher set (and therefore `Delta_avg`'s weighting and the moment set feeding the Hansen J-test) still includes arbitrarily thin trajectories (e.g., the TZA one-person trajectory the spec names), while the Python auxiliary OLS/inversion already drop sub-5 trajectories via `drop_sparse_switchers`, the two estimators the paper reports side by side are still fit on different switcher sets.
This is not a new discovery beyond what the spec documents, but it confirms the spec's description is accurate against the current code and pinpoints the exact lines Change B's MUST-3/B-3 must touch.

Paper reference: `main-updated.tex:369-375` (definition of $\mathcal{D}_S$, switcher trajectories) and `:705-722` (GRC results tables affected by Change B); spec "Change B: the current inconsistency" and plan B-3.

Confidence: HIGH.

### 33. nonag: switcher-inclusion-consistency plan's regeneration checklist omits the non-agricultural GMM cell

Location: `quality_reports/plans/2026-07-13-switcher-inclusion-consistency.md:134` (S-2) versus `RP7/scripts/5_GrRC_NonAg.do:64`.

Description: the plan's regeneration checklist (S-2) explicitly names which scripts to re-run after Change A/B land: "the main-path .ster (4_GrRC.do, and hukou 7_GrRC_hukou.do), the inversion attach (5b_inversion.do), the VV path (17_verdier_robust.do), and the E1 exporter CSVs."
It never names `5_GrRC_NonAg.do` or the nonag Section 2 block of `10_make_tables.do`.
Yet `5_GrRC_NonAg.do` calls the exact same shared programs the changes target, `setup_grc_estimation` (line 64), `run_grc`, `define_switcherpars`, on `IDN_unb_nonag.dta`, which is itself built by the same `data_setup`/`handle_balance` pipeline Change A patches (`1_processData.do` lines 29-38 call `data_setup IDN nonag consumption unb`).
Once Change A (sample restriction) and Change B (switcher keep-list, implemented inside `setup_grc_estimation` per plan B-3) land, the nonag GMM's sample and switcher set will silently change too, but S-2 gives no instruction to re-run `5_GrRC_NonAg.do` or regenerate its `.ster`/table outputs.
A literal reading of S-2 leaves the non-agricultural appendix results on the pre-change sample and switcher set while the paper's headline urban numbers move, exactly the internal inconsistency spec MUST 7 ("Regenerate every affected .ster... and re-quote every paper number that moves") is meant to prevent but the plan's operational checklist does not enforce for this cell.

Confidence: HIGH.

### 34. nonag: on-disk nonag appendix table is stale and internally contradictory (rejected J-test, sign-flipped phi)

Location: `RP7/output/tables/GRC_IDN_consumption_nonag_unb.tex` (dated 2026-05-13) versus `RP7/scripts/5_GrRC_NonAg.do:92-97` and `RP7/scripts/0_programs.do:3276-3278,3449-3450`.

Description: the appendix table currently on disk for this script's cell (input by `main.tex:891` as `\input{tables/GRC_IDN_consumption_nonag_unb}`) has 5 data columns, including a column-1 "no covariates" (`c0`) result: `Delta_never`=0.271***, `phi`=-2.226***, J-stat=63.5, J-stat p-value=0.000 (Hansen's J rejects), which flatly contradicts columns 2-5's phi of roughly +0.8 (opposite sign) and non-rejected J-tests (p=0.07-0.21).
The current `5_GrRC_NonAg.do` (lines 92-97) has the `c0` `run_grc` call commented out ("no longer estimated (2026-07-01): dropped from the tables and often non-convergent"), and `grc_tex_table_trend`'s default `covs2set` is "ct c1 c2 ca" (4 columns; `0_programs.do:3277`), confirmed by its own comment at 3449-3450 ("5-column GRC tables (label + 4 covariate columns after dropping c0)").
No `.ster` file matching `grc_IDN_cnu_*` exists anywhere under `RP7/output` (verified by a recursive search of the tree), and the table file plus every `grc_IDN_cnu_*.csv` headline file are all dated 2026-05-13 13:21, before both the `c0` removal and the 2026-07-10 lca-inversion merge: this cell has not been (re-)estimated since.
Because `grc_tex_table_trend` only `di as error`-and-exits when the first required `.ster` is missing (`0_programs.do:3345-3349`) rather than hard-erroring the master pipeline, a full pipeline run that skips or fails this one cell leaves this stale, internally contradictory 5-column table (rejected overidentification test and sign-flipped phi in column 1) sitting in `RP7/output/tables` ready to be copied verbatim into the paper's "Additional Results: Non-agricultural Sector" appendix (`main.tex:886-891`) with no error surfacing.

Confidence: HIGH.

### 35. summary-stats: IDN urban consumption/income premium is off by roughly an order of magnitude from the table it cites

Location: `tables/summary_stats_combined_unb.tex:8,10` versus `main-updated.tex:584`.

Description: the paper states "consumption and income are higher for observations in urban areas than in rural areas (3.3% and 3.5%, respectively)" for Indonesia, but the table it cites shows a Log Consumption gap of -0.39 log points (Rural=11.84, Urban=12.23) and a Log Income gap of -0.50 log points (Rural=14.64, Urban=15.15).
Converting log-point gaps to percent differences ($e^{0.39}-1$, $e^{0.50}-1$) gives approximately 47.7% and 64.9%, roughly 14x and 19x the stated 3.3%/3.5%.
No other row in the table (Female, Age, Education, Household Size) is close to 3.3%/3.5% either, so this is not a mislabeled reference to a different row.

Confidence: HIGH.

### 36. summary-stats: a `choice` local referenced in sumstats_table is never declared, silently dropping all column headers

Location: `RP7/scripts/0_programs.do:619-690` (`sumstats_table`), lines 647,653,656.

Description: `sumstats_table` references a local `choice` at lines 647, 653, and 656 to decide the table's float placement (`[h!]` vs. `[htbp]`) and to write the column-header row ("& All & Rural & Urban & Difference \\" or the nonag variant).
But `choice` is never declared in the program's `syntax` statement (line 621: only `TABle_notes`/`COUNTRY`/`OUTputdir`/`FILEname`/`BALance`) and no call site in `2_summaryStats.do` passes a `choice()` option, so the local is always empty inside the program.
As a result the `[h!]` branch and both header-writing branches are unreachable dead code; every table silently emits `[htbp]` and no column-header labels.
Confirmed directly in generated output: `tables/summary_stats_IDN_unb.tex:2`, `tables/summary_stats_IDN_unb_2waves.tex:2`, and `tables/summary_stats_IDN_unb_nonag.tex:2` all show a blank header row (" &  &  &  & $t$-test \\") with no "All/Rural/Urban/Difference" text.
Current paper impact is limited because none of these per-country tables are `\input` anywhere in `main-updated.tex` (all references are commented out: line 581 for IDN unb, lines 1116-1118 for the `_bal` variants, and no nonag/2waves/3waves `\input` exists at all), but the bug would silently produce headerless tables the moment anyone re-enables those references.

Confidence: HIGH.

### 37. grc-hukou: switcher-inclusion-consistency plan/spec's hukou-regressor premise is wrong for this script too

Location: `C:/git/ckt/RP7/scripts/7_GrRC_hukou.do:44-46` (repeated identically at every cell's covariate block, e.g., `148-150,252-254,352-354`); contrast with `C:/git/ckt/RP7/scripts/0_programs.do:589-592`.

Description: the switcher-inclusion-consistency spec (R-5) and plan (m2) both assert "the hukou path adds `hukou`" to the strict-column regressor set that Change A must protect, implying `7_GrRC_hukou.do`'s GMM covariates include `hukou`.
They do not: every cell in `7_GrRC_hukou.do` locally redefines `global covs_gmm "female"`, `covs_gmm2 "$covs_gmm age2"`, `covs_gmm_all "$covs_gmm2 education_max education_max2"`, identical to the pooled-CHN main path, with no `hukou` term anywhere.
A separate, `_hukou`-suffixed set of globals that does include `hukou` (`covs_gmm_hukou "hukou"`, `covs_gmm2_hukou`, `covs_gmm3_hukou`, `covs_gmm_all_hukou` at `0_programs.do:589-592`) is defined in `set_covariates` but is never referenced anywhere else in `RP7/scripts` (grep-verified repo-wide), it is dead code, presumably intended for a different, unimplemented "control for hukou status on the pooled sample" robustness spec, not the sample-split design `7_GrRC_hukou.do` actually runs.
Within a hukou-split subsample (rural_first, urban_first, rural_only, urban_only), `hukou` is close to a constant by construction (`0_CHN_hukou_restrictions.do` splits the sample on `hukou`), so adding it as a regressor would be near-collinear and was correctly never wired in.
An implementer following the spec/plan's literal premise for Change A's strict-regressor predicate on "the hukou path" would misidentify the strict-column set for this script; the practical consequence is likely a benign no-op (hukou is never missing, since it is the sample-splitting variable), but the premise itself is factually wrong and should be corrected before Change A is implemented against this script.

Paper reference: not applicable (spec/plan-vs-code mismatch, not a paper claim); spec `quality_reports/specs/2026-07-13-switcher-inclusion-consistency.md` R-5; plan `quality_reports/plans/2026-07-13-switcher-inclusion-consistency.md` m2.

Confidence: HIGH.

### 38. data-construction: paper's stated sample-restriction criteria omit an undisclosed education requirement that removes 18.2% of CHN individuals

Location: `RP7/scripts/0_programs.do:594-596` (`set_covariates`).

Description: the paper's Data section states the sample restriction criteria as "For all countries, we restrict the data to individuals aged 16 and above with non-missing information on urban/rural status and total consumption," with no mention of an education requirement.
The code additionally and unconditionally drops every individual missing years of education (`education_max`, time-invariant per person) via `drop if mi(education_max)` (`0_programs.do:594`), which removes 18.2% of CHN individuals (9,000 of 49,398, verified against raw CHN.dta) and a small share of IDN individuals (13 of 42,792, verified against raw IDN.dta).
This is a substantively sized, undisclosed sample-construction criterion for CHN specifically, not a footnote-level technicality, and large enough to raise a selection concern if education missingness correlates with migration status, consumption, or urban/rural residence.

Paper reference: `main-updated.tex:497`, "For all countries, we restrict the data to individuals aged 16 and above with non-missing information on urban/rural status and total consumption."

Confidence: HIGH.

### 39. data-construction: per-capita consumption is a cube-root equivalence scale, not literal division by household size as stated in the paper

Location: `RP7/scripts/0_programs.do:297-309` (`handle_depvar`, called from `1_processData.do`); denominator constructed downstream at `RP7/scripts/4_GrRC.do:62` and five further sites.

Description: the paper states "The dependent variable in all regressions is the log of per capita consumption, which is defined as total household-level consumption divided by the number of household members."
`handle_depvar` (called by `data_setup` in `1_processData.do`) only constructs raw `log(consumption)`; the per-capita transform is applied downstream, throughout the main GRC estimation driver, as `lndepvar = log(consumption/hhsize_cube)` (`4_GrRC.do:62,138,214,317,393,469`).
`hhsize_cube` is not raw household size: it is `hhsize^(1/3)`, labeled "Cube root of hhsize" at `databuild/1_build_IDN.do:151-152` (and analogously built for CHN/TZA).
A cube-root equivalence scale differs sharply from literal per-member division for larger households (e.g., an 8-person household implies a denominator of 2 under the cube-root scale versus 8 under literal division), so the paper's stated construction of its primary outcome variable does not match what the code computes for every headline regression.

Paper reference: `main-updated.tex:632`, "The dependent variable in all regressions is the log of per capita consumption, which is defined as total household-level consumption divided by the number of household members."

Confidence: HIGH.

### 40. learning: learning-tables output is not referenced anywhere in the compiled paper

Location: `C:/git/ckt/RP7/scripts/8_learning.do:1-223`.

Description: `8_learning.do` runs as part of the production pipeline (included at `C:/git/ckt/RP7/scripts/0_master.do:120`) and, when `$copyOverleaf==1`, copies `OLS_IDN_consumption_learning_bal.tex` and `OLS_CHN_consumption_learning_bal.tex` into the Overleaf `tables/` folder (confirmed present at both `C:/git/ckt/RP7/output/tables/` and the Overleaf `tables/` directory).
But the current compile target, `main-updated.tex`, never `\input`s either file, and the string "learning" does not appear anywhere in `main-updated.tex`, in the legacy `main.tex`, or in any archived section (`archive/sections/*.tex`), grep-verified across all three.
There is no paper text describing a "returns to learning" analysis.
The code therefore has no paper claim to check against; it is a live, pipeline-integrated analysis whose output is currently disconnected from the manuscript.

Confidence: HIGH.

### 41. learning: table footnote misdescribes column 4 as including female and education controls that are actually absorbed by the individual FE

Location: `C:/git/ckt/RP7/scripts/8_learning.do:100,191` (`table_notes` locals) and `C:/git/ckt/RP7/scripts/0_programs.do:1309,1397` (`reg4_IDN`/`reg4_CHN` specs).

Description: the `table_notes` text in `8_learning.do` says "Columns (3) and (4) add a female indicator, age squared, and education (years of schooling, maximum across periods) and its square."
Column 4 (`reg4_IDN`/`reg4_CHN` in `0_programs.do`) estimates `$covs_all` (female, `c.age#c.age`, `c.education_max##c.education_max`) with `absorb(pid period)`, i.e., individual fixed effects.
`female` and `education_max`/`education_max2` are person-level constants (`female` by construction; `education_max` is defined as the max over periods per the table's own note), so they are perfectly collinear with the individual FE.
Verified empirically on a synthetic panel with the identical structure (pid+period FE, one time-invariant and one time-varying covariate) that `reghdfe` silently omits the time-invariant covariates ("note: X is probably collinear with the fixed effects," coefficient reported as 0/omitted) while keeping the time-varying one intact.
Because `esttab`'s `keep()` list in `create_panel_tex_table_learn_IDN`/`_CHN` only displays the urban/rural period dummies, a reader of the table sees "Covariates: All" in column 4's footer with no way to see that female and education silently contribute nothing there.
The footnote's description of column 4 is inaccurate for two of the three listed controls.

Confidence: HIGH.

### 42. learning: this script's own sample counts corroborate part of the Change-A defect but also flag a CHN shortfall the spec claims does not exist

Location: `C:/git/ckt/RP7/scripts/8_learning.do:40,137` (use processed `bal.dta`); generated tables `OLS_IDN_consumption_learning_bal.tex:40-41` and `OLS_CHN_consumption_learning_bal.tex:32-33` (Overleaf-Dropbox `tables/` folder).

Description: this script reads the same `{country}_bal.dta` that Change A targets.
The IDN table reports Individuals=3,284, Observations=16,391; 3,284 x 5 (waves) = 16,420, a shortfall of exactly 29, matching, to the person-wave, the 29 IDN individuals with a single-wave-missing `hhsize_cube` documented in the switcher-inclusion-consistency spec (`quality_reports/specs/2026-07-13-switcher-inclusion-consistency.md`, Change A section, lines 22-25).
This independently corroborates the spec's diagnosis from a completely separate downstream script.
But the CHN table reports Individuals=14,214, Observations=56,855; 14,214 x 4 = 56,856, a shortfall of exactly 1, even though the spec's acceptance criterion A2 (`quality_reports/specs/2026-07-13-switcher-inclusion-consistency.md:44-46`) asserts "TZA is unaffected... CHN is untouched by inspection but re-checked in the same pass."
A 1-observation shortfall in a nominally "untouched" country contradicts that claim and flags that the Change A re-check (plan step A-3, `quality_reports/plans/2026-07-13-switcher-inclusion-consistency.md:82-85`) needs to actually find and account for this CHN individual before asserting zero effect.

Confidence: MEDIUM.

### 43. learning: cumulative urban/rural period counters do not reset on return migration, contradicting their "since migrating" label

Location: `C:/git/ckt/RP7/scripts/8_learning.do:52-53,55-77,149-150,152-170`.

Description: `urban_periods`/`rural_periods` are built as a simple running cumulative sum of the urban/rural indicator over period (`bys pid (period): g urban_periods = sum(urban)`), with no reset when an individual returns to the other location.
But the `trajectory` variable that the rest of the pipeline uses is built from the literal concatenated per-period choice string with no monotonicity restriction (`0_programs.do:334-361`, `handle_trajectory_groups`: "reshape wide choice... concatenate... encode string_traj"), so non-monotonic (return-migration) trajectories are structurally possible in the data the paper models (the project's own documentation cites "01011" as an example switcher pattern in `reference_unbalanced_lumps_trajectories.md`).
For any individual with more than one 0-1 transition, `urban_Nperiod`/`rural_Nperiod` as coded measure lifetime-cumulative time in a location, not consecutive time since the most recent migration, silently contradicting the "since migrating" label attached via `lab var` (`8_learning.do:56-77,153-170`) and reproduced in the table's coefficient labels ("1st/2nd/3rd/4th urban/rural period").
The processed `.dta` was not queried to confirm any non-monotonic switcher actually exists in the IDN/CHN balanced samples used here, so this is flagged as a latent construction risk rather than a confirmed numeric error.

Confidence: MEDIUM.

### 44. tables: six generated heterogeneity Delta/mu tables are never surfaced in the paper

Location: `RP7/scripts/10_make_tables.do:881-1011` (`het_table_delta`/`het_table_mu` calls for IDN/CHN/TZA).

Description: this script generates six heterogeneity tables (`hetDelta_table_IDN.tex`, `hetDelta_table_CHN.tex`, `hetDelta_table_TZA.tex`, `hetmu_table_IDN.tex`, `hetmu_table_CHN.tex`, `hetmu_table_TZA.tex`) and copies all six to the Overleaf `tables/` folder (confirmed present on disk), but none of them is ever `\input` or otherwise referenced anywhere in `main-updated.tex` (grep across the compile-target file, `preamble.tex`, and the `tables/` directory finds zero uses of "hetDelta" or "hetmu").
The paper-side wrapper macros that would consume them, `\GRChetDeltatable` and `\GRChetMutable`, do not exist in `preamble.tex`; the `het_table_delta`/`het_table_mu` program comments themselves flag this ("Paper-side wrapper: `\GRChetDeltatable` (TBD)"), and `preamble.tex:305-306` explicitly notes "Heterogeneity table macros (Templates D/E) deferred."
This is dead output: the pipeline computes and formats per-trajectory `Delta_s` and `mu:switcher_s` coefficients (exactly the objects Change B's disclosure requirement targets) but the paper currently only shows switcher-trajectory-level detail through Figure \ref{fig:heterogeneity} (a separate, non-tabular figure), not through these six generated tables.

Paper reference: `preamble.tex:305-306` ("Heterogeneity table macros (Templates D/E) deferred until 16_heterogeneity_tables.do canonical IDN heterogeneity prose has been read in detail").

Confidence: HIGH.

## Minor findings (23)

### 45. chn-hukou-setup: hukou-augmented covariate globals are defined but never consumed

Location: `RP7/scripts/0_programs.do:572-575,589-592`.

Description: the hukou-augmented covariate globals `covs_1_hukou`/`covs_2_hukou`/`covs_3_hukou`/`covs_all_hukou`/`covs_gmm_hukou`/`covs_gmm2_hukou`/`covs_gmm3_hukou`/`covs_gmm_all_hukou`, defined specifically for the four hukou country strings this script produces (CHN_hukou_rural_only/urban_only/rural_first/urban_first), are set every time `set_covariates` runs on one of those countries but are never consumed anywhere in the codebase (confirmed by grep across `RP7/scripts`: the only other hits are in comments/naming docs).
A reader of `set_covariates` would reasonably infer that the hukou split controls for hukou status directly as a covariate in addition to subsetting the sample; in fact the paper's own description at `main-updated.tex:761` ("we estimate the restricted GRC model separately for rural and urban hukou holders") matches only the sample-subsetting behavior that `0_CHN_hukou_restrictions.do` performs, so the dead globals do not create a paper-code contradiction, but they are a misleading vestige that should either be wired up or removed.

Paper reference: `main-updated.tex:761`.

Confidence: HIGH.

### 46. rank-diagnostic: header comment names files that no longer exist at the stated path

Location: `RP7/scripts/1b_unbalanced_rank_diagnostic.do:76-78`.

Description: the header's "Output" block claims the generated macros file is "Inputted by `paper/unbalanced_proposition.tex` and `paper/unbalanced_proposition_short.tex`."
Neither file exists at that path in the live Overleaf project; both have been moved to `archive/` (`archive/sections/app_unbalanced_proposition.tex` and `archive/unbalanced_proposition_short.tex`).
The actual live consumer is `main-updated.tex`, which does `\input{tables/unbalanced_rank_macros}` directly inline inside the `app:pooling` section (`main-updated.tex:1163`).

Paper reference: `main-updated.tex:1160-1163` (section labeled `app:pooling` with the direct `\input`), versus the archived, unused `archive/sections/app_unbalanced_proposition.tex` and `archive/unbalanced_proposition_short.tex` the comment names.

Confidence: HIGH.

### 47. rank-diagnostic: four macros computed for a decomposition the paper never surfaces

Location: `RP7/scripts/1b_unbalanced_rank_diagnostic.do:141-184,220-227`.

Description: diagnostic (b) computes and writes `\unbCountXXX`, `\unbBothXXX`, `\unbAlwaysRuralXXX`, `\unbAlwaysUrbanXXX` per country to `unbalanced_rank_macros.tex`, but a grep of the entire live Overleaf project (`main-updated.tex` and every file under `tables/`) shows none of those four macros is ever cited outside the macros file itself; the paper text only cites `\unbUrbanRateXXX`, `\unbResidShareXXX`, and `\unbShareXXX` (`main-updated.tex:1236-1240`).
The script's own header (lines 15-19) states the point of (b) is "so the reader can see whether between-individual variation comes from a meaningful number of always-urban unbalanced individuals or from one or two outliers," but the compiled paper never surfaces that decomposition; only the derived both/total ratio (`unbShare`) appears, so the promised always-rural/always-urban visibility does not currently exist in the manuscript.

Paper reference: `main-updated.tex:1160-1243` (`app:pooling` section); `\unbCountCHN/IDN/TZA`, `\unbBothCHN/IDN/TZA`, `\unbAlwaysRuralCHN/IDN/TZA`, `\unbAlwaysUrbanCHN/IDN/TZA` do not appear anywhere in it.

Confidence: HIGH.

### 48. extras: 44 experience/birth robustness tables have no destination in the compiled manuscript

Location: `RP7/scripts/0_programs.do:3698-3793` (`extras_tex_table`); called 44 times from `RP7/scripts/10_make_tables.do:1023-1084`.

Description: `extras_tex_table` writes 44 LaTeX tables (`GRC_{country}_{depvar}_{choice}_{balance}_{exp,exp_max,exp_sh,exp_m_sh,birth}.tex`) to `$output/tables` and, when `$copyOverleaf==1`, copies them into the Overleaf `tables/` folder.
A search of the current paper draft (`main-updated.tex`) finds no `\input` of any of these 44 filenames; the only paper-visible output of the experience/birth robustness family is the two coefplot figures (`fig:robustness_coefplot_IDN`, `fig:robustness_coefplot_TZA`) built separately by `grc_robustness_coefplot` from a subset of the same sters.
The 44 per-cell tables therefore currently have no destination in the compiled manuscript.

Confidence: MEDIUM.

### 49. figures: IDN robustness-coefplot caption cites the wrong table (copy-paste from the TZA caption)

Location: Overleaf `main-updated.tex:968` (compare to the correct usage at `main-updated.tex:980`).

Description: the floatfoot for Figure \ref{fig:robustness_coefplot_IDN} (generated by `grc_robustness_coefplot IDN`, `0_programs.do:1646` called from `11_make_figures.do:136`) states the "Main" coefficient "reproduces our preferred specification (the final column of Table \ref{tab:GRC_TZA_consumption_urban_unb})," citing the Tanzania GRC table inside the Indonesia figure's caption.
The code itself correctly reads the IDN `.ster` (`grc_IDN_cuu_ca`, `0_programs.do:1673`), so this is a paper-text cross-reference bug (likely copy-paste from the analogous TZA caption at line 980, which correctly self-references \ref{tab:GRC_TZA_consumption_urban_unb}), not a code defect.

Paper reference: `main-updated.tex:966-970` (IDN figure caption) vs. `main-updated.tex:978-981` (TZA figure caption, correctly self-referential).

Confidence: HIGH.

### 50. figures: two migration-pattern figures are generated but never referenced in the paper

Location: `RP7/scripts/11_make_figures.do:296-431` (trajectories_2waves/_3waves generation) and export lines 425-430, 561-566.

Description: the script builds and exports `trajectories_2waves.pdf` and `trajectories_3waves.pdf` (bar charts of migration patterns among individuals with at least 2 or 3 waves respectively), including a `copyOverleaf` call for each.
A grep of the full paper source (`main-updated.tex`) finds no `\includegraphics` or other reference to either filename anywhere in the manuscript, so this is dead output that consumes pipeline time and Overleaf figure-folder space without being cited in the paper.
It is also the more population-inclusive alternative to the flawed balanced-only `trajectories.pdf` described in CRITICAL finding 2 above, which makes its being unused more notable.

Paper reference: no reference found for `figures/trajectories_2waves.pdf` or `figures/trajectories_3waves.pdf` in `main-updated.tex`.

Confidence: HIGH.

### 51. ols-hukou: reghdfe_regressions ignores the choice/depvar/balance arguments passed to it

Location: `C:/git/ckt/RP7/scripts/0_programs.do:1280`.

Description: the program signature `args country choice depvar balance` (`0_programs.do:1281`) accepts four arguments, but the regression commands hardcode the literal Stata variable names `choice` and `lndepvar` (set earlier by `handle_choice`/`handle_depvar` when the `.dta` was built) rather than referencing the passed-in locals.
Only `country` is actually used (for `eststo` naming, e.g., `reg6_`country'`).
Passing different values for `choice`, `depvar`, or `balance` at any of the 12 call sites in `6_OLS_uGRC_hukou.do` (e.g., line 46: `reghdfe_regressions CHN choice depvar balance`) has zero effect on which variables enter the model; a future edit expecting to change the outcome or treatment variable via these arguments would silently be a no-op.

Confidence: HIGH.

### 52. ols-hukou: migrants-only column will drift from the headline switcher set once Change B ships

Location: `C:/git/ckt/RP7/scripts/0_programs.do:1297`.

Description: Change B lumps sub-threshold switcher trajectories into `trajectory==999`/`unbalanced==1` only inside `setup_grc_estimation` (a GRC-estimation-time step), never touching the saved processed `{country}_{balance}.dta` files that `6_OLS_uGRC_hukou.do` reads.
Column 5's "Migrants only" restriction (reg5: `if regression_sample & switcher`, `0_programs.do:1297-1298`) uses the `switcher` flag computed once in the shared `handle_trajectory_groups` (`0_programs.do:376-380`) from the raw, unlumped `trajectory` variable.
After Change B ships, this column's migrant sample will still include individuals from any hukou-subgroup switcher trajectory that falls below the 5-both-states threshold, while the headline GMM/auxiliary-OLS/inversion no longer treat them as switchers, a fourth, unscoped notion of "migrant" that the spec's MUST 1 ("one keep-set 'per (country, specification, sample) cell' driving 'all three estimators'") does not mention or require to match.
Not a violation of the spec's stated acceptance criteria (this table is outside its named scope), but a foreseeable silent inconsistency if this table is ever cited alongside the headline numbers.

Confidence: MEDIUM.

### 53. inversion: covs_0 iteration in the inversion driver is dead code

Location: `C:/git/ckt/RP7/scripts/5b_inversion.do:93,98-101`.

Description: `5b_inversion.do`'s `foreach spec in covs_0 covs_trend covs_1 covs_2 covs_all` still includes `covs_0` (covs2 token `c0`, empty controls, lines 98-101).
But `4_GrRC.do` no longer estimates the `c0` column for any country: the `run_grc` call for `grc_{country}_cuu_c0` is commented out ("c0 (no covariates) no longer estimated (2026-07-01): dropped from the tables and often non-convergent," `4_GrRC.do:93-98` and identically at `169-174,245-250`).
Since no `grc_{country}_cuu_c0.ster` parent ever exists, the `covs_0` iteration in `5b_inversion.do` is a guaranteed no-op every run (caught by the "SKIP (no parent ster)" guard at lines 126-130), dead code that looks like an active spec.

Paper reference: not applicable (pipeline hygiene, not a paper claim).

Confidence: HIGH.

### 54. inversion: no Delta_unb inversion coordinate exists for the joint confidence region the paper describes

Location: `C:/git/ckt/.claude/worktrees/lca-inversion/explorations/python-grc/lca_inversion.py:836-841`.

Description: `compute_all_inversion_cis`, which `attach_inversion_ci` drives via this script, returns inversion objects keyed only "phi," "delta_never," "delta_avg," "delta_always" (`lca_inversion.py:836-841`); there is no `delta_unb` entry anywhere in this function or in `attach_inversion_for_stata`'s macro exports (`lca_inversion.py:912-929`).
The paper states the misallocation-gap CI is built by recomputing the counterfactual "at every point of a joint 95% confidence region for ($\phi$, $\beta$, $\Delta_{unb}$)" (`main-updated.tex:832`).
If that joint region is meant to be assembled from the per-parameter inversions this script produces, the `Delta_unb` coordinate is absent.
This may instead be computed by a separate script outside this review's scope (plausibly `12_counterfactuals.do`); flagged for verification, not asserted as a confirmed defect.

Paper reference: `main-updated.tex:831-833`.

Confidence: MEDIUM.

### 55. inversion: script inherits, unmodified, the Change-A per-wave-drop sample defect

Location: `C:/git/ckt/RP7/scripts/5b_inversion.do:74-80`.

Description: `5b_inversion.do` loads `$dirdata/processed/{country}_unb.dta`, recomputes `lndepvar = log(consumption/hhsize_cube)`, and drops only `mi(lndepvar) | mi(choice)` row-by-row (lines 74-80), identical to `4_GrRC.do` (lines 59-65).
It therefore inherits, unmodified, the Change-A sample defect: the 29 IDN individuals missing `hhsize_cube` in exactly one wave were already flagged `unbalanced==0` upstream in `handle_balance` (`0_programs.do:321`, before `hhsize_cube` is referenced), so this script's local drop removes only their one bad wave, not their trajectory-cell membership; they remain counted in a balanced switcher/never/always cell with a short panel.
No separate fix is needed here: once Change A lands upstream in `handle_balance`/`data_setup`, this script inherits the corrected sample automatically since it applies no local override.
Flagged for completeness only, confirming this script is in-scope for, and not yet compliant with, Change A.

Paper reference: `quality_reports/specs/2026-07-13-switcher-inclusion-consistency.md`, Change A section (MUST A1).

Confidence: HIGH.

### 56. verdier: coeflabels() option passed by the caller is silently discarded

Location: `0_programs.do:3491-3496,3536,3548` versus `17_verdier_robust.do:201`.

Description: `grc_tex_table_trend_robust` declares a required `COEFLABels(string asis)` syntax option (`0_programs.do:3495`), and `17_verdier_robust.do` passes `coeflabels(choice "Urban")` to it (`17_verdier_robust.do:201`), but the program body never references the `coeflabels` local; the two `esttab` calls that would use it are hardcoded instead (`0_programs.do:3536`: `coeflabels(Delta_never "$\Delta_{\text{never}}$" Delta_always "$\Delta_{\text{always}}$")`; `3548`: `coeflabels(Delta_avg "Average $\Delta$")`).
The caller-supplied argument is silently discarded every call; the hardcoded labels happen to be correct for what the table shows, so there is no visible output error today, but the option is misleading dead code that would not warn if a caller ever needed a different label.

Confidence: HIGH.

### 57. verdier: superseded |V|-1 cluster-FE variant is dead code with no call site

Location: `0_programs.do:2585-2871` (`run_grc_robust`).

Description: `run_grc_robust` (the |V|-1 cluster-fixed-effects variant, distinct from `run_grc_robust_vv`) is defined but never called by any numbered driver `.do` file in `RP7/scripts`, a repo-wide search finds only its own internal `di`/comment self-references, no call site.
Its own header comment explains it was superseded because the extra |V|-1 free parameters made the GMM objective nearly flat in `phi` with multiple local minima (confirmed on TZA, hung on CHN).
It is unused, unreferenced code that should either be removed or explicitly marked archival so a future reader does not mistake it for a live estimation path.

Confidence: HIGH.

### 58. ols-fe: income table notes overstate the outcome as per-capita when it is raw household income

Location: `RP7/scripts/3_OLS_uGRC.do:301` (income `table_notes`) and `RP7/scripts/0_programs.do:305-306` (`gen ln_income = ln(income)`).

Description: the income-outcome OLS table's notes claim "log income per capita as the dependent variable," but no household-size division is ever applied to income anywhere in the grepped pipeline (`0_programs.do:305-306` sets `ln_income = ln(income)` with no denominator, and no analogous per-capita `replace` for income was found in `4_GrRC.do`'s income section, lines 542+).
This mirrors CRITICAL finding 6 but for the secondary income outcome: the label overstates what the variable actually is.

Paper reference: `RP7/scripts/3_OLS_uGRC.do:301` (`table_notes`: "log income per capita as the dependent variable").

Confidence: MEDIUM.

### 59. grc-main: two same-valued "5" thresholds count different things and risk conflation under Change B

Location: `RP7/scripts/0_programs.do:1875,2002` (`$grc_min_switchers_per_wave` usage in `initial_values`/`initial_values_robust`); `RP7/scripts/0_path_config.do:51`.

Description: a threshold named `$grc_min_switchers_per_wave`, set to 5, already exists in the current code, but it gates a different decision than the one Change B introduces: it is used only in `initial_values`/`initial_values_robust`'s base-trajectory selection ("if N_s / T > $grc_min_switchers_per_wave"), where N_s is a raw row count (sum of the trajectory variable, i.e., person-waves) divided by T, an approximate, wave-normalized count, and it only decides which switcher trajectory becomes the numeraire base d0, not whether a trajectory gets its own moment condition at all.
Change B's planned keep-rule (spec D1, plan B-1) is a different threshold, also defaulting to 5, but counting exact distinct individuals observed in both an urban and a rural period within the trajectory, used to decide whether the trajectory enters the GMM as a switcher at all.
Both are coincidentally 5 today.
If Change B's implementation (plan item MAY-14, "fold the threshold into a single named constant") reuses `$grc_min_switchers_per_wave` for the new `compute_switcher_keeplist` threshold without noticing the different counting unit and denominator, it would silently conflate two semantically distinct cutoffs.

Paper reference: not applicable, a code-to-code (current vs. planned) risk, flagged because it lives in the programs Change B will edit.

Confidence: MEDIUM.

### 60. nonag: header comment claims scope (income outcome, 5 columns) that the script body does not deliver

Location: `RP7/scripts/5_GrRC_NonAg.do:8-10,26`.

Description: the file header claims "outcomes: consumption per capita (adult equivalent: cube) and income" and "Dependent variable: consumption / income," and lists 5 covariate columns "(1) nothing, (2) add time FE, (3) add female, (4) add age^2, (5) add education (max) & education^2."
The actual code body only ever sets local `depvar` to `consumption` (no income arm exists anywhere in the file) and only runs 4 active `run_grc` calls (`ct`, `c1`, `c2`, `ca`); the `c0`/"nothing" column is commented out at lines 92-97.
This also matches the paper correctly on the income point: `main.tex`'s income appendix section is entirely commented out (`main.tex:894-901`) and never references a nonag+income table, so the header's income claim was never true of what the paper reports, not just stale relative to the current code.

Confidence: HIGH.

### 61. summary-stats: agricultural/non-agricultural indicators are not mutually exclusive and exhaustive in the IDN nonag summary table

Location: `tables/summary_stats_IDN_unb_nonag.tex:20` (via `RP7/scripts/0_programs.do:1001-1065` `country_summary_stats_nonag`).

Description: in the (unused) IDN non-agricultural summary table, the Observations row reports All=93,038 but Agricultural=46,797 plus Non-Agricultural=69,289 sums to 116,086, a discrepancy of 23,048 observations, indicating the `ag` and `nonag` indicator variables used by `count if ag`/`count if nonag` (`0_programs.do:1016-1021`) are not mutually exclusive/exhaustive over the sample.
Root cause not traceable within this script or its called programs; not currently paper-visible since this table is never `\input` in `main-updated.tex`.

Confidence: MEDIUM.

### 62. summary-stats: switcher-inclusion-consistency plan omits re-running summary stats after Change A

Location: `quality_reports/plans/2026-07-13-switcher-inclusion-consistency.md` S-2 (Sequencing, regeneration, and re-certification) versus `RP7/scripts/2_summaryStats.do`.

Description: Change A's individual-level relabeling (29 IDN individuals moved from `unbalanced==0` to `unbalanced==1`) will reduce the IDN balanced-panel Individuals/Observations counts that `2_summaryStats.do` reports (currently 3,284 individuals / 16,420 observations in `tables/summary_stats_combined_bal.tex:21-22` and the standalone `summary_stats_IDN_bal.tex`), but the plan's explicit regeneration list (S-2: `.ster`, `5b_inversion.do`, `17_verdier_robust.do`, E1 exporter CSVs) does not mention rerunning `2_summaryStats.do` even though it reads the same corrected processed `.dta` that `1_processData.do` rebuilds under S-1.
The unbalanced-panel totals the paper's prose actually quotes (93,038 obs / 29,716 individuals for IDN) are unaffected by the lumping and stay valid, so this is a completeness gap in the checklist rather than a numbers-already-wrong issue.

Confidence: MEDIUM.

### 63. grc-hukou: stale comment points to a "sibling _tables.do" file that does not exist under that name

Location: `C:/git/ckt/RP7/scripts/7_GrRC_hukou.do:130-134` (repeated identically at `234-238,440-443,543-546,645-647,749-751,850-854,951-953,1055-1058,1159-1162,1258-1261`).

Description: every section of the script ends with the comment "Tables for this section are produced by the sibling `_tables.do` file ... Run that separately to refresh tables without re-running GMM."
No file literally named `_tables.do`, or matching a `*_tables.do` sibling-naming pattern, exists anywhere in `RP7/scripts` (glob-verified).
The actual table generator is Section 3 of `10_make_tables.do` (whose own internal header comment at line 15 still calls itself "8_GrRC_hukou_tables.do," a stale filename from an earlier script-numbering scheme, matching the same stale reference in `preamble.tex:290`, "`\GRChukoutable`: hukou-subgroup tables (8_GrRC_hukou.do)").
This does not affect computation but would mislead anyone trying to locate the "sibling `_tables.do` file" to refresh tables without re-running the GMM.

Confidence: HIGH.

### 64. grc-hukou: plan's per-country framing may miss the four hukou subgroups when Change B's keep-list is wired in

Location: `C:/git/ckt/RP7/scripts/7_GrRC_hukou.do` (all four hukou subgroups) versus `quality_reports/plans/2026-07-13-switcher-inclusion-consistency.md` B-1/B-2.

Description: the switcher-inclusion-consistency plan's worked examples for the per-(country,path) keep-list (B-1, B-2, and the "one switcher keep-set per (country, specification, sample) cell" language in the spec) discuss IDN/TZA/CHN as the unit of "country," with no explicit mention of the four hukou subgroups this script estimates.
`handle_trajectory_groups` (`0_programs.do:334-391`) independently re-encodes `trajectory` within each hukou subsample (it is not the same numbering as the pooled CHN encoding), and the split subsamples are materially smaller than pooled CHN (25,491 individuals in the currently-materialized rural-first table vs. 9,024 in urban-first, both well below CHN's pooled N), so thin switcher-trajectory cells are plausibly more common here than in the pooled path this script splits from.
Confirmed in this script: `setup_grc_estimation` (`0_programs.do:1469-1494`), which every cell in `7_GrRC_hukou.do` calls, builds `$switchers` from `tab trajectory` with no minimum-cell threshold (`0_programs.do:1471-1492`), exactly the unrestricted-keep behavior the spec's Change B section describes as the current defect for the main path.
If an implementer follows the plan's literal (IDN/TZA/CHN-only) framing without separately enumerating rural_first/urban_first/rural_only/urban_only as their own "path" cells, the hukou-split GMM in this script could be missed when Change B's keep-list authoring is wired in, leaving it on the unrestricted rule while the pooled-CHN and other-country paths adopt the five-both-states rule.

Confidence: MEDIUM.

### 65. data-construction: singleton-observation drop uses a stale, pre-covariate-drop count

Location: `RP7/scripts/0_programs.do:386` (`handle_trajectory_groups`, `obs_per_individual`) versus `0_programs.do:594-596` (`set_covariates`).

Description: `obs_per_individual` is computed once, in `handle_trajectory_groups` (`0_programs.do:386`), before `set_covariates` runs, and is never recomputed.
The subsequent row-level drops `drop if mi(education_max)` and `drop if mi(age)` inside `set_covariates` (`0_programs.do:594-595`) can remove additional rows per individual, so the immediately following `drop if obs_per_individual == 1` (`0_programs.do:596`) uses a stale, pre-drop count and cannot catch individuals who become singleton-observation only as a result of those two drops.
Verified directly against production data by replicating the exact filter sequence: this leaves 1 IDN individual and 2 TZA individuals (0 for CHN) in the final `_unb.dta` processed dataset with exactly one usable person-wave, despite the evident intent of the immediately adjacent filter to exclude exactly this case.
The magnitude is negligible for point estimates, but a singleton-observation individual who was assigned a switcher trajectory code earlier in `handle_trajectory_groups` (based on their full, pre-drop choice history) can end up contributing only one state (urban-only or rural-only) to that trajectory's GMM moment, the same within-person-both-states identification concern Change B's keep rule targets at the trajectory-cell level.
This individual-level version of the problem is addressed by neither Change A's predicate (`hhsize_cube`/female/age/`education_max` completeness, not `obs_per_individual` staleness) nor Change B's cell-level both-states count.

Paper reference: `quality_reports/specs/2026-07-13-switcher-inclusion-consistency.md`, D1 (both-states keep rule) and spec section "Change B: the current inconsistency."

Confidence: HIGH.

### 66. learning: header comment claims TZA coverage that does not exist in the code

Location: `C:/git/ckt/RP7/scripts/8_learning.do:20`.

Description: the header comment block lists "Countries: IDN / TZA / CHN" as the scope of the analysis, but the script body only ever processes IDN and CHN; no TZA block exists in `8_learning.do`, and no `reghdfe_regressions_learn_TZA` or `create_panel_tex_table_learn_TZA` program exists anywhere in `0_programs.do` (grep-confirmed).
No TZA learning table is ever produced.
The comment is stale/misleading relative to the actual code scope.

Confidence: HIGH.

### 67. tables: heterogeneity-table section independently re-derives the switcher set, a latent Change-B drift risk

Location: `RP7/scripts/10_make_tables.do:601,677,753` (`setup_grc_estimation` calls inside the heterogeneity-table section).

Description: the heterogeneity-table section of this script (lines ~591-814) reloads the processed `.dta` for each country and calls `setup_grc_estimation` itself to rebuild the `$switchers` numlist used to label the (currently dead, per MAJOR finding 44) Delta/mu coefficient rows, rather than consuming the switcher set that was actually used when `4_GrRC.do` fit the `.ster` it then loads via `estimates use`.
Today this recomputation is harmless because `setup_grc_estimation` applies no threshold-based drop, so `tab trajectory` on the same processed data is deterministic and reproduces the identical `$switchers` set.
Once Change B lands (spec MUST 1/3, plan D6/B-2: a shared keep-list computed once and consumed everywhere, precisely to remove this kind of independent re-derivation), this script's independent re-call to `setup_grc_estimation` must pick up the same lumped/kept switcher set that produced the loaded `.ster`, or the row labels attached to `Delta_s`/`mu:switcher_s` could silently drift out of alignment with the coefficients they are labeling.
This is inert today only because the tables are unused (finding 44) and because no drop rule yet exists.

Paper reference: `quality_reports/specs/2026-07-13-switcher-inclusion-consistency.md` MUST 1 ("One switcher keep-set per (country, specification, sample) cell, computed once and shared, drives all three estimators") and plan D6 ("the shared keep-set is authored in Stata and exported to Python, rather than coded independently").

Confidence: MEDIUM.

## Per-unit index

| Unit | Summary | CRITICAL | MAJOR | MINOR |
|---|---|---|---|---|
| chn-hukou-setup | Rural-first/urban-first/rural-only/urban-only classification matches the paper's definitions, but silently loses individuals with missing classifying-wave hukou, and the switcher-inclusion-consistency plan's premise that the hukou path adds `hukou` as a regressor is false. | 0 | 2 | 1 |
| rank-diagnostic | Internally correct against the current paper today, but reads the base processed `.dta` before Change B's switcher-lumping and will go stale once that change ships; two dead/stale documentation issues. | 0 | 1 | 2 |
| extras | Correctly reproduces the deleted files' 44-cell coverage and matches the paper's description of the experience/birth robustness figures, but one cell silently runs on the wrong dataset and the covariate ladder can drop already-validated switcher trajectories. | 0 | 2 | 1 |
| figures | Heterogeneity figure computed on raw consumption instead of per-capita, and the migration-patterns chart is silently restricted to the balanced-only sample despite being framed as full-sample; plan omits the figures pipeline from regeneration. | 2 | 1 | 2 |
| ols-hukou | Hukou OLS/FE tables mislabel every panel "Indonesia," falsely claim per-capita consumption when the outcome is raw household total, and are entirely unreferenced in the compiling paper. | 2 | 2 | 2 |
| inversion | Correctly mirrors 4_GrRC.do's data setup and clustering, but the attached Python inversion runs a different switcher-inclusion rule and weight vector than the GMM, and a threshold mismatch can silently abort the whole multi-country run. | 0 | 3 | 3 |
| verdier | Correctly implements the cluster-residualized-instrument idea, but a second uncoordinated script overwrites the shared summary table (visible in the paper today), imposes no switcher threshold, drops an instrument undisclosed, and reports starred non-converged estimates. | 1 | 3 | 2 |
| ols-fe | Two critical defects: outcome is raw consumption not per-capita, and the code has 6 columns against the paper's narrated 7; several quoted numbers also do not match the generated table, which is itself stale relative to a fresh run. | 2 | 3 | 1 |
| grc-main | Correctly implements the restricted-GRC/LCA moment equations, but the results narrative describes a 5-column table with education/trend columns the code cannot produce, and the quoted Delta_never numbers do not match the on-disk tables. | 2 | 1 | 1 |
| nonag | Correctly builds and estimates the IDN non-agricultural GMM cell, but its on-disk artifacts are stale/internally contradictory and the switcher-inclusion-consistency plan's regeneration checklist omits this script. | 0 | 2 | 1 |
| summary-stats | Confirmed critical bug: the unbalanced-panel "non-switchers" percentage miscounts unbalanced individuals as switchers, contradicting the paper's own prose for the same table; a separate numeric claim is off by an order of magnitude, and a scoping bug drops column headers. | 1 | 2 | 2 |
| grc-hukou | GMM machinery is internally sound, but the compiled paper's hukou-split table is stale (still shows a deprecated column) and its column-1 J-test rejects, contradicting the paper's unqualified "neither subsample rejects" claim. | 1 | 1 | 2 |
| data-construction | Faithfully implements the pre-Change-A/B sample construction and reproduces the paper's headline sample sizes, but unconditionally drops (rather than lumps) ~9,000 CHN individuals missing education, and the per-capita denominator is a cube-root scale, not literal household size as stated. | 1 | 2 | 1 |
| learning | Internally executable with no interaction with Change B, but its output tables are unreferenced in the compiled paper, one footnote misdescribes its own individual-FE column, and its own sample counts both corroborate and complicate the Change-A diagnosis. | 0 | 4 | 1 |
| tables | Internally consistent Stata code, but a pending column-count migration (5-to-4) will silently break every GRC table on the next regeneration, headline numbers in the results prose no longer match the tables, and six heterogeneity tables are dead output. | 2 | 1 | 1 |
