# Copy-edit review: results_counterfactuals.tex (round 1)

Target: `C:\git\ckt\.claude\worktrees\lca-inversion\paper\results_counterfactuals.tex`
Reviewer: critic-writing
Date: 2026-06-24
Mode: full (claim-evidence findings routed through `verifier-claim` in forked context, CoVe protocol)

## Verdict

Not ready. Three CRITICAL issues block readiness regardless of score: an undefined citation, two undefined table references, and load-bearing empirical magnitudes that the section never points the reader to a table for. The prose is strong and largely in the author's voice, but the section reads as a working draft: it contains two `TODO` footnotes, two inline "Author, Year, *Journal*" citations not yet converted to `\cite{}`, and several promises that results "will be reported." None of that is submission-grade.

Numeric score: 58/100 (hard rules 60% weight carry the CRITICAL/MAJOR load here; the prose-quality and voice components score well).

## Methodology note

I built a label inventory across `paper/main.tex` and the section file, and routed four load-bearing claims through `verifier-claim` in fresh context (it had no access to this draft). The verifier independently confirmed: the Tanzania and China gap magnitudes DO match a generated table `RP7/output/tables/counterfactual_misallocation.tex`; the two hukou GRC table labels are defined nowhere; the 74%/26% shares trace to no table; the 2.04-log-point figure is an external citation with no internal support. Findings C1--C4 below incorporate the verifier's independent verdicts.

---

## CRITICAL

| Field | Value |
|---|---|
| Severity | CRITICAL |
| Confidence | HIGH |
| Hard rule or default | hard |
| Location | line 100, `\cite{gaiRuralPensionsLabor2025}` |
| Problem | Undefined citation: `gaiRuralPensionsLabor2025` is cited but has no entry in `paper/CKT.bib` (Grep returned zero occurrences); the other five keys used in the section all resolve. |
| Suggested fix | Add the bib entry for Gai et al. (2025) to `CKT.bib`, or remove the cite until the entry exists. |

| Field | Value |
|---|---|
| Severity | CRITICAL |
| Confidence | HIGH |
| Hard rule or default | hard |
| Location | line 129, `\ref{tab:GRC_CHN_hukou_rural_first_consumption_urban_unb}` and `\ref{tab:GRC_CHN_hukou_urban_first_consumption_urban_unb}` |
| Problem | Both table labels are referenced but never defined. Verifier (C3) confirmed no `\label{}` with either key exists anywhere in the worktree; the generated table `.tex` files in `RP7/output/tables/` are bare `tabular` environments with no `\caption{}\label{}`, and the `\input{}` calls in `main.tex` are not wrapped in a `table` float. Both `\ref{}` calls will emit undefined-reference warnings and render as `??`. |
| Suggested fix | Wrap the two hukou table inputs in `main.tex` in `table` floats carrying the matching `\caption{}\label{...}`, or point the prose at whatever labels those tables actually receive. |

| Field | Value |
|---|---|
| Severity | CRITICAL |
| Confidence | HIGH |
| Hard rule or default | hard |
| Location | lines 77--79, 83--84, 94 (all bracketed-magnitude sentences); also the cross-country results paragraph generally |
| Problem | The section reports specific empirical magnitudes ($[+5.7\%, +6.1\%]$ for IDN, $[+14.7\%, +22.8\%]$ for TZA, $[+7.5\%, +8.8\%]$ for CHN, the hukou-regime splits, and the without-fallback inflated bounds $+58.0\%$/$+145.0\%$) but never inputs or references any table for them. Verifier (C1, C2) confirmed these numbers match the generated table `RP7/output/tables/counterfactual_misallocation.tex`, so the numbers are correct, but a Grep confirms that table is never `\input` or `\ref`'d in the manuscript. An empirical claim the reader cannot trace to a table in the document violates the hard claim-evidence rule even when the underlying number is right. |
| Suggested fix | Add the misallocation results table to `main.tex` with a `\label{}`, and add `(Table~\ref{...})` pointers to the cross-country and hukou-regime result sentences. |

| Field | Value |
|---|---|
| Severity | CRITICAL |
| Confidence | HIGH |
| Hard rule or default | hard |
| Location | line 79, "$74\%$ of CHN individuals with defined hukou status" and "$26\%$" |
| Problem | The population shares that the China aggregate is weighted by trace to no table or figure. Verifier (C2) found no internal table reporting the 74%/26% split. The China headline gap is a population-weighted aggregate of these two shares, so the shares are load-bearing for the headline number, yet they float without a source. |
| Suggested fix | Report the hukou-status shares in a descriptive table (or the data-overview table) and cite it, or footnote the source. |

---

## MAJOR

