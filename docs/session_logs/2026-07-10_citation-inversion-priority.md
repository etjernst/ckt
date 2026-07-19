# Session log: citation edit and inversion-inference priority

Date: 2026-07-10

## Goal

Correct the Schoellman citations and duplicate BibTeX entry, then decide whether the paper's inversion-inference prose should be revised immediately or only after code reruns.

## Decisions and why

- `main-updated.tex` is the manuscript target. Protected `main.tex` was not edited.
- Donovan and Schoellman (2023) moved into the main selection-versus-frictions sentence because that review directly organizes the debate.
- Herrendorf and Schoellman (2018) is no longer cited as rural--urban consumption-return evidence. The replacement separates its cross-country census evidence from agriculture-to-nonagriculture panel wage evidence and distinguishes the authors' U.S. estimate from the Brazil/Indonesia studies they cite.
- Lee and Liao remains postponed at the author's request.
- Inference prose is gated on computation. Existing synthetic coverage falls materially below 95% for some headline objects, and the generalized inverse can drop rank while the current code retains nominal degrees of freedom. Static code alignment is therefore insufficient for a coverage claim.
- The first computational rerun should be the IDN/TZA auxiliary-OLS inversion and simulation pilot, not the full multi-day GMM sweep. A GMM rerun is conditional on missing or irreproducible `.ster` inputs, changes to the GMM estimator, incoherent China/hukou tables, or failed point-estimate reproduction.

## Files changed

- `quality_reports/specs/2026-07-10-citation-and-inversion-paper-update.md`
- `quality_reports/plans/2026-07-10-citation-and-inversion-paper-update.md`
- Live author-approved `main-updated.tex` and `CKT.bib` in the Overleaf-Dropbox project.
- Audit and manifest files under `citation_audits/`, `quality_reports/reviews/`, and `quality_reports/staging/`.

## Verification

The staged full project compiled successfully through XeLaTeX/BibTeX/XeLaTeX/XeLaTeX. The only undefined reference was the pre-existing `hukou` reference. Protected `main.tex` and `preamble.tex` retained their baseline hashes.

## Next step

Execute Phase B1/B2 of the revised plan: freeze the baseline, expose rank/grid diagnostics, and run the R=20 IDN/TZA correctness/timing pilot. Present projected compute cost before any R=1,000 launch or results-changing finite-sample adjustment.
