# Paper table text extraction (Phase 1b.1)

Extracted from `RP7/scripts/{5,6,8,10-16}_*.do` on 2026-04-28.
Purpose: catalog every caption / notes / postfoot block currently emitted into `RP7/output/tables/GRC_*.tex` so the paper-side macro design (Phase 1b.2) can faithfully migrate them.

Country-specific and depvar-specific information is called out **explicitly** below (per user direction) so each piece can become its own macro component, not blended.

## 1. Caption pattern

All captions follow a strict generative template:

```
Restricted GRC Estimates of the Returns to <TREATMENT> on log <DEPVAR_PROSE> <CONNECTOR> <COUNTRYNAME>[, <MODIFIER>]
```

| Slot | Values | Source |
|------|--------|--------|
| `<TREATMENT>` | `Urban Location` \| `Non-Agricultural Sector` | choice variable |
| `<DEPVAR_PROSE>` | `Consumption` \| `Income` | depvar |
| `<CONNECTOR>` | `in` (for cons specs) \| `,` (for income specs) | depvar |
| `<COUNTRYNAME>` | `Indonesia` \| `China` \| `Tanzania` | country |
| `<MODIFIER>` (optional, comma-separated) | see modifier table below | balance / variant |

Modifier values:

| Modifier (in caption) | Source |
|-----------------------|--------|
| `Balanced Panel` | `balance==bal` |
| `Experience Controls` | from 10 |
| `Max Experience Controls` | from 11 |
| `Experience Share Controls` | from 12 |
| `Max Experience Share Controls` | from 13 |
| `Urban Birth Controls` | from 15 |
| `Rural Hukou First` | from 8 §1-3 |
| `Urban Hukou First` | from 8 §4-6 |
| `Only Rural Hukou` | from 8 §7-9 |
| `Only Urban Hukou` | from 8 §10-12 |

Modifiers can stack with comma separation, e.g. `Balanced Panel, Max Experience Share Controls` (from 13's §2 cells) or `Balanced Panel, Rural Hukou First` (from 8's §2 cells).

For the **heterogeneity tables** (`16_heterogeneity_tables.do`), the template is different:
```
Heterogeneity in Restricted GRC <Delta|Mu> Estimates of the Returns to Urban Location on log Consumption in <COUNTRYNAME>
```

## 2. Label pattern

All labels follow:
```
\label{tab:GRC_<COUNTRY>_<depvar>_<choice>_<balance>[_<variant>]}
```
where `<COUNTRY>` is `IDN`/`CHN`/`TZA`, `<variant>` is the .tex filename variant token (e.g. `_exp`, `_exp_max`, `_exp_sh`, `_exp_m_sh`, `_birth`, `_hukou_rural_first`).

Heterogeneity tables use:
```
\label{tab:hetDelta_table_<COUNTRY>}   or   \label{tab:hetmu_table_<COUNTRY>}
```

## 3. Notes templates

Five distinct note templates currently in use.

### Template A: Canonical full-prose notes (IDN cons/urban/unb only)

`5_GrRC.do` line 354. Used ONLY for the IDN/cons/urban/unb table; every other table cross-references this one.

```
This table uses data from the Indonesia Family Life Survey.
Please refer to Section \ref{sec:data} for further details on the data.
The dependent variable is the log of total consumption per capita.
Urban is an indicator equal to one for individuals who report living in a city or town, as opposed to a village.
Individuals are assigned to trajectories based on their location history across the survey waves.
This table reports the extrapolated returns to migrating to an urban location for individuals who are never observed in an urban location in the data.
Columns (2) to (5) include time (survey wave) fixed effects, column (3) adds a female indicator, column (4) adds age squared, and column (5) adds education (years of schooling, maximum across periods) and its square.
We report robust standard errors, clustered at the individual level, in parentheses.
Stars denote: $^{*} p<0.10$; $^{**} p<0.05$; $^{***} p<0.01$.
```