| Field | Value |
|---|---|
| Severity | MAJOR |
| Confidence | HIGH |
| Hard rule or default | hard |
| Location | lines 29, 99 (two `TODO` footnotes); lines 28, 98 ("Kennan and Walker, 2011, \emph{Econometrica}"; "Tombe and Zhu, 2019, \emph{American Economic Review}; Fan, 2019, \emph{AEJ: Macroeconomics}") |
| Problem | Four citations are hand-typed inline as "Author, Year, *Journal*" rather than `\cite{}` calls, and two `TODO` footnotes flag this in the rendered text. These are draft residue that must not survive to submission, and inline-typed cites bypass the bibliography. |
| Suggested fix | Add bib entries for Kennan-Walker (2011), Tombe-Zhu (2019), Fan (2019); convert all four to `\cite{}`; delete the two TODO footnotes. |

| Field | Value |
|---|---|
| Severity | MAJOR |
| Confidence | HIGH |
| Hard rule or default | hard (per voice profile section 6: no contact clauses) |
| Location | line 19, "magnitudes the migration literature presses on" |
| Problem | Contact clause: relative-clause "that" omitted after "magnitudes" ("magnitudes [that] the migration literature presses on"). The voice profile flags dropped subordinators. (This is a relative clause rather than a verb-complement clause, but the same explicit-subordination preference applies; flag is MINOR-to-MAJOR by the voice rule. Listed here once.) |
| Suggested fix | "magnitudes that the migration literature presses on". |

| Field | Value |
|---|---|
| Severity | MAJOR |
| Confidence | MEDIUM |
| Hard rule or default | hard (compound complexity) |
| Location | line 25 |
| Problem | The opening sentence of the second paragraph stacks three independent ideas: the tradition placement, a three-item em-dash list of structural-migration precedents, and an "and at the intersection with" clause, plus a trailing footnote. One sentence, far more than two clauses, and the em-dash aside itself carries an enumerated three-citation list. The 50-plus-word sentence carries multiple ideas. |
| Suggested fix | Split into two sentences: one placing the exercise in the structural-migration tradition, one connecting to the misallocation strand. |

