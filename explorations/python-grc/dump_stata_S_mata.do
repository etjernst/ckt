* ============================================================
* Title:   Mata-direct dump of Stata's cluster-S(theta_1) for IDN
* Author:  CKT diagnostic
* Date:    2026-04-23
* Purpose: Build the cluster-robust S matrix at Stata's saved theta_1
*          element-by-element in Mata, bypassing e(W) and its inverse.
*          Compares directly to Python's _cluster_S(theta_1_stata).
* Input:   IDN_unb.dta + stata_theta1.csv (Stata's theta_1 from gmm onestep)
* Output:  stata_S_mata.csv     (the n_moments x n_moments S matrix)
*          stata_S_meta.csv     (n, G_clusters, n_moments, dropped flags)
* ============================================================
version 19
clear all
set more off
set varabbrev off
capture log close
log using "dump_stata_S_mata.smcl", replace

global dir     "C:/Users/maand/Dropbox (Personal)/Returns to migration/ReplicationPackage6"
global dirdata "$dir/data"
global scripts "$dir/scripts"

do "$scripts/0_programs.do"

use "$dirdata/processed/IDN_unb.dta", clear
replace lndepvar = log(consumption/hhsize_cube)
setup_grc_estimation
tab period, gen(period_)
drop if mi(lndepvar) | mi(choice)

* Re-run gmm onestep to get e(b), then exit Mata to compute S directly
initial_values lndepvar, switchers($switchers) balance(unb) estname(initial_idn_S)
local base `r(base)'
local initial "`r(initial)'"

local switcher_traj
foreach s of numlist $switchers {
    local switcher_traj "`switcher_traj' switcher_`s'"
}
define_switcherpars, switchers($switchers) base(`base')
local switcherpars `r(switcherpars)'

eststo step1S: gmm (lndepvar - {mu: never `switcher_traj'} ///
    - {Delta_base}*choice ///
    - {phi=-1}*(`switcherpars') ///
    - ({kappa}+{phi}*({kappa} - {mu: switcher_`base'}))*(always#1.choice) ///
    - {xb: unbalanced unbalanced_choice}) ///
    , instruments( ///
        unbalanced unbalanced_choice ///
        never `switcher_traj' choice ///
        always_choice switcher_*_choice, nocons ///
    ) ///
    onestep ///
    winitial(unadjusted) ///
    from(`initial') ///
    quickderivatives nolog ///
    iterate(500)

* Capture predicted residuals from the GMM equation
predict double resid_eq, residuals equation(#1)

* Capture the instrument list as Stata sees it AT estimation time, including
* any omitted-due-to-collinearity flags.
local Z_full unbalanced unbalanced_choice never `switcher_traj' choice always_choice
foreach s of numlist $switchers {
    local Z_full "`Z_full' switcher_`s'_choice"
}
di as text "Z_full instrument list (Stata order):"
di as text "`Z_full'"

* Identify omitted instruments by inspecting e(b)'s column names:
* Stata marks them with "o." prefix or includes them in e(omit_list).
local Z_present
foreach v of local Z_full {
    capture confirm variable `v'
    if _rc == 0 {
        local Z_present "`Z_present' `v'"
    }
}

* Cluster id and obs counts.
egen long _cid = group(pid)
sum _cid
local Gc = r(max)
local n  = _N
di as text "n = `n', G_clusters = `Gc'"

* --- Mata: build S = (1/n) * sum_i g_i g_i'  where g_i = sum_t z_it * eps_it
mata:
    // Pull data into Mata.
    Z   = st_data(., tokens(st_local("Z_full")))
    eps = st_data(., "resid_eq")
    cid = st_data(., "_cid")

    n  = rows(Z)
    m  = cols(Z)
    Gc = colmax(cid)

    // g_it = z_it * eps_it (n x m)
    g_it = Z :* eps

    // Sum within cluster.
    g_clust = J(Gc, m, 0)
    for (i = 1; i <= n; i++) {
        g_clust[cid[i], .] = g_clust[cid[i], .] + g_it[i, .]
    }

    // S = (1/n) * sum_g g_g g_g'
    S_mata = (g_clust' * g_clust) / n

    // Diagnostics: per-moment diagonal, count of clusters with nonzero g
    diag_S = diagonal(S_mata)
    nz_per_moment = J(m, 1, 0)
    for (j = 1; j <= m; j++) {
        nz_per_moment[j] = sum(g_clust[., j] :!= 0)
    }

    // Save S matrix and per-moment diagnostics.
    fh = fopen("stata_S_mata.csv", "w")
    fput(fh, "row,col,value")
    for (i = 1; i <= m; i++) {
        for (j = 1; j <= m; j++) {
            fput(fh, sprintf("%g,%g,%21.15e", i, j, S_mata[i, j]))
        }
    }
    fclose(fh)

    fh2 = fopen("stata_S_diag.csv", "w")
    fput(fh2, "idx,instrument,diag_S,n_clusters_nonzero")
    Z_names = tokens(st_local("Z_full"))
    for (j = 1; j <= m; j++) {
        fput(fh2, sprintf("%g,%s,%21.15e,%g",
            j, Z_names[j], diag_S[j], nz_per_moment[j]))
    }
    fclose(fh2)
end

* --- Compare e(W) to inv(S_mata): does Stata zero out the same row/col we suspect?
mata:
    W_st = st_matrix("e(W)")
    // e(W) may have rows/cols of zeros where Stata dropped collinear instruments.
    // Compare element 44 (switcher_11_choice) specifically.
end

* Identify which instrument index corresponds to switcher_11_choice in our
* listing; then dump the relevant row and column of e(W) for inspection.
mata:
    Z_names = tokens(st_local("Z_full"))
    sw11_idx = .
    for (j = 1; j <= cols(Z_names); j++) {
        if (Z_names[j] == "switcher_11_choice") sw11_idx = j
    }
    if (sw11_idx != .) {
        printf("switcher_11_choice index in Z_full: %g\n", sw11_idx)
        printf("S_mata diagonal at switcher_11_choice: %21.15e\n",
               S_mata[sw11_idx, sw11_idx])
        printf("Number of clusters with nonzero g at switcher_11_choice: %g\n",
               nz_per_moment[sw11_idx])
    }
    // e(W) dimension may differ from Z_full (omitted columns); print info
    if (W_st != J(0, 0, .)) {
        printf("e(W) dim: %g x %g\n", rows(W_st), cols(W_st))
    }
end

file open fhmeta using "stata_S_meta.csv", write replace
file write fhmeta "stat,value" _n
file write fhmeta "n,`n'" _n
file write fhmeta "G_clusters,`Gc'" _n
file write fhmeta "Z_full_count,`: word count `Z_full''" _n
file write fhmeta "base,`base'" _n
file close fhmeta

log close
exit, STATA clear
