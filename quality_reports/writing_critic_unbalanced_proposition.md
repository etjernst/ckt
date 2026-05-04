# Writing critic report: `unbalanced_proposition.tex`

Date: 2026-04-24
Reviewed after: humanizer pass on the revised appendix.
Scope: clarity, notation, American English, em-dash spacing, headings, `\paragraph{}`/`\emph{}` usage, topic sentences, AI-ish phrasing, redundancy in `(\mu_{\mathrm{unb}},\Delta_{\mathrm{unb}})` descriptions.

## Summary tally

| Severity | Count |
|----------|-------|
| CRITICAL | 0 |
| MAJOR    | 2 |
| MINOR    | 7 |

**Aggregate score: 84/100.** Commit-ready (above 80) but below PR threshold (90). No CRITICAL issues.

## Findings

### MAJOR

**M1. Bold labels used as pseudo-headings inside the proof.**
- Lines 92, 109, 123: `\textbf{Step 1 (moment validity).}`, `\textbf{Step 2 (identification and asymptotics).}`, `\textbf{Step 3 (efficiency).}`.
- Hard rule: "No bold subheadings or bold labels in prose. Structure through headings, paragraphs, and transitions."
- Confidence: HIGH.
- Fix: drop the bold and let the sentence do the work. The Step 1/2/3 roadmap sentence on line 90 already previews the structure.

**M2. Placeholder `\textbf{[X\%]}` and `\textbf{[Y\%]}` on line 17 with author-facing footnote.**
- Bold used as emphasis/label. Footnote phrasing ("Placeholder---...Do not confuse with...") reads as a note to self.
- Confidence: HIGH.
- Fix: fill in the shares from the summary-stats tables before circulation. In the meantime, at minimum drop the `\textbf{...}`.

### MINOR

**m1. `d_T` vs `\underline d` convention.**
- Lines 24, 32, 40, 77, 79, 85, 110, 111, 114, 119, 121, 132, 133 use `d_T` (no underline) while other trajectory labels are underlined. Flagged in the prior self-review and still present.
- Fix: change every `d_T` to `\underline d_T`, or confirm main-text convention and note it once.
- Note from implementation: main.tex uses `d_T` without underline; kept for consistency with main text.

**m2. Line 14 sentence is dense.**
- The parenthetical after the em-dash defines two terms at once.
- Suggested split: "Rather than discard them, we pool them into a single additional cell. An adjusted rural intercept $\mu_{\mathrm{unb}}$ and an adjusted urban-return parameter $\Delta_{\mathrm{unb}}$ index the cell; they are the pooled-cell analogues of $\mu_{\underline d}$ and $\Delta_{\underline d}$ for a stratum whose trajectory label is undefined."

**m3. Throat-clearing topic sentence on line 59.**
- "Assumption~\ref{ass:orthogonality} is the condition the proof of Proposition~\ref{prop:pooling} uses on the unbalanced stratum."
- Describes what the assumption does rather than asserting something.
- Suggested: "Assumption~\ref{ass:orthogonality} is weaker than a full latent-distribution MAR condition but sufficient for the proof of Proposition~\ref{prop:pooling}."

**m4. Awkward sentence tail on line 139.**
- "...less sensitive to unbalanced-stratum misspecification than an estimator that let the unbalanced individuals contribute directly to trajectory identification would be."
- Fix: "...less sensitive to unbalanced-stratum misspecification than one that let the unbalanced individuals contribute directly to trajectory identification."

**m5. Line 114 starts with a label-like fragment.**
- "Count of moments versus parameters:" reads as a pasted header.
- Fix: "Counting moments against parameters gives $(\lvert\mathcal D\rvert - 1) + \lvert\mathcal D_S\rvert + 2 + \dim(x)$ moments for $\lvert\mathcal D\rvert + \dim(x) + 3$ parameters; when $\lvert\mathcal D_S\rvert \geq 3$ the system is overidentified in $\phi$."

**m6. Cluster-inference paragraph still sits as an orphan (line 49).**
- Prior review asked for it to move out of Step 1; it now lives between the setup and the assumption block.
- Fix: append to the end of the setup paragraph at line 47 so the setup reads as one block.

**m7. "Is consistent with the joint null" (line 152) is a claim without a magnitude.**
- "Close correspondence" does not quantify closeness.
- Fix: either cite a specific magnitude from the balanced/pooled comparison tables, or let the table cross-reference carry the claim.

## Items checked and clean

- American English: no British spellings.
- Em-dashes: all flush, no spaces.
- `\paragraph{}`: none.
- `\emph{}`: none.
- Redundancy in pooled-cell-analogue descriptions: the prior draft's second copy after equation (1) was removed.
- Proof structure parses; three steps deliver what the roadmap sentence promises.
- Internal cross-references resolve (`ass:orthogonality`, `ass:common-gamma`, `prop:pooling`, `eq:kappa-T`, `eq:restricted-grc-unbalanced`).
- Voice profile: opens with functional purpose, quantifies where it can, avoids stock hedging, uses active voice for author claims.

## Priority fixes for the next pass

1. Delete `\textbf{}` around Step 1/2/3 labels.
2. Fill in `\textbf{[X\%]}/[Y\%]` shares and rewrite the footnote to address the reader.
3. Resolve `d_T` vs `\underline d_T` against the main-text convention.
4. Tighten lines 14 (split), 59 (assert), 114 (integrate), 139 (drop "would be").
5. Fold the cluster-inference paragraph into the setup block above the first assumption.
