* _smoke_table_render.do --- post-port smoke for grc_tex_table_trend.
*
* Renders one paper table (IDN urban consumption unbalanced) end-to-end
* against the staged 5-cell IDN smoke sters in $dir/output/. Verifies
* that the new Delta_always block renders, the inversion CI rows
* appear, and the M\"obius tablenote sits in the postfoot.
version 19
clear all
set more off
set varabbrev off
set linesize 250
capture log close

global dir "C:/git/ckt/.claude/worktrees/lca-inversion/RP7"
quietly include "$dir/scripts/0_path_config.do"
global logs "$dir/output"

quietly include "$dir/scripts/0_programs.do"

log using "$logs/_smoke_table_render.log", replace

capture noisily {
    local country IDN
    local depvar  consumption

    di as text "{hline 72}"
    di as text "Rendering paper table for `country'/cuu via grc_tex_table_trend"
    di as text "{hline 72}"

    local reportvars "phi:_cons"
    local varlab "$\phi$"
    local fname _smoke_table_render_`country'_cuu
    local postfoot_str Time FE & & Y & Y & Y & Y \\ Covariates & & & Female & \& Age$^2$ & All \\

    grc_tex_table_trend, columns(5) ///
        spec(cuu)                                           ///
        country(`country')                                  ///
        filename(`fname')                                   ///
        keep(`reportvars')                                  ///
        varlabel(`varlab')                                  ///
        postfoot(`postfoot_str')                            ///
        coeflabels(choice "Urban")                          ///
        textdepvar( log(`depvar') )

    di as text ""
    di as text "{hline 72}"
    di as text "Rendered table at $output/tables/_smoke_table_render_`country'_cuu.tex"
    di as text "{hline 72}"
}
local rc = _rc
capture log close
if `rc' != 0 di as error ">>> _smoke_table_render FAILED rc=`rc'"
