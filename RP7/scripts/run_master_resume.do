* run_master_resume.do
* Resume the full pipeline using the canonical skip-if-exists path documented
* in 0_programs.do (around line 1842): if ${skip_if_exists} == "1", run_grc
* skips any (country x choice x balance x covs) cell whose _g.ster is already
* on disk. To force a re-fit of any cell, delete its sters before launching.
*
* Use:
*   stata-mp -e do run_master_resume.do
*
* Equivalent semantics to running 0_master.do, except already-saved fits are
* reused. Data prep (1_processData), summary stats (2_summaryStats), OLS
* (3_OLS_uGRC), and the table/figure builders all run unconditionally; only
* run_grc cells are short-circuited.

global skip_if_exists 1
do "0_master.do"
