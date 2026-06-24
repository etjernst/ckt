/*******************************************************************************
Returns to Migration --- data-construction pipeline
0_databuild_paths.do

Sets the directory globals for the data build.
Run this from the databuild directory (the master and each country build call it),
so the current directory is the pipeline root.

  $databuild  pipeline root (this folder)
  $inputs     copied replication inputs (gitignored)
  $output     regenerated analysis datasets (gitignored)
  $canonical  copied canonical country datasets, used only for verification
*******************************************************************************/

global databuild "`c(pwd)'"
global inputs    "$databuild/inputs"
global output    "$databuild/output"
global canonical "$inputs/canonical"

cap mkdir "$output"
cap mkdir "$output/_intermediate"

* sanity check: warn (do not raise) if inputs are not where we expect.
* A raise here would pop a modal in batch mode; the master wraps each build
* in capture noisily so a genuine failure is logged, not modal.
capture confirm file "$inputs/chn_panel.dta"
if _rc {
	display as error "WARNING: inputs not found at $inputs --- run from the databuild directory so c(pwd) is the pipeline root."
}
