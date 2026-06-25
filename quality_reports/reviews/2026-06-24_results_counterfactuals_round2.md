# Copy-edit review: results_counterfactuals.tex (round 2)

Target: `C:\git\ckt\.claude\worktrees\lca-inversion\paper\results_counterfactuals.tex`
Reviewer: critic-writing
Date: 2026-06-24
Mode: full (claim-evidence findings routed through `verifier-claim` in forked context, CoVe protocol)

## Verdict

Closer, but not yet ready. Two of the four round-1 CRITICAL items are cleared: the `gaiRuralPensionsLabor2025` bib entry now exists, and the misallocation results table now exists with `\label{tab:counterfactual_misallocation}`, is `\input` at line 91, and is referenced at lines 77 and 83. The verifier independently re-confirmed in fresh context that all five bracketed magnitudes match the generated table.

Two CRITICAL items survive into round 2. The two hukou GRC table labels referenced at line 139 are still defined nowhere in the worktree, so both `\ref{}` calls will render as `??`. And the 74%/26% hukou population shares (line 80) still trace to no table; the verifier confirmed the misallocation table carries no share column. A third undefined reference surfaced this round that round 1 did not flag: `app:inversion-preview` (line 58) resolves nowhere in the paper directory despite the header comment marking it "verified."

The MAJOR draft-residue items are partly cleared (the two TODO footnotes and four inline "Author, Year, *Journal*" citations remain at lines 30, 103--104). The compound-complexity sentences flagged in round 1 were reworked but two new long-list sentences took their place. The contact clause at old line 19 is fixed.

Numeric score: 66/100 (up from 58). Three CRITICAL issues (two undefined table refs, one undefined appendix ref, and the floating hukou shares) block readiness regardless of score.

## Methodology note

I rebuilt the label inventory across `paper/main.tex`, the section file, and sibling section files in `paper/`, and routed the five load-bearing bracketed magnitudes plus the value-of-observed-migration characterization through `verifier-claim` in fresh context (no access to this draft or to my findings). The verifier confirmed: all five misallocation intervals match `RP7/output/tables/counterfactual_misallocation.tex` exactly; the table carries no 74%/26% share data and no without-fallback inflated bounds; and the Indonesia "value of observed migration" is +5.1% against a [+5.7%, +6.1%] gap, a near-1:1 ratio that bears on one prose characterization (M5 below). Mechanical findings (em dashes, headings, spelling, citation format) were checked deterministically, not through the verifier.

---

## CRITICAL

| Field | Value |
|---|---|
| Severity | CRITICAL |
| Confidence | HIGH |
| Hard rule or default | hard |
| Location | line 139, `\ref{tab:GRC_CHN_hukou_rural_first_consumption_urban_unb}` and `\ref{tab:GRC_CHN_hukou_urban_first_consumption_urban_unb}` |
| Problem | Unresolved from round 1. A Grep for either `\label{}` key across the entire worktree returns nothing. Both `\ref{}` calls will emit undefined-reference warnings and render as `??`. The generated hukou GRC table files are bare `tabular` environments with no `\caption{}\label{}`, so the labels must be supplied by `table` floats in `main.tex` that do not currently exist (or exist under different keys). |
| Suggested fix | Wrap the two hukou GRC table inputs in `main.tex` in `table` floats carrying `\caption{}\label{tab:GRC_CHN_hukou_rural_first_consumption_urban_unb}` and the urban-first analogue, or repoint the prose at whatever labels those tables actually receive. |

| Field | Value |
|---|---|
| Severity | CRITICAL |
| Confidence | HIGH |
| Hard rule or default | hard |
| Location | line 80, "$74\%$ of CHN individuals with defined hukou status" and "$26\%$"; footnote on line 80 |
| Problem | Unresolved from round 1. The China headline gap is a population-weighted aggregate of these two shares, so the shares are load-bearing for the headline number, yet they trace to no table or figure. The verifier confirmed `tab:counterfactual_misallocation` carries no share column. The footnote states the shares are "the fractions of CHN individuals classified as rural-hukou-first versus urban-hukou-first among those with defined hukou status in the estimation sample (CFPS)" but points to no table. A footnote asserting a number is not the same as a table the reader can inspect. |
| Suggested fix | Report the hukou-status shares in a descriptive or data-overview table and cite it from this sentence, replacing the bare footnote assertion. |

