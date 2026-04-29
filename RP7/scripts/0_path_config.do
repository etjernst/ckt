* **********************************************************************
* Project:          Returns to migration
* Task:             Set sub-directory globals
* **********************************************************************
* Set working directories as relative absolute filepaths
  global      scripts         "$dir/scripts"
  global      dirdata         "$dir/data"
  global      logs            "$dir/scripts/logs"
  global      output          "$dir/output"

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
	
	