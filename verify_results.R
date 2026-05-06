library(betareg)

repo_dir <- getwd()
work_dir <- tempfile("analysis-reproduction-")
dir.create(file.path(work_dir, "data"), recursive = TRUE)
stopifnot(file.copy(
  file.path(repo_dir, "data", "security_issue_density_by_sprint.csv"),
  file.path(work_dir, "data", "security_issue_density_by_sprint.csv")
))
stopifnot(file.copy(
  file.path(repo_dir, "data", "security_issue_density_change.csv"),
  file.path(work_dir, "data", "security_issue_density_change.csv")
))
old_wd <- setwd(work_dir)
on.exit(setwd(old_wd), add = TRUE)

source(file.path(repo_dir, "reproduce_results.R"), local = environment())

expected_d0_cols <- c("X", "ID", "Language", "LOC", "issues", "IpLOC", "grp", "Was", "Runde")
expected_d1_cols <- c("X", "IDX", "grp", "lng1", "was1", "Q21", "Q32")
stopifnot(identical(names(d0), expected_d0_cols))
stopifnot(identical(names(d1), expected_d1_cols))
stopifnot(nrow(d0) == 84)
stopifnot(nrow(d1) == 28)
stopifnot(length(unique(d0$ID)) == 14)
stopifnot(setequal(unique(d0$ID), c(2:14, 101)))
stopifnot(sum(abs(d0$issues / d0$LOC - d0$IpLOC) > 1e-12) == 0)

# d1 ratios must agree with d0. IDX is <ID>B or <ID>F.
for (i in seq_len(nrow(d1))) {
  idx <- as.character(d1$IDX[i])
  team_id <- as.integer(substr(idx, 1, nchar(idx) - 1))
  layer <- ifelse(substr(idx, nchar(idx), nchar(idx)) == "B", "Backend", "Frontend")
  rows <- d0[d0$ID == team_id & d0$Was == layer, ]
  stopifnot(nrow(rows) == 3)
  q21 <- rows$IpLOC[rows$Runde == 2] / rows$IpLOC[rows$Runde == 1]
  q32 <- rows$IpLOC[rows$Runde == 3] / rows$IpLOC[rows$Runde == 2]
  stopifnot(abs(q21 - d1$Q21[i]) < 1e-12)
  stopifnot(abs(q32 - d1$Q32[i]) < 1e-12)
}

expected_table3 <- matrix(c(11, 0, 11, 3, 14, 17, 14, 14, 28), nrow = 3, byrow = FALSE)
observed_table3 <- with(d1, addmargins(table(was1, lng1)))
stopifnot(all(unname(observed_table3) == expected_table3))

medians <- tapply(d0$IpLOC, d0$grp, median)
stopifnot(abs(medians[["CON"]] - 0.08484972) < 1e-8)
stopifnot(abs(medians[["SEC"]] - 0.05101191) < 1e-8)

mod0_coef <- coef(summary(mod0))$mean
stopifnot(abs(mod0_coef["as.factor(grp)SEC", "Estimate"] - (-0.3962859)) < 1e-7)
stopifnot(abs(mod0_coef["as.factor(grp)SEC", "Pr(>|z|)"] - 0.03415047) < 1e-8)

mod4_coef <- summary(mod4)$coefficients
stopifnot(abs(mod4_coef["(Intercept)", "Estimate"] - 2.7257576) < 1e-7)
stopifnot(abs(mod4_coef["grpSEC", "Estimate"] - 2.1807601) < 1e-7)
stopifnot(abs(mod4_coef["was1Frontend", "Estimate"] - (-0.9163101)) < 1e-7)
stopifnot(abs(mod4_coef["grpSEC:was1Frontend", "Estimate"] - (-2.3035810)) < 1e-7)

observed_table9 <- with(d1, round(tapply(Q32 / Q21, list(grp, was1), mean), 2))
expected_table9 <- matrix(c(2.73, 4.91, 1.81, 1.69), nrow = 2,
                          dimnames = list(c("CON", "SEC"), c("Backend", "Frontend")))
stopifnot(identical(observed_table9, expected_table9))

expected_outputs <- c(
  "outputs/figures/fig4_security_issue_density_by_group.pdf",
  "outputs/figures/fig5_loc_by_group_layer_sprint.pdf",
  "outputs/figures/fig6_security_issues_by_group_layer_sprint.pdf",
  "outputs/figures/fig7_security_issue_density_by_group_layer_sprint.pdf",
  "outputs/figures/fig8_relative_change_security_issue_density.pdf"
)
stopifnot(all(file.exists(file.path(work_dir, expected_outputs))))

cat("analysis reproduction checks passed\n")
