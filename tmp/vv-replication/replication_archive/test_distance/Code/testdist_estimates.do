use Data/SuriPanel_extended.dta, clear

qui do Code/firststage_projection_bs 1 4

egen distancebar = mean(fertskm), by(hhid)

*note can't include all distance in regression, would lose lots of obs. Could test correlation though, but this more intuitive I think

drop if !switcher
drop if a==.
drop if return==.
duplicates drop hhid, force

forvalues per = 1/4 {
	gen hybrid`per'_filled = hybrid`per'
	replace hybrid`per'_filled=0 if hybrid`per'_filled==.
}

ivregress 2sls a (return = hybrid*_filled) distancebar, vce(cluster vil)
test distancebar == 0

local epsilon (a-{alpha0}-{alpha1}*return-{alpha2}*distancebar)

local mc_step1 `epsilon'
forvalues per=1/4 {
	local mc_step1 `mc_step1' (hybrid`per'_filled*`epsilon')
}
local mc_step1 `mc_step1' (distancebar*`epsilon')

capture drop ones
gen ones=1
putmata Z = (ones hybrid*_filled distancebar), replace
mata
Winit = invsym(Z'*Z)
st_matrix("Winit",Winit)
end

gmm `mc_step1', winitial(Winit)  vce(cluster vil) onestep
gmm `mc_step1', winitial(Winit)  vce(cluster vil) wmatrix(cluster vil)
matrix bhat=e(b)
scalar alpha2=bhat[1,3]
