# Stage 8 config-hygiene review

Date: 2026-07-20.
Reviewer: `critic-stata`, scoped to the Stage 8 diff (not a full legacy-file audit).
Branch: `stage8-config-hygiene` (commits `bca707e`, `06b7658`, `654092c`, `c68a7cb`, `4d1578c`).
Score: 96/100. No CRITICAL, no MAJOR.

## Confirmed correct

`use_data` regex branch (0_programs.do:304): the four hukou country strings in circulation are exactly `CHN_hukou_{rural,urban}_{only,first}`; all match `^CHN_hukou_`, the base countries `CHN`/`IDN`/`TZA` do not, so no misrouting. `cond()` is valid in a macro/scalar context. The `_unb.dta` variants read elsewhere already use direct `use "$dirdata/processed/..."` and bypass `use_data`, so they are unaffected.
`0_CHN_hukou_restrictions.do`: all four saves repointed to `processed/`; all four raw `CHN.dta` reads left in `countries/`, as intended.
`0_master.do` named master log: every other script uses an unnamed log closed with a bare `log close`, which Stata scopes to the unnamed log and never to a `name()`-ed log, so no collision; no other script uses `name(master)`; the log opens after `$logs` exists and closes as the file's last statement.
`0_path_config.do`: `global dirdata "$dir/data"` set unconditionally; zero live `$values`/`$vsfx`/`data_real` dependents remain (the only hits are frozen Stage 6 gate fixtures under `tests/stage0`, out of scope).

## MINOR findings, both DECLINED

MINOR-1, `use_data` regex is start-anchored only (`^CHN_hukou_`, no trailing anchor). DECLINED.
The prefix match is the intended semantic: every hukou subset, current or future, routes to `processed/`. A full anchor does not fit, since the names carry `_rural_only`/`_urban_first`/etc suffixes after `CHN_hukou_`; tightening would mean hard-coding the exact four-name set. The failure mode the critic describes (a hypothetical future token starting with `CHN_hukou_` that has no saved file) is a loud file-not-found, not a silent wrong-data read, consistent with the project's preference for loud-safe failure over defensive guards (the Stage 6 F4 adjudication).

MINOR-2, the timestamped master-log filename uses `replace`, so two runs in the same wall-clock second by the same user would overwrite. DECLINED.
The per-second `replace` timestamp is the documented AEA master-log pattern in `rules/stata-conventions.md`, followed verbatim. Two runs within the same second by the same user is not a real scenario; adding sub-second precision would deviate from the convention for no practical gain.

## Verification cross-reference

Independent parse+path smoke ([stage8_verify.do](file:///C:/git/ckt/RP7/tests/stage0/stage8_verify.do)) passed all asserts: `0_programs.do` parses after the 60-site strip, `$dirdata` resolves, log-stamp logic parses, hukou loads from `processed/` (N=105,457), raw CHN from `countries/` (N=143,252).
