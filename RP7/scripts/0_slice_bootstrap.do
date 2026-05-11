* **********************************************************************
* 0_slice_bootstrap.do
*
* Shared post-$dir setup for the family slice drivers (run_extras_*.do).
* Caller must have set $dir before including this file; everything else
* is derived.
*
* What this does:
*   1. Set sub-directory globals ($scripts, $logs, $output, $dirdata) and
*      project-wide constants ($grc_max_iter, $grc_min_switchers_per_wave)
*      via 0_path_config.do. Reads $values (default: nominal) to pick the
*      data path and the $vsfx suffix.
*   2. Load all shared programs (run_grc, run_grc_with_extra_regressor,
*      initial_values, etc.) via 0_programs.do. Quietly because the
*      155 KB file would otherwise saturate batch output.
*   3. Enable the resume guard: run_grc skips any cell whose _g$vsfx.ster
*      is already on disk. Safe to run concurrently with other slice
*      drivers and with 0_master.do --- the filesystem coordinates.
*   4. Disable copyOverleaf: slice drivers don't run the table builders,
*      but set this defensively in case any called helper attempts a copy.
*
* Not in scope: $dir resolution (stays inline in each slice driver because
* Stata cannot resolve sibling-file lookups from an arbitrary launch cwd),
* log open/close (log filename differs per driver), and the body of cell
* calls (the actual content that differs between drivers).
* **********************************************************************

if "${dir}" == "" {
    di as error "0_slice_bootstrap: \$dir not set. Resolve \$dir before including this file."
    exit 198
}

include "$dir/scripts/0_path_config.do"

quietly include "$scripts/0_programs.do"

global skip_if_exists 1

global copyOverleaf   0
