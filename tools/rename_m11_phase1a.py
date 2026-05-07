"""tools/rename_m11_phase1a.py

One-shot rename of GRC ster filenames and stored estimate names per M11
(spec at quality_reports/specs/2026-04-24_grc-pipeline-refactor.md, sect M11).

Phase 1a: pure rename, no semantic change. Run from worktree root:
    python tools/rename_m11_phase1a.py

Per-file substitution maps below. The script is non-idempotent: re-running
after a successful rename will leave files unchanged but will warn about
each pattern that no longer matches. Substitutions within each list run
in order, longest-suffix first, so `_never` / `_avg` get rewritten before
the bare prefix that contains them as substrings.

For 5_GrRC.do and 8_GrRC_hukou.do, substitutions are section-aware
(per-section spec3 token).

File IO uses bytes to preserve original line endings (CRLF stays CRLF,
LF stays LF).
"""
from pathlib import Path

ROOT = Path(__file__).parent.parent.resolve()
SCRIPTS = ROOT / "RP7" / "scripts"


def read_text(path):
    return path.read_bytes().decode("utf-8")


def write_text(path, text):
    path.write_bytes(text.encode("utf-8"))


def apply_subs(text, subs, label):
    """Apply (old, new) substitutions in order. Print counts."""
    total = 0
    for old, new in subs:
        n = text.count(old)
        if n == 0:
            print(f"  [WARN] {label}: no match for {old!r}")
        text = text.replace(old, new)
        total += n
    print(f"  [{label}] total substitutions: {total}")
    return text


def section_subs(spec3):
    """Substitutions for one section of 5_GrRC.do (spec3 in {cuu, cub, iuu})."""
    return [
        # Suffixed forms first (so the bare-prefix sub does not corrupt them).
        (f'"$dir/output/grc_`country\'_urban_`estname\'_never"',
         f'"$dir/output/grc_`country\'_{spec3}_`estname\'_n"'),
        (f'"$dir/output/grc_`country\'_urban_`estname\'_avg"',
         f'"$dir/output/grc_`country\'_{spec3}_`estname\'_g"'),
        ("grc_`country'_u_`estname'_never",
         f"grc_`country'_{spec3}_`estname'_n"),
        ("grc_`country'_u_`estname'_avg",
         f"grc_`country'_{spec3}_`estname'_g"),
        # Bare prefixes (in foreach-loop reads / stores).
        (f'"$dir/output/grc_`country\'_urban_`estname\'"',
         f'"$dir/output/grc_`country\'_{spec3}_`estname\'"'),
        ("grc_`country'_u_`estname'",
         f"grc_`country'_{spec3}_`estname'"),
        # Foreach iteration list: long covs_X -> short cX.
        ("foreach estname in covs_0 covs_trend covs_1 covs_2 covs_all",
         "foreach estname in c0 ct c1 c2 ca"),
        # estimates table calls listing the 5 stored names (Option-B `_u_` form).
        ("grc_`country'_u_covs_0", f"grc_`country'_{spec3}_c0"),
        ("grc_`country'_u_covs_trend", f"grc_`country'_{spec3}_ct"),
        ("grc_`country'_u_covs_1", f"grc_`country'_{spec3}_c1"),
        ("grc_`country'_u_covs_2", f"grc_`country'_{spec3}_c2"),
        ("grc_`country'_u_covs_all", f"grc_`country'_{spec3}_ca"),
        # run_grc estname args (the `_urban_` verbose form on disk).
        ("grc_`country'_urban_covs_0", f"grc_`country'_{spec3}_c0"),
        ("grc_`country'_urban_covs_trend", f"grc_`country'_{spec3}_ct"),
        ("grc_`country'_urban_covs_1", f"grc_`country'_{spec3}_c1"),
        ("grc_`country'_urban_covs_2", f"grc_`country'_{spec3}_c2"),
        ("grc_`country'_urban_covs_all", f"grc_`country'_{spec3}_ca"),
        # grc_tex_table_trend caller arg.
        ("spec(urban)", f"spec({spec3})"),
    ]


