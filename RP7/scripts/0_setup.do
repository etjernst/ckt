* **********************************************************************
* Project:          Returns to migration
* Task:             Installs dependencies (user-written Stata programs) 
* **********************************************************************
* Dependencies
    local ssc_install    "estout reghdfe ftools coefplot unique ietoolkit sdecode boottest summclust"
    local styles         "schemepack"

* **********************************************************************
* 0 - Decide if you want to update ado files (otherwise set adoUpdate to 0)
* **********************************************************************
* Set $adoUpdate to 0 to skip updating ado files if they already exist
    global adoUpdate    0

* **********************************************************************
* 1 - Check if required packages are installed
* **********************************************************************

* Packages from SSC
foreach package in `ssc_install' {
    capture : which `package', all
    if (_rc) {
        capture window stopbox rusure "You are missing some packages." "Do you want to install `package'?"
        if _rc == 0 {
            quietly capture ssc install `package', replace
            if (_rc) {
                window stopbox rusure `"Do you want to proceed without this package?"'
            }
        }
        else {
            exit 199
        }
    }
}

* Update all ado files
    if $adoUpdate == 1 {
        ado update, update
    }
	
* Can't check if a theme is installed using "-which-" so just install schemepack

* Schemes don't have .ado files so -which- doesn't work
* Instead use -findfile- to search for the file
foreach style in `styles' {
  qui: findfile `styles'.sthlp   // help file for the style exists if installed
  * Check if the file was found
  if _rc == 0 {
    display "`style' is installed (found helpfile here: `r(fn)')"
  } 
  else {
    capture window stopbox rusure "You are missing some packages." "Do you want to install `style'?"
    if _rc == 0 {
      quietly capture ssc install `package', replace
      if (_rc) {
        window stopbox rusure `"Do you want to proceed without this package?"'
      }
    }
    else {
      exit 199
    }
  }
}  

* **********************************************************************
* 2 - Set preferences
* **********************************************************************

set varabbrev off
