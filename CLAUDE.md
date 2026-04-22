# Returns to migration (CKT)

## Core principles

- Plan first. No substantive file edits without an approved spec and plan.
- Verify after. Every implementation round ends with critic review.
- Quality gates decide readiness. Severity tiers (CRITICAL/MAJOR/MINOR) carry the signal; numeric scores assist triage but do not substitute for judgment.
- Learn continuously. Record reusable insights in docs/session_logs/.
- Human decides. Econometrics findings, identification questions, and any change that alters results require human approval.

## Project identity

- **Paper:** "Selection and Heterogeneity in the Returns to Migration"
- **Authors:** Cenci, Kleemans, Tjernström
- **Description:** Estimates heterogeneous returns to rural-urban migration using a generalized Roy model with panel data from China (CFPS), Indonesia (IFLS), and Tanzania (TZNPS). Reconciles divergent estimates in the literature by showing that standard panel methods (OLS, FE) mask substantial heterogeneity in returns across migration trajectories.
- **Identification:** Correlated random coefficient (CRC) model cast as a group random coefficient (GRC) model following Suri (2011) and Tjernström (2023). Workers have location-specific skills ($\theta_i^U$, $\theta_i^R$); comparative advantage ($\theta_i^U - \theta_i^R$) drives both sorting and heterogeneous returns. A linear comparative advantage (LCA) restriction ($\Delta_i = \beta + \phi\theta_i$) allows extrapolation from switchers to non-switchers. Estimated via GMM; overidentification tested with Hansen's J-test.
- **Key estimand:** Trajectory-specific returns to urban location ($\Delta_{\underline{d}}$) for switcher subpopulations, plus extrapolated returns for never-migrants. The slope parameter $\phi$ measures whether migration is "pro-poor" ($\phi < 0$: those with lowest rural consumption gain most) or "pro-rich" ($\phi > 0$).
- **Key finding:** $\phi < 0$ consistently across all three countries, indicating migration is pro-poor. Non-migrants have substantially higher potential returns than observed switcher returns suggest, pointing to labor misallocation and barriers to mobility.
- **Treatment:** Urban location ($D_{it} = 1$); also non-agricultural sector for IDN.
- **Outcomes:** Log per-capita consumption (primary), log income (secondary).
- **Unit of observation:** Individual-year panel. Countries: CHN (4 waves, 2010--2016), IDN (5 waves, 1993--2015), TZA (3 waves, 2008--2013). Over 75,000 individuals total; >90% are non-switchers.
- **Data sources:** China Family Panel Studies (CFPS), Indonesia Family Life Survey (IFLS), Tanzania National Panel Survey (TZNPS). CHN and TZA data from Lagakos et al. (2023); IDN cleaned from raw IFLS following Kleemans (2018) and Hamory et al. (2021).

## Platform, stack, and commands

- OS: Windows 11. Shell: Git Bash. Use Windows-compatible paths.
- Python: Anaconda (`C:\Users\maand\anaconda3\python.exe`); bare `python` works.
- LaTeX: MikTeX with XeLaTeX. Use `--include-directory=` flag, not `TEXINPUTS=`.
- Stata: `stata-mp` on PATH. cd into script directory so log lands there.
- Git: conventional commits, branch per feature. Co-authoring line: `with Claude`.

```bash
# Stata (run full pipeline)
cd scripts && stata-mp -b do 0_master.do

# Stata (run single do-file; set $dir first)
cd scripts && stata-mp -b do 5_GrRC.do

# Python
python scripts/python/analysis.py
```

## Directory layout

```
paper/              # main.tex lives here (added manually, not symlinked)
scripts/ -> Dropbox/.../ReplicationPackage6/scripts/   # do-files + 0_programs.do
data/    -> Dropbox/.../ReplicationPackage6/data/       # countries/ (raw .dta) + processed/
output/  -> Dropbox/.../ReplicationPackage6/output/     # .ster files, tables/, figures/
docs/               # specs, plans, session_logs, reviews
quality_reports/    # quality scores
explorations/       # experimental analysis
```

Symlinks are Windows directory junctions into `C:\Users\maand\Dropbox (Personal)\Returns to migration\ReplicationPackage6\`.

## Stata code structure

- `0_master.do` runs the full pipeline. Sets `$dir` per user, then includes all scripts.
- `0_path_config.do` sets subdirectory globals (`$scripts`, `$dirdata`, `$logs`, `$output`).
- `0_programs.do` defines all shared programs (~92KB). Key programs:
  - `data_setup` / `data_setup_2waves` -- data loading and variable construction
  - `run_grc` -- runs the GRC estimation
  - `define_switcherpars` -- defines switcher parameters for GRC
  - `initial_values` -- sets initial values for GRC optimization
  - `grc_tex_table` -- formats GRC results into LaTeX tables
  - `heterogeneity_plots` -- generates heterogeneity figures
- Scripts 1--16 run sequentially: data processing, summary stats, OLS, heterogeneity plots, GRC regressions (main, non-ag, hukou, experience, birth controls), heterogeneity tables.

## Notation and key parameters

- $y_{it}^l$: systematic log consumption for worker $i$ at time $t$ in location $l \in \{R, U\}$.
- $\theta_i^U, \theta_i^R$: time-invariant location-specific productivities.
- $\tau_i$: absolute advantage (orthogonal to comparative advantage).
- $\theta_i \equiv b_R(\theta_i^U - \theta_i^R)$: rescaled comparative advantage.
- $\phi \equiv (b_U - b_R)/b_R$: governs how strongly returns increase with comparative advantage.
- $\Delta_i = \beta + \phi\theta_i$: worker-specific return to urban location.
- $\Delta_{\underline{d}}$: average return for trajectory $\underline{d}$ (identified for switchers only in unrestricted model).
- $\mu_{\underline{d}}$: average rural consumption for trajectory $\underline{d}$.
- $\underline{d}_0$: baseline switcher trajectory in restricted GRC.
- $\mathcal{D}_S$: set of switcher trajectories; $d_N$: always-rural; $d_T$: always-urban.

## Known issues

- `define_switcherpars` in `0_programs.do` is hardcoded to `base(2)`. This is wrong for income specs with IDN (base=16) and TZA (base=5). Consumption results are unaffected.
- Hansen's J-test rejects in pooled CHN sample. Splitting by hukou status (rural-first vs urban-first) resolves rejection, suggesting institutional heterogeneity rather than model failure. Separate $\phi$ estimates needed per hukou regime.

## Sync protocol

- Never push to Overleaf. Dropbox sync corrupts Overleaf track changes.
- Pull from Overleaf is fine (entire Overleaf folder into `project/overleaf/`).
- The user manually copies `main.tex`, `CKT.bib`, and `preamble.tex` to Overleaf when ready.

## Conventions

- Three countries: CHN (China), IDN (Indonesia), TZA (Tanzania).
- File naming pattern for output: `{type}_{country}_{depvar}_{choice}_{balance}.{ext}` (e.g., `GRC_CHN_consumption_urban_unb.tex`).
- `.ster` files store estimation results: `grc_{country}_{spec}.ster` with `_always`, `_delta`, `_never` suffixes for subgroup estimates.
