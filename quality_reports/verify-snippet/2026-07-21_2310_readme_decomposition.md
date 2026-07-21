# Verify-snippet decomposition: RP7/README.md

Snippet: the replication README ([RP7/README.md](file:///C:/git/ckt/RP7/README.md)), adapted from the skill's short-snippet flow because the document exceeds the snippet size: the factual premises are grouped per README subsection, one fresh-context verifier per group, each checking the subsection against the script it describes.
Sources: the pipeline scripts in `RP7/scripts/`, `0_programs.do`, `0_path_config.do`, `0_setup.do`, the utilities folder, `explorations/python-grc/lca_inversion.py`, and `paper/CKT.bib` for citations.
Out of scope: every HTML-comment FILL IN placeholder (author-owned), and paper-side claims the scripts cannot witness.

## Substantive content

- The README presents itself as sufficient for a replicator to run the package from raw data to final output via `0_master.do` alone; the substantive check asks whether the described pipeline order and instructions match `0_master.do` as committed.

## Factual premises about the source, grouped per verifier

- V1: the `0_CHN_hukou_restrictions.do` and `1_processData.do` subsections (hukou coding and four independent sections; the full processed-cell inventory with no income cells; the six dataset characteristics; keep-list CSVs; lumping deferred to load time).
- V2: the `2_summaryStats.do` and `1b_unbalanced_rank_diagnostic.do` subsections (output table names; iebaltab/ietoolkit; income as descriptive only; the rank-diagnostic outputs and its hard-stop check).
- V3: the `3_OLS_uGRC.do` and `6_OLS_uGRC_hukou.do` subsections (three and eight output tables; six-column structure; FE column sets the common sample; individual clustering).
- V4: the `4_GrRC.do` subsection (6 cells x 4 columns = 24 main fits; `cuu`/`cub` and `ct/c1/c2/ca` naming; c0 commented out; `_n/_a/_d/_g` companions and the `_esample.dta` marker; the four shared programs' described roles; `$grc_max_iter` = 100 in `0_path_config.do`; base-trajectory selection rule).
- V5: the `5b_inversion.do` and `5c_inversion_hukou.do` subsections (the `attach_inversion_ci` to `lca_inversion.py`/`attach_inversion_for_stata` call path; the attached scalars; marker-vs-fallback behavior; 5c covers rf/uf only; the claimed covariate-column count for 5c; which companion files each updates).
- V6: the `5_GrRC_NonAg.do` and `7_GrRC_hukou.do` subsections (`cnu` naming; the hukou ster naming `grc_CHN_{rf,uf,ro,uo}_...` and `initial_*` sters; eight input datasets).
- V7: the `8_learning.do` subsection (IDN and CHN only; period counts per country; four-column structure; output names; balanced data; clustering).
- V8: the `9_GRC_extras.do` subsection plus the utilities bullets (31 calls; the five family tags; column naming for extras; the three slice drivers' coverage; the resume guard; `run_master_resume.do` equivalence).
- V9: the `10_make_tables.do` subsection (the named table families and counts, including the forty-four extras tables; which sters it reads; explicit per-table calls rather than loops).
- V10: the `11_make_figures.do` and `11b_extrapolation_support_figure.do` subsections (figure inventory; robustness coefplots IDN/TZA only; PNG width 3600; 11b outputs, singleton-exclusion rule, runs-last rationale).
- V11: the `17_verdier_robust.do` and `17b_cluster_summary.do` subsections (`vv_` ster naming and the thirty-fit count; table names including the `_cluster.tex` copies; keeplist CSV names; `skip_if_exists` default; the five 17b rows and their cluster variables; sole-producer claim).
- V12: cross-cutting premises: the Stata package list against `0_setup.do`; the Python package list against `lca_inversion.py` imports; the no-randomness claim against a sweep of the pipeline scripts; the Instructions section against `0_master.do` mechanics; the four references against `paper/CKT.bib`.

## Verdict rule

GO: substantive check clean and every premise group VERIFIED.
WARN: any PARTIAL.
FIX: any NOT-VERIFIED or a CRITICAL substantive finding.
