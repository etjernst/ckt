* ============================================================
* Out-of-support diagnostic for LCA extrapolation
* For each country, plot the distribution of individual rural-period
* mean log consumption by trajectory category, highlight never-migrants,
* and overlay vertical lines at min/max of switcher trajectory means.
* ============================================================

version 17
clear all
set more off
set varabbrev off
capture log close

if "$dir" == "" global dir "C:/git/ckt/.claude/worktrees/lca-inversion/RP7"
global proc    "$dir/data/processed"
global figures "$dir/output/figures"
global logs    "$dir/output/logs"

cap mkdir "$dir/output"
cap mkdir "$figures"
cap mkdir "$logs"

log using "$logs/extrapolation_support_diagnostic.smcl", replace

program drop _all
program define plot_one_country
    args country
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

    twoway ///
        (kdensity ind_rural_mean if is_dN, lwidth(thick) lcolor(cranberry) recast(area) color(cranberry%25)) ///
        (kdensity ind_rural_mean if is_switcher, lwidth(medthick) lcolor(navy)) ///
        , xline(`mu_dN', lcolor(cranberry) lwidth(medthick) lpattern(dash)) ///
          xline(`sw_min', lcolor(navy) lwidth(thin) lpattern(dot)) ///
          xline(`sw_max', lcolor(navy) lwidth(thin) lpattern(dot)) ///
          legend(order(1 "never-migrants (d_N)" 2 "switchers (lumped)") position(2) ring(0) cols(1)) ///
          title("`country': rural log consumption by trajectory", size(medium)) ///
          subtitle("dashed = mu_dN; dotted = min/max of switcher mu_d", size(small) color(gs6)) ///
          xtitle("rural-period mean log consumption", size(small)) ///
          ytitle("density", size(small)) ///
          graphregion(color(white)) plotregion(lcolor(none))

    graph export "$figures/extrapolation_support_`country'.pdf", replace
    graph export "$figures/extrapolation_support_`country'.png", replace width(2400)
    di as text "  saved: $figures/extrapolation_support_`country'.{pdf,png}"
end

plot_one_country CHN
plot_one_country IDN
plot_one_country TZA

log close