# 5_GrRC.do --- 3 sections
def do_5():
    path = SCRIPTS / "5_GrRC.do"
    text = read_text(path)
    print(f"\n=== {path.name} ===")
    s1 = text.find("* 1. Consumption | Urban | Unbalanced | GRC")
    s2 = text.find("* 2. Consumption | Urban | Balanced | GRC")
    s3 = text.find("* 3. Income | Urban | Unbalanced | GRC")
    assert s1 != -1 and s2 != -1 and s3 != -1, "5_GrRC: missing section markers"
    pre, sec1, sec2, sec3 = text[:s1], text[s1:s2], text[s2:s3], text[s3:]
    print("-- section 1 (cons/urban/unb -> cuu)")
    sec1 = apply_subs(sec1, section_subs("cuu"), "5_GrRC sec1")
    print("-- section 2 (cons/urban/bal -> cub)")
    sec2 = apply_subs(sec2, section_subs("cub"), "5_GrRC sec2")
    print("-- section 3 (income/urban/unb -> iuu)")
    sec3 = apply_subs(sec3, section_subs("iuu"), "5_GrRC sec3")
    write_text(path, pre + sec1 + sec2 + sec3)


# 6_GrRC_NonAg.do --- single section, cnu
def do_6():
    path = SCRIPTS / "6_GrRC_NonAg.do"
    text = read_text(path)
    print(f"\n=== {path.name} ===")
    spec3 = "cnu"
    subs = [
        (f'"$dir/output/grc_`country\'_nonag_`estname\'_never"',
         f'"$dir/output/grc_`country\'_{spec3}_`estname\'_n"'),
        (f'"$dir/output/grc_`country\'_nonag_`estname\'_avg"',
         f'"$dir/output/grc_`country\'_{spec3}_`estname\'_g"'),
        ("grc_`country'_n_`estname'_never", f"grc_`country'_{spec3}_`estname'_n"),
        ("grc_`country'_n_`estname'_avg", f"grc_`country'_{spec3}_`estname'_g"),
        (f'"$dir/output/grc_`country\'_nonag_`estname\'"',
         f'"$dir/output/grc_`country\'_{spec3}_`estname\'"'),
        ("grc_`country'_n_`estname'", f"grc_`country'_{spec3}_`estname'"),
        ("foreach estname in covs_0 covs_trend covs_1 covs_2 covs_all",
         "foreach estname in c0 ct c1 c2 ca"),
        ("grc_`country'_n_covs_0", f"grc_`country'_{spec3}_c0"),
        ("grc_`country'_n_covs_trend", f"grc_`country'_{spec3}_ct"),
        ("grc_`country'_n_covs_1", f"grc_`country'_{spec3}_c1"),
        ("grc_`country'_n_covs_2", f"grc_`country'_{spec3}_c2"),
        ("grc_`country'_n_covs_all", f"grc_`country'_{spec3}_ca"),
        ("grc_`country'_nonag_covs_0", f"grc_`country'_{spec3}_c0"),
        ("grc_`country'_nonag_covs_trend", f"grc_`country'_{spec3}_ct"),
        ("grc_`country'_nonag_covs_1", f"grc_`country'_{spec3}_c1"),
        ("grc_`country'_nonag_covs_2", f"grc_`country'_{spec3}_c2"),
        ("grc_`country'_nonag_covs_all", f"grc_`country'_{spec3}_ca"),
        ("spec(nonag)", "spec(cnu)"),
    ]
    text = apply_subs(text, subs, "6_GrRC_NonAg")
    write_text(path, text)


