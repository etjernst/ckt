# Draft email to coauthors: ster filename collision

**Draft for review. Do not send until Emilia has edited.**

---

**Subject:** Hidden estimation-output collision in 5/6/10--15 GrRC do-files (quick fix needed)

Hi [Andy, Paul],

I ran into a silent issue in the Stata pipeline while working on a weak-identification-robust confidence interval for $\phi$. Flagging it here because the current `.ster` files in `output/` are not what the published tables assume they are, and it needs a small naming fix in several do-files.

## What's happening

Multiple GrRC do-files write `.ster` files to `output/` using the same filename pattern, so whichever script runs last wins. Specifically:

| Filename pattern | Do-files that write it |
|---|---|
| `grc_<country>_covs_{0,trend,1,2,all}.ster` | `5_GrRC.do` (urban) and `6_GrRC_NonAg.do` (nonag) |
| `grc_<country>_{c1,c2,c3,ca}.ster` | `10_GrRC_experience.do`, `11_GrRC_max_experience.do`, `12_GrRC_experience_share.do`, `13_GrRC_max_experience_share.do`, `14_GrRC_NonAg_experience.do`, `15_GrRC_birth.do` |

Both patterns silently overwrite each other depending on run order.

`8_GrRC_hukou.do` is OK --- it uses `grc_<country_short>_...` which encodes the hukou subgroup.

## Evidence this is live, not hypothetical

For IDN `consumption/urban/unb`, the current `.ster` files on Dropbox `output/` show:

| File | mtime | Sample $N$ | $\hat\phi$ |
|---|---|---:|---:|
| `grc_IDN_covs_0.ster` | Apr 1 14:16 | 69,447 | $-2.225$ |
| `grc_IDN_covs_trend.ster` | Apr 1 14:21 | 69,447 | $+0.795$ |
| `grc_IDN_covs_1.ster` | Apr 1 14:26 | 69,445 | $+0.810$ |
| `grc_IDN_covs_2.ster` | Apr 1 14:32 | 69,445 | $+0.805$ |
| `grc_IDN_covs_all.ster` | Apr 2 02:41 | 92,439 | $-0.526$ |

The first four have $N=69{,}447$, which is not the IDN consumption/urban sample size (92,450). It matches the nonag sample (nonag has more missingness). And the $\phi$ values are positive for covs_trend/1/2 --- the opposite sign from urban. So these four were overwritten by a subsequent run of `6_GrRC_NonAg.do`. Only `covs_all.ster` matches the published urban table (mtime 13+ hours later, suggesting it was re-run on its own under urban).

The corresponding table `output/tables/GRC_IDN_consumption_urban_unb.tex` is dated Apr 1 13:09, built from urban-spec estimates that no longer exist on disk. The table itself is correct but unreproducible from the current `.ster` files.

## Proposed fix

Two minimal conventions would fix this without changing any numbers, just how things are stored:

1. Include the choice variable in the `.ster` filename when it varies:
   - `5_GrRC.do`: `grc_<country>_urban_covs_*` (or keep `covs_*` as the default urban)
   - `6_GrRC_NonAg.do`: `grc_<country>_nonag_covs_*`
2. Include the script's signature in the experience-family suffix:
   - `10_GrRC_experience.do`: `grc_<country>_exp_{c1,c2,c3,ca}`
   - `11_GrRC_max_experience.do`: `grc_<country>_maxexp_{c1,c2,c3,ca}`
   - `12_GrRC_experience_share.do`: `grc_<country>_expsh_{c1,c2,c3,ca}`
   - `13_GrRC_max_experience_share.do`: `grc_<country>_maxexpsh_{c1,c2,c3,ca}`
   - `14_GrRC_NonAg_experience.do`: `grc_<country>_nonag_exp_{c1,c2,c3,ca}`
   - `15_GrRC_birth.do`: `grc_<country>_birth_{c1,c2,c3,ca}`

Follow-on edits to `16_heterogeneity_tables.do` and any other downstream readers to match the new names.

## Impact on the published results

None on the headline IDN consumption/urban numbers, as far as I can tell. `GRC_IDN_consumption_urban_unb.tex` was built Apr 1 13:09 from a self-consistent urban run. The phi values in columns (1)--(5) are $-2.445$, $-0.309$, $-0.310$, $-0.321$, $-0.526$. My Python replication of those estimates agrees (same data, same spec, Python hits the same optima to 3--4 decimals).

But: anyone re-running `5_GrRC.do` today without also re-running `6_GrRC_NonAg.do` in the same session will produce a table that mixes urban and nonag estimates silently, with no warning. So the naming fix is needed before the next round of edits touches the Stata pipeline.

## What I'm doing on my side

- Re-running the IDN section of `5_GrRC.do` now to confirm the published phi values are reproducible, and writing up a side-by-side comparison of the GMM estimates to the LCA-inversion CI.
- Not editing the pipeline do-files myself --- wanted to flag this to you first so we can coordinate the rename together.

Happy to prepare a PR with the rename if you'd like.

Best,
[Emilia]

---

## Internal notes (not part of the email)

- The draft above assumes we want to confirm the numbers before shipping. If Emilia is confident the Apr 1 13:09 run was correct, the "confirming" step can be skipped.
- Keeping the phrase "none on the headline" is contingent on the rerun matching the table. If they differ, revise before sending.
- The fix proposal in §2 is a starting point; Emilia may prefer different suffix conventions. Don't send without that decision.
