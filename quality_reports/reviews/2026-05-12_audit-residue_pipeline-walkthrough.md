# Audit-residue: docs/pipeline-walkthrough.html

Date: 2026-05-12
File: [docs/pipeline-walkthrough.html](file:///C:/git/ckt/.claude/worktrees/grc-pipeline-refactor/docs/pipeline-walkthrough.html)

## Audience caveat

This document is a coauthor heads-up note, not a paper.
The intended readers (Cenci, Kleemans) DO hold the prior expectations the document responds to — they used the previous pipeline and would otherwise wonder what changed, whether they need to reconfigure, whether their numbers move.
Most "anticipated objection" phrasing is therefore doing legitimate work; it addresses the actual reader, not a phantom reviewer.

The audit-residue skill's own scope note ("Do not use for internal memos") technically covers this case.
I'm still flagging genuine residue below where the sentence presupposes a path-not-taken or argues with an absent third party rather than the coauthor reader.

## Findings

### Flag 1: "actually" in the lede

- **Location**: line 241 (lede)
- **Verbatim**: "A short tour of what's new, organized around the handful of files and switches you'll actually open."
- **Flavor**: path-not-taken
- **Diagnosis**: "actually" contrasts the in-scope files against files the reader wouldn't open. The reader doesn't need the contrast — they're not wondering whether the document will waste their time.
- **Suggested fix**: Drop "actually". Result: "the handful of files and switches you'll open."

### Flag 2: "without you touching anything"

- **Location**: line 264 (switches intro)
- **Verbatim**: "A handful of globals live near the top of 0_master.do. Defaults are picked so the pipeline runs end-to-end without you touching anything."
- **Flavor**: anticipated-objection (mild)
- **Diagnosis**: Preempts "do I need to configure stuff before running?" but the coauthors already know about the user blocks and have been running the pipeline for years — they don't hold this expectation. The sentence reassures against a concern they wouldn't have.
- **Suggested fix**: Cut the second sentence; the existing user blocks already make the point. Or rephrase positively: "Defaults match the previous pipeline's behavior."

### Flag 3: "the same way you've always run a do-file"

- **Location**: line 328
- **Verbatim**: "Open whichever fits the situation and run it the same way you've always run a do-file."
- **Flavor**: anticipated-objection (mild)
- **Diagnosis**: Reassures the reader they don't need to learn a new workflow. But the reader is reading this document precisely because they expect changes; the trailing clause sounds slightly defensive against a worry they may not have voiced.
- **Suggested fix**: Cut "the same way you've always run a do-file". Result: "Open whichever fits the situation and run it."

## Considered and kept

The following sentences look residue-shaped but pass the test for this audience.

- Line 259, "Everything else about the pipeline … works the way you remember."
  Legitimate. Coauthors who used the old pipeline DO hold the expectation that more might have changed.

- Line 314, "Defaulting it off means Python doesn't need to be installed for the pipeline to finish."
  Legitimate. Coauthors who don't have Python installed need to know the default is safe for them.

- Line 326, "Data prep, OLS, table builders, and figure builders all run unconditionally — they're cheap."
  Legitimate. Coauthors WOULD ask "does the resume mode also skip those?" and the answer matters.

- Line 353, "no manual rescaling needed on your end."
  Legitimate. The pre-fix workaround involved a manual rescaling step in some draft tables; coauthors who saw that need to know it's gone.

- Line 246 (TL;DR), "If anything looks off: open 0_master.do first."
  Legitimate. Useful pointer for the reader; not defending against an objection.

## Recommended action

Three mild flags, all clustered around mild defensive phrasing. The document is otherwise clean of path-not-taken residue and clean of phantom-reviewer addresses. Apply Flag 1 and Flag 3 (both single-word/clause deletions); leave Flag 2 alone or apply only if you want to compress further.
