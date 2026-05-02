# Benchmark R clubSandwich on the same TZA covs_trend design matrix at
# the same J values used in the Stata benchmark.  Reads the Stata .dta
# (via haven), fits OLS, computes vcovCR(type="CR2"), runs Wald_test
# with constrain_zero on (beta_s_4, beta_s_5, beta_s_6, beta_s_7).
# Times each subsample identically to the Stata script.

suppressPackageStartupMessages({
  if (!requireNamespace("haven", quietly = TRUE)) {
    install.packages("haven", repos = "https://cloud.r-project.org", quiet = TRUE)
  }
  library(haven)
  library(clubSandwich)
})

set.seed(20260501)

df <- read_dta("tza_covs_trend_design.dta")
df <- as.data.frame(df)
cat(sprintf("loaded: rows=%d, clusters=%d\n", nrow(df), length(unique(df$pid))))

formula_str <- paste(
  "lndepvar ~",
  paste(c(paste0("alpha_d_", 1:8),
          paste0("beta_s_", c(2, 4, 5, 6, 7)),
          "unbalanced", "unbalanced_choice",
          "period_2", "period_3"),
        collapse = " + ")
)
cat("formula: ", formula_str, "\n")

contrast_names <- c("beta_s_4", "beta_s_5", "beta_s_6", "beta_s_7")

run_one <- function(J_target) {
  pids <- unique(df$pid)
  if (J_target >= length(pids)) {
    sub <- df
  } else {
    keep_pids <- sample(pids, J_target)
    sub <- df[df$pid %in% keep_pids, ]
  }
  cat(sprintf(">>> J_target=%d, J_actual=%d, N=%d\n",
              J_target, length(unique(sub$pid)), nrow(sub)))

  t0 <- Sys.time()
  m <- lm(as.formula(formula_str), data = sub)
  V <- vcovCR(m, cluster = sub$pid, type = "CR2")
  res <- Wald_test(m, constraints = constrain_zero(contrast_names, coef(m)),
                   vcov = V, test = "HTZ")
  t1 <- Sys.time()
  wall <- as.numeric(t1 - t0, units = "secs")
  cat(sprintf("    wall=%.2f s  F=%.6e  df2=%.4e  p=%.4e\n",
              wall, res$Fstat, res$df_denom, res$p_val))
  data.frame(
    J = length(unique(sub$pid)),
    N = nrow(sub),
    wall_sec = wall,
    F_stat = res$Fstat,
    F_df1 = res$df_num,
    F_df2 = res$df_denom,
    F_pvalue = res$p_val
  )
}

rows <- list()
for (J in c(100, 500, 1000, 2000, 5000, 11012)) {
  out <- tryCatch(run_one(J), error = function(e) {
    cat(sprintf("    ERROR at J=%d: %s\n", J, conditionMessage(e)))
    data.frame(J = J, N = NA, wall_sec = NA,
               F_stat = NA, F_df1 = NA, F_df2 = NA, F_pvalue = NA)
  })
  rows[[length(rows) + 1]] <- out
}

bench <- do.call(rbind, rows)
write.csv(bench, "benchmark_clubsandwich_r_out.csv", row.names = FALSE)
cat("wrote benchmark_clubsandwich_r_out.csv\n")
print(bench)
