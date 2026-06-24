# Table-input migration: where we stand

Date: 2026-05-13
Scope: the GRC table preamble macros (`\GRCtable`, `\GRCexptable`, `\GRChukoutable`) added 2026-04-28 and what's left to fully adopt them.

## TL;DR

Stata-side migration is done.
Paper-side migration is partial (only the canonical IDN/CHN/TZA `consumption_urban_unb` block uses the macros).
Overleaf-side table copies are stale --- the slim versions sit in `RP7/output/tables/` waiting to be copied over, but the Overleaf folder still holds the pre-migration full-envelope versions for most cells.

Three buckets to close out:

1. Paper section files: replace raw `\input{tables/...}` with macro calls in five locations.
2. Overleaf table copies: refresh them with the slim local versions, AT THE SAME TIME as bucket 1 lands (otherwise compilation breaks).
3. Housekeeping: the `temp-tables/` orphan folder in Overleaf and 54 local tables without Overleaf copies.

## What's already in place

### Stata side (in `RP7/scripts/0_programs.do`)

`grc_tex_table_trend` (line 3069) is the workhorse for all GRC cells.
The header comment at line 3048 reads:

> Phase 1b: produces a SLIM tabular-only output (no `\begin{table}`, `\caption`, `\label`, or tablenotes).
> The paper-side macros (`\GRCtable / \GRCexptable / \GRChukoutable` in preamble.tex) wrap the `\input` with the table envelope, caption, label, and notes.

This program emits `\begin{tabular}...\end{tabular}` only.
Every call site in `10_make_tables.do` routes through it (24+ calls verified by grep).
Wrapper `extras_tex_table` for the experience/birth/cnu families (line 3306) also produces slim output.

Spot-checked outputs in `RP7/output/tables/`:

- `GRC_IDN_consumption_urban_unb.tex` --- 1563 bytes, slim.
- `GRC_IDN_consumption_urban_bal.tex` --- 1563 bytes, slim.
- `GRC_CHN_hukou_rural_only_consumption_urban_unb.tex` --- slim (verified head).
- `GRC_IDN_consumption_urban_unb_exp.tex` --- 1627 bytes, slim.

So the Stata side has been writing slim tables for every GRC variant since at least May 4 (file mtime).

### Preamble side

`preamble.tex` lines 176--309 define three macros, each wrapping a `\input{tables/...}` in a full table environment with caption, label, threeparttable, and tablenotes.

- `\GRCtable{country}{depvar}{choice}{balance}[notes-override]` --- 5-col main GRC tables (`4_GrRC.do`, `5_GrRC_NonAg.do`).
- `\GRCexptable{country}{depvar}{choice}{balance}{variant}` --- 4-col experience/birth family tables (replaces the old `10`--`15`).
- `\GRChukoutable{country}{depvar}{choice}{balance}{hukou}` --- hukou subgroup tables (`7_GrRC_hukou.do`).

Captions and notes draw on smaller helper macros (`\countryname...`, `\depvar...`, `\datasource...`, `\GRCnotesIDNcanonical`, `\GRCnotesIncomeShared`).

### Paper side, partially

`sec_results.tex` lines 98--100 already use `\GRCtable` for the canonical IDN/CHN/TZA `consumption_urban_unb` triple, with the `[\GRCnotesIDNcanonical]` notes override on the IDN row.

This is the only place currently using the new macros.

### Copy mechanism

`copyOverleaf` program at `0_programs.do:165` copies one file via Stata's `copy ..., replace`.
`10_make_tables.do` calls it after each GRC cell behind an `if $copyOverleaf == 1` gate.
So when the pipeline runs with `$copyOverleaf = 1`, every freshly-emitted slim table flows to Overleaf.

The Overleaf table folder hasn't been refreshed since the migration: `GRC_IDN_consumption_urban_bal.tex` in Overleaf is 2592 bytes dated Apr 28 (old full envelope), while the local copy is 1563 bytes dated May 4 (new slim).

## What's pending

### Bucket 1: paper section files still using raw `\input{}`

Five locations.
In each, the macro call sits next to the raw `\input{}` as a commented-out line.

In `sec_results.tex`:

```latex
% line 165-168 (CHN hukou)
% \GRChukoutable{CHN}{consumption}{urban}{unb}{rural_first}
% \GRChukoutable{CHN}{consumption}{urban}{unb}{urban_first}
\input{tables/GRC_CHN_hukou_rural_first_consumption_urban_unb}
\input{tables/GRC_CHN_hukou_urban_first_consumption_urban_unb}
```

In `sec_robustness.tex`:

```latex
% line 11-16 (IDN/CHN/TZA balanced panel)
% \GRCtable{IDN}{consumption}{urban}{bal}
% \GRCtable{CHN}{consumption}{urban}{bal}
% \GRCtable{TZA}{consumption}{urban}{bal}
\input{tables/GRC_IDN_consumption_urban_bal}
\input{tables/GRC_CHN_consumption_urban_bal}
\input{tables/GRC_TZA_consumption_urban_bal}
```

In `app_balanced.tex`:

```latex
% line 9-11 (mirror of the robustness section)
% \input{tables/GRC_IDN_consumption_urban_bal}
% \input{tables/GRC_CHN_consumption_urban_bal}
% \input{tables/GRC_TZA_consumption_urban_bal}
```