| Field | Value |
|---|---|
| Severity | MAJOR |
| Confidence | MEDIUM |
| Hard rule or default | hard (compound complexity) |
| Location | line 122 |
| Problem | "The intercept gap $\beta^{rh} - \beta^{uh}$ absorbs four sources in principle:" followed by a four-item comma-and-clause list inside one sentence. The four sources are themselves multi-word clauses ("the pecuniary urban premium net of cost-of-living," "compensating differentials for non-pecuniary location amenities," ...), making a single sentence carry four distinct ideas. |
| Suggested fix | Recast as an enumerated "First... Second... Third... Fourth..." structure (the author's signature move per the voice profile), or break into two sentences. |

| Field | Value |
|---|---|
| Severity | MAJOR |
| Confidence | MEDIUM |
| Hard rule or default | hard (compound complexity) |
| Location | line 124 |
| Problem | "The resorting version then simulates which rural-hukou workers would select urban under the no-barrier rule, computes the aggregate consumption gain, and decomposes that gain into [piece A] (who...) and [piece B] (who...)." Three coordinated verbs plus two parenthetical asides in one sentence. More than one parenthetical aside is itself a flagged pattern. |
| Suggested fix | Split after "consumption gain." Make the decomposition its own sentence, and move at least one parenthetical into the main clause. |

| Field | Value |
|---|---|
| Severity | MAJOR |
| Confidence | MEDIUM |
| Hard rule or default | hard (define-then-use jargon) |
| Location | line 100, "the staggered NRPS rollout"; line 100, "the Fan (2019) Hukou Index" |
| Problem | "NRPS" appears with no gloss on first use. A reader of an applied-migration section will not necessarily know NRPS = New Rural Pension Scheme. "Hukou Index" is also a named term-of-art introduced without definition. |
| Suggested fix | Gloss inline: "the staggered New Rural Pension Scheme (NRPS) rollout". Briefly say what the Fan (2019) Hukou Index measures. |

| Field | Value |
|---|---|
| Severity | MAJOR |
| Confidence | MEDIUM |
| Hard rule or default | hard (\emph{} sparingly) |
| Location | lines 28, 29, 98 (`\emph{Econometrica}`, `\emph{American Economic Review}`, `\emph{AEJ: Macroeconomics}`) |
| Problem | `\emph{}` used to italicize journal names in hand-typed citations. This is a symptom of the inline-citation problem (MAJOR above): once converted to `\cite{}`, the journal italics belong to the bibliography style, not the prose. Flagging because the rule is "\emph{} extremely sparingly" and these are the only `\emph{}` uses in the file. |
| Suggested fix | Resolve with the inline-to-`\cite{}` conversion; the `\emph{}` disappears. |

---

## MINOR

| Field | Value |
|---|---|
| Severity | MINOR |
| Confidence | HIGH |
| Hard rule or default | default (voice: no contact clauses; flag every instance) |
| Location | line 73, "roughly nine in ten individuals sit in that cell" is fine; but line 66, "would imply $\hat\Delta_{d_N} < 0$, contradicting..." — check; primary instance: line 117, "the true gain from removing the barrier exceeds this floor because optimal sort would select..." (no "that" needed, fine). Confirmed contact-clause instance: line 19 (logged above). No additional verb-complement "that"-drops found. |
| Problem | Scanned all cognition/communication/instruction verbs (find, show, suggest, imply, reveal, identify, report). No verb-complement contact clauses beyond the relative-clause case at line 19. Logging the clean result so round 2 does not re-scan. |
| Suggested fix | None beyond line 19. |

| Field | Value |
|---|---|
| Severity | MINOR |
| Confidence | HIGH |
| Hard rule or default | default (minimize "it is worth ...") |
| Location | line 24, "Two features of this exercise are worth flagging up front." |
| Problem | "are worth flagging" is the throat-clearing variant of "it is worth noting," which the voice profile explicitly lists under avoid. It also delays the content by one sentence. |
| Suggested fix | Lead with the first feature directly, or "Two features distinguish this exercise." |

| Field | Value |
|---|---|
| Severity | MINOR |
| Confidence | MEDIUM |
| Hard rule or default | default (topic sentences make claims, not labels) |
| Location | line 34, "The aggregate misallocation gap brackets observed migration against two extremes." |
| Problem | Acceptable as a claim, but the following sentences (35--36) are sentence fragments: "At one end, a no-further-migration scenario in which..." and "At the other end, a world of optimal sort, where..." have no main verb. Fragments read as note-taking rather than finished prose. |
| Suggested fix | "At one end sits a no-further-migration scenario in which..."; "At the other end lies a world of optimal sort, where...". |

| Field | Value |
|---|---|
| Severity | MINOR |
| Confidence | MEDIUM |
| Hard rule or default | default (active voice preferred) |
| Location | lines 52--56 ("is identified by", "are identified non-parametrically", "is identified from", "is identified by") |
| Problem | A cluster of passive "is identified" constructions. The agent (the GRC, the LCA inversion, the extrapolation) is named in each case, so these fall on the active-voice-preferred side rather than the carve-out side. The density is what draws the eye; one or two are fine. |
| Suggested fix | Vary: "The GRC identifies each term"; "The LCA inversion identifies $\Delta_{d_T}$"; keep one or two passives for rhythm. Lower priority than the CRITICAL items. |

| Field | Value |
|---|---|
| Severity | MINOR |
| Confidence | HIGH |
| Hard rule or default | hard (sentence case headings) — PASS |
| Location | lines 16, 32, 96, 134 |
| Problem | None. All four headings ("Counterfactual experiments", "Aggregate consumption gap from misallocated migration", "Removing the hukou wedge in China", "From consumption to welfare") are correctly sentence case. Logged as a pass so round 2 skips it. |
| Suggested fix | None. |

| Field | Value |
|---|---|
| Severity | MINOR |
| Confidence | HIGH |
| Hard rule or default | hard (American English, em dashes flush) — PASS |
| Location | whole file |
| Problem | None. American spellings throughout ("optimizing", "parameterizes", "behavior"-class words absent but no British forms found). All em dashes are flush (`counterfactuals---\cite`, `cousin trades`, `panels---distance`). No spaced em dashes. Logged as a pass. |
| Suggested fix | None. |

| Field | Value |
|---|---|
| Severity | MINOR |
| Confidence | MEDIUM |
| Hard rule or default | default (hedging / promissory language) |
| Location | lines 60 ("we will address"), 109 ("We report two versions"), 119--132 ("we report... as a function of $\sigma_\eta$", "is left to ongoing work"), 127 ("Two open implementation choices will be reported transparently"), 129 ("We will report results both with...") |
| Problem | The hukou-counterfactual subsection is written largely in the future/promissory tense: the experiment is described as planned rather than done, and one quantity ($\sigma_\eta$ identification) is "left to ongoing work." This is honest, and matches the voice profile's directness about limitations, but a results subsection that reports no realized magnitude for its headline experiment is not submission-ready. Distinct from the prose rule; flag for the author's awareness. |
| Suggested fix | Either run and report the resorting magnitude, or relabel the subsection as a planned extension so a reader does not expect a result. |

---

## Voice consistency notes

The section is strongly in the author's voice on the positive markers: it quantifies relentlessly (bracketed CIs, "nine in ten", "an order of magnitude smaller"), offers counter-arguments immediately and honestly ("driven by the singularity rather than honest uncertainty"; "is conservative whenever $\Delta_{d_N} > 0$"), and states limitations specifically rather than with hedge words (the $\phi = -1$ boundary discussion, the Gaussian-$\theta$ auxiliary-assumption caveat). The enumerated "First... Second..." structure appears at lines 63--64 and 110/119, matching the signature move.

Deviations from voice, all logged above: one contact clause (line 19), one "are worth flagging" throat-clear (line 24), and three `\emph{}` uses (a citation-format artifact). No AI-tell vocabulary ("novel", "delve", "it should be noted") detected.

---

## Summary of blocking items (must clear before commit)

1. Undefined citation `gaiRuralPensionsLabor2025` (line 100).
2. Two undefined table references (line 129) — labels defined nowhere.
3. Reported magnitudes trace to no in-document table (lines 77--94); add and reference the misallocation results table.
4. 74%/26% hukou shares trace to no table (line 79).

Then clear the MAJOR draft-residue items (TODO footnotes, four inline citations) and the compound-complexity sentences.
