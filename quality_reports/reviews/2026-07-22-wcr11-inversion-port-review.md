# Plan review: wire the WCR11-corrected inversion into the real-data pipeline

Reviewing as: applied econometrics methodology specialist.
Plan source: [quality_reports/plans/2026-07-22-wcr11-inversion-port.md](file:///C:/git/ckt/quality_reports/plans/2026-07-22-wcr11-inversion-port.md).
Mode: solo (fresh-context reviewer with repo read access).
Depth: standard (two searches).

## Best practices context

1. The restricted (null-imposed) wild cluster bootstrap is the MacKinnon-Nielsen-Webb recommended default, and in test inversion the bootstrap DGP must re-impose the null at every tested parameter value.
2. Rademacher weights are standard; Webb six-point weights are recommended when the effective cluster count is very small, and WCR can under-reject badly with few treated clusters.
3. The finite-B rule wants alpha(B+1) integral at every alpha used; B = 399 gives 20 and 40 at the 5 and 10 percent levels.
4. Grid-inversion CIs inherit precision from grid resolution and endpoints; islands must be handled explicitly.
5. Bootstrap CIs wobble with the seed at finite B; publication practice records the seed, reports B, and checks sensitivity once.

Sources: [fwildclusterboot documentation](https://s3alfisc.github.io/fwildclusterboot/), [its literature survey](https://s3alfisc.github.io/fwildclusterboot/articles/Literature.html), [Roodman, Nielsen, MacKinnon, and Webb (2019), "Fast and wild"](https://journals.sagepub.com/doi/full/10.1177/1536867X19830877), [MacKinnon and Webb (2018, Econometrics Journal)](https://onlinelibrary.wiley.com/doi/abs/10.1111/ectj.12107), [Stata wildbootstrap manual](https://www.stata.com/manuals/rwildbootstrap.pdf), [Canay, Santos, and Shaikh, "The wild bootstrap with a small number of large clusters"](https://home.uchicago.edu/amshaikh/webfiles/wild.pdf), [Pustejovsky on bootstrap CI variation](https://jepusto.com/posts/Bootstrap-CI-variations/), [Greenwood, intermediate statistics notes](https://stats.libretexts.org/Bookshelves/Advanced_Statistics/Intermediate_Statistics_with_R_(Greenwood)/02:_(R)e-Introduction_to_statistics/2.09:_Confidence_intervals_and_bootstrapping).

## Strengths

1. Parity gates before wiring, with the oracle check and size-reproduction check as separate committed artifacts; the reviewer independently confirmed the anchor row (`count_desc,1.0,26,500,0.264,0.048`) and all four reference artifacts on the branch.
2. The statistical core is right: restricted-residual refit per grid point, CV1 throughout, exact finite-B rule, B = 399 integral at both levels.
3. One sign matrix reused across grid points is common-random-numbers done right; it smooths the p-value curve in phi and stabilizes endpoints.
4. Seed discipline and typed B_valid failures meet the reproducibility bar.
5. Pilot pricing with an author gate before any expensive run.
6. Most verified preconditions survived independent re-verification (sys.path insert, bridge signature, no-parent SKIP branch).
7. The islands machinery already avoids silent convex-hulling.
8. Honest handling of the CHN urban-first unbounded region; Overleaf preamble edits as proposed diffs.
9. Fresh diagnosis of the China attachment instead of pre-fixing a possibly-resolved bug.

## Weaknesses and gaps

Red. Mixed-table rule not implemented end to end.
The plan's mechanism ("attach stops writing the delta CI scalars") fails twice against the code.
First, stale macros: `attach_inversion_ci` loads a ster, ereturns, and re-saves; sters that already carry chi-squared `inv_dN`/`inv_davg`/`inv_dT` results (the definitive run's 5c attached both hukou splits 4/4) keep them through a re-save that merely stops writing new ones, so Stage 6 would produce exactly the forbidden table: corrected phi beside uncorrected delta CIs.
Second, hardcoded rows: `grc_tex_table_trend`'s `invci` block (0_programs.do around lines 3381-3384) hardcodes the delta CI `stats()` rows, a file the plan never touches; stale values print, or empty label rows dangle.
Fix: the attach step actively scrubs the three delta prefixes on every re-save; the `invci` block drops the delta rows and keeps the phi row; Stage 6 verification adds "no delta CI macro in any reported ster, no delta CI row in any rebuilt table."

Yellow. Chi-squared site inventory wrong in "verified preconditions."
The file has five chi2 sites (221, 312, 442, 537, 632), not three, and line 312 is `grid_md_inversion` (a phi MD variant used only by smoke scripts), not a derived-quantity inversion.
The functional target is unaffected, but a false claim under a "verified" heading is corrosive and line numbers are brittle.
Fix: rescope by function name; state that `grid_md_inversion` stays chi-squared and is off the attach path.

Yellow. Accept-rule boundary mismatch.
The plan says accept when p* > 0.05 but `find_islands` uses >=, and the finite-B lattice contains exactly 0.05 with positive probability at B = 399, exactly where endpoints live.
Fix: strict rule implemented consistently through `find_islands`, plus a boundary-tie unit test.

Yellow. Branch checkout under a live master run.
Checkout swaps the whole tree while the running master still has unexecuted scripts to re-read from disk (10_make_tables, figures, Verdier).
Fix: develop in a git worktree (with the junction-target check from the 2026-06-23 protocol before any worktree operation), leaving the main tree untouched until the run completes.

Yellow. The c0 skip is a silent spec amendment.
The spec's MUST lists covs_0; the plan satisfies it via the no-parent skip.
Defensible, but it reinterprets a MUST without author ratification.
Fix: add it to the approval checklist.

Yellow. No seed-sensitivity or B-escalation check for published intervals.
Endpoints wobble at finite B; publication practice leans B = 999.
Fix: pilot reruns the cell with a second seed and once at B = 999, reporting endpoint movement in grid steps; author picks production B.

Yellow. Wider CIs may hit the grid bounds.
Correcting a 0.264-size test widens accept regions; interior regions may now touch the phi grid endpoints in cells beyond CHN urban-first.
Fix: Stage 6 endpoint check per cell; a region touching a bound triggers a widened grid and a rerun of that cell.

Yellow. No named fallback if the byte-identity assert fires.
`build_aux_design` may never have seen production quirks.
Fix: name the contingency (reconcile against `fit_auxiliary_ols` or build the design from the fit's own code path, then re-run Gates A/B).

Green. Rademacher-vs-Webb justification absent (one sentence: the cluster count is individuals, large, and the sim validated the actual sparsity surface; optionally expose the weight family).
Green. Gate B tolerance should state its comparison rule (same-seed exact, or a root-sum-of-variances tolerance near 0.014, not 0.010).
Green. The 5b skip guard keys on `e(inv_phi_ci95_lo)`, which chi-squared-era sters satisfy; attach `e(inv_method) = "wcr11"` and key the guard on it.
Green. A few project-shorthand phrases need glosses for a cold reader.
Green. Pin the chi-squared comparison path with a fixture regression test.

## Verdict: REVISE

The statistical core is sound and well-guarded, and most preconditions survived independent verification.
But the one decision the spec forbids making silently, shipping a corrected phi CI beside an uncorrected delta CI, is the default outcome of executing the plan as written, via stale macros on the already-attached hukou sters and the hardcoded delta rows in `grc_tex_table_trend`.
That Red plus the unratified covs_0 reinterpretation and the live-run checkout risk are each cheap to fix and none disturbs the design.

## Revisions to apply to the plan

1. [CHANGED] Stage 3: attach actively scrubs `inv_dN`/`inv_davg`/`inv_dT` scalars and macros on every re-save (not merely stops writing them); adds `e(inv_method) = "wcr11"` and rekeys the 5b/5c skip guards on it.
2. [NEW] Stage 3b: edit `grc_tex_table_trend`'s `invci` block to drop the three delta CI rows and keep the phi row; this lands with the port, before any Stage 6 table rebuild.
3. [CHANGED] Stage 6 verification adds: no delta CI macro in any reported ster; no delta CI row in any rebuilt table; per-cell grid-endpoint check with widen-and-rerun on contact.
4. [CHANGED] Verified preconditions: chi-squared inventory rescoped by function name (five sites; `grid_lca_inversion` is the sole port target; `grid_md_inversion` stays chi-squared, off the attach path; the three delta MD inversions untouched).
5. [CHANGED] Stage 2: strict p* > alpha rule threaded through `find_islands` with a boundary-tie unit test; Rademacher justification sentence added to the note, weight family exposed as a parameter.
6. [CHANGED] Stage 0: development happens in a git worktree (junction check first), main tree untouched until the master run completes.
7. [CHANGED] Stage 1 Gate B states its comparison rule (same-seed exact reproduction, else tolerance sqrt(2) x MCSE, about 0.014).
8. [CHANGED] Stage 2: named contingency if the `build_aux_design` byte-identity assert fires; reconcile and re-run Gates A/B before proceeding.
9. [CHANGED] Stage 5 pilot: second-seed rerun plus a B = 999 run, endpoint movement reported in grid steps; author picks production B.
10. [CHANGED] Stage 4: add the chi-squared fixture regression test.
11. [CHANGED] Approval checklist gains item 5: ratify the covs_0-skip reading of the spec's every-specification MUST.
