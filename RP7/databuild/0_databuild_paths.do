/*******************************************************************************
Returns to Migration --- data-construction pipeline
0_databuild_paths.do

Sets the directory globals for the data build.
Run this from the databuild directory (the master and each country build call it),
so the current directory is the pipeline root.

  $databuild  pipeline root (this folder)
  $inputs     copied replication inputs (gitignored)
  $output     regenerated analysis datasets (gitignored)
  $canonical  copied canonical countries/*.dta, used only for verification
*******************************************************************************/

global databuild "`c(pwd)'"
global inputs    "$databuild/inputs"
global output    "$databuild/output"
global canonical "$inputs/canonical"

cap mkdir "$output"
cap mkdir "$output/_intermediate"

* sanity check: fail loudly if inputs are not where we expect
capture confirm file "$inputs/chn_panel.dta"
if _rc {
	display as error "Inputs not found at $inputs."
	display as error "Run from the databuild directory so c(pwd) is the pipeline root."
	exit 601
}
