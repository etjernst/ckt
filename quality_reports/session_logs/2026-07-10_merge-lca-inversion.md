# 2026-07-10 --- Merge lca-inversion into main

## If you resume

One-line state: `lca-inversion` is merged into `main` (merge commit `5a9c7a6`); the main tree at `C:/git/ckt` is now the working tree for submission finalizing, with `$dir` repointed (`e6ba836`) and all worktree-only `.ster` files copied into `C:/git/ckt/RP7/output`.
NEXT ACTION: none pending from the merge itself; finalizing work (open items below) starts from here.

## Mode

Maintenance (merge + artifact sync; no results, claims, or specifications changed).

## What happened

- Merged `lca-inversion` (134 commits ahead) into `main` (7 Verdier cluster-robustness commits ahead) at `C:/git/ckt`.
- The only conflict was `docs/TODO.md`, a both-added case in the Active section; resolved by keeping all three entries (main's cluster-pooling run and inversion-CI wiring, the branch's trajectory-density paper figure).
- Main's uncommitted `runDashboard` comment tweak in `0_master.do` was stashed across the merge, popped cleanly, and committed together with the `$dir` repoint (`e6ba836`).
- `RP7/scripts/0_programs.do` and `17_verdier_robust.do` auto-merged: main's side only added the `cluster_comparison_table` program and driver hooks, so no semantic overlap with the branch's GRC edits.
- Copied 260 `.ster` files from the worktree's `RP7/output` into main's `RP7/output` (now 310 total). The 10 name collisions (`grc_*_cuu_ca{,_n}.ster`) were byte-identical---main's copies were themselves copies made 2026-07-01 for the cluster-comparison baselines. Main's 40 unique Verdier sters (`vv_*`, `mc_robust_vv*`, `sanity_robust_vv*`, `vvd_simple_IDN*`) were untouched.
- Verified the tracked counterfactual CSVs (`counterfactual_{results,decomposition,diagnostics,results_baseline}.csv` and `counterfactual_inputs/`) match the worktree content-wise; the byte differences are CRLF normalization from the new `.gitattributes` (`a7f806f`). Figures directories are identical.

## State to know

- The lca-inversion worktree at `C:/git/ckt/.claude/worktrees/lca-inversion` still exists. Do NOT remove it with `git worktree remove --force` without first checking its `RP7/data` junction, which points INTO the hub `C:/git/ckt/RP7/data`---this is the exact mechanism of the 2026-06-23 data loss. Safe removal: `cmd /c rmdir` the junctions inside the worktree first, then remove the worktree.
- A stash remains on the lca-inversion worktree: `stash@{0}` "CRLF-only churn in het tables (content-identical, verified 2026-07-09)"; droppable but left for the user.
- Uncommitted in main's working tree (pre-existing, untouched): modified `paper/slides/verdier-modification.pdf`, three deleted `papers/inbox/` PDFs, assorted untracked files.

## Open items carried over (none block anything in git)

- The hukou stub footnote (`\footnote{Tables \ref{hukou}}`, line 754 of Overleaf `main-updated.tex`): user decides delete vs point at the appendix hukou tables; the document's only remaining undefined reference.
- Bryan-Morten restyle of sec:counterfactuals (Todoist `6h4694ChV544Wg4J`).
- Merge the duplicate Kennan-Walker items in Zotero (`L8VL7CQB` / `8PT5AIBU`).
