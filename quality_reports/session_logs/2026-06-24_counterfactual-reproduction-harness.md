# 2026-06-24: counterfactual reproduction harness + merge with main + E1 section review

## If you resume

Two pieces shipped this session, both committed: the E1 counterfactual reproduction harness (`f1b00ba`) and a full review-and-polish of the E1 paper section (`940334b`).
There is no open thread mid-flight; the next move is a fresh task.

The natural next deliverable is E2 (the hukou-wedge counterfactual), which is the last substantive piece.
The section [paper/results_counterfactuals.tex](file:///C:/git/ckt/.claude/worktrees/lca-inversion/paper/results_counterfactuals.tex) describes E2 in subjunctive with no numbers; the RF/UF inversion scalars it needs are attached, and the lower-bound version (eq:hukou-bound) is a short Python script following the run_cell pattern in counterfactuals.py.

Two punch lists are handed back to the user, neither blocking:

1. Overleaf / CKT.bib (cannot be fixed in this worktree): the undefined refs `tab:GRC_CHN_hukou_rural_first_consumption_urban_unb`, `..._urban_first_...`, and `app:inversion-preview`; the four inline "Author, Year, Journal" cites (Kennan-Walker 2011, Tombe-Zhu 2019, Fan 2019) plus their bib entries; the two `TODO` footnotes. See [the FINAL review report](file:///C:/git/ckt/.claude/worktrees/lca-inversion/quality_reports/reviews/2026-06-24_results_counterfactuals_FINAL.md).
2. MAY1 before the ReplicationPackage7 handoff: move counterfactuals.py + lca_inversion.py from explorations/python-grc/ under RP7/scripts/, and add a Python env spec.

To run the harness: `global run_counterfactuals 1` in 0_master.do, or `stata-mp -e do 12_counterfactuals.do` from RP7/scripts (~7--10s). Self-check guards the numbers against the committed baseline.

## Modes active

Implementation (the harness) then Review (critic/fixer on both code and the paper section).

## What got built

The deliverable: graduate the E1 counterfactual from dated exploration drivers into a production pipeline step the master can run.

- [RP7/scripts/12_counterfactuals.do](file:///C:/git/ckt/.claude/worktrees/lca-inversion/RP7/scripts/12_counterfactuals.do): new driver, mirrors 5b_inversion.do. Step A `include`s the two exporters; Step B calls Python over the SFI bridge. Included by 0_master.do behind `global run_counterfactuals` (default 0), placed last.
- [explorations/python-grc/counterfactuals.py](file:///C:/git/ckt/.claude/worktrees/lca-inversion/explorations/python-grc/counterfactuals.py): consolidated the two dated drivers' glue into `run_cell` / `run_all_cells` / `run_counterfactuals_for_stata` (the Stata entry, named to match `lca_inversion.attach_inversion_for_stata`, NOT `e1_*` per user). Writes `counterfactual_results.csv` + the paper table; golden-snapshot self-check vs `counterfactual_results_baseline.csv` (fails on >0.001 log-pt drift).
- [RP7/scripts/_export_e1_inputs.do](file:///C:/git/ckt/.claude/worktrees/lca-inversion/RP7/scripts/_export_e1_inputs.do) and [_export_e1_inputs_hukou.do](file:///C:/git/ckt/.claude/worktrees/lca-inversion/RP7/scripts/_export_e1_inputs_hukou.do): dropped `clear all` (root-cause fix per user) so they conform to the sub-do convention; guarded the `_d` ster read.
- [RP7/scripts/README_counterfactuals.md](file:///C:/git/ckt/.claude/worktrees/lca-inversion/RP7/scripts/README_counterfactuals.md): documents the two-tier chain and the switch.
- Spec + plan: [quality_reports/specs/2026-06-24-counterfactual-reproduction-harness.md](file:///C:/git/ckt/.claude/worktrees/lca-inversion/quality_reports/specs/2026-06-24-counterfactual-reproduction-harness.md), [quality_reports/plans/2026-06-24-counterfactual-reproduction-harness.md](file:///C:/git/ckt/.claude/worktrees/lca-inversion/quality_reports/plans/2026-06-24-counterfactual-reproduction-harness.md).

Earlier in the session: merged `main` into `lca-inversion` (commit `3aebbb9`). Five conflicts, all resolved: `0_programs.do` (comment-only, the within-switcher fix was already cherry-picked to main), two generated GRC tables (took our branch's version per user --- they carry the inversion-CI rows and corrected magnitudes), two doc files moved to the renamed `quality_reports/reviews/`. Branch is now 0 behind main.

## Headline numbers (reproduce exactly, verified)

| cell | misallocation gap (P3, 95% CI) | value of migration (P3) |
|---|---|---|
| IDN | [+5.7%, +6.1%] | +5.1% |
| TZA | [+14.7%, +22.8%] | +4.4% |
| CHN national | [+7.5%, +8.8%] | +4.3% |
| CHN rural-hukou | [+9.9%, +11.7%] | +4.0% |
| CHN urban-hukou | [+0.9%, +1.2%] | +5.2% |

Without the P3 fallback the upper bounds inflate to +58% (IDN), +145% (TZA), +65969% (CHN-uf) --- pole-driven, not honest uncertainty. The draft prose at results_counterfactuals.tex already states all these numbers and they match the harness to the rounding.

## Decisions, with the why

- Stata orchestrates, Python computes. The E1-specific math is almost entirely Python; Stata's role is the upstream estimation plus thin ster-to-CSV export. So the driver follows 5b_inversion.do's SFI pattern rather than being a standalone Python orchestrator. The master must run it for a full replication, which is why it is a numbered do-file.
- Self-check baseline is a committed golden CSV, not in-code constants and not a .ster. The final aggregates live only in the CSV (the sters hold the upstream phi/beta/mu/J that feed the aggregation, not its output). Drift then shows up as both a test failure and a git diff; updating the baseline is a deliberate `regenerate_baseline=True` run plus a reviewable commit. (User's idea; better than my original hard-coded-numbers plan.)
- Exporters must not `clear all` (user directive). Standard sub-dos clear only data via `use ..., clear`. Removing `clear all` + switching the driver from `do` to `include` is the root-cause fix; it replaced my earlier save/restore-$dir workaround and fixed a latent path-loss bug for coauthors.
- Lean harness now, full production pipeline (12_/13_ do-files, T1--T3 tables, F1--F2 figures, D1--D9 diagnostics from the 2026-05-18 plan) deferred until E2 exists, so it is built once.

## Two Stata gotchas burned ~6 tool calls (worth remembering)

The driver ran for 0--1s doing nothing, twice, before I caught it:
1. Markdown-style backticks in a comment (`` `clear all` ``): a bare backtick opens a Stata local-macro reference needing a closing apostrophe, so `` `clear all` `` is unterminated and Stata swallows the rest of the file.
2. `/*` inside a comment: `counterfactual_inputs/*_e1_*.csv` contains `/*`, which Stata reads as a block-comment opener; with no `*/` it consumed the whole file. THIS was the real culprit. Diagnosis: the -e auto-log showed the entire file echoed as `>` continuation with zero execution; the `.`-to-`>` transition pinpointed the offending line. Lesson: a 0-second Stata run that only creates the auto-log = the body never executed; check for stray `/*` and backticks in comments.

## Review status (code)

Two critic rounds on counterfactuals.py + the do-files, all fixes routed through fixer-code (the critic-fixer-enforcer hook blocks parent Edit on critic-pending files --- correct behavior, do not work around it).
Round 2: critic-stata 87 (commit-ready), critic-python 71 (passes exploration gate; its two MAJORs are "blocks graduation to scripts/", i.e. the deferred MAY1 move). Eight defensive fixes applied across the two rounds, none changing the numbers (verified each time).

## Approaches rejected

- Hard-coding canonical numbers as the self-check baseline (brittle, circular) --- replaced with the golden CSV.
- Save/restore $dir around the exporter `do` calls --- superseded by removing `clear all` at the source.
- A new `e1_counterfactuals.py` module --- user rejected the `e1_` prefix; the entry went into the existing `counterfactuals.py`.
- Standalone Python orchestrator --- wrong for a replication package that runs via the master do-file.

## Open items

1. `/review-file` on results_counterfactuals.tex: paused at the approval gate (round-1 report at [quality_reports/reviews/2026-06-24_results_counterfactuals_round1.md](file:///C:/git/ckt/.claude/worktrees/lca-inversion/quality_reports/reviews/2026-06-24_results_counterfactuals_round1.md)). Backup at paper/results_counterfactuals.tex.review-backup.
2. Wire the generated table into the section (user-directed; = critic C3).
3. Bib punch list (Overleaf/CKT.bib, not section-fixable): add Gai 2025, Kennan-Walker 2011, Tombe-Zhu 2019, Fan 2019; convert four inline cites; fix two undefined `tab:GRC_CHN_hukou_*` refs.
4. E2 (hukou-wedge counterfactual): still the substantive deliverable. Section describes it but in subjunctive with no numbers. RF/UF inversion scalars are attached; the lower-bound version is a short script.
5. MAY1: move counterfactuals.py + lca_inversion.py under RP7/scripts/ and add an env spec before the ReplicationPackage7 handoff.

## State to know

- Branch lca-inversion, 0 behind main after the merge. Harness committed at `f1b00ba`.
- `$dir` for maand points at the lca-inversion worktree (0_master.do line 64 active). The driver runs via `stata-mp -e do 12_counterfactuals.do` from RP7/scripts in ~7--10s.
- The input CSVs regenerated byte-identical after the exporter refactor, confirming no output change.

---

# Continuation (crossed into 2026-06-25): review and polish the E1 section

## Goals

After the harness landed, the user asked what the results look like, then whether the draft section discusses them, then to run `/review-file` on [paper/results_counterfactuals.tex](file:///C:/git/ckt/.claude/worktrees/lca-inversion/paper/results_counterfactuals.tex).
Mid-stream they added two directives: wire in the generated table, and run `humanize-econ` plus `audit-residue` after the review loop.
On the residue findings the user overrode my hedging: everything I had marked borderline was "very clear residue that you should fix".

## What got changed

[paper/results_counterfactuals.tex](file:///C:/git/ckt/.claude/worktrees/lca-inversion/paper/results_counterfactuals.tex), committed at `940334b`:

- Wired in the generated table: `\input{tables/counterfactual_misallocation.tex}` plus `Table~\ref{tab:counterfactual_misallocation}` pointers; footnoted the 74/26 hukou-share source.
- Prose (two fixer-writing rounds): split four compound sentences, enumerated the four-source intercept-gap list, glossed NRPS and the Hukou Index, restored a dropped "that", repaired two fragments, varied a passive cluster, dropped a throat-clear, added a precision pointer so the small-value/large-gap conditional reads onto Tanzania not Indonesia.
- humanize-econ: one edit, removed the "A subtlety we will address explicitly is that..." throat-clear at line 62.
- audit-residue: six residue fixes via fixer-writing --- recast the Hsieh-Klenow contrast and the "relative to these exercises... the literature does not deliver" framing as direct claims, dropped a redundant "not delta-method intervals" disclaimer (already stated twice) and two future-work closers.

Review trail under [quality_reports/reviews/](file:///C:/git/ckt/.claude/worktrees/lca-inversion/quality_reports/reviews/): round1, round2, FINAL, and the audit-residue report.

## Decisions, with the why

Decision: hold the bib/label/appendix criticals as an Overleaf punch list rather than fixing them in the worktree.
Why: the four cites need verified bib metadata (no-fabrication rule), and the undefined table/appendix labels live in the Overleaf `main.tex`, not this fragment; the local CKT.bib is stale anyway.

Decision: keep the table as an `\input` rather than inlining its content into the section.
Why: the table is generated by 12_counterfactuals.do, so an `\input` keeps it the single source of truth; inlining would make it a static copy that drifts from the harness.

Decision: skip a standalone xelatex compile of the section.
Why: it is a fragment with external `\ref`/`\cite` to labels in sec_model.tex and the Overleaf main; it cannot compile alone, and pushing to Overleaf is forbidden. Verified balanced braces instead.

Decision: fork a fresh-context adjudicator for the audit-residue KEEPs, and apply its overrules.
Why: the skill's load-bearing step against my own leniency. It overruled two KEEPs (the Hsieh-Klenow contrast and the GE-positioning sentence) to RESIDUE, which the user then confirmed.

Decision: do not de-residue the E2 subsection beyond the two flagged closers.
Why: E2 has not been run, so its subjunctive tense is honest, not residue; aggressive rewriting would falsely imply E2 results exist.

## Approaches rejected

Marking the four contribution-framing / future-work sentences BORDERLINE rather than RESIDUE.
The user rejected this as too soft; they are clear residue and were fixed.

## Open items

1. E2 hukou-wedge counterfactual: still the substantive deliverable, not started in code.
2. Overleaf/CKT.bib punch list (see top block).
3. MAY1 graduation move before the ReplicationPackage7 handoff (see top block).

## State to know

- Branch lca-inversion, 0 behind main. Three commits this session: `3aebbb9` (merge main), `f1b00ba` (harness), `940334b` (section review).
- The review-file backup `paper/results_counterfactuals.tex.review-backup` was removed at the end.
- Date crossed from 2026-06-24 to 2026-06-25 during the review loop.
