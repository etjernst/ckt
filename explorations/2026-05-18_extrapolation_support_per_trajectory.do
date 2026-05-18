* ============================================================
* Per-trajectory variant of the out-of-support diagnostic.
* One kdensity per switcher trajectory (thin navy lines) plus a
* highlighted $d_N$ density, with a rug of trajectory means
* $\hat\mu_{\underline{d}}$ at the bottom of each panel.
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

cap mkdir "$figures"
cap mkdir "$logs"

log using "$logs/extrapolation_support_per_trajectory.smcl", replace

program drop _all
program define plot_per_trajectory
    args country min_n

    di as text _newline(2) "==== `country' ===="
    use "$proc/`country'_bal.dta", clear
    quietly drop if missing(consumption) | missing(trajectory) | missing(choice)

    gen log_consumption = ln(consumption) if consumption > 0 & !missing(consumption)
    gen log_cons_rural  = log_consumption if choice == 0
    bysort pid: egen ind_rural_mean = mean(log_cons_rural)

    bysort pid: gen pid_first = (_n == 1)
    quietly keep if pid_first == 1

    bysort trajectory: egen mu_d_traj = mean(ind_rural_mean)
    bysort trajectory: egen n_traj    = count(pid)

    quietly sum trajectory
    local max_traj = r(max)

    quietly levelsof trajectory if n_traj >= `min_n', local(keep_levels)
    di as text "  trajectories with N >= `min_n': `keep_levels'"

    * Build the twoway plot command piece by piece.
    local plot_cmd ""

    * d_N density first (under the switcher curves visually, but with strong fill)
    local plot_cmd `"`plot_cmd' (kdensity ind_rural_mean if trajectory == 1, lwidth(thick) lcolor(cranberry) recast(area) color(cranberry%30))"'

    * Switcher densities, one per trajectory
    foreach t of local keep_levels {
        if `t' == 1 continue
        if `t' == `max_traj' continue
        local plot_cmd `"`plot_cmd' (kdensity ind_rural_mean if trajectory == `t', lwidth(thin) lcolor(navy%35))"'
    }

    * Get d_N mean for the dashed line
    quietly sum mu_d_traj if trajectory == 1, meanonly
    local mu_dN = r(mean)

    * Get switcher mu_d's for tick marks at the bottom (as xlines, dotted)
    quietly levelsof mu_d_traj if trajectory != 1 & trajectory != `max_traj' & n_traj >= `min_n', local(sw_mus)
    local xline_cmd "xline(`mu_dN', lcolor(cranberry) lwidth(medthick) lpattern(dash))"
    foreach mu of local sw_mus {
        local xline_cmd `"`xline_cmd' xline(`mu', lcolor(navy%30) lwidth(thin) lpattern(dot))"'
    }

    twoway `plot_cmd' ///
        , `xline_cmd' ///
          legend(off) ///
          title("`country': rural log consumption, one density per trajectory", size(medium)) ///
          subtitle("rust = never-migrants (d_N); navy = switcher trajectories; dashed = mu_dN; dotted = switcher mu_d", size(small) color(gs6)) ///
          xtitle("rural-period mean log consumption", size(small)) ///
          ytitle("density", size(small)) ///
          graphregion(color(white)) plotregion(lcolor(none))

    graph export "$figures/extrapolation_support_pertraj_`country'.pdf", replace
    graph export "$figures/extrapolation_support_pertraj_`country'.png", replace width(2400)
    di as text "  saved: $figures/extrapolation_support_pertraj_`country'.{pdf,png}"
end

* Use min_n = 30 to keep noisy small-N trajectory kdensities out.
plot_per_trajectory CHN 30
plot_per_trajectory IDN 30
plot_per_trajectory TZA 30

log close
