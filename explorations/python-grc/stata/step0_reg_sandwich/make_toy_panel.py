"""
Generate a balanced panel for the AHZ-vs-HTZ Step 0 cross-check.

Design notes:
- J=20 clusters, T=4, N=80. Multi-parameter contrast q=3 (test
  H0: beta_x1 = beta_x2 = beta_x3 = 0).
- Cluster-level random effect alpha_i to give CR2 something to do.
- Three regressors with both within-cluster and between-cluster variation.
- A fourth regressor z stays in the regression to make the design
  non-trivial but is NOT in the joint test.
- y is generated under the null on (x1, x2, x3) so the F-test should
  have correct size; the cross-check itself does not depend on the
  truth being null, but null DGP keeps things readable in the log.
"""

import numpy as np
import pandas as pd
from pathlib import Path

OUT = Path(__file__).resolve().parent / "toy_panel.csv"
RNG = np.random.default_rng(20260501)

J, T = 20, 4
N = J * T

pid = np.repeat(np.arange(1, J + 1), T)
period = np.tile(np.arange(1, T + 1), J)

alpha = RNG.standard_normal(J)
alpha_long = np.repeat(alpha, T)

x1 = RNG.standard_normal(N)
x2 = RNG.standard_normal(N) + 0.3 * alpha_long
x3 = RNG.standard_normal(N) - 0.2 * np.repeat(RNG.standard_normal(J), T)
z = RNG.standard_normal(N)

# True DGP: betas on x1,x2,x3 = 0 (so the joint test is correctly sized);
# z carries a real coefficient and the intercept is 1.
beta0, beta_z = 1.0, 0.4
eps = RNG.standard_normal(N)
y = beta0 + beta_z * z + alpha_long + eps

df = pd.DataFrame(
    {
        "pid": pid,
        "period": period,
        "y": y,
        "x1": x1,
        "x2": x2,
        "x3": x3,
        "z": z,
    }
)

df.to_csv(OUT, index=False, float_format="%.16g")
print(f"wrote {OUT} ({len(df)} rows, {df.shape[1]} cols)")
print(df.head())
print(f"\ny mean={df.y.mean():.6f}, sd={df.y.std(ddof=1):.6f}")
print(f"clusters: {df.pid.nunique()}, periods: {df.period.nunique()}")
