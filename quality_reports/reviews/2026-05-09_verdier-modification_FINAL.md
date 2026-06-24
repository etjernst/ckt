---
file: paper/slides/verdier-modification.tex
critic: critic-slide-layout
fixer: fixer-writing
rounds: 3
verdict: APPROVED
date: 2026-05-09
---

# Review-fix loop FINAL: verdier-modification.tex

## Verdict

APPROVED at round 3 (zero CRITICAL, zero MAJOR/HIGH).

## Per-round counts

| Round | CRITICAL | MAJOR/HIGH | MEDIUM | MINOR/LOW | Approved | Fixed | Skipped |
|-------|----------|------------|--------|-----------|----------|-------|---------|
| 1     | 0        | 1          | 14     | ~7        | 15       | 15    | 0       |
| 2     | 0        | 4          | 9      | 7         | 20       | 17    | 5 (no-action) |
| 3     | 0        | 0          | 4      | 6         | -        | -     | -       |

(Round 3 medium/low items are residual polish items; loop terminated on zero-major rule.)

## Snapshot

Pre-loop snapshot: `git stash push -u -m "review-file pre-round-1 paper/slides/verdier-modification.tex"`. Stash was popped after the round-1 audit to restore A3 edits made before the loop began. Rollback path: `git checkout HEAD -- paper/slides/verdier-modification.tex`.

## Files

- [paper/slides/verdier-modification.tex](file:///C:/git/ckt/.claude/worktrees/worktree-vanilla-vv/paper/slides/verdier-modification.tex)
- [paper/slides/verdier-modification.pdf](file:///C:/git/ckt/.claude/worktrees/worktree-vanilla-vv/paper/slides/verdier-modification.pdf)
- Round-1 critic report (returned inline, not saved)
- Round-2 critic report (returned inline, not saved)
- Round-3 critic report (returned inline, not saved)

## Aggregate diff

212 insertions, 118 deletions vs HEAD across rounds 1+2+3.

## Notable changes (round-by-round)

Round 1 (15 fixes):
- Split slide 16 into assumptions slide + estimator-table slide
- Removed `\footnotesize` on slides 11, 12, 14, 16, 20, 24, 26 by SPLITTING dense slides rather than shrinking
- Replaced both misused `alertblock` instances with plain prose
- Removed 6 unearned bold pseudo-labels; kept 4 that earned their weight as definitional contrasts
- Swept trailing periods from bullets across the deck
- Added a takeaway/bottom-line slide before the appendix divider
- Re-titled procedural slides ("VV Step 1: ..." → assertion form)
- Dropped "(pending)" hedge from slide 22 title; conditional mood preserves status
- Adjusted TikZ label and legend coordinates on slide 8
- Dropped the off-pattern "China: hukou..." bullet from slide 4

Round 2 (17 fixes, 5 no-action):
- Resolved TikZ label collisions on slide 8 by dropping one redundant `slope = $\phi$` annotation
- Compressed A3 statement on slide 15 to conditional-mean form only (matches what the proof actually uses; formal marginal-independence form is sufficient-but-stronger-than-needed per Verdier-verification)
- Widened appendix-table column widths on slides 25 and 26 to eliminate ransom-note word-stacking
- Split appendix slide 24 into two sub-slides at `\addlinespace` boundaries
- Removed duplicated "special-case identity" content from slide 14 (lives in appendix slide 27)
- Re-titled slide 15 from label to assertion ("A2' is strictly weaker than A2; A3 is the cost of trajectory pooling")
- Converted slide 16 closing four-sentence prose to a 3-bullet list
- Converted three `\emph{}` pseudo-labels on slide 27 to "First, ... Second, ..." lead-in prose
- Split a packed bullet on slide 13 into two
- Inserted one short breath slide between slides 13 and 14

## Remaining residuals (round 3, medium-only, non-blocking)

- Slide 5 density: italic A2 vs A2' contrast could become a `description` block or 2-row tabular
- Slide 9 title contains `\&` (replace with "and")
- Slide 10 density: still 4 `\vspace` calls + display equation + `align*` block
- Slide 11 density: 3 display equations on one slide (Simple-IV + FW residualized moment)
- Slide 14: three multi-sentence bullets where a 2x3 tabular would render the contrast better

These are quality-polish items, not blockers. Worth a deliberate session rather than incremental patching.

## Round-3 low-severity notes (cosmetic)

- Two ampersand-in-prose instances (slides 2, 3) — replace `\&` with "and"
- Slide 6 title prefix "In practice:" weakens the assertion
- Slide 6 has a forward reference to a later geography slide
- Slide 19 bullet 3 is denser than bullets 1-2 (adjacent-density mismatch)
- Slide 20 has 4 `\vspace` calls separating 5 content blocks
- Appendix `[allowframebreaks]` on the estimator-details slide is harmless if the table fits, ugly if it breaks — verify visually

## Verdier-verification side note

A separate background subagent (not part of the review-fix loop) read Verdier (2020) directly to verify the A3 framing in the deck. Finding: the formal A3 in `paper/verdier_robust.tex:51` (marginal independence of trajectory and cluster) is **sufficient but unnecessarily strong**. The proof in `paper/robust_equivalence_proof.tex` actually uses only the conditional-mean condition $E[\theta_i \mid \underline d_i, v_i] = E[\theta_i \mid v_i]$. Verdier himself has no A3-equivalent — his robust procedure uses worker-level cluster FE and never pools across clusters within trajectory. The slide now uses the conditional-mean form only. The manuscript itself was not changed in this loop; whether to weaken `ass:cluster-pooling` in the paper is a separate Implementation-mode decision.
