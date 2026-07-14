* regenerate hukou intermediates with current script into scratch, compare
global dir "C:/git/ckt/RP7"
include "$dir/scripts/0_path_config.do"
global dirdata "C:/Users/maand/AppData/Local/Temp/claude/C--git-ckt/6f4531b7-aa10-4c73-a728-e6fd75436c40/scratchpad/hukou_check"
include "$dir/scripts/0_CHN_hukou_restrictions.do"
foreach f in rural_only urban_only rural_first urban_first {
    use "$dirdata/countries/CHN_hukou_`f'.dta", clear
    cf _all using "C:/git/ckt/RP7/data/countries/CHN_hukou_`f'.dta", verbose
    di ">>> CHN_hukou_`f': identical to canonical"
}