In `app_hukou.tex`:

```latex
% line 5-8 (CHN hukou rural_only / urban_only)
% \GRChukoutable{CHN}{consumption}{urban}{unb}{rural_only}
% \GRChukoutable{CHN}{consumption}{urban}{unb}{urban_only}
\input{tables/GRC_CHN_hukou_rural_only_consumption_urban_unb}
\input{tables/GRC_CHN_hukou_urban_only_consumption_urban_unb}
```

In `app_nonag.tex`:

```latex
% line 7-8 (IDN consumption nonag unb)
% \GRCtable{IDN}{consumption}{nonag}{unb}
\input{tables/GRC_IDN_consumption_nonag_unb}
```

### Bucket 2: stale Overleaf table copies

Inventory:

- Overleaf `tables/` holds 58 `.tex` files.
- Local `RP7/output/tables/` holds 112.
- 54 local tables don't have Overleaf copies at all (mostly the extras-family `_exp`, `_exp_max`, etc. and various variants).
- For the 58 that DO exist on both sides, several are stale full-envelope copies from before the migration (e.g. `GRC_IDN_consumption_urban_bal.tex`).

The mtime gap (Apr 28 on Overleaf vs May 4 locally) confirms the pipeline hasn't been run with `$copyOverleaf=1` since the migration.

### Bucket 3: housekeeping

`temp-tables/` exists in Overleaf with two orphan files (`GRC_IDN_consumption_urban_unb.tex`, `GRC_TZA_consumption_urban_unb.tex`).
Not referenced by `main-sections.tex` or any sibling section file based on a grep.
Looks like leftover from an earlier experiment; can be cleaned up.

## The ordering trap

Updating the paper side first and the Overleaf tables later (or vice versa) breaks compilation.

- If we uncomment a `\GRCtable{IDN}{consumption}{urban}{bal}` call but the Overleaf `tables/GRC_IDN_consumption_urban_bal.tex` is still the old full envelope (its own `\begin{table}`), the macro's `\input` puts a `\begin{table}` inside another `\begin{table}` --- LaTeX errors out.
- If we refresh the Overleaf table with the slim version but the paper still does raw `\input{tables/...}` with no surrounding `\begin{table}`, the cell renders as a bare tabular floating in the page --- no caption, no label, broken cross-references.

So bucket 1 and bucket 2 must land together for each cell, ideally in a single commit on the paper side plus one Overleaf-folder update that the user does manually.

## Proposed path forward

Three options for how to actually execute the migration:

### Option A: run the pipeline with `$copyOverleaf=1` and update sections at the same time

- Set `global copyOverleaf 1` (default is already 1; the user just needs the local `$overleaf` global to point at the Dropbox-Overleaf folder).
- Run `10_make_tables.do` standalone (no estimation needed; reads existing sters).
- All 112 local tables fan out to the Overleaf `tables/` folder.
- User then edits `main-sections.tex` and the four section files to swap raw `\input{}` for macro calls (five locations total).
- Compile; verify.

This is the cleanest path.
Risk: the user's repeated rule is to keep edits to `main-sections.tex` minimal and gated on explicit approval, so they would want to see the specific edits before they land.

### Option B: manually refresh only the eight tables we're actively switching to macros

Only the eight tables backing the five edit locations actually need refreshing today.
The other 50-ish stale tables can wait until the next pipeline run.

Eight tables:

- `GRC_CHN_hukou_rural_first_consumption_urban_unb.tex`
- `GRC_CHN_hukou_urban_first_consumption_urban_unb.tex`
- `GRC_IDN_consumption_urban_bal.tex`
- `GRC_CHN_consumption_urban_bal.tex`
- `GRC_TZA_consumption_urban_bal.tex`
- `GRC_CHN_hukou_rural_only_consumption_urban_unb.tex`
- `GRC_CHN_hukou_urban_only_consumption_urban_unb.tex`
- `GRC_IDN_consumption_nonag_unb.tex`

The user copies these eight from `RP7/output/tables/` to the Overleaf `tables/` folder by hand (or runs a targeted Stata `copy` block).
Then the paper-side edits land.

### Option C: do nothing yet

Defer the full migration until after PR-7 lands.
The paper currently compiles fine because the raw `\input{}` lines + stale full-envelope tables are internally consistent.

## Things to confirm before any edit

- Should the migration also cover OLS and summary-stats tables?
  Today those are still full-envelope on both sides (e.g. `OLS_consumption_urban_unb.tex` has `\begin{table}` baked in, with matching `\input{tables/OLS_...}` in the section files).
  No preamble macro exists for them, so they're a separate (larger) project.
- Should `temp-tables/` in Overleaf be deleted, kept, or left alone?
- The five edit locations would be touching `main-sections.tex` (via its `\input{}` of `sec_results.tex`, `sec_robustness.tex`, `app_balanced.tex`, `app_hukou.tex`, `app_nonag.tex`).
  None of these are `main.tex`.
  All five files appear to be currently editable per the Overleaf rules in memory.

## Recommendation

Option B if we want this done in this branch; Option A if we want it done thoroughly and we're OK with a wider Overleaf sync.
Option C is reasonable if PR-7 review is imminent and we don't want scope creep.
