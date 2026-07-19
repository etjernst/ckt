# Execution manifest: literature and bibliography edit

Date: 2026-07-10

## Live-file baseline

| File | Baseline SHA-256 |
|---|---|
| `main-updated.tex` | `E34D1850259264BCA5C009D76E5AB9CD08BD985D9528A0ADFEE870FCF8A9DEEA` |
| `CKT.bib` | `5174F5E067425264079544677703633B59A93434AE6D13B7E272562D9FBCD62E` |
| protected `main.tex` | `1B013FBD8B92B91728E575C8CE1D0BFF58F89B5F81F34C1FA950CEB856443DF5` |
| protected `preamble.tex` | `3C49E5EAC0C624E139935595D07BB84068AC322056FCBA27B6A15E71F7EAAE33` |

## Applied-file hashes

| File | Final SHA-256 |
|---|---|
| `main-updated.tex` | `E188912EBE7AF4D6EB0D04CDF180E4F0A505F7010EAAF85D1A8314584B4A11B3` |
| `CKT.bib` | `27B5B0453463E5323F53B7376F6011E273D1961A69E1E1D4F41B98E826FE51B4` |

The protected-file hashes were unchanged after the copy.

## Build

- Build copy: `quality_reports/staging/2026-07-10-overleaf-build-lit/`
- Engine: MiKTeX XeTeX 3.141592653-2.6-0.999997 (MiKTeX 25.12)
- Sequence: XeLaTeX, BibTeX, XeLaTeX, XeLaTeX, all with `-halt-on-error` for XeLaTeX.
- Result: success, 66-page PDF.
- Changed citations resolved in the `.bbl`.
- Pre-existing warning retained: undefined reference `hukou` at manuscript line 762.
- Pre-existing BibTeX warnings retained for `ISSS2015`, `alvarez-cuadradoSelectionAbsoluteAdvantage2023`, `kleemansMigrationChoiceRisk`, `pulidoBarriersMobilitySorting2021`, and `worldbank2024wdi`; none was introduced by this patch.

## Audits

- Citation faithfulness: CLEAN.
- Targeted retained-entry metadata validation: CLEAN.
- Editorial residue: CLEAN.
- Humanization: CLEAN after one source-specific wording revision.
- Writing review: APPROVED.
