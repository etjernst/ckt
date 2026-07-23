# Definitive-run master-log sanity sweep

Date: 2026-07-24.
Target: [0_master.log](file:///C:/git/ckt/RP7/scripts/0_master.log), 91,976 lines, from the definitive master run of 2026-07-21 22:33 to 2026-07-23 17:41.
Method: two read-only subagent passes over disjoint halves, error-pattern search with per-hit context classification, plus script-boundary flow verification; cell identification for every convergence warning done in the main session against the log.

## Verdict

The run terminated normally with the single expected abort and no unexpected failures.
Ten non-fatal GMM convergence-cap warnings are the only substantive findings, all in cells outside the twenty mainline consumption/urban/unbalanced cells; two of the ten sit behind reported tables and need author adjudication.

## Confirmed expected

`5b_inversion.do` aborted at log lines 21617-21642 on the since-deleted `grc_IDN_cuu_c0` fossil (`r(460)`, no e(sample) marker); the capture wrapper caught it and the pipeline continued.
This is the known error; the WCR11 Stage 6 re-run supersedes this script's attachments anyway.
`5c_inversion_hukou.do` completed cleanly (rc 0), `12_counterfactuals.do` was skipped by its flag as designed, every FAILED guard in the tail came back untriggered, and the master ended at "end of do-file".

## Ster accounting

1,055 `.ster` files were written by this run (mtime after 2026-07-21 22:30), inside the expected 1,020-1,050 range.
Total on disk is 1,095; the roughly 40 older files are stale income-era artifacts covered by the approved purge.

## The ten convergence-cap warnings

Every one is the same pattern: `gmm` reached the default `iterate(100)` cap with the criterion essentially flat (changes in the seventh or eighth decimal, "backed up" steps), printed `convergence not achieved`, saved the ster, and continued.
None aborted anything.

| # | Log line | Cell | Where it lands |
|---|---|---|---|
| 1 | 23417 | `grc_IDN_cnu_ca` | IDN non-agricultural unbalanced, full covariates: behind the reported IDN nonag tables |
| 2 | 28844 | `grc_CHN_uf_cub_ca` | CHN urban-first hukou, balanced sample, full covariates: behind the reported balanced hukou table |
| 3 | 67583 | `grc_IDN_cnu_maxexp_ca` | IDN nonag max-experience extra (appendix) |
| 4 | 69540 | `grc_IDN_cnu_expsh_ca` | IDN nonag experience-share extra (appendix) |
| 5-9 | 84275-86545 | five `run_grc_robust_vv` fits (13/23 cluster block) | Verdier-implementation robustness |
| 10 | 90630 | `vv_CHN_ts_covs_all` | Verdier-implementation robustness, CHN two-step |

## Adjudication options (author call)

Accept as-is: a flat criterion at the cap is standard for these hard cells, `iterate(100)` is the convention across branches, and the estimates printed with Hansen J statistics.
Or re-run only the flagged cells at a higher cap and confirm the estimates do not move; rows 1 and 2 are the two with reported-table exposure, so if anything gets the higher-cap check it should be those.

## Benign-pattern coverage

Both agents reported per-pattern benign counts (hundreds of routine `(file not found)` pre-save notes, `(N missing values generated)` generation notes, echoed guard branches that never fired, and the structural `rural = 1 - urban` balance-table variance warnings in `2_summaryStats.do`); details in the session transcript.