| Field | Value |
|---|---|
| Severity | CRITICAL |
| Confidence | HIGH |
| Hard rule or default | hard (undefined reference) |
| Location | line 58, `Appendix~\ref{app:inversion-preview}` |
| Problem | New this round (round 1 trusted the header-comment claim that this label was "verified"). A Grep for `\label{app:inversion-preview}` across `paper/*.tex` returns nothing. The reference is load-bearing: it is where the reader is sent for the joint $(\phi, \beta)$ inversion confidence region that the entire inference strategy rests on. It will render as `??`. The header comment on line 11 marks it "verified," which is now stale and itself a small instance of the sloppiness this section should avoid. |
| Suggested fix | Confirm the appendix label exists under this exact key (it may live in a section file not present in this worktree); if it does, note that in the header comment. If it does not, define the appendix or repoint the reference. Flag for HUMAN REVIEW: the appendix may live outside the paths visible to this review. |

---

## MAJOR

| Field | Value |
|---|---|
| Severity | MAJOR |
| Confidence | HIGH |
| Hard rule or default | hard |
| Location | lines 30, 103--104 (two `TODO` footnotes); line 29 ("Kennan and Walker, 2011, \emph{Econometrica}"); line 103 ("Tombe and Zhu, 2019, \emph{American Economic Review}; Fan, 2019, \emph{AEJ: Macroeconomics}") |
| Problem | Unresolved from round 1. Four citations are still hand-typed inline as "Author, Year, *Journal*" rather than `\cite{}` calls, and two TODO footnotes still flag this in the rendered text. These are draft residue that must not survive to submission, and inline-typed cites bypass the bibliography. |
| Suggested fix | Add bib entries for Kennan-Walker (2011), Tombe-Zhu (2019), Fan (2019); convert all four to `\cite{}`; delete the two TODO footnotes. The three `\emph{}` journal-name uses (lines 29, 103) disappear with the conversion. |

| Field | Value |
|---|---|
| Severity | MAJOR |
| Confidence | MEDIUM |
| Hard rule or default | hard (compound complexity) |
| Location | line 105 |
| Problem | The `gaiRuralPensionsLabor2025` sentence stacks four ideas in one ~60-word sentence: the extension of the macro template, the NRPS-as-shock identification, the embedding in a generalized-Roy GE framework "that builds on the Fan (2019) Hukou Index," an em-dash gloss of what that index is, and the 2.04-log-point result after a semicolon. One sentence, four clauses plus an em-dash aside. This is the canonical compound-complexity failure. |
| Suggested fix | Split into two or three sentences: one for what Gai et al. do (NRPS shock, GE framework), one for the Hukou Index gloss, one for the 2.04-log-point counterfactual result. |

| Field | Value |
|---|---|
| Severity | MAJOR |
| Confidence | MEDIUM |
| Hard rule or default | hard (compound complexity) |
| Location | line 28 |
| Problem | "What our identification delivers that distinguishes the exercise: trajectory-conditional returns identified from switchers and extrapolated to non-switchers through the LCA restriction, with inference propagated through the inversion confidence region rather than asymptotic standard errors that the identification boundary at $\phi = -1$ would make unreliable." One ~45-word sentence carrying the identification claim, the extrapolation claim, and the inference-method contrast in a trailing "rather than" clause that itself embeds a relative clause. The colon-fragment construction ("What X delivers: Y") also reads as a label rather than a finished sentence. |
| Suggested fix | Make the colon a full sentence and split off the inference contrast: "Our identification delivers trajectory-conditional returns identified from switchers and extrapolated to non-switchers through the LCA restriction. Inference propagates through the inversion confidence region rather than asymptotic standard errors, which the identification boundary at $\phi = -1$ would make unreliable." |

