
/*
The seed is defined at the end of the file
*/

* Check if Stata is running in batch or interactively
local is_console = c(mode) == "batch" | c(console) == "console"
local OS = c(os)
loc repetitions = 1000
/*
7_1_SimulationsPhi program arguments
    // args param1 param2 param3 param4 param5
    // display "Seed: `param1'"
    // display "Sample: `param2'"
    // display "eta: `param3'"
    // display "Repetitions: `param4'"
    // display "Path: `param5'"
*/

if ("`OS'" != "Windows") & (`is_console' != 0) {
    * If batching in console
    ***** Sample 1000
    dobatch "$script_simulations/7_1_SimulationsPhi.do" 234     1000 0.1  `repetitions' "$root_path"
    dobatch "$script_simulations/7_1_SimulationsPhi.do" 453     1000 0.25 `repetitions' "$root_path"
    dobatch "$script_simulations/7_1_SimulationsPhi.do" 623     1000 0.5  `repetitions' "$root_path"
    dobatch "$script_simulations/7_1_SimulationsPhi.do" 62      1000 1    `repetitions' "$root_path"
    ***** Sample 2000
    dobatch "$script_simulations/7_1_SimulationsPhi.do" 633     2000 0.1  `repetitions' "$root_path"
    dobatch "$script_simulations/7_1_SimulationsPhi.do" 434     2000 0.25 `repetitions' "$root_path"
    dobatch "$script_simulations/7_1_SimulationsPhi.do" 2256    2000 0.5  `repetitions' "$root_path"    
    dobatch "$script_simulations/7_1_SimulationsPhi.do" 78889   2000 1    `repetitions' "$root_path"    
    ***** Sample 5000
    dobatch "$script_simulations/7_1_SimulationsPhi.do" 6456    5000 0.1  `repetitions' "$root_path"    
    dobatch "$script_simulations/7_1_SimulationsPhi.do" 43      5000 0.25 `repetitions' "$root_path"
    dobatch "$script_simulations/7_1_SimulationsPhi.do" 235     5000 0.5  `repetitions' "$root_path"
    dobatch "$script_simulations/7_1_SimulationsPhi.do" 7897    5000 1    `repetitions' "$root_path"    
    dobatch_wait 
    include "$script_simulations/7_2_SimulationCompile.do"
}

* If running in Windows
if ("`OS'" == "Windows")   {
   
    cd "${root_path}/output/simulations/"
   
    ***** Sample 1000
    * eta 0.1
    winexec "${Stata_path}" -e do "$script_simulations/7_1_SimulationsPhi.do" 234   1000 0.1    `repetitions' "$root_path"
    * eta 0.25
    winexec "${Stata_path}" -e do "$script_simulations/7_1_SimulationsPhi.do" 453   1000 0.25   `repetitions' "$root_path"
    * eta 0.5
    winexec "${Stata_path}" -e do "$script_simulations/7_1_SimulationsPhi.do" 623   1000 0.5    `repetitions' "$root_path"
    * eta 1
    winexec "${Stata_path}" -e do "$script_simulations/7_1_SimulationsPhi.do" 62    1000 1      `repetitions' "$root_path"

    ***** Sample 2000
    * eta 0.1
    winexec "${Stata_path}" -e do "$script_simulations/7_1_SimulationsPhi.do" 598   2000 0.1    `repetitions' "$root_path"
    * eta 0.25
    winexec "${Stata_path}" -e do "$script_simulations/7_1_SimulationsPhi.do" 434   2000 0.25   `repetitions' "$root_path"
    * eta 0.5
    winexec "${Stata_path}" -e do "$script_simulations/7_1_SimulationsPhi.do" 2256  2000 0.5    `repetitions' "$root_path"
    * eta 1
    winexec "${Stata_path}" -e do "$script_simulations/7_1_SimulationsPhi.do" 78889 2000 1      `repetitions' "$root_path"

    ***** Sample 5000
    * eta 0.1
    winexec "${Stata_path}" -e do "$script_simulations/7_1_SimulationsPhi.do" 6456  5000 0.1    `repetitions' "$root_path"
    * eta 0.25
    winexec "${Stata_path}" -e do "$script_simulations/7_1_SimulationsPhi.do" 43    5000 0.25   `repetitions' "$root_path"
    * eta 0.5
    winexec "${Stata_path}" -e do "$script_simulations/7_1_SimulationsPhi.do" 235   5000 0.5    `repetitions' "$root_path"
    * eta 1
    winexec "${Stata_path}" -e do "$script_simulations/7_1_SimulationsPhi.do" 7897  5000 1      `repetitions' "$root_path"

    * Check simulations have been produced before compiling table 
    foreach sample_size of numlist 1000 2000 5000 {
        if "`sample_size'" == "1000" local seed_list = "234 453 623 62"
        if "`sample_size'" == "2000" local seed_list = "598 434 2256 78889"
        if "`sample_size'" == "5000" local seed_list = "6456 43 235 7897"

        foreach seed_value of local seed_list {
            local cap_confirm = 1
            local timer = 0
            while `cap_confirm' != 0 {
                cap confirm file "${root_path}/output/simulations/temp/crc_GMM_t2_sim_`sample_size'_`seed_value'.dta"
                local cap_confirm = _rc
                
                // if `timer' != 0 sleep 500000
                if `timer' != 0 sleep 1000
                local timer = 1  
           }
        di in red "File confirmed: ${root_path}/output/simulations/temp/crc_GMM_t2_sim_`sample_size'_`seed_value'.dta"
        }

    }
    // Generate table: Wait until loop is done 
    include "$script_simulations/7_2_SimulationCompile.do"
}