# 8_GrRC_hukou.do --- 4 hukou subgroups x 3 spec3 sub-sections
def do_8():
    path = SCRIPTS / "8_GrRC_hukou.do"
    text = read_text(path)
    print(f"\n=== {path.name} ===")
    subgroup_meta = [
        ("rural hukou first", "rf", "rural_first"),
        ("urban hukou first", "uf", "urban_first"),
        ("only rural hukou", "ro", "rural_only"),
        ("only urban hukou", "uo", "urban_only"),
    ]
    starts = []
    for tag, hu, full in subgroup_meta:
        marker = f"* 1. Consumption | Urban | Unbalanced | GRC | {tag}"
        idx = text.find(marker)
        assert idx != -1, f"8_GrRC: missing subgroup marker {marker!r}"
        starts.append((idx, tag, hu, full))
    pre = text[:starts[0][0]]
    pieces = [pre]
    for i, (start, tag, hu, full) in enumerate(starts):
        end = starts[i + 1][0] if i + 1 < len(starts) else len(text)
        chunk = text[start:end]
        print(f"-- subgroup: {full} -> {hu}")
        s_cuu = chunk.find(f"* 1. Consumption | Urban | Unbalanced | GRC | {tag}")
        s_cub = chunk.find(f"* 2. Consumption | Urban | Balanced | GRC | {tag}")
        s_iuu = chunk.find(f"* 3. Income | Urban | Unbalanced | GRC | {tag}")
        assert s_cuu == 0, f"8_GrRC: subgroup {tag} should start at cuu"
        assert s_cub != -1 and s_iuu != -1, f"8_GrRC: missing sub-marker in {tag}"
        c_cuu = chunk[s_cuu:s_cub]
        c_cub = chunk[s_cub:s_iuu]
        c_iuu = chunk[s_iuu:]
        new_chunks = []
        for spec3, c_chunk in [("cuu", c_cuu), ("cub", c_cub), ("iuu", c_iuu)]:
            old_cs = f"local country_short CHN_{full}"
            new_cs = f"local country_short CHN_{hu}_{spec3}"
            n_cs = c_chunk.count(old_cs)
            c_chunk = c_chunk.replace(old_cs, new_cs)
            c_chunk = c_chunk.replace(
                '"$dir/output/grc_`country_short\'_`estname\'_avg"',
                '"$dir/output/grc_`country_short\'_`estname\'_g"',
            )
            c_chunk = c_chunk.replace(
                "estimates store grc_`country_short'_`estname'_avg",
                "estimates store grc_`country_short'_`estname'_g",
            )
            print(f"   spec3={spec3}: {n_cs} country_short rename(s)")
            new_chunks.append(c_chunk)
        pieces.append("".join(new_chunks))
    write_text(path, "".join(pieces))


# 10/11/12/13: experience family, single section per file, prefix with cuu
def do_10_to_13():
    family_map = {
        "10_GrRC_experience.do": "exp",
        "11_GrRC_max_experience.do": "maxexp",
        "12_GrRC_experience_share.do": "expsh",
        "13_GrRC_max_experience_share.do": "maxexpsh",
    }
    spec3 = "cuu"
    for fname, fam in family_map.items():
        path = SCRIPTS / fname
        text = read_text(path)
        print(f"\n=== {fname} (family={fam}) ===")
        subs = [
            (f'"$dir/output/grc_`country\'_{fam}_`estname\'_never"',
             f'"$dir/output/grc_`country\'_{spec3}_{fam}_`estname\'_n"'),
            (f'"$dir/output/grc_`country\'_{fam}_`estname\'_avg"',
             f'"$dir/output/grc_`country\'_{spec3}_{fam}_`estname\'_g"'),
            (f"grc_`country'_{fam}_`estname'_never",
             f"grc_`country'_{spec3}_{fam}_`estname'_n"),
            (f"grc_`country'_{fam}_`estname'_avg",
             f"grc_`country'_{spec3}_{fam}_`estname'_g"),
            (f'"$dir/output/grc_`country\'_{fam}_`estname\'"',
             f'"$dir/output/grc_`country\'_{spec3}_{fam}_`estname\'"'),
            (f"grc_`country'_{fam}_`estname'",
             f"grc_`country'_{spec3}_{fam}_`estname'"),
            (f"grc_`country'_{fam}_c1", f"grc_`country'_{spec3}_{fam}_c1"),
            (f"grc_`country'_{fam}_c2", f"grc_`country'_{spec3}_{fam}_c2"),
            (f"grc_`country'_{fam}_c3", f"grc_`country'_{spec3}_{fam}_c3"),
            (f"grc_`country'_{fam}_ca", f"grc_`country'_{spec3}_{fam}_ca"),
            (f"spec({fam})", f"spec({spec3}_{fam})"),
        ]
        text = apply_subs(text, subs, fname)
        write_text(path, text)


