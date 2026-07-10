* ============================================================
* In-support diagnostic for the LCA never-migrant extrapolation
* For each country, plot the density of individual rural-period
* mean log consumption for never-migrants and (lumped) switchers,
* overlay a dashed line at mu_dN, solid lines at the min/max of
* switcher trajectory means, and a rug of per-trajectory means
* showing the interior of the switcher hull is populated.
* Exports per-country panels plus a combined 1x3 paper figure.
* ============================================================

version 17
clear all
set more off
set varabbrev off
capture log close

if "$dir" == "" global dir "C:/git/ckt/RP7"
global proc    "$dir/data/processed"
global figures "$dir/output/figures"
global logs    "$dir/output/logs"

cap mkdir "$dir/output"
cap mkdir "$figures"
cap mkdir "$logs"

log using "$logs/extrapolation_support_diagnostic.smcl", replace

* House palette (matches the robustness coefplots in 0_programs.do)
global c_switch "16 62 106"
global c_never  "216 128 60"

program drop _all
program define plot_one_country
    args country textcountry
    di as text _newline(2) "==== `country' ===="

    use "$proc/`country'_bal.dta", clear
    quietly drop if missing(consumption) | missing(trajectory) | missing(choice)

    quietly sum trajectory
    local max_traj = r(max)
    di as text "  trajectory levels: 1 to `max_traj'"

    * consumption in the processed .dta files is in levels (local currency).
    * The paper's $\mu_{\underline{d}}$ is mean log consumption, so transform.
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

    twoway ///
        (kdensity ind_rural_mean if is_dN, lwidth(thick) lcolor("$c_never") recast(area) color("$c_never%25")) ///
        (kdensity ind_rural_mean if is_switcher, lwidth(medthick) lcolor("$c_switch")) ///
        (scatter zero mu_d_traj if traj_tag & is_switcher, msymbol(pipe) msize(large) mcolor("$c_switch")) ///
        , xline(`mu_dN', lcolor("$c_never") lwidth(thick) lpattern(dash)) ///
          xline(`sw_min', lcolor("$c_switch") lwidth(medthick)) ///
          xline(`sw_max', lcolor("$c_switch") lwidth(medthick)) ///
          legend(off) ///
          title("`textcountry'", size(medium) color(black)) ///
          xtitle("rural-period mean log consumption", size(small)) ///
          ytitle("density", size(small)) ///
          xlabel(, labsize(small)) ylabel(, labsize(small)) ///
          graphregion(color(white)) plotregion(lcolor(none)) ///
          name(support_`country', replace) ///
          saving(support_`country', replace)

    graph export "$figures/extrapolation_support_`country'.pdf", replace
    graph export "$figures/extrapolation_support_`country'.png", replace width(2400)
    di as text "  saved: $figures/extrapolation_support_`country'.{pdf,png}"
end

plot_one_country CHN "China"
plot_one_country IDN "Indonesia"
plot_one_country TZA "Tanzania"

* Combined 1x3 paper figure (matches the robustness coefplot layout)
graph combine support_CHN.gph support_IDN.gph support_TZA.gph, ///
    row(1) xsize(19) ysize(7) graphregion(color(white))
graph export "$figures/extrapolation_support_combined.pdf", replace
graph export "$figures/extrapolation_support_combined.png", replace width(3600)
di as text "  saved: $figures/extrapolation_support_combined.{pdf,png}"

* Sweep intermediate .gph files
foreach c in CHN IDN TZA {
    capture erase support_`c'.gph
}

log close
