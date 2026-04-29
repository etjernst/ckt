* **********************************************************************
* Project:          Returns to migration
* Task:             Set sub-directory globals + project-wide constants
* **********************************************************************
* Set working directories as relative absolute filepaths
  global      scripts         "$dir/scripts"
  global      dirdata         "$dir/data"
  global      logs            "$dir/scripts/logs"
  global      output          "$dir/output"

* **********************************************************************
* Project-wide constants (set ONCE here so individual programs don't
* re-define magic numbers locally). Set in 0_path_config.do --- not
* 0_master.do --- so that alternate entry points (e.g. _smoke_full.do)
* that bypass 0_master.do still see them.
*   grc_max_iter               --- GMM iterations cap; was a magic 100
*                                  hardcoded in 5/6/8/GRC_extras + make_tables
*   grc_min_switchers_per_wave --- minimum N/T threshold in initial_values
*                                  for a switcher trajectory to be eligible
*                                  as the base; was a magic 5
* **********************************************************************
  global      grc_max_iter               100
  global      grc_min_switchers_per_wave 5

* Create logs directory if it doesn't exist already
* (the others should already exist)
	qui: capture mkdir          "$logs"
	qui: capture mkdir          "$output"
	qui: capture mkdir          "$output/tables"
	qui: capture mkdir          "$output/figures"
	qui: capture mkdir          "$dirdata/processed"
	
* $overleaf is set per-user in 0_master.do user-specific blocks. If not set,
* $copyOverleaf calls will be skipped (safer than silently copying to a
* hardcoded path that doesn't exist on the current machine).
	if ("$overleaf" == "") {
		di as error "Note: \$overleaf is not set. copyOverleaf calls will be skipped."
		di as error "Add a {it:global overleaf <path>} line to your user block in 0_master.do to enable."
	}
	else {
		di as text "Output will be copied to Overleaf repo $overleaf"
	}
	
	