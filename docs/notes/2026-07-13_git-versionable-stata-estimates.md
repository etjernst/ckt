# Git-versionable Stata estimates: a tool concept

Date: 2026-07-13.
Status: thinking memo, not scheduled work.
Origin: the CKT pipeline gitignores its `.ster` files because they are binary and undiffable, but we would like the estimation results themselves under version control so we can see what moves between runs.

## The realization that makes it feasible

A text export can regenerate graphs, not just tables, which is the point that makes this worth building.
A `.ster` file earns its keep because you can `estimates use` it and then rebuild tables and graphs, and the instinct is that a text export cannot do the graph half.
A `coefplot`-style graph needs only `e(b)` and `e(V)`, which are named numbers and serialize to text without loss.
Stata pushes a coefficient vector and variance matrix back into a live result with `ereturn post b V`, after which you re-add the scalars and macros with `ereturn scalar`/`ereturn local`.
Once that is done, `esttab`, `coefplot`, `test`, `lincom`, and `nlcom` behave exactly as if the estimate had been loaded from a `.ster`.
The only post-estimation a text file cannot support is the kind that needs the estimation data back in memory, `margins` and `predict`, and a standalone `.ster` cannot do those either because it does not store the data.
So a text format with a reader loses nothing that a `.ster` gives you on its own.

The whole tool is that round trip: serialize `e()` to a diffable text file, then deserialize it back into a posted `e()` that downstream code treats as a real estimate.

## Why this is a contribution beyond our repo

The Stata ecosystem has no standard git-friendly, round-trippable estimates format.
`estout`/`esttab` (Jann) export presentation tables that are one-way and lossy and cannot reconstitute an estimate, and `estimates save` is binary and version-fragile.
Community commands in this space need checking before we build (there is at least an `estwrite`/`estread` pair; I should verify its format and whether it round-trips, and search SSC for any `est2json`), but a lossless estimate-to-text serializer with an exact-round-trip guarantee appears to be a real gap.

The payoff is not just storage; the compelling feature is diffable results in code review.
A pull request that changes a specification would show a clean line-by-line diff of every coefficient, standard error, and scalar that moved, old value beside new.
That capability is genuinely novel for Stata and serves the reproducibility and transparency that economics increasingly cares about.
Adjacent wins follow: machine-readable results for meta-analysis, cross-language interoperability because the same JSON reads into R and Python, and provenance if we embed the command, the depvar, N, and a hash of the input data so a result file records how it was produced.

## Shape of the tool

