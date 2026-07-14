* CRITICAL-1 verification on the rebuilt hub
foreach c in CHN IDN TZA {
    use pid period nr_periods_obs obs_per_individual pid_first_obs using ///
        "C:/git/ckt/RP7/data_rebuild/processed/`c'_unb.dta", clear
    quietly bysort pid: gen true_n = _N
    quietly count if obs_per_individual != true_n
    local stale_opi = r(N)
    quietly count if nr_periods_obs != true_n
    local stale_npo = r(N)
    quietly bysort pid: egen byte has_first = max(pid_first_obs)
    quietly count if has_first == 0
    local no_first = r(N)
    quietly count if true_n == 1
    local singletons = r(N)
    di ">>> `c'_unb: rows w/ stale obs_per_individual=`stale_opi'  stale nr_periods_obs=`stale_npo'  rows of pids w/o first-obs flag=`no_first'  surviving singleton rows=`singletons'"
}
* the traced pid
use pid period nr_periods_obs obs_per_individual pid_first_obs using ///
    "C:/git/ckt/RP7/data_rebuild/processed/CHN_unb.dta", clear
keep if pid == 620123103
list, clean
