* *******************************************************************
* Title:   Stage 7 diagnostic: always-rural vs always-urban densities
* Author:  Emilia Tjernstrom
* Date:    2026-07-20
* Purpose: Sanity check on the corrected support figure. For each
*          country, plot the density of individual mean log
*          per-capita consumption over each person's own observed
*          waves, separately for the always-rural (trajectory 1)
*          and always-urban (trajectory max) groups. Always-urban
*          should sit clearly to the right; the log also prints
*          group Ns, means, and the share of urban waves per group
*          as a trajectory-coding check.
* Input:   stage7_root/data/processed/<country>_bal.dta
* Output:  stage7_root/output/figures/diag_traj_densities_*.{pdf,png}
* *******************************************************************

version 17
clear all
set more off
set varabbrev off
capture log close

global dir "C:/git/ckt/RP7/tests/stage0/stage7_root"
global xdiag_proc "$dir/data/processed"
global xdiag_fig  "$dir/output/figures"
global xdiag_log  "$dir/output/logs"

log using "$xdiag_log/stage7_diag_traj_densities.smcl", replace

global xdiag_crural "cranberry"
global xdiag_curban "16 62 106"

program drop _all
program define diag_one_country
    args country textcountry leftmost ymax ylab
    di as text _newline(2) "==== `country' ===="

    use "$xdiag_proc/`country'_bal.dta", clear
    quietly drop if missing(logpc_consumption) | missing(trajectory) | missing(choice)

    quietly sum trajectory
    local max_traj = r(max)
    gen byte is_dN = (trajectory == 1)
    gen byte is_dT = (trajectory == `max_traj')

    * Trajectory-coding check: share of urban waves must be 0 for
    * always-rural and 1 for always-urban
    quietly sum choice if is_dN
    di as text "  always-rural : share urban waves = " %6.4f r(mean)
    quietly sum choice if is_dT
    di as text "  always-urban : share urban waves = " %6.4f r(mean)

    bysort pid: egen ind_mean = mean(logpc_consumption)
    bysort pid: gen pid_first = (_n == 1)
    quietly keep if pid_first == 1

    quietly count if is_dN
    local n_dN = r(N)
    quietly sum ind_mean if is_dN
    local m_dN = r(mean)
    quietly count if is_dT
    local n_dT = r(N)
    quietly sum ind_mean if is_dT
    local m_dT = r(mean)
    di as text "  always-rural : N = `n_dN', mean = " %9.4f `m_dN'
    di as text "  always-urban : N = `n_dT', mean = " %9.4f `m_dT'

    * Densities on a common grid spanning both groups
    quietly sum ind_mean if is_dN | is_dT
    local xmin = r(min)
    local xmax = r(max)
    gen grid = `xmin' + (_n - 1) * (`xmax' - `xmin') / 199 in 1/200
    kdensity ind_mean if is_dN, gen(fx_dN) at(grid) nograph
    kdensity ind_mean if is_dT, gen(fx_dT) at(grid) nograph

    quietly sum fx_dN
    local pk_dN = r(max)
    quietly sum grid if fx_dN > 0.5 * `pk_dN'
    local x_dNleft = r(min)
    quietly sum fx_dT
    local pk_dT = r(max)
    quietly sum grid if fx_dT > 0.5 * `pk_dT'
    local x_dTright = r(max)
    local pk_all = max(`pk_dN', `pk_dT')

    local labels ///
        text(`=0.55*`pk_dN'' `x_dNleft' "Always-rural", color("$xdiag_crural") place(w) size(small)) ///
        text(`=0.55*`pk_dT'' `x_dTright' "Always-urban", color("$xdiag_curban") place(e) size(small))
    local ytit ""
    if `leftmost' local ytit "Density"

    local xlo = ceil(`xmin')
    local xhi = floor(`xmax')

    twoway ///
        (area fx_dN grid, color("$xdiag_crural%25") lwidth(none)) ///
        (area fx_dT grid, color("$xdiag_curban%25") lwidth(none)) ///
        , `labels' legend(off) ///
          title("`textcountry'", size(medium) color(black)) ///
          xtitle("Mean log consumption per capita, own observed waves", size(medsmall)) ///
          ytitle("`ytit'", size(medsmall)) ///
          xlabel(`xlo'(1)`xhi', labsize(small)) ///
          ylabel(`ylab', labsize(small) nogrid) ///
          yscale(range(0 `ymax')) ///
          graphregion(color(white) margin(small)) plotregion(lcolor(none) margin(small)) ///
          name(diag_`country', replace) ///
          saving(diag_`country', replace)

    graph export "$xdiag_fig/diag_traj_densities_`country'.pdf", replace
    graph export "$xdiag_fig/diag_traj_densities_`country'.png", replace width(2400)
end

capture noisily {
    diag_one_country IDN "Indonesia" 1 0.75 0(.25)0.75
    diag_one_country CHN "China"     0 0.75 0(.25)0.75
    diag_one_country TZA "Tanzania"  0 0.85 0(.2)0.8

    graph combine diag_IDN.gph diag_CHN.gph diag_TZA.gph, ///
        row(1) xsize(20) ysize(6) imargin(2 2 2 2) graphregion(color(white) margin(small))
    graph export "$xdiag_fig/diag_traj_densities_combined.pdf", replace
    graph export "$xdiag_fig/diag_traj_densities_combined.png", replace width(3600)

    foreach c in IDN CHN TZA {
        capture erase diag_`c'.gph
    }
}
local rc = _rc
log close
if `rc' di as error "RUN FAILED with rc = `rc'"
