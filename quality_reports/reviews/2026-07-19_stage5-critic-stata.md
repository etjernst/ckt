# Stage 5 critic-stata review, adjudicated

Date: 2026-07-19.
Target: branch `stage5-inversion-esample`, commit `2ab4b21` (save_esample_marker, attach_inversion_ci rework, lca_inversion.py esample argument, Stage 5 test and gate drivers).
Critic score: 70/100 with one CRITICAL, one MAJOR, three MINORs; the CRITICAL blocks readiness by rule.
Adjudication below is the coordinator's; fixes await author approval per the review protocol.

## CRITICAL: attach path is `$vsfx`-blind, so the real-values track gets no inversion CIs

The critic is right about the defect and its consequence: `attach_inversion_ci` builds `parent`, `marker`, and the suffix-loop targets from `estbase` alone, and `5b_inversion.do`/`5c_inversion_hukou.do` build `estbase` and their skip-guard paths the same way, while every fitter saves sters as `estname'${vsfx}` (`_r` on the real track).
Under `values=real` the attach pass would skip every cell with a polite message, or worse, attach nominal results if bare-named sters coexist in the same output directory.
Adjudication nuance: the ster-side blindness is PRE-EXISTING (main's `attach_inversion_ci` line 4156 and both callers have no `$vsfx` reference); the Stage 5 diff inherited it into the new marker lookup rather than introducing it.
Proposed fix, small and inside the Stage 5 surface: append `${vsfx}` per the established convention in `attach_inversion_ci` (`estbase'${vsfx}.ster`, `estbase'${vsfx}_esample.dta`, `estbase'`suffix'${vsfx}.ster`) and in the two callers' parent-guard paths.
Under nominal (`vsfx` empty) every string is unchanged, so the running gate stays valid and no refit is needed.
The critic's suggested real-values gate leg is NOT proposed for Stage 5: the real track is the M4 workstream and has never run the inversion pass; recording the coverage gap here and testing it when that track next runs is the cheaper honest path.
Author call.
RESOLVED 2026-07-20 (author): the real-values track is dropped entirely; the `$values`/`$vsfx` machinery and `data_real` references are scheduled for removal in the Stage 8 config-hygiene sweep, so this finding is superseded by removal and no vsfx threading is applied.

## MAJOR: the `estimates esample:` re-declaration is dead where it stands

Correct finding: the declaration lands on the loaded parent estimates and is discarded two steps later when the suffix loop reloads the same ster from disk, so the comment ("any Stata-side consumer can condition on e(sample)") overclaims.
Proposed fix: make it real instead of deleting it, since the author asked for this behavior at plan time: move the declaration to the end of the program, after the suffix loop, on a fresh reload of the (now CI-carrying) parent ster, so `attach_inversion_ci` returns with the parent estimates active and their true sample declared for interactive follow-up; the comment states the declaration is session-only and never persisted.

## MINOR 1: `hhid()` is parameterized but the marker key is hardcoded `pid period`

Accept as documentation: the marker key is the project-wide `pid period` contract (isid-enforced at build), and `hhid()` is a Python-side pass-through.
Proposed fix: one comment line in each header saying exactly that.

## MINOR 2: no country cross-check between loaded data and marker

Declined: the pid-period merge with the unmatched-row and count guards covers realistic mistakes; a cross-country pid collision that also matches the marker's exact pid-period set and count is far-fetched, and the caller-discipline invariant is documented in the drivers.

## MINOR 3: magic modulus 43 in the contract test

Accept: hoist to a named local with a one-line comment.

## Calibration notes the critic got right

The merge row-order restoration, the preserve/restore placement of the marker write at all four call sites, and the injected-then-healed missingness contract test were each independently verified sound.

## Recommended fix set for approval

Fix CRITICAL (vsfx threading in `attach_inversion_ci` + both callers' guards), MAJOR (move the declaration post-loop and correct the comment), MINOR 1 (header comments), MINOR 3 (named local).
Decline MINOR 2.
All proposed edits are nominal-track no-ops, so the detached gate batches keep running and their results stay valid.
