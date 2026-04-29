* **********************************************************************
* Interactive replay of a single GRC cell for troubleshooting.
*
* Use this to investigate any cell that crashed in batch mode. Runs ONE
* run_grc_with_extra_regressor call (or a manual run_grc / run_grc_hukou
* call) so the error fires in your face with full context, instead of
* being buried in a 1.8 MB smoke log.
*
* DO NOT run this batch-mode (no `exit, STATA clear` at the end). Open
* an interactive Stata, then `do tests/replay_one_cell.do`. The session
* stays alive after the cell runs so you can inspect e(), r(), local
* macros, the dataset in memory, etc.
*
* Usage pattern:
*   1. Open interactive Stata.
*   2. Edit the "CONFIGURE" block below to point at the cell you want
*      to replay.
*   3. `do tests/replay_one_cell.do`
*   4. If the cell crashes, the error fires here. Inspect with:
*        di "$grc_timer_slot"
*        macro list _all
*        sum age2 if e(sample)
*        ...
* **********************************************************************

clear all
set more off
capture log close

* --- Set $dir per user (mirror the smoke driver) ---
if "`c(username)'" == "maand" {
    global dir = "C:/git/ckt/.claude/worktrees/grc-pipeline-refactor/RP7"
}

include "$dir/scripts/0_path_config.do"
include "$scripts/0_setup.do"
include "$scripts/0_programs.do"

* Don't write to Overleaf during troubleshooting.
global copyOverleaf 0

* Always re-run the cell when troubleshooting (override any stale ster).
global skip_if_exists 0

* **********************************************************************
* CONFIGURE: which cell to replay
* **********************************************************************
* For the 2026-04-30 GRC_extras crash, the failing cell was
* CHN cuu maxexp c3. We don't know yet if c3 fails on its own or only
* fails when the timer slot has wrapped past 100. Two scenarios below;
* uncomment one.
*
* SCENARIO A: replay just the cell from a clean session (timer starts
* at slot 1). If the timer-wrap fix in commit 5c21224 is correct AND
* the timer slot was the only cause, this should now succeed.
*
* SCENARIO B: pre-pump the timer slot to mimic the state mid-Tier 3
* (CHN cuu maxexp c3 was around slot 117 in the 2026-04-30 run). Use
* this to confirm the timer wrap actually fires correctly AND that no
* other state-dependent bug is hiding.
* **********************************************************************

* --- SCENARIO A: clean timer slot (default) ---
* (no pre-pump; ${grc_timer_slot} starts unset, will be initialized to 0)

* --- SCENARIO B: simulate mid-Tier-3 timer state ---
* Uncomment to deliberately push the slot past 100 BEFORE the cell runs.
* Without the timer-wrap fix this would crash with `r(198) invalid syntax`
* on the first run_grc call. With the fix (commit 5c21224) the slot
* should wrap to 1 and the cell should fit normally.
*
* global grc_timer_slot 117

* --- The cell to replay ---
* Replace these args to investigate any cell. country/spec3/regressor map:
*   country  in {IDN, CHN, TZA}
*   spec3    in {cuu, cub, iuu, cnu}
*   regressor in {exp, exp_max, exp_share, exp_max_share, urbanbirth}
local replay_country  CHN
local replay_spec3    cuu
local replay_regressor exp_max

display as text "============================================"
display as text "Replaying cell: " "`replay_country' `replay_spec3' `replay_regressor'"
display as text "Initial timer slot: ${grc_timer_slot}"
display as text "============================================"

run_grc_with_extra_regressor,                  ///
    country(`replay_country')                  ///
    spec3(`replay_spec3')                      ///
    regressor(`replay_regressor')

display as text "============================================"
display as text "Replay complete."
display as text "Final timer slot: ${grc_timer_slot}"
display as text "Inspect e() with: ereturn list"
display as text "Inspect dataset with: describe; sum"
display as text "============================================"

* NOTE: no `exit, STATA clear` --- intentional. Keeps the session alive
* for post-mortem inspection.
