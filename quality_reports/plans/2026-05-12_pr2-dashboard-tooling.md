# PR-2 draft: headlines cache + results-overview dashboard

Date: 2026-05-12
Branch: `worktree-grc-pipeline-refactor` → `main`
Status: draft (depends on PR-1 landing first; the rescaler-overlay deletion
in `compare.py` is part of PR-1, not PR-2)

This file holds the PR description so it survives across sessions.
Edit before opening the PR; copy the rendered version into the GitHub PR
body via `gh pr create --body-file ...`.

---

## Title (suggested)

Results-overview dashboard + headlines cache (default-off, additive)

## Summary

New side-channel tooling for inspecting GRC results.
Adds a Quarto-rendered HTML dashboard that scrapes `.ster` files and
`.log` files under `RP7/output/`, plus a per-stem CSV headlines cache
that short-circuits the slow `estimates use` path during render.

Purely additive.
No estimation code touched, no paper artifacts changed, no
sample / specification / identification changes.
The dashboard is gated behind `$runDashboard` (default 0) in
`0_master.do`, so coauthors without Python or Quarto installed never
trigger the tooling.

## What changes

### Headlines cache

- New script: `tools/results_overview/scrape_headlines.py` (306 lines).
  Walks `RP7/output/*.ster`, extracts the headline scalars (point
  estimate, SE, t-stat, p-value, N, converged flag, Hansen J) for
  each main fit plus its `_n` / `_a` / `_g` / `_always` / `_delta` /
  `_never` subgroup sters, and writes one CSV per stem to
  `RP7/output/headlines/<stem>.csv` via `os.replace` atomic rename.
  Supports `--incremental` (only restate stems whose ster mtimes
  exceed the existing CSV's mtime).
- Cache contents tracked in git: `RP7/output/headlines/*.csv`,
  273 stems at branch tip.
  Tracking the CSVs lets the dashboard render on a fresh clone
  without needing the underlying `.ster` files (which are gitignored).
- New test: `tools/results_overview/test_cache_equivalence.py`
  (110 lines) verifies cache-loaded headlines round-trip against
  freshly-extracted values for a sample of stems.

### Dashboard

- New Quarto source: `tools/results_overview/report.qmd` (558 lines).
  Renders 24 sections covering main-GRC, NonAg, hukou, experience,
  birth, maxexp, expsh, maxexpsh, cnu-family fits, plus six
  nominal-vs-real value-axis comparisons and four CHN/IDN balanced-vs-
  unbalanced comparisons.
- New Python module: `tools/results_overview/compare.py` (879 lines).
  Defines `Fit`, `FitGroup`, and rendering helpers; pulls from the
  headlines cache first and falls back to `estimates use` only on
  cache miss.
- Supporting scripts: `scrape.py` (189 lines, bootstraps the bank
  of scraped log fields the dashboard uses for old runs without
  ster files) and `scrape_logs.py` (571 lines, the bank scraper
  itself).
- Profiling harness: `profile_render.py` (119 lines, used during
  cache development to measure render-time speedup; ~10× faster
  with cache hit).

### Master pipeline integration

- `0_master.do` gains `global runDashboard 0` (default off) and
  gates the tail `shell python "$dir/../tools/results_overview/scrape_headlines.py" --incremental` behind
  `${runDashboard} == "1"`.
  Lands in PR-1 (commit `43ab63d`), but the gate is what makes this
  PR additive for coauthors.

### Rendered artifact

- `tools/results_overview/report.html`: rendered dashboard
  snapshot, 2.6 MB, 24 chunks populated.
  Regenerable from the qmd + cache + ster files; included so a
  coauthor can open it without Quarto installed.

## Test plan

- [x] Cache equivalence test passes
  (`pytest tools/results_overview/test_cache_equivalence.py`).
- [x] Render on a fresh clone with only cache CSVs (no ster files):
  all 24 chunks populate, no Python errors.
- [x] Render with full ster set on disk: matches cache-only render
  byte-for-byte except for the "Results from DATE" line.
- [ ] Incremental cache refresh after a re-fit produces the same
  values as a from-scratch rescrape (spot-check 5 stems).

## Risks

- Numeric: none.
  Dashboard reads existing artifacts; never writes to `.ster` or
  to any paper output.
- Reproducibility: dashboard is not part of the paper pipeline.
  Anyone running `do 0_master.do` with `$runDashboard 0` (the
  default) gets the same paper tables and figures as without this
  PR.
- Coauthor friction: dashboard is opt-in.
  Coauthors without Python / Quarto see no change in behavior.

## Pre-merge checklist

- [ ] PR-1 merged first
  (the `compare.py` rescaler-overlay deletion belongs to PR-1; rebasing
  PR-2 onto post-PR-1 main should be clean).
- [ ] Re-render `report.html` against the post-refit ster set
  so the shipped snapshot reflects corrected Delta_avg.
- [ ] Verify `runDashboard 0` gate still wraps the
  `scrape_headlines.py` call in `0_master.do`.
- [ ] Push branch and open PR with this body.

## Commits in scope (19 total)

```
ee1b8a6  Track headlines cache CSVs in git
dc83443  Headlines cache: write per-stem CSVs, short-circuit load_fit
7c4c5aa  Dashboard: re-render with experience-family tables
1f1f5c7  Dashboard: add 'converged' row reporting GMM e(converged)
19cd009  Dashboard: apply Delta_avg sidecar override + tolerate missing chunks
1b2712d  Dashboard: per-table 'Results from DATE' line
57ff3c2  S1 results overview: render with 11 nominal-vs-real sections
655ecb5  S1 results overview: drop nominal-vs-real income section
be1ef40  S1 results overview: add NonAg + 4 hukou nominal-vs-real sections
1a3f489  S1 results overview: scrape NonAg + hukou logs into bank
75c5f55  S1 results overview: six nominal-vs-real demo sections
7dc3f38  S1 results overview: nominal-vs-real values axis with bank fallback
e5c9033  S1 results overview: eight new comparison sections
6e450ca  S1 results overview: commit rendered report.html
b047593  S1 results overview: section heading separator from em-dash to pipe
e1d8ae1  S1 results overview: nonag + income sections, +exp coefplot row, mtime cache
68eb85c  S1 results overview: family + hukou comparison axes, panel shading
fd292d0  S1 results overview: add CHN balanced vs unbalanced comparison
0791442  tools/results_overview: prototype Quarto report (IDN bal vs unbal)
```

## Out of scope

- The `19cd009` Delta_avg sidecar override block in `compare.py`
  is deleted as part of PR-1's rescaler cleanup, not this PR.
  After PR-1 lands and PR-2 rebases, that commit's substantive
  contribution is gone but the surrounding chunk-tolerance fix
  survives.
- Quarto installation instructions for coauthors who want to
  re-render the dashboard themselves
  (not a blocker; the rendered `report.html` ships in-tree).
