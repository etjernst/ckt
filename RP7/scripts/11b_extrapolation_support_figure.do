* ============================================================
* In-support figure for the LCA never-migrant extrapolation
* (paper figure: fig:extrapolation_support, robustness section)
* For each country, plot the density of individual rural-period
* mean log consumption for never-migrants and (lumped) switchers,
* a vertical line at mu_dN, and a rug of per-trajectory switcher
* means showing where mu_dN sits inside the switcher range.
* Runs standalone (sets $dir if empty) or after 0_master.do.
* Outputs: extrapolation_support_{IDN,CHN,TZA,combined}.{pdf,png}
* in $dir/output/figures.
* ============================================================

version 17
clear all
set more off
set varabbrev off
capture log close

if "$dir" == "" global dir "C:/git/ckt/RP7"
global xsup_proc "$dir/data/processed"
global xsup_fig  "$dir/output/figures"
global xsup_log  "$dir/output/logs"

cap mkdir "$dir/output"
cap mkdir "$xsup_fig"
cap mkdir "$xsup_log"

log using "$xsup_log/extrapolation_support_figure.smcl", replace

* Palette: blue for switchers (coefplot anchor), red for never-migrants
global xsup_cswitch "16 62 106"
global xsup_cnever  "cranberry"

program drop _all
program define plot_one_country
    args country textcountry leftmost ruglab_side ruglab_off
    di as text _newline(2) "==== `country' ===="

    use "$xsup_proc/`country'_bal.dta", clear
    quietly drop if missing(consumption) | missing(trajectory) | missing(choice)

    quietly sum trajectory
    local max_traj = r(max)
    di as text "  trajectory levels: 1 to `max_traj'"

    * consumption in the processed .dta files is in levels (local currency).
    * The paper's mu_d is mean log consumption, so transform.
    gen log_consumption = ln(consumption) if consumption > 0 & !missing(consumption)
    gen log_cons_rural  = log_consumption if choice == 0
    bysort pid: egen ind_rural_mean = mean(log_cons_rural)

    bysort pid: gen pid_first = (_n == 1)
    quietly keep if pid_first == 1

    bysort trajectory: egen mu_d_traj = mean(ind_rural_mean)

    gen byte is_dN       = (trajectory == 1)
    gen byte is_dT       = (trajectory == `max_traj')
    gen byte is_switcher = (trajectory > 1 & trajectory < `max_traj')

    quietly sum mu_d_traj if is_dN, meanonly
    local mu_dN = r(mean)

    quietly sum mu_d_traj if is_switcher
    local sw_min = r(min)
    local sw_max = r(max)

    di as text "  mu_dN            = " %9.4f `mu_dN'
    di as text "  switcher mu_d in [" %9.4f `sw_min' ", " %9.4f `sw_max' "]"

    * Rug of per-trajectory switcher means: one tick per trajectory at y = 0
    egen byte traj_tag = tag(trajectory)
    gen zero = 0

    * Densities evaluated on a common grid spanning the pooled support,
    * so the area fill tails off smoothly instead of stopping at the
    * subsample's own data range.
    quietly sum ind_rural_mean
    local xmin = r(min)
    local xmax = r(max)
    gen grid = `xmin' + (_n - 1) * (`xmax' - `xmin') / 199 in 1/200
    kdensity ind_rural_mean if is_dN, gen(fx_dN) at(grid) nograph
    kdensity ind_rural_mean if is_switcher, gen(fx_sw) at(grid) nograph

    * Anchors for direct labels (peak-relative so each panel's free
    * y-scale keeps the labels inside the plot region)
    quietly sum fx_dN
    local pk_dN = r(max)
    quietly sum grid if fx_dN > 0.5 * `pk_dN'
    local x_dNleft = r(min)
    quietly sum fx_sw
    local pk_sw = r(max)
    quietly sum grid if float(fx_sw) == float(`pk_sw')
    local x_swmode = r(mean)
    quietly sum grid if fx_sw < 0.3 * `pk_sw' & grid > `x_swmode'
    local x_swright = r(min)
    if `x_swright' >= . local x_swright = `xmax'
    local pk_all = max(`pk_dN', `pk_sw')

    * Rug label sits left of the smallest switcher mean or right of the
    * largest, whichever side the country's densities leave clear
    if "`ruglab_off'" == "" local ruglab_off 0.02
    if "`ruglab_side'" == "right" {
        local x_ruglab = `sw_max' + `ruglab_off' * (`xmax' - `xmin')
        local rugplace e
    }
    else {
        local x_ruglab = `sw_min'
        local rugplace w
    }
    local labels ///
        text(`=0.5*`pk_dN'' `x_dNleft' "Never-migrants", color("$xsup_cnever") place(w) size(small)) ///
        text(`=0.3*`pk_sw'' `x_swright' "Switchers", color("$xsup_cswitch") place(e) size(small)) ///
        text(`=1.10*`pk_all'' `mu_dN' "Never-migrant mean", color("$xsup_cnever") place(e) size(small)) ///
        text(`=0.09*`pk_all'' `x_ruglab' "Switcher trajectory" "means", color(gs6) place(`rugplace') size(small))
    local ytit ""
    if `leftmost' local ytit "Density"

    * Tight integer x ticks to avoid whitespace beyond the data
    local xlo = ceil(`xmin')
    local xhi = floor(`xmax')

    twoway ///
        (area fx_dN grid, color("$xsup_cnever%25") lwidth(none)) ///
        (line fx_sw grid, lcolor("$xsup_cswitch") lwidth(medthick)) ///
        (scatter zero mu_d_traj if traj_tag & is_switcher, msymbol(pipe) msize(large) mcolor(gs6)) ///
        , xline(`mu_dN', lcolor(cranberry%70) lwidth(medthick)) ///
          `labels' legend(off) ///
          title("`textcountry'", size(medium) color(black)) ///
          xtitle("Rural mean log consumption", size(medsmall)) ///
          ytitle("`ytit'", size(medsmall)) ///
          xlabel(`xlo'(1)`xhi', labsize(small)) ///
          ylabel(0(.2)`=0.2*ceil(`pk_all'/0.2)', labsize(small) nogrid) ///
          yscale(range(0 `=1.14*`pk_all'')) ///
          graphregion(color(white) margin(small)) plotregion(lcolor(none) margin(small)) ///
          name(support_`country', replace) ///
          saving(support_`country', replace)

    graph export "$xsup_fig/extrapolation_support_`country'.pdf", replace
    graph export "$xsup_fig/extrapolation_support_`country'.png", replace width(2400)
    di as text "  saved: $xsup_fig/extrapolation_support_`country'.{pdf,png}"
end

capture noisily {
    * Paper order: Indonesia, China, Tanzania; y-title on the leftmost panel
    plot_one_country IDN "Indonesia" 1 left
    plot_one_country CHN "China"     0 right 0.05
    plot_one_country TZA "Tanzania"  0 right 0.02

    * Combined 1x3 paper figure
    graph combine support_IDN.gph support_CHN.gph support_TZA.gph, ///
        row(1) xsize(20) ysize(6) imargin(2 2 2 2) graphregion(color(white) margin(small))
    graph export "$xsup_fig/extrapolation_support_combined.pdf", replace
    graph export "$xsup_fig/extrapolation_support_combined.png", replace width(3600)
    di as text "  saved: $xsup_fig/extrapolation_support_combined.{pdf,png}"

    * Sweep intermediate .gph files
    foreach c in CHN IDN TZA {
        capture erase support_`c'.gph
    }
}
local rc = _rc
log close
if `rc' di as error "RUN FAILED with rc = `rc'"