| Field | Value |
|---|---|
| Severity | MAJOR |
| Confidence | MEDIUM |
| Hard rule or default | default (define-then-use jargon) |
| Location | line 105, "the staggered rollout of the New Rural Pension Scheme (NRPS)"; line 105, "the Fan (2019) Hukou Index---an index of hukou-based migration barriers" |
| Problem | Partly cleared from round 1. NRPS is now glossed on first use, good. The Hukou Index now has an inline gloss ("an index of hukou-based migration barriers"), which is acceptable. Downgrading from round 1's MAJOR to a note: both glosses are fine; the remaining issue is purely that they sit inside the overloaded sentence flagged above (line 105 compound complexity). No separate jargon action needed. |
| Suggested fix | None beyond the line-105 split. Logged as substantially resolved. |

| Field | Value |
|---|---|
| Severity | MAJOR |
| Confidence | MEDIUM |
| Hard rule or default | default (claim-characterization precision) |
| Location | line 50 read against the Indonesia row of `tab:counterfactual_misallocation` |
| Problem | The prose at line 50 sets up the rhetorical pattern "a small value of observed migration alongside a large misallocation gap would sharpen our pro-poor finding." The verifier flagged that Indonesia does not fit this pattern: its value of observed migration is +5.1% against a misallocation gap of [+5.7%, +6.1%], a near-1:1 ratio. The pattern fits Tanzania cleanly (+4.4% against [+14.7%, +22.8%]) and the prose at line 75 correctly assigns the never-migrant-dominated story to TZA. This is not a contradiction in the current text, since line 50 is stated as a conditional ("would sharpen"), but a reader who maps the conditional onto Indonesia will be misled. Confidence MEDIUM because the claim is hedged as a conditional, not asserted of Indonesia directly. |
| Suggested fix | When the cross-country numbers are discussed (lines 77--80), state explicitly which country exhibits the small-value/large-gap pattern (Tanzania) so the conditional at line 50 is not silently read onto Indonesia, whose value of observed migration is comparable to its gap. |

---

## MINOR

| Field | Value |
|---|---|
| Severity | MINOR |
| Confidence | HIGH |
| Hard rule or default | default (active voice preferred) |
| Location | lines 53--57, now opening with "The GRC identifies each term" |
| Problem | Round 1's passive "is identified" cluster is partly addressed: line 53 now leads actively ("The GRC identifies each term"). Residual passives remain at line 56 ("are identified non-parametrically"), line 57 ("identifies"... fine), line 58 ("Inference for the aggregate proceeds by recomputing"). The density is lower than round 1; this is now a light touch rather than a cluster. |
| Suggested fix | Optional. One or two passives here read fine for rhythm; no action required for commit. |

| Field | Value |
|---|---|
| Severity | MINOR |
| Confidence | HIGH |
| Hard rule or default | default (promissory / future tense) |
| Location | lines 114--142 (hukou-counterfactual subsection): "We report two versions" (114), "We will report results both with..." (139), "is left to ongoing work" (141), "Two open implementation choices will be reported transparently" (137), "for now we report the resorting magnitude as a function of $\sigma_\eta$" (141) |
| Problem | Unresolved from round 1. The hukou-counterfactual subsection still reports no realized magnitude for its headline resorting experiment; it is described as planned ("will be reported," "left to ongoing work," "for now... as a function of $\sigma_\eta$"). This is honest and matches the voice profile's directness, but a results subsection whose headline experiment has no number is not submission-ready. The contrast with the misallocation subsection (which now has a table) is stark. |
| Suggested fix | Either run and report the resorting magnitude, or relabel `sec:hukou-counterfactual` as a planned extension so a reader does not arrive expecting a result. |

| Field | Value |
|---|---|
| Severity | MINOR |
| Confidence | HIGH |
| Hard rule or default | hard (sentence case headings) --- PASS |
| Location | lines 16, 33, 101, 144 |
| Problem | None. All four headings ("Counterfactual experiments", "Aggregate consumption gap from misallocated migration", "Removing the hukou wedge in China", "From consumption to welfare") are sentence case. Logged as a pass. |
| Suggested fix | None. |

