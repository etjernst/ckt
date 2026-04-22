use Data/SuriPanel_extended.dta, clear

qui do Code/firststage_projection_bs 1 4

sort hhid per

xtset hhid per

gen Dyresid = D.yresid if hybrid==L.hybrid

local count = 1
foreach h in 0 1 {
	foreach p in 2 3 4 {
		foreach s in 0 1 {
			capture drop index`count'
			gen index`count' = (hybrid==`h'&per==`p'&switcher==`s')
			local count = `count' +1
		}
	}
}

reg Dyresid index1-index12, nocons vce(cluster vil)
scalar F= e(F)
matrix b = e(b)
forvalues count = 1/12 {
	scalar mu`count' = b[1,`count']
}
