/*******************************************************************************
Project: Returns to Migration
Team: E. Tjernstrom, M. Kleemans, E. Cenci
Version: May 2026

Phase 1b.6: GRC regressions for the "extras" family --- specs that add an
extra non-period regressor (experience-family or urban-birth) on top of
the c1 covariate set. Replaces the deleted files
    10_GrRC_experience.do
    11_GrRC_max_experience.do
    12_GrRC_experience_share.do
    13_GrRC_max_experience_share.do
    14_GrRC_NonAg_experience.do
    15_GrRC_birth.do

Each call below estimates ONE STEM (country x spec3 x extra-regressor
family), with each stem yielding 5 sters (c1/c2/c3/ca + _n + _g per fit).
Estname pattern: grc_<country>_<spec3>_<fam>_<col>.

Disambiguation: the M11 ster-rename pass (Phase 1a) deferred 10-15's
cross-section collisions to Phase 1b. This file finally fixes them ---
all 44 stems (220 sters) coexist on disk under unique names.

Tables for these stems are built in 10_make_tables.do (NOT here). Run:
    1. this file (9_GRC_extras.do)  to produce the sters
    2. 10_make_tables.do              to produce the .tex tables

Cell coverage (44 stems = 36 + 4 + 4):
    - 36 = 4 families x 3 spec3 x 3 countries  (from 10/11/12/13)
    - 4  = 1 country (IDN) x 1 spec3 (cnu) x 4 families  (from 14)
    - 4  = 1 country (IDN) x 4 spec3 x 1 family (birth)  (from 15)
*******************************************************************************/

capture log close
log using "$logs/9_GRC_extras.log", replace

* **********************************************************************
* Family: experience  (regressor = exp; from file 10)
* **********************************************************************
* cuu (consumption, urban, unbalanced) x 3 countries
run_grc_with_extra_regressor, country(IDN) spec3(cuu) regressor(exp)
run_grc_with_extra_regressor, country(CHN) spec3(cuu) regressor(exp)
run_grc_with_extra_regressor, country(TZA) spec3(cuu) regressor(exp)

* cub (consumption, urban, balanced) x 3 countries
run_grc_with_extra_regressor, country(IDN) spec3(cub) regressor(exp)
run_grc_with_extra_regressor, country(CHN) spec3(cub) regressor(exp)
run_grc_with_extra_regressor, country(TZA) spec3(cub) regressor(exp)

* iuu (income, urban, unbalanced) x 3 countries
run_grc_with_extra_regressor, country(IDN) spec3(iuu) regressor(exp)
run_grc_with_extra_regressor, country(CHN) spec3(iuu) regressor(exp)
run_grc_with_extra_regressor, country(TZA) spec3(iuu) regressor(exp)

* **********************************************************************
* Family: max_experience  (regressor = exp_max; from file 11)
* **********************************************************************
run_grc_with_extra_regressor, country(IDN) spec3(cuu) regressor(exp_max)
run_grc_with_extra_regressor, country(CHN) spec3(cuu) regressor(exp_max)
run_grc_with_extra_regressor, country(TZA) spec3(cuu) regressor(exp_max)

run_grc_with_extra_regressor, country(IDN) spec3(cub) regressor(exp_max)
run_grc_with_extra_regressor, country(CHN) spec3(cub) regressor(exp_max)
run_grc_with_extra_regressor, country(TZA) spec3(cub) regressor(exp_max)

run_grc_with_extra_regressor, country(IDN) spec3(iuu) regressor(exp_max)
run_grc_with_extra_regressor, country(CHN) spec3(iuu) regressor(exp_max)
run_grc_with_extra_regressor, country(TZA) spec3(iuu) regressor(exp_max)

* **********************************************************************
* Family: experience_share  (regressor = exp_share; from file 12)
* **********************************************************************
run_grc_with_extra_regressor, country(IDN) spec3(cuu) regressor(exp_share)
run_grc_with_extra_regressor, country(CHN) spec3(cuu) regressor(exp_share)
run_grc_with_extra_regressor, country(TZA) spec3(cuu) regressor(exp_share)

run_grc_with_extra_regressor, country(IDN) spec3(cub) regressor(exp_share)
run_grc_with_extra_regressor, country(CHN) spec3(cub) regressor(exp_share)
run_grc_with_extra_regressor, country(TZA) spec3(cub) regressor(exp_share)

run_grc_with_extra_regressor, country(IDN) spec3(iuu) regressor(exp_share)
run_grc_with_extra_regressor, country(CHN) spec3(iuu) regressor(exp_share)
run_grc_with_extra_regressor, country(TZA) spec3(iuu) regressor(exp_share)

* **********************************************************************
* Family: max_experience_share  (regressor = exp_max_share; from file 13)
* **********************************************************************
run_grc_with_extra_regressor, country(IDN) spec3(cuu) regressor(exp_max_share)
run_grc_with_extra_regressor, country(CHN) spec3(cuu) regressor(exp_max_share)
run_grc_with_extra_regressor, country(TZA) spec3(cuu) regressor(exp_max_share)

run_grc_with_extra_regressor, country(IDN) spec3(cub) regressor(exp_max_share)
run_grc_with_extra_regressor, country(CHN) spec3(cub) regressor(exp_max_share)
run_grc_with_extra_regressor, country(TZA) spec3(cub) regressor(exp_max_share)

run_grc_with_extra_regressor, country(IDN) spec3(iuu) regressor(exp_max_share)
run_grc_with_extra_regressor, country(CHN) spec3(iuu) regressor(exp_max_share)
run_grc_with_extra_regressor, country(TZA) spec3(iuu) regressor(exp_max_share)

* **********************************************************************
* IDN cnu (nonag) x experience families  (from file 14)
*   These open <country>_unb_nonag.dta, the choice=nonag dataset.
* **********************************************************************
run_grc_with_extra_regressor, country(IDN) spec3(cnu) regressor(exp)
run_grc_with_extra_regressor, country(IDN) spec3(cnu) regressor(exp_max)
run_grc_with_extra_regressor, country(IDN) spec3(cnu) regressor(exp_share)
run_grc_with_extra_regressor, country(IDN) spec3(cnu) regressor(exp_max_share)

* **********************************************************************
* Family: birth  (regressor = urbanbirth; IDN-only; from file 15)
* **********************************************************************
* cuu, cub, iuu use the spec3 default datasets.
run_grc_with_extra_regressor, country(IDN) spec3(cuu) regressor(urbanbirth)
run_grc_with_extra_regressor, country(IDN) spec3(cub) regressor(urbanbirth)
run_grc_with_extra_regressor, country(IDN) spec3(iuu) regressor(urbanbirth)

* IDN cnu x birth: file 15 sec 4 used the URBAN dataset (IDN_unb.dta) for
* this cell, not the nonag dataset. Faithful replication of historical
* behavior --- override the default cnu data path.
run_grc_with_extra_regressor, country(IDN) spec3(cnu) regressor(urbanbirth) ///
    data_path_override("$dirdata/processed/IDN_unb.dta")

log close

* Suppress the Windows batch-mode "Stata finished" popup.
exit, STATA clear
