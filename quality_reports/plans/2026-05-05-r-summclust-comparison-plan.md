# R `summclust` head-to-head plan (do not run yet)

Date: 2026-05-05
Status: planning only.
Do NOT execute on the main workstation; the prior R `clubSandwich` attempt at TZA scale ($N \approx 29{,}864$, $J = 11{,}012$) peaked above 13 GB and crashed.
See [2026-05-02 session log](file:///C:/git/ckt/.claude/worktrees/lca-inversion/quality_reports/session_logs/2026-05-02_step0a-backend-benchmark-and-pivot.md) for the prior failure mode.

## Goal

Decide whether the R `summclust` port (paired with `fixest::feols` for absorption) is materially faster than Stata `summclust` at IDN scale, holding the statistical estimator fixed.
The R port and the Stata `.ado` implement the same CR3 / CV3J jackknife per MNW (2023); any wall-time difference is purely an implementation gap.
The decision feeds back into rev 5 path G: keep Stata as production, switch to R as production, or use R as a faster prototyping aid while shipping Stata `.ster` artifacts.

## What we already know

Stata `summclust` baseline at IDN unbalanced (today's sweep, [`output/summclust_scaling_sweep_2026May4_224022.csv`](file:///C:/git/ckt/.claude/worktrees/lca-inversion/explorations/python-grc/stata/step0_5_summclust_preflight/output/summclust_scaling_sweep_2026May4_224022.csv)):

| $J$ (clusters) | $N_{\text{obs}}$ | active z's | wall (s) |
|---:|---:|---:|---:|
| 5,000 | 15,650 | 28 | 480 |
| 10,000 | 31,397 | 28 | 8,066 |

Empirical scaling exponent $\approx 4.07$ in $J$.
Linear extrapolation to $J = 29{,}715$: ~8 days.
A second sweep is in flight that drops the `jackknife` option to isolate the CV3J cost; results pending.

Prior R attempt failure mode (different package, different estimator).
R `clubSandwich::vcovCR(type = "CR2")` on TZA covs_trend $J = 11{,}012$ peaked above 13 GB and OOM'd before completing; the diagnosis at the time was that the dense $N \times N$ influence matrix $H$ does not fit in 16 GB at TZA scale, let alone IDN scale ($N \approx 90{,}000$, $H$ projected ~65 GB).
The recommendation in that session log was to absorb FE first via `fixest::feols`, but the recommendation was never tested before the path C / path G pivot.

Why R `summclust` is not the same risk.
The R port `summclust::vcov_CR3J.fixest` is dispatched on a `fixest` model object, which already absorbs the FE columns and never materializes the dense $H$.
It computes per-cluster influence matrices analytically rather than constructing $H$ as a single block.
This is the exact "absorb FE first" strategy the prior session flagged as the next thing to try; pairing it with the CR3 port (rather than CR2 + dense $H$) is the new combination.
But this is theoretical until benchmarked; the prior R crash is a strong prior that R-on-Windows hits memory walls at our scale even with promising package choices.

## Test design

Three tightly scoped probes, each run separately and each with a hard memory ceiling enforced from outside R.
Smaller comes first; do not start the next probe until the previous one completes successfully and reports peak memory below ceiling.

### Probe R.1: smoke test at $J = 500$

Reproduce the exact Stata probe ([`probe_idn_setup.do`](file:///C:/git/ckt/.claude/worktrees/lca-inversion/explorations/python-grc/stata/step0_5_summclust_preflight/probe_idn_setup.do)) in R: load IDN unb, build the recoded design at $\hat\phi$, drop singletons, subsample to $J = 500$, fit `fixest::feols(lndepvar ~ z_active + period_ | trajectory, cluster = ~ pid)`, then `summclust::vcov_CR3J.fixest()`.
Confirm the estimated coefficients match Stata's `summclust ..., fevar(trajectory)` to $10^{-6}$ relative on $\hat\beta$ and $10^{-3}$ relative on the standard errors.
Goal: prove the R toolchain runs end-to-end at trivial scale and agrees with Stata.
Wall budget: 5 min total.
Memory budget: 1 GB peak.

### Probe R.2: scaling sweep at $J \in \{1000, 2000, 5000\}$

Same setup as R.1 but at three sizes.
Capture wall time and peak RSS per cell via `Rprof(memory.profiling = TRUE)` and externally via Windows `Get-Process -Name Rscript | Select-Object PeakWorkingSet64`.
Compare wall time to Stata's $J = 5{,}000$ baseline (480 s).
Goal: estimate the R scaling exponent and the constant factor versus Stata.
Wall budget: 30 min total (assuming R is at most 4x slower than Stata at $J = 5{,}000$).
Memory budget: 4 GB peak.
Hard kill: external Windows monitor that kills the R process if peak RSS exceeds 6 GB.

### Probe R.3: IDN-scale stress test at $J = 10{,}000$

Only run if R.2 completes and the projected wall and memory at $J = 29{,}715$ are within budget.
Wall budget: 4 hours.
Memory budget: 8 GB peak.
Hard kill: external monitor at 12 GB.
Skip entirely if R.2 shows scaling worse than Stata's $J^4$ exponent.

## Apples-to-apples constraints

The comparison only carries information if both backends compute the same quantity on the same data.

Statistical estimator.
CR3 covariance and CV3J jackknife per MNW (2023), with `nograph` (no leverage figure), no `addmeans`, no `gstar`, no `regtable`.
Stata invocation: `summclust lndepvar z_2 ... z_K period_2 ... period_T, cluster(pid) fevar(trajectory) jackknife nograph`.
R invocation: `m <- fixest::feols(lndepvar ~ z_2 + ... + z_K + period_2 + ... + period_T | trajectory, data = d, cluster = ~ pid); v <- summclust::vcov_CR3J.fixest(m, cluster = "pid", type = "CR3")`.
The active-z filter applies in both: drop $z_s$ columns with zero variance in the subsample, computed identically in Stata and R, before passing to the estimator.

Random subsampling.
Use the same seed 20260504 and the same sampling rule (rank pids by `runiform()`, keep the first $J$).
Implement the seed and rank in R via `set.seed(20260504); pid_unique <- unique(d$pid); idx <- order(runif(length(pid_unique)))[1:J]; keep <- pid_unique[idx]; d <- d[d$pid %in% keep, ]`.
Verify by hashing the resulting `pid` set: it should be identical to Stata's subsample at the same $J$.

Singleton handling.
Apply the singleton drop on the FULL dataset before subsampling, identical to Stata.

Phi at which to recode.
Use $\hat\phi_{\text{point}} = -0.30948$ from `grc_IDN_urban_covs_trend.ster`, hardcoded in the R script.
Document the value at the top of the R script with a comment pointing to the source ster.

## Memory and crash protection

Run R from PowerShell with an external monitor that polls peak RSS every 5 seconds and force-kills the Rscript process if the ceiling is breached.
Skeleton:

```powershell
$ceiling_gb = 6
$proc = Start-Process -FilePath "Rscript.exe" -ArgumentList "probe_R2.R" -PassThru
while (-not $proc.HasExited) {
    Start-Sleep -Seconds 5
    $rss_gb = $proc.PeakWorkingSet64 / 1GB
    if ($rss_gb -gt $ceiling_gb) {
        Stop-Process -Id $proc.Id -Force
        Write-Host "KILLED at peak $($rss_gb) GB" -ForegroundColor Red
        break
    }
}
```

Do not skip the monitor.
The prior R attempt's 13 GB peak landed because nothing was watching; the workstation got pushed into swap and froze.
Even if today's R port is theoretically lighter, treat the empirical ceiling as enforced from outside R.

## Decision criteria

After R.2 completes, compute the head-to-head ratio at $J = 5{,}000$.
Three regimes drive the decision.

R is materially faster (R wall < 0.5 $\times$ Stata wall at $J = 5{,}000$).
Recommend pivoting production to R for path G; ship Stata `.ster` only for the small-$J$ self-consistency anchor.
Schedule R.3 to verify the win holds at $J = 10{,}000$.

R is comparable (Stata wall < R wall < 2 $\times$ Stata wall).
Stay on Stata for production; the implementation cost of switching toolchains and validating against the existing pipeline is not justified by a 1.5x speedup.
R becomes a parallel-execution option for development iteration.

R is materially slower (R wall > 2 $\times$ Stata wall) or R hits the memory ceiling.
Stata stays on path G.
Document the result in the rev 5 plan's path G section so future revisions do not re-investigate.

## Where to run

Not the user's main workstation while the IDN GRC pipeline is in flight.
The prior R crash made the machine unresponsive for 30+ minutes.

Two viable hosts.

User's work laptop (Monash) sits idle 99% of the time.
Confirmed has 16 GB RAM, multi-core, and R is already installed (used for prior `clubSandwich` benchmarks).
Pros: trivially accessible; user can monitor in person; if it crashes the work laptop, the main workstation stays clean.
Cons: 16 GB matches the original crash machine, so the memory ceiling is just as tight; R.3 at $J = 10{,}000$ may fail.

MQ HPC / shared compute server.
Action item: user to scope what's available at MQ (which queue, RAM ceiling per job, R version, package install protocol).
Pros: more headroom for R.3 and any IDN full-$J$ run; production-grade environment.
Cons: queue wait, package install friction, no interactive feedback during the run.

Default to the work laptop for R.1 and R.2; defer R.3 until either the work laptop completes R.2 cleanly or MQ access is set up.

## Effort estimate

Per probe.

R.1 (smoke at $J = 500$): 1 h to write the R script + 5 min wall.
R.2 (scaling at $J \in \{1000, 2000, 5000\}$): 30 min to wire the loop + 30 min wall.
R.3 (stress at $J = 10{,}000$): 0 incremental code; 4 h wall budget.

Total to a decision: half a working day plus the R.3 wall if it runs.

## Open questions

The R `summclust::vcov_CR3J.fixest` documentation does not explicitly benchmark to large $J$ (search done 2026-05-05).
The CRAN vignette uses `nlswork`-style examples ($J \approx 4{,}710$).
Whether the implementation exploits sparsity in the FE-absorbed design at $J = 29{,}715$ is unverified; the prior failure mode (dense $H$) suggests no.
R.1 will quickly clarify by reporting peak RSS at $J = 500$.

PyFixest as a third option.
PyFixest supports CV3 but explicitly does NOT support CV2 ([per the 2026-05-01 session log](file:///C:/git/ckt/.claude/worktrees/lca-inversion/quality_reports/session_logs/2026-05-01_f-adjustment-plan-rev3-via-reg-sandwich.md)).
PyFixest does support CV3 / CV3J (per [statsmodels PR #8596](https://github.com/statsmodels/statsmodels/pull/8596) and PyFixest's own docs).
Defer until R is ruled out: adding a third toolchain triples the comparison and validation surface.

## Picking up

Read this plan and the prior session logs.
The Stata sweep results to anchor against live in [`output/`](file:///C:/git/ckt/.claude/worktrees/lca-inversion/explorations/python-grc/stata/step0_5_summclust_preflight/output/).
Do NOT run R on the main workstation without the PowerShell memory monitor in place.
The hardcoded $\hat\phi_{\text{point}}$ to use is $-0.30948$ from `grc_IDN_urban_covs_trend.ster`.