# 14_GrRC_NonAg_experience.do: 4 sections, all `nonag_exp`. Phase 1a preserves
# the existing collision (only section 4's sters survive on disk after a full
# run); each section's tex_table runs immediately after its own run_grc fits,
# so the produced .tex is bit-identical. Disambiguation lands in Phase 1b.
def do_14():
    path = SCRIPTS / "14_GrRC_NonAg_experience.do"
    text = read_text(path)
    print(f"\n=== {path.name} ===")
    spec3 = "cnu"
    fam = "exp"
    subs = [
        (f'"$dir/output/grc_`country\'_nonag_{fam}_`estname\'_never"',
         f'"$dir/output/grc_`country\'_{spec3}_{fam}_`estname\'_n"'),
        (f'"$dir/output/grc_`country\'_nonag_{fam}_`estname\'_avg"',
         f'"$dir/output/grc_`country\'_{spec3}_{fam}_`estname\'_g"'),
        (f"grc_`country'_nonag_{fam}_`estname'_never",
         f"grc_`country'_{spec3}_{fam}_`estname'_n"),
        (f"grc_`country'_nonag_{fam}_`estname'_avg",
         f"grc_`country'_{spec3}_{fam}_`estname'_g"),
        (f'"$dir/output/grc_`country\'_nonag_{fam}_`estname\'"',
         f'"$dir/output/grc_`country\'_{spec3}_{fam}_`estname\'"'),
        (f"grc_`country'_nonag_{fam}_`estname'",
         f"grc_`country'_{spec3}_{fam}_`estname'"),
        (f"grc_`country'_nonag_{fam}_c1", f"grc_`country'_{spec3}_{fam}_c1"),
        (f"grc_`country'_nonag_{fam}_c2", f"grc_`country'_{spec3}_{fam}_c2"),
        (f"grc_`country'_nonag_{fam}_c3", f"grc_`country'_{spec3}_{fam}_c3"),
        (f"grc_`country'_nonag_{fam}_ca", f"grc_`country'_{spec3}_{fam}_ca"),
        (f"spec(nonag_{fam})", f"spec({spec3}_{fam})"),
    ]
    text = apply_subs(text, subs, path.name)
    write_text(path, text)


# 15_GrRC_birth.do: 2 sections (cuu, cub). Phase 1a preserves collision per
# spec recommendation: both sections use `cuu_birth` prefix. .tex output
# identical because each section's tex_table runs immediately after its fits.
def do_15():
    path = SCRIPTS / "15_GrRC_birth.do"
    text = read_text(path)
    print(f"\n=== {path.name} ===")
    spec3 = "cuu"
    fam = "birth"
    subs = [
        (f'"$dir/output/grc_`country\'_{fam}_`estname\'_never"',
         f'"$dir/output/grc_`country\'_{spec3}_{fam}_`estname\'_n"'),
        (f'"$dir/output/grc_`country\'_{fam}_`estname\'_avg"',
         f'"$dir/output/grc_`country\'_{spec3}_{fam}_`estname\'_g"'),
        (f"grc_`country'_{fam}_`estname'_never",
         f"grc_`country'_{spec3}_{fam}_`estname'_n"),
        (f"grc_`country'_{fam}_`estname'_avg",
         f"grc_`country'_{spec3}_{fam}_`estname'_g"),
        (f'"$dir/output/grc_`country\'_{fam}_`estname\'"',
         f'"$dir/output/grc_`country\'_{spec3}_{fam}_`estname\'"'),
        (f"grc_`country'_{fam}_`estname'",
         f"grc_`country'_{spec3}_{fam}_`estname'"),
        (f"grc_`country'_{fam}_c1", f"grc_`country'_{spec3}_{fam}_c1"),
        (f"grc_`country'_{fam}_c2", f"grc_`country'_{spec3}_{fam}_c2"),
        (f"grc_`country'_{fam}_c3", f"grc_`country'_{spec3}_{fam}_c3"),
        (f"grc_`country'_{fam}_ca", f"grc_`country'_{spec3}_{fam}_ca"),
        (f"spec({fam})", f"spec({spec3}_{fam})"),
    ]
    text = apply_subs(text, subs, path.name)
    write_text(path, text)


# 16_heterogeneity_tables.do: read-only against urban max-cov sters
def do_16():
    path = SCRIPTS / "16_heterogeneity_tables.do"
    text = read_text(path)
    print(f"\n=== {path.name} ===")
    subs = [
        ('"$dir/output/grc_`country\'_urban_covs_all_delta"',
         '"$dir/output/grc_`country\'_cuu_ca_d"'),
        ('"$dir/output/grc_`country\'_urban_covs_all"',
         '"$dir/output/grc_`country\'_cuu_ca"'),
        ("grc_`country'_u_covs_all_delta", "grc_`country'_cuu_ca_d"),
        ("grc_`country'_u_covs_all", "grc_`country'_cuu_ca"),
    ]
    text = apply_subs(text, subs, path.name)
    write_text(path, text)


def main():
    do_5()
    do_6()
    do_8()
    do_10_to_13()
    do_14()
    do_15()
    do_16()
    print("\nDone. Run a Tier 1 grep audit next.")


if __name__ == "__main__":
    main()
