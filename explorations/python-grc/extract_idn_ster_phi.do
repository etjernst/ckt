* ============================================================
* Extract phi (and related quantities) from the current IDN
* covs_* ster files. The table GRC_IDN_consumption_urban_unb.tex
* appears to be older than the ster files; this do-file reads
* the current estimates directly and dumps them to CSV so we
* can compare against the LCA inversion on comparable specs.
* ============================================================
version 19
clear all
set more off
capture log close
log using "extract_idn_ster_phi.smcl", replace

global dir "C:/Users/maand/Dropbox (Personal)/Returns to migration/ReplicationPackage6"

tempname fh
file open `fh' using "idn_ster_phi.csv", write replace
file write `fh' "spec,phi,phi_se,Delta_base,Delta_base_se,kappa,kappa_se,J,J_p,N,converged" _n

foreach spec in covs_0 covs_trend covs_1 covs_2 covs_all {
    capture estimates use "$dir/output/grc_IDN_`spec'"
    if _rc {
        di as error "Missing ster file: grc_IDN_`spec'"
        file write `fh' "`spec',NA,NA,NA,NA,NA,NA,NA,NA,NA,NA" _n
        continue
    }

    local phi    = _b[phi:_cons]
    local phi_se = _se[phi:_cons]
    local Db     = _b[Delta_base:_cons]
    local Db_se  = _se[Delta_base:_cons]
    local ka     = _b[kappa:_cons]
    local ka_se  = _se[kappa:_cons]
    local J      = e(J)
    local Jp     = e(J_p)
    local N      = e(N)
    local cv     = cond(e(converged) == 1, "Y", "N")

    di as result "`spec': phi = " %8.4f `phi' " (" %6.4f `phi_se' ")  " ///
                 "Delta_base = " %8.4f `Db' "  kappa = " %8.4f `ka' ///
                 "  J = " %8.2f `J' " (p = " %5.3f `Jp' ")"

    file write `fh' "`spec',`phi',`phi_se',`Db',`Db_se',`ka',`ka_se',`J',`Jp',`N',`cv'" _n
}

file close `fh'

log close
exit, STATA clear
