* Trajectory distribution check — uses built-in batch log (no log using).

local data_dir "C:\git\ckt\data\processed"

foreach f in CHN_unb CHN_bal CHN_unb_income CHN_hukou_rural_first_unb CHN_hukou_rural_only_unb CHN_hukou_urban_first_unb TZA_unb TZA_unb_income IDN_unb IDN_unb_income {
    di _n _n "==== `f' ===="
    cap use "`data_dir'/`f'.dta", clear
    if _rc {
        di "  (file not found, skipping)"
        continue
    }

    di "--- Person-year trajectory distribution ---"
    tab trajectory, missing

    quietly summarize trajectory
    local maxtraj = r(max)
    di "Max trajectory (= always-urban label) = `maxtraj'"

    count if trajectory == `maxtraj'
    local n_always_py = r(N)
    count
    local n_total_py = r(N)
    count if trajectory == 1
    local n_never_py = r(N)

    preserve
        bysort pid (period): keep if _n == 1
        count
        local n_total_pids = r(N)
        count if trajectory == `maxtraj'
        local n_always_pids = r(N)
        count if trajectory == 1
        local n_never_pids = r(N)
    restore

    di ""
    di "Person-years: always-urban = `n_always_py' / `n_total_py' (" %5.2f 100*`n_always_py'/`n_total_py' "%)"
    di "Person-years: never-urban  = `n_never_py' / `n_total_py' (" %5.2f 100*`n_never_py'/`n_total_py' "%)"
    di "Unique pids:  always-urban = `n_always_pids' / `n_total_pids' (" %5.2f 100*`n_always_pids'/`n_total_pids' "%)"
    di "Unique pids:  never-urban  = `n_never_pids' / `n_total_pids' (" %5.2f 100*`n_never_pids'/`n_total_pids' "%)"
}