**Components:**
- `<DATASOURCE>` (country-specific): `the Indonesia Family Life Survey`
- `<DEPVAR_PROSE>` (depvar-specific): `log of total consumption per capita`
- Variable explanations (treatment + trajectories + columns) --- shared across all main GRC tables conceptually but only spelled out here
- `<SECLUSTERIND>` (constant): `We report robust standard errors, clustered at the individual level, in parentheses.`
- `<SIGSTARS>` (constant): `Stars denote: $^{*} p<0.10$; $^{**} p<0.05$; $^{***} p<0.01$.`

### Template B: Standard cross-ref notes (most cells)

Used for: 5_GrRC.do CHN/TZA cons unb, all 6 cons bal cells, and 10/11/12/13/15 cells (with variant-specific data-source-line variant for balanced panel).

```
This table uses[ the balanced panel from] data from <DATASOURCE>.
Please refer to Section \ref{sec:data} for further details on the data and to the notes of Table \ref{tab:GRC_IDN_consumption_urban_unb} for additional information on the variables.
We report robust standard errors, clustered at the individual level, in parentheses.
Stars denote: $^{*} p<0.10$; $^{**} p<0.05$; $^{***} p<0.01$.
```

**Country-specific datasource sentence:**

| Country | Unbalanced version | Balanced version |
|---------|---------------------|------------------|
| IDN | `This table uses data from the Indonesia Family Life Survey.` | `This table uses the balanced panel from the Indonesia Family Life Survey.` |
| CHN | `This table uses data from the China Family Panel Survey.` | `This table uses the balanced panel from the China Family Panel Survey.` |
| TZA | `This table uses data from the National Panel Survey from Tanzania.` | `This table uses the balanced panel from the Tanzanian National Panel Survey.` (note: word order different for TZA balanced!) |

### Template C: Income canonical notes (income/urban/unb, all 3 countries share)

`5_GrRC.do` line 1171 --- ONE notes block reused across IDN/CHN/TZA income tables (no cross-ref pattern in the income section). Slightly different prose than Template A: drops the "uses data from X" line entirely, opens with `The dependent variable is...`.

```
The dependent variable is the log of income per capita.
Urban is an indicator equal to one for individuals who report living in a city or town, as opposed to a village.
Individuals are assigned to trajectories based on their location history across the survey waves.
This table reports the extrapolated returns to migrating to an urban location for individuals who are never observed in an urban location in the data.
Columns (2) to (5) include time (survey wave) fixed effects, column (3) adds a female indicator, column (4) adds age squared, and column (5) adds education (years of schooling, maximum across periods) and its square.
We report robust standard errors, clustered at the individual level, in parentheses.
Stars denote: $^{*} p<0.10$; $^{**} p<0.05$; $^{***} p<0.01$.
```

