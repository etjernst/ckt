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
	
* Add global to overleaf repo IF user has not already set it
	// Check if the global macro is empty
	if ("$overleaf" == "") {
		global overleaf 													///
		"C:/Users/maand/Dropbox (Personal)/Apps/Overleaf/ReturnsToMigration-clean"
	} 
	di as text "Output will be copied to Overleaf repo $overleaf"
	
	