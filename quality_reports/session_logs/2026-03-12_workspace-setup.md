# Session log: Workspace setup

**Date:** 2026-03-12
**Mode:** Bootstrap

## Goal

Set up a Claude Code workspace for the CKT paper ("Selection and Heterogeneity in the Returns to Migration") by creating a wrapper git repo at `c:/git/ckt/` with directory junctions into the Dropbox folder at `C:\Users\maand\Dropbox (Personal)\Returns to migration\ReplicationPackage4\`.

## Key context

- Paper lives in Overleaf; user will add `main.tex` to `paper/` manually.
- Authoritative code is in `ReplicationPackage4/scripts/` (22 do-files + `0_programs.do`).
- Three countries: CHN (CFPS), IDN (IFLS), TZA (TZNPS).
- Known bug: `define_switcherpars` hardcoded to `base(2)`, wrong for IDN/TZA income specs.
- Sync rule: never push to Overleaf.

## Progress

- Created local directories: `paper/`, `docs/{specs,plans,session_logs,reviews}`, `quality_reports/`, `explorations/`.
- Attempted `ln -s` for symlinks but Git Bash created copies instead of junctions.
- Provided user with `mklink /J` commands to create proper Windows directory junctions. **Awaiting user action.**
- Created `.gitignore` (excludes symlinked dirs, Stata/LaTeX artifacts, .vscode, .claude/state).
- Created `CLAUDE.md` with project identity, stack, directory layout, code structure, known issues, sync protocol.
- Created `.claude/rules/source-of-truth.md`.

## Completed

- User ran junction commands; junctions verified working.
- Updated MEMORY.md with new workspace paths and [LEARN:windows] entry about `ln -s` vs `mklink /J`.
- Read full paper (903 lines) and updated CLAUDE.md with:
  - Expanded project identity: CRC→GRC pipeline, LCA restriction, GMM, J-test, pro-poor finding.
  - New notation section listing all key parameters ($\theta_i$, $\phi$, $\Delta_i$, $\mu_{\underline{d}}$, trajectory sets).
  - Added J-test rejection in pooled CHN to known issues.
- Initial git commit.