Three commands ship as an `.ado` package aimed at SSC.
First, serialize: dump the current `e()` to a human-readable file capturing every `e(matrix)` (not just `b` and `V`, so `gmm`'s weighting matrix and any estimator-specific matrices survive), every `e(scalar)`, every `e(macro)`, plus metadata.
Second, deserialize: reconstitute a posted `e()` via `ereturn post b V` and re-added scalars and macros, so table and graph builders run unchanged.
Third, diff: compare two serialized files and report which coefficients and scalars changed and by how much, the feature that makes the format worth adopting.

JSON is the natural container because `e()` is a nested, named, mixed object: matrices with equation-prefixed row and column names, scalars, and macros.
JSON diffs cleanly with sorted keys and one value per line.
A flat long-CSV convenience view (columns: object, name, eq, row, col, value) is worth offering for the just-the-numbers case, but the round-trippable artifact should be JSON.

## Design points that decide whether it is faithful

Full precision governs everything: encode every number at full double precision (`%21x` hex float, or `%.17g`) so the round trip is exact, because default formatting silently drops digits and breaks byte-equality of regenerated tables.
Equation names must survive, since `e(b)` carries `coleq`/`colnames` structure that the serializer has to preserve rather than flatten, the same coleq/colnames subtlety that has bitten this project before, and JSON holds it naturally.
Completeness means looping over `e(scalars)`, `e(macros)`, and `e(matrices)` and capturing all of them, so the format is estimator-agnostic rather than hardcoded to `b` and `V`.
The limits belong in the documentation up front: `e(sample)` cannot round-trip without the data (nor can a `.ster`), data-dependent post-estimation needs a data reload either way, and a few estimators set `e(cmd)`/`e(predict)` macros that specialized post-estimation reads, so those macros must be preserved for full fidelity.
The test suite is the deliverable's spine: for a spread of estimators (`regress`, `gmm`, `reghdfe`, `ivreg2`), it must assert that a table and a coefplot built from the deserialized estimate are byte-identical to those built from the `.ster`.

## Effort and staging

This is a bounded mini-project, days rather than hours, and separable from the CKT paper work.
For our immediate need, the near-term step is the smaller one you already flagged: extend the existing headlines-cache CSV export (from the 2026-05-09 headlines-cache plan) to the full set of coefficients, standard errors, and scalars, so this run's results are git-versioned and diffable even before any round-trip reader exists.
The round-trippable JSON serializer plus the diff command is the broader tool, worth doing on its own if the near-term CSV proves its value.

## Prior art (searched 2026-07-13)

The specific niche appears unfilled: no tool serializes estimation results to a git-diffable text format with a round-trip reader and a result-diff command.
Three neighbors exist, none of which occupies that niche.

`estimates save` (StataCorp, native): binary `.ster`, one-way to disk, not diffable.

`estwrite`/`estread` (Ben Jann, SSC `s450201`): the closest tool, and it beats `estimates save` on storage, not on diffability.
It stores estimation results richly on disk, can store and recover `e(sample)` via an `id()` variable (which `estimates save` cannot), preserves underscore-prefixed `e()` returns, and holds multiple estimation sets per file, with a default `.sters` extension.
It is a richer binary-style store, not a plain-text diffable format; verify the exact encoding of the `alt`/`estsave` variants before building, but nothing in its documentation offers a line-diffable text output.
Consequence: `estwrite` already owns the "store everything, including the sample, better than `.ster`" ground, so our tool's novel value narrows to the two things `estwrite` does not do, a git-diffable text format and a `estdiff`-style command that reports which coefficients moved between two runs.
Build on `estwrite`'s `id()`-based `e(sample)` reconstitution rather than reinventing it, and cite it.

`jsonio` / `StataJSON` (William Buchanan): data-to-JSON serialization via the Jackson Java library, retaining variable and value labels.
It serializes datasets, not estimation results, so it does not round-trip `e()`; it is a reference for JSON mechanics in Stata, not a competitor.

## What a .ster actually does, and what the round trip must match (from [R] estimates save)

The manual settles the "uses we could not replicate" question: after `estimates use`, "the situation is nearly identical to what it was immediately after you fit the model. The one difference is that `e(sample)` is set to 0."
So a `.ster` restores the entire `e()` namespace except the estimation-sample marker, which it deliberately zeroes because the data need not be in memory.
Everything that reads `e()` therefore works after `estimates use`: `esttab`, `coefplot`, `test`, `lincom`, `nlcom`, `lrtest`, `hausman`, and the `estat` commands that read stored results.
The commands that do not work standalone, `predict`, `margins`, `suest`, and any sample-only postestimation, need the data reloaded and `e(sample)` re-established with `estimates esample: varlist if ...`, and this is a `.ster` limitation, not something a JSON format would newly impose.

The implication is clean: a JSON round trip that captures the complete `e()` namespace (every matrix, every scalar, every macro including the dispatch macros `e(cmd)`, `e(predict)`, `e(properties)`, `e(marginsok)`, and `e(cmdline)`) and reconstitutes it via `ereturn post b V` plus re-added scalars and macros reaches full parity with `.ster`.
The one thing it does not restore, `e(sample)`, is exactly the one thing `.ster` does not restore either, and it is recovered the same way through `estimates esample:`.
The engineering care point is completeness: a naive reader that posts only `b` and `V` would break `predict`/`margins` dispatch by dropping `e(predict)`/`e(cmd)`, so the test suite must verify `predict` and `margins` parity after a data reload, not only table and coefplot parity.
