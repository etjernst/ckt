# stage5_root

Shadow root for the Stage 5 gate (inversion CIs key off e(sample)).
`scripts` and `data` are junctions to the working tree's `RP7/scripts` and the canonical hub at `RP7/data`; `output/` receives the Stage 5 refit sters and their `_esample.dta` markers.
Refits must be byte-identical to `stage34_root/output`, because the marker write cannot touch the fit; `gate_stage5_compare.do` adjudicates.
The attach legs copy these sters to `stage5_legA_output` (markers removed, fallback path) and `stage5_legB_output` (markers kept, marker path) before running `5b_inversion.do` and `5c_inversion_hukou.do` against each.