| Field | Value |
|---|---|
| Severity | MINOR |
| Confidence | HIGH |
| Hard rule or default | hard (American English, em dashes flush) --- PASS |
| Location | whole file |
| Problem | None. American spellings throughout ("optimizing", "parameterizes", "maximizes", "non-parametrically"). All em dashes are flush (`counterfactuals---\cite`, `cousin trades`, `panels---distance`, `Index---an index`, `barrier; the urban-hukou`). No spaced em dashes. Logged as a pass. |
| Suggested fix | None. |

| Field | Value |
|---|---|
| Severity | MINOR |
| Confidence | HIGH |
| Hard rule or default | default (voice: no contact clauses) --- mostly PASS |
| Location | whole file; round-1 instance at old line 19 now reads "magnitudes that the migration literature presses on" (line 19) |
| Problem | The round-1 contact clause is fixed ("that" restored at line 19). Re-scanned all cognition/perception/communication/instruction verbs (find, show, suggest, imply, reveal, identify, report, specify, treat). No verb-complement contact clauses found. Logged clean. |
| Suggested fix | None. |

| Field | Value |
|---|---|
| Severity | MINOR |
| Confidence | MEDIUM |
| Hard rule or default | default (throat-clearing opener) --- resolved |
| Location | line 24, now "Two features distinguish this exercise." |
| Problem | Round 1's "Two features ... are worth flagging up front" is fixed; the opener now lands as a claim ("Two features distinguish this exercise."), matching the suggested round-1 fix. Logged as resolved. |
| Suggested fix | None. |

| Field | Value |
|---|---|
| Severity | MINOR |
| Confidence | LOW |
| Hard rule or default | hard (stale source comment) |
| Location | lines 8--13 (header comment block) |
| Problem | The header comment marks `app:inversion-preview` and the four `eq:` cross-references as "verified," but `app:inversion-preview` does not resolve in the available paths (see CRITICAL above). The comment is editorial residue that asserts a verification that no longer holds. Low confidence because the appendix may live outside this worktree. |
| Suggested fix | Update or delete the "verified" annotations once the appendix reference is confirmed; do not ship source comments that assert a stale verification. |

---

## Voice consistency notes

The section remains strongly in the author's voice on the positive markers. It quantifies relentlessly (five bracketed CIs now tied to a table, "roughly nine in ten individuals," "an order of magnitude smaller"), offers counter-arguments immediately and honestly ("driven by the singularity rather than honest uncertainty"; "is conservative whenever $\Delta_{d_N} > 0$"; the four-source decomposition of the intercept gap at lines 127--131 now uses the signature "First... Second... Third... Fourth..." enumeration that round 1 recommended). Limitations are stated specifically rather than with hedge words (the $\phi = -1$ boundary, the Gaussian-$\theta$ auxiliary-assumption caveat at line 68).

The round-1 voice deviations are cleared: the contact clause (line 19) is fixed, the "are worth flagging" throat-clear (line 24) is fixed, and the intercept-gap list is now enumerated. The only residual `\emph{}` uses (lines 29, 103) are citation-format artifacts that vanish with the inline-to-`\cite{}` conversion. No AI-tell vocabulary detected.

---

## Summary of blocking items (must clear before commit)

1. Two undefined hukou GRC table references (line 139) --- labels defined nowhere in the worktree. (Round 1, unresolved.)
2. 74%/26% hukou shares trace to no table (line 80); footnote asserts but does not cite. (Round 1, unresolved.)
3. Undefined appendix reference `app:inversion-preview` (line 58). (New this round; may live outside the worktree --- HUMAN REVIEW.)

Then clear the MAJOR draft-residue (two TODO footnotes, four inline citations at lines 29--30, 103--104) and the two compound-complexity sentences (lines 28, 105).

## Resolved since round 1

- `gaiRuralPensionsLabor2025` bib entry now exists (was undefined CRITICAL).
- Misallocation results table now exists, labeled, `\input` at line 91, referenced at lines 77 and 83; verifier re-confirmed all five magnitudes against it (was the floating-magnitudes CRITICAL).
- Contact clause at line 19, throat-clear at line 24, intercept-gap list now enumerated, NRPS and Hukou Index now glossed.
