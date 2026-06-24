Hey both, I found two issues in the GRC code that I wanted to flag. Both are my bugs from the original replication package.

**1. Base trajectory mismatch in the GMM estimation**

When we estimate the restricted GRC, we pick a baseline switcher trajectory. The baseline shows up in three places: (a) the `switcherpars` string that builds the $\phi(\mu_s - \mu_{\underline{d}_0})$ interactions, (b) the always-urban term in the GMM residual, and (c) the `nlcom` that extrapolates $\Delta_{\text{never}}$.

The problem is that (a) uses a hardcoded base (trajectory 2) via `define_switcherpars, base(2)`, while (b) and (c) use a data-adaptive base that `initial_values` picks by choosing the switcher with the highest t-statistic. When these differ, the moment condition is internally inconsistent---part of the equation is normalized to one trajectory and part to another---and the `nlcom` computes $\Delta_{\text{never}}$ with a formula that mixes the two bases.

For consumption-urban specs, I believe `initial_values` picks trajectory 2 anyway, so those results are probably fine. But for income, the data-adaptive base differs (base 16 for IDN, base 5 for TZA), so those results are wrong. The main effect is on $\Delta_{\text{never}}$ (directly computed with the wrong formula). $\phi$ is slightly affected too since the misspecified always-urban moment conditions pull it, but that effect is small because $\phi$ is primarily identified from switcher pairwise comparisons and the always-urban group is tiny.

I'm going to fix this by restructuring `run_grc` so that it calls `define_switcherpars` internally. That way the base is set once and used everywhere---it becomes impossible to mismatch. The `switcherpars()` option disappears from all call sites. I'll re-run everything afterward and compare to current tables.

**2. Income results**

Separately from the base bug, I'm a bit worried about the income results. When I look at the income GRC tables, the picture is quite different from consumption. In IDN, $\phi$ is *positive* (0.445, significant at 5%) in the preferred spec---the opposite sign from consumption. And $\Delta_{\text{never}}$ is negative and insignificant (-0.088). So the income results say migration is pro-rich, which contradicts the consumption story. TZA income is also unstable: $\Delta_{\text{never}}$ flips from -1.57 to +1.41 and $\phi$ flips sign depending on controls. CHN income is the one country that's consistent with consumption ($\phi$ strongly negative), but cols (2)--(3) don't converge.

Some of the income instability might be caused by the base mismatch (since that's where the bug bites hardest). So step one is fixing the base issue, re-running the income specs, and seeing if the picture improves. If not, I think we need to say something in the paper about the consumption-income discrepancy. Right now the income tables are in the appendix without discussion, and a referee will notice that $\phi$ flips sign for Indonesia.

One framing option: consumption is our primary outcome, income is noisier and harder to measure in developing countries, and the consumption results are what we hang our hat on. But we should be upfront about it.
