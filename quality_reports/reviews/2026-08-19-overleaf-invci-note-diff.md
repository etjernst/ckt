# Proposed Overleaf edits: table note for the 90 percent phi inversion-CI row

Date: 2026-08-19.
For Emilia to place in the Overleaf-Dropbox folder (`preamble.tex` and `main-updated.tex`); nothing here has been applied.
The five tables that carry the row are the main GRC tables for IDN, CHN, and TZA (`\GRCtable{...}{consumption}{urban}{unb}`) and the two main hukou tables (`\GRChukoutable{CHN}{consumption}{urban}{unb}{rural_first}` and `{urban_first}`); the balanced-panel, experience, birth, rural-only, and urban-only tables have no inversion row and must not get the note.

## 1. `preamble.tex`: one new macro, placed after `\GRCnotesIncomeShared` (around line 250)

```latex
% Note for the phi inversion-CI row (main GRC tables and the two main hukou tables only).
\newcommand{\invcinote}{%
  The ``90\% inv.\ CI'' row reports the 90 percent weak-identification-robust confidence set for $\phi$, obtained by inverting the linear-comparative-advantage restrictions with a restricted wild cluster bootstrap (999 draws, clustered by individual); it can be a union of intervals, reads ``empty'' when every value on the search grid is rejected, and shows $\pm\infty$ when the set reaches the edge of the search grid.
  All other inference in the table is conventional 95 percent, clustered by individual.
}
```

## 2. `preamble.tex`: append the note to the IDN canonical notes

In `\GRCnotesIDNcanonical`, change the last line

```latex
  \seclusterind{} \sigstars
```

to

```latex
  \seclusterind{} \sigstars{} \invcinote
```

## 3. `preamble.tex`: give `\GRChukoutable` an optional trailing argument for extra notes

Replace the macro header and the notes item:

```latex
\NewDocumentCommand{\GRChukoutable}{m m m m m O{}}{%
  ...
    \item \csname datasource#1#4\endcsname{} \refdatasec{} \refIDNcanon. \seclusterind{} \sigstars{} #6
```

(only the `O{}` in the argument list and the trailing `#6` change; everything else in the macro stays).

## 4. `main-updated.tex`: pass the note on the four calls that need it

Lines 728 and 729:

```latex
\GRCtable{CHN}{consumption}{urban}{unb}[\GRCnotesxref{CHN}{unb} \invcinote]
\GRCtable{TZA}{consumption}{urban}{unb}[\GRCnotesxref{TZA}{unb} \invcinote]
```

Lines 793 and 794:

```latex
\GRChukoutable{CHN}{consumption}{urban}{unb}{rural_first}[\invcinote]
\GRChukoutable{CHN}{consumption}{urban}{unb}{urban_first}[\invcinote]
```

The IDN main table (line 727) picks the note up through `\GRCnotesIDNcanonical` and needs no change.

## 5. Copy the rebuilt tables

The five `.tex` files with the 90 percent row are in `C:/git/ckt/RP7/output/tables/` (rebuilt 2026-08-19 12:37); copying them into the Overleaf `tables/` folder is additive and carries no track-changes risk.