**Note:** this template currently does NOT vary across countries even though country differs. That's a quirk of the existing pipeline (RA wrote one notes block for all 3). Probably should be one of:
- (a) keep current behavior --- one notes block reused across IDN/CHN/TZA income tables (less informative; doesn't say which dataset)
- (b) align with Template B and add per-country datasource lines --- more informative but a paper-text change

**Decision needed at Phase 1b.2 (macro design):** which behavior to preserve. **Lean: (a) for bit-identical reproducibility.** If we want to change the prose, that's a separate decision.

### Template D: Heterogeneity table notes (16, IDN canonical)

`16_heterogeneity_tables.do` IDN cells (Delta and Mu). Long-form prose. Not directly read this turn; see 16_heterogeneity_tables.do lines 333--378.

### Template E: Heterogeneity cross-ref (16, CHN/TZA cells)

`16_heterogeneity_tables.do` CHN/TZA. Cross-references Template D's IDN heterogeneity table:
```
This table uses data from <DATASOURCE>.
Please refer to Section \ref{sec:data} ... and to the notes of Table \ref{tab:hetDelta_table_IDN} (or \ref{tab:hetmu_table_IDN}) for additional information on the variables.
<SECLUSTERIND>
<SIGSTARS>
```

## 4. Postfoot indicator rows

Two patterns currently exist.

### Postfoot pattern P1 (5-column tables: 5/6/8 main GRC)

```
Time FE & & Y & Y & Y & Y \\
Covariates & & & Female & \& Age$^2$ & All \\
\bottomrule
\end{tabular}
\begin{tablenotes}[flushleft] \footnotesize \item{`table_notes'} \end{tablenotes}
\end{threeparttable}
\end{table}
```

The first 2 lines (Time FE + Covariates indicator rows) are the **DATA** that must remain in the .do output --- they tell readers which cols include FE / female / age² / etc.
Everything from `\bottomrule` onward is wrapper that moves to the paper macros.

Used by: 5_GrRC.do (all sections), 6_GrRC_NonAg.do, 8_GrRC_hukou.do, 15_GrRC_birth.do (4 columns variant exists too --- see P2).

### Postfoot pattern P2 (4-column tables: 10/11/12/13/14/15 experience+birth families)

To be confirmed by reading 10/14/15's `local postfoot_str`. Likely shape:
```
Time FE & Y & Y & Y & Y \\
Covariates & <regressor> & <regressor> & + Age$^2$ & All \\
\bottomrule \end{tabular} \begin{tablenotes}...
```

Different from P1 because:
- Only 4 cells, not 5 (no "no covariates" baseline column)
- First Time FE column is "Y" not blank (every cell includes time FE)
- Covariates row starts with the variant regressor, not blank

This needs a per-variant value for the regressor name in the indicator row.
**TODO at Phase 1b.3:** read the postfoot from 10's source explicitly to confirm shape.

### Postfoot pattern P3 (heterogeneity tables, 16)

```
Time FE & Y \\
Covariates & All \\
\bottomrule \end{tabular} \begin{tablenotes}...
```

Single-column tables. Verified at lines 344, 377, 416, 449, 488, 521 of 16.

## 5. Cell-by-cell catalog

### 5_GrRC.do --- 9 cells (3 specs × 3 countries)

| Cell | Caption modifier | Notes template | Postfoot |
|------|------------------|----------------|----------|
| IDN cons urban unb | (none) | A (canonical) | P1 |
| CHN cons urban unb | (none) | B (cross-ref → IDN cons unb) | P1 |
| TZA cons urban unb | (none) | B (cross-ref → IDN cons unb) | P1 |
| IDN cons urban bal | Balanced Panel | B (cross-ref → IDN cons unb) | P1 |
| CHN cons urban bal | Balanced Panel | B (cross-ref → IDN cons unb) | P1 |
| TZA cons urban bal | Balanced Panel | B (cross-ref → IDN cons unb) | P1 |
| IDN income urban unb | (none, comma-form caption) | C (income canonical, shared) | P1 |
| CHN income urban unb | (none, comma-form caption) | C (income canonical, shared) | P1 |
| TZA income urban unb | (none, comma-form caption) | C (income canonical, shared) | P1 |

### 6_GrRC_NonAg.do --- 1 cell

| Cell | Caption modifier | Notes template | Postfoot |
|------|------------------|----------------|----------|
| IDN cons nonag unb | (none, treatment="Non-Agricultural Sector") | B (cross-ref → IDN cons unb) | P1 |

### 8_GrRC_hukou.do --- 12 cells (4 hukou subgroups × 3 specs)

All cells: country=CHN, treatment="Urban Location", depvar varies, balance varies.

| Cell | Caption modifier(s) | Notes template | Postfoot |
|------|---------------------|----------------|----------|
| CHN cons urban unb (4 hukou) | `<HukouModifier>` | B (CHN cross-ref) | P1 |
| CHN cons urban bal (4 hukou) | `Balanced Panel, <HukouModifier>` | B (CHN balanced cross-ref) | P1 |
| CHN income urban unb (4 hukou) | `<HukouModifier>` (income comma-form) | (TBD --- check whether income notes are shared template C or per-table) | P1 |

### 10_GrRC_experience.do --- 9 cells (3 specs × 3 countries)

Variant token: `exp`. Family file output names: `GRC_<c>_<depvar>_<choice>_<balance>_exp`.

| Cell | Caption modifier | Notes template |
|------|------------------|----------------|
| IDN cons urban unb exp | Experience Controls | (TBD --- canonical for IDN-exp?) |
| CHN cons urban unb exp | Experience Controls | B (cross-ref → IDN cons unb) |
| TZA cons urban unb exp | Experience Controls | B (cross-ref → IDN cons unb) |
| IDN cons urban bal exp | Balanced Panel, Experience Controls | B-balanced |
| CHN cons urban bal exp | Balanced Panel, Experience Controls | B-balanced |
| TZA cons urban bal exp | Balanced Panel, Experience Controls | B-balanced |
| IDN income urban unb exp | Income comma-form, Experience Controls | C (income shared)? |
| CHN income urban unb exp | Income comma-form, Experience Controls | C (income shared)? |
| TZA income urban unb exp | Income comma-form, Experience Controls | C (income shared)? |

Same shape for 11 (`exp_max`, modifier=`Max Experience Controls`), 12 (`exp_sh`, `Experience Share Controls`), 13 (`exp_m_sh`, `Max Experience Share Controls`).

### 14_GrRC_NonAg_experience.do --- 4 cells (4 variants × IDN nonag)

| Cell | Caption modifier | Notes template |
|------|------------------|----------------|
| IDN cons nonag unb exp | Experience Controls (Non-Agricultural Sector treatment) | (TBD) |
| IDN cons nonag unb exp_max | Max Experience Controls | (TBD) |
| IDN cons nonag unb exp_sh | Experience Share Controls | (TBD) |
| IDN cons nonag unb exp_m_sh | Max Experience Share Controls | (TBD) |

### 15_GrRC_birth.do --- 4 cells (4 specs × IDN birth)

| Cell | Caption modifier | Notes template |
|------|------------------|----------------|
| IDN cons urban unb birth | Urban Birth Controls | (TBD) |
| IDN cons urban bal birth | Balanced Panel, Urban Birth Controls | B-balanced |
| IDN income urban unb birth | Urban Birth Controls (income comma-form) | C? |
| IDN cons nonag unb birth | Urban Birth Controls (Non-Agricultural Sector treatment) | (TBD) |

### 16_heterogeneity_tables.do --- 6 cells (2 stat × 3 countries)

| Cell | Caption | Notes template |
|------|---------|----------------|
| IDN Delta | Heterogeneity in Restricted GRC Delta Estimates of the Returns to Urban Location on log Consumption in Indonesia | D (canonical hetDelta) |
| CHN Delta | ... in China | E (cross-ref → hetDelta_IDN) |
| TZA Delta | ... in Tanzania | E (cross-ref → hetDelta_IDN) |
| IDN Mu | Heterogeneity in Restricted GRC Mu Estimates of the Returns to Urban Location on log Consumption in Indonesia | D (canonical hetmu) |
| CHN Mu | ... in China | E (cross-ref → hetmu_IDN) |
| TZA Mu | ... in Tanzania | E (cross-ref → hetmu_IDN) |

## 6. Total tables to migrate

53 GRC tables + 6 heterogeneity tables = **59 paper-side macro calls** to write in Phase 1b.4.

Of those, **12 hukou tables (in 8_GrRC_hukou.do)** may not all be currently referenced in `main-sections.tex`; **TBD at Phase 1b.4** whether to add them all or only the ones the paper currently uses.

## 7. Questions for macro design (Phase 1b.2)

1. **Income notes template C** --- preserve as-is (one shared block, no per-country datasource line) for bit-identical reproducibility, or align with Template B (per-country datasource)? **Recommend (a) preserve.**
2. **Country-specific data source phrasing** --- is "the National Panel Survey from Tanzania" (TZA unb) vs "the Tanzanian National Panel Survey" (TZA bal) a typo or intentional? Different word order. **Recommend: preserve both (a paper-prose decision is out of scope for this refactor).**
3. **TZA balanced datasource word order** --- currently "the Tanzanian National Panel Survey" (different from unb). Same recommendation: preserve.
4. **Hukou table inputs** --- only some are currently in main-sections.tex (likely 4: rural_first cuu, urban_first cuu, rural_only cuu, urban_only cuu). TBD at 1b.4.
5. **TODO marked (TBD)** items: postfoot patterns P2 for 10-15, notes templates for IDN-exp / IDN-birth / income+variant cells. Resolved by direct read of source files at Phase 1b.3 when modifying `grc_tex_table_trend*` programs.
