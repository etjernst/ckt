# Critic report: slice infrastructure

Date: 2026-05-13
Scope: three infrastructure files introduced for the GRC pipeline refactor slice-driver system.

Files reviewed:

- [RP7/scripts/0_slice_bootstrap.do](file:///C:/git/ckt/.claude/worktrees/grc-pipeline-refactor/RP7/scripts/0_slice_bootstrap.do)
- [RP7/scripts/run_master_resume.do](file:///C:/git/ckt/.claude/worktrees/grc-pipeline-refactor/RP7/scripts/run_master_resume.do)
- [RP7/scripts/run_extras_birth.do](file:///C:/git/ckt/.claude/worktrees/grc-pipeline-refactor/RP7/scripts/run_extras_birth.do)

Out of scope: `9_GRC_extras.do`, `0_programs.do`, and the two sibling slice drivers (`run_extras_maxexpsh.do`, `run_extras_cnu.do`).
The user-block duplication across entry-point files is deliberate per project memory (`feedback_no_loops_for_regressions.md`); it is noted where it surfaces a latent bug (F5) but not flagged purely for duplication.

---

## F1

[run_master_resume.do line 16](file:///C:/git/ckt/.claude/worktrees/grc-pipeline-refactor/RP7/scripts/run_master_resume.do)
Lens 1 --- Reproducibility
Severity: MAJOR
Confidence: HIGH

`do "0_master.do"` is a bare relative path that resolves against the shell CWD at launch time.
The USAGE comment (`stata-mp -e do run_master_resume.do`) works only when the shell CWD is `$dir/scripts`; launching from `$dir` or any other directory causes "file not found" and the session produces no output and no log.
The project convention prohibits `cd` and uses path globals precisely to avoid this fragility.
Because `$dir` is not set inside `run_master_resume.do` itself (it inherits from `0_master.do`'s user block), a clean fix requires either (a) adding a user block to establish `$dir`/`$scripts` first and then calling `do "$scripts/0_master.do"`, or (b) documenting prominently that the file must be launched from `$dir/scripts` and enforcing it with an early guard.

---

## F2

[run_master_resume.do lines 15--16](file:///C:/git/ckt/.claude/worktrees/grc-pipeline-refactor/RP7/scripts/run_master_resume.do)
Lens 4 --- Output
Severity: MAJOR
Confidence: HIGH

`run_master_resume.do` sets `global skip_if_exists 1` then calls `0_master.do`, which unconditionally sets `global copyOverleaf 1` at line 81.
On any machine where `$overleaf` is configured (e.g., `maand`), a resume run therefore copies all tables and figures to Overleaf---behavior the file does not mention and that a user running a resume refit of missing cells would not expect.
The slice drivers guard against this via `global copyOverleaf 0` in `0_slice_bootstrap.do`; `run_master_resume.do` has no equivalent guard.
Correct fix: add `global copyOverleaf 0` before the `do` call, or document explicitly that Overleaf copying is intentional during resume runs.

---

## F3

[run_master_resume.do lines 1--16](file:///C:/git/ckt/.claude/worktrees/grc-pipeline-refactor/RP7/scripts/run_master_resume.do)
Lens 1 --- Reproducibility / Lens 5 --- Code Quality
Severity: MAJOR
Confidence: HIGH

`run_master_resume.do` has no `version` declaration, no `clear all`, and no `set more off`.
It is a standalone entry-point `.do` file; `stata-conventions.md` requires these at the top of every such file.
`0_master.do` supplies `clear all` and `version 17` once it begins executing, so the omission is functional only when the bare `do "0_master.do"` path succeeds; if it fails (see F1), no version constraint is ever set on the calling session.
Correct pattern (after resolving F1):

```stata
clear all
set more off
version 17
global skip_if_exists 1
global copyOverleaf 0
do "$scripts/0_master.do"
```

---

## F4

[run_master_resume.do line 3](file:///C:/git/ckt/.claude/worktrees/grc-pipeline-refactor/RP7/scripts/run_master_resume.do)
Lens 5 --- Code Quality
Severity: MINOR
Confidence: LOW

The comment references `0_programs.do (around line 1842)`.
Hardcoded line numbers become stale whenever `0_programs.do` is edited.
A search-key hint---"search for `skip_if_exists` in `0_programs.do`"---would survive line-number drift.

---

## F5

[run_extras_birth.do lines 29--31](file:///C:/git/ckt/.claude/worktrees/grc-pipeline-refactor/RP7/scripts/run_extras_birth.do)
Lens 1 --- Reproducibility
Severity: MINOR
Confidence: HIGH

The `kleemans` user block assigns `$dir` twice: line 30 sets a C: path, line 31 immediately overwrites it with a D: path.
The C: assignment is dead code on every execution.
The apparent intent is "prefer D: if available, fall back to C:", but no fallback logic is implemented---the last assignment always wins, so if the D: drive is absent `$dir` still points to it.
This pattern is inherited verbatim from `0_master.do`, so no unique regression is introduced here, but the dead line should be removed or replaced with a conditional check in both files.

---

## F6

[run_extras_birth.do line 63](file:///C:/git/ckt/.claude/worktrees/grc-pipeline-refactor/RP7/scripts/run_extras_birth.do)
Lens 5 --- Code Quality
Severity: MINOR
Confidence: HIGH

`if \`saved_rc' != 0 di as error ...` is a brace-less single-statement `if`.
Stata permits this, but a future edit adding a second statement after the `di` would execute unconditionally.
The same pattern appears in the sibling driver `run_extras_maxexpsh.do` line 71 (outside scope but worth a global fix).

---

## F7

[run_extras_birth.do lines 1--20](file:///C:/git/ckt/.claude/worktrees/grc-pipeline-refactor/RP7/scripts/run_extras_birth.do) and [run_master_resume.do lines 1--14](file:///C:/git/ckt/.claude/worktrees/grc-pipeline-refactor/RP7/scripts/run_master_resume.do)
Lens 5 --- Code Quality
Severity: MINOR
Confidence: MEDIUM

Neither `run_extras_birth.do` nor `run_master_resume.do` carries the canonical header block required by `stata-conventions.md` (Title, Author, Date, Purpose, Input, Output).
`run_extras_birth.do` has a rich descriptive comment block that covers Purpose and Cells but omits Author, Date, and the key-value structure.
`run_master_resume.do` has only a prose paragraph.
`0_slice_bootstrap.do` is an `include`-file helper, not a standalone entry point, and is exempt from the entry-point header requirement.

---

## Score

These three files are infrastructure, not estimation scripts; Inference (L2) and Data Quality (L3) have no applicable issues.

| Lens | Weight | Issues | Raw lens score |
|------|--------|--------|----------------|
| L1 Reproducibility | 25% | F1 MAJOR, F3 MAJOR, F5 MINOR | 82 |
| L2 Inference | 30% | none | 100 |
| L3 Data Quality | 20% | none | 100 |
| L4 Output | 10% | F2 MAJOR | 90 |
| L5 Code Quality | 15% | F4 MINOR, F6 MINOR, F7 MINOR | 93 |

Weighted aggregate: 0.25 x 82 + 0.30 x 100 + 0.20 x 100 + 0.10 x 90 + 0.15 x 93 = **93 / 100**

No CRITICAL issues.
The three MAJORs are all in `run_master_resume.do` and addressable together: fix path resolution (F1), add `global copyOverleaf 0` (F2), and add `clear all` / `version 17` / `set more off` (F3).
The MINORs (F4--F7) are style and can be addressed opportunistically.
Readiness: above the 90/100 PR threshold numerically, but F1 (CWD-dependent path) and F2 (silent Overleaf copy during resume) are behavioral issues that should be resolved before the file enters the coauthor-facing handoff.

Numeric scores are rough heuristics for triage; the severity tiers carry the decision-relevant signal.
