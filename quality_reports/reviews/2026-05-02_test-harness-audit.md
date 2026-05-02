# Test-harness audit --- three Python validation tools

The branch has accumulated three Python validation harnesses under [`tests/`](file:///C:/git/ckt/.claude/worktrees/grc-pipeline-refactor/tests/).
Each was added when the previous one stopped working against the post-refactor table state.
Auditing whether all three should ship in the PR.

## The three harnesses

| Tool | Added | Scope | Tolerance |
|---|---|---|---|
| [`tests/regression_test.py`](file:///C:/git/ckt/.claude/worktrees/grc-pipeline-refactor/tests/regression_test.py) | `dda62b2` (2026-04-24, M6 + M7 scaffold) | Whole `tests/reference/output/` tree | Bit-strict (`filecmp.cmp(shallow=False)`) |
| [`tests/compare_tabular_bodies.py`](file:///C:/git/ckt/.claude/worktrees/grc-pipeline-refactor/tests/compare_tabular_bodies.py) | `80f2afc` (2026-04-29) | Tables only, body only | Bit-strict on body only; tolerant of envelope drift |
| [`tests/tier2_table_diff.py`](file:///C:/git/ckt/.claude/worktrees/grc-pipeline-refactor/tests/tier2_table_diff.py) | `c46de1a` (2026-05-02) | Tables only, body only | Classified diffs (`LABEL_FLIP` / `BLANK_ROW` / `ADDLINESPACE` / `UNEXPECTED`) |

Each tool was a strict scope expansion on the previous, made necessary by intentional refactor-time changes:

1. The original M6 + M7 scaffold worked when reference and live tables were bit-identical.
2. Phase 1b.5 trimmed the table envelope (caption / label / tablenotes moved to paper macros), and `regression_test.py` started failing on every table.
   `compare_tabular_bodies.py` was added to compare bodies only.
3. Δbar (`5e2277c`) and Phase 1b.6 (`f68892e`) introduced expected body-level diffs that `compare_tabular_bodies.py` could not distinguish from regressions.
   `tier2_table_diff.py` was added with classified diff hunks.

## What's in the reference today

`tests/reference/output/` contains a single subdir, `tables/`, with 53 `.tex` files.
No figures, no sters.

```
tests/reference/output/tables/    53 .tex files
```

So `regression_test.py`'s broader scope (tables + figures + anything else under `output/`) is currently moot --- only tables exist in the reference, and against tables it is the strictest of the three (no envelope tolerance, no expected-diff classification).

## Coverage relationship

In the current state:

```
regression_test.py         ⊂  compare_tabular_bodies.py  ⊂  tier2_table_diff.py
(strictest, broken on
 envelope drift)              (broken on Δbar / blank-row drift)
```

`tier2_table_diff.py` is a strict superset: it does the same body extraction as `compare_tabular_bodies.py`, and against the bit-strict end of its `UNEXPECTED` bucket it does the same job as `regression_test.py` would on tables.
The other two have no scope or tolerance not also covered by `tier2_table_diff.py`.

## Recommendation

1. Delete `tests/compare_tabular_bodies.py`.
   Strict subset of `tier2_table_diff.py`.
   Last useful for the 2026-04-29 verification before Δbar / Phase 1b.6 landed.
2. Delete `tests/regression_test.py`.
   Currently broken for tables (the only thing in the reference).
   When figures get captured into the reference (a deferred M7 item per the spec), write a minimal `tier2_figure_diff.py` then.
   Resurrecting `regression_test.py` for figures would inherit its current bit-strict-everywhere assumption, which is the wrong default --- figures often have legitimate small floating-point differences and need their own tolerance scheme.
3. Update [`tests/README.md`](file:///C:/git/ckt/.claude/worktrees/grc-pipeline-refactor/tests/README.md) to point at `tier2_table_diff.py` as the canonical Tier 2 harness, drop the "9 tables" outdated count (now 53), and remove the references to the deleted scripts.
4. Update [`quality_reports/reviews/2026-05-02_PR-description-draft.md`](file:///C:/git/ckt/.claude/worktrees/grc-pipeline-refactor/quality_reports/reviews/2026-05-02_PR-description-draft.md) to remove the bullet points for the two deleted tools.

## Caveat

Both candidates for deletion are referenced from past session logs and from `RP7/scripts/STER_NAMING.md` and `RP7/scripts/_smoke_full.do` (comment text only).
Deleting the files does not break those references --- they live in committed history --- but it does mean a future reader of the comments encounters a dangling reference.
Light touch: leave the comments alone; anyone confused can run `git log` to find the deleted-on-2026-05-02 commit.

## Decision pending

Both deletions await user approval since they remove tracked code that has been used in past verifications.
If approved, the deletes go in two atomic commits, plus the README + PR-draft updates.

with Claude
