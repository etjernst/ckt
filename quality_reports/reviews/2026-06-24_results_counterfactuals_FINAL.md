# review-file FINAL: results_counterfactuals.tex

Date: 2026-06-24.
Critic: critic-writing. Fixer: fixer-writing.
Verdict: HALTED (by design) --- all remaining blockers are out-of-scope for a section fragment and require Overleaf-side / bibliography work.
Snapshot for rollback: `paper/results_counterfactuals.tex.review-backup` (and the file was committed at the parent of this session's work).

## Per-round counts

| Round | Critical | Major | Minor | Fixed this round | Skipped (out of scope) |
|---|---|---|---|---|---|
| 1 | 4 | 7 | 5 | 10 (table wiring, share footnote, contact clause, 3 sentence splits, NRPS gloss, throat-clear, fragments, passive cluster) | C1 bib, C2 labels, 4 inline cites, \emph |
| 2 | 3 | 5 | 6 | 3 (line 28 colon-fragment, line 105 Gai split, line 50 precision pointer) | C labels, C shares-table, C app ref, inline cites |

Numeric score: 58 -> 66 (round 2). The score is held down entirely by the out-of-scope reference/bibliography items, not by prose quality.

## Applied (section-fixable, done)

- Wired in the generated results table: `\input{tables/counterfactual_misallocation.tex}` plus `Table~\ref{tab:counterfactual_misallocation}` pointers at the cross-country and hukou-regime sentences. All five magnitudes re-verified against the table in fresh context.
- Footnoted the source of the 74/26 hukou shares.
- Prose: restored the dropped "that" (line 19); split four compound-complexity sentences (lines 25, 28, 105, 122/124); recast the four-source intercept-gap list as enumerated First/Second/Third/Fourth; glossed NRPS and the Hukou Index; replaced the "are worth flagging" throat-clear; repaired two sentence fragments; varied the passive "is identified" cluster; added a precision pointer so the line-50 conditional reads onto Tanzania, not Indonesia.

## Out of scope --- punch list for the user (Overleaf / CKT.bib)

These are real CRITICAL/MAJOR items but cannot be fixed inside this section fragment without fabricating or editing files that live on Overleaf:

1. Undefined hukou GRC table refs `tab:GRC_CHN_hukou_rural_first_consumption_urban_unb` and `..._urban_first_...` (line ~139). The labels must be supplied by `table` floats in the Overleaf `main.tex`; confirm the exact keys.
2. Undefined `app:inversion-preview` (line ~58). Almost certainly defined in the Overleaf appendix, not this worktree --- confirm the key resolves and update or drop the "verified" header comment accordingly.
3. The 74/26 hukou shares ideally point to a descriptive table column, not just a footnote (critic's preferred fix; the footnote is the interim).
4. Bibliography: add entries for Kennan-Walker (2011), Tombe-Zhu (2019), Fan (2019); convert the four inline "Author, Year, Journal" cites to `\cite{}`; delete the two `TODO` footnotes. The three `\emph{}` journal-name uses vanish with that conversion. (Gai 2025 already resolves.)

## Note

`humanize-econ` and `audit-residue` were run after this loop (user request) as additional prose passes; see their output for any further small changes (the stale "verified" header annotation is an audit-residue target).
