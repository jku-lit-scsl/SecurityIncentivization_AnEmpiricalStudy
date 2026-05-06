# --- preps for eval

  library(betareg)

  cgrps = c("sienna2","green3")
  xlabs = c("B-CON-1","F-CON-1","B-SEC-1","F-SEC-1",
            "B-CON-2","F-CON-2","B-SEC-2","F-SEC-2",
            "B-CON-3","F-CON-3","B-SEC-3","F-SEC-3")

  dir.create("outputs/figures", recursive = TRUE, showWarnings = FALSE)
  dir.create("outputs/tables",  recursive = TRUE, showWarnings = FALSE)

# --- helpers for table export

  # Map factor variable names from the dataset/model to paper-facing labels.
  label_var = function(v) {
    switch(v,
      grp      = "Group",
      Was      = "Layer",
      was1     = "Layer",
      lng1     = "Language",
      Language = "Language",
      Runde    = "Sprint",
      v)
  }

  # Strip 'as.factor(X)' wrappers and short prefixes from coefficient names,
  # producing labels like 'LayerFrontend', 'GroupSEC', 'Sprint2'.
  clean_term = function(s) {
    if (s == "(Intercept)") return(s)
    parts = strsplit(s, ":", fixed = TRUE)[[1]]
    cleaned = vapply(parts, function(p) {
      m = regmatches(p, regexec("^as\\.factor\\(([^)]+)\\)(.+)$", p))[[1]]
      if (length(m) == 3) return(paste0(label_var(m[2]), m[3]))
      for (pre in c("Language", "lng1", "was1", "Was", "Runde", "grp")) {
        if (startsWith(p, pre)) {
          return(paste0(label_var(pre), substr(p, nchar(pre) + 1, nchar(p))))
        }
      }
      p
    }, character(1))
    paste(cleaned, collapse = ":")
  }

  signif_marks = function(p) {
    ifelse(p < 0.001, "***",
    ifelse(p < 0.01,  "**",
    ifelse(p < 0.05,  "*",
    ifelse(p < 0.1,   ".",  ""))))
  }

  # Standard coefficient table for lm / glm / betareg (mean model only).
  coef_table_df = function(model) {
    co = if (inherits(model, "betareg")) coef(summary(model))$mean
         else                            summary(model)$coefficients
    data.frame(
      term      = vapply(rownames(co), clean_term, character(1)),
      estimate  = round(unname(co[, 1]), 4),
      std_error = round(unname(co[, 2]), 4),
      statistic = round(unname(co[, 3]), 3),
      p_value   = format.pval(unname(co[, 4]), digits = 4, eps = 2e-16),
      signif    = signif_marks(unname(co[, 4])),
      stringsAsFactors = FALSE,
      row.names = NULL
    )
  }

  save_csv = function(filename, df) {
    write.csv(df, file.path("outputs/tables", filename), row.names = FALSE)
  }

# --- read data

  d0 = read.csv("data/security_issue_density_by_sprint.csv")
  d1 = read.csv("data/security_issue_density_change.csv")

# --- Sec. 5: Results ----------------------------------------------------------

# Tab. 3: Agreement language & layer
  tab3 = with(d1, addmargins(table(was1, lng1)))
  tab3
  save_csv("tab3_language_by_layer.csv",
           cbind(Layer = rownames(tab3), as.data.frame.matrix(tab3)))


# --- Sec. 5.1: Global Effect --------------------------------------------------

# Fig. 4: Boxplots of Issues/LOC
  pdf("outputs/figures/fig4_security_issue_density_by_group.pdf", width=8, height=5)
  par(mar=c(2,2,0,0)+0.2)
      bx = boxplot(IpLOC ~ as.factor(grp),
                   col=cgrps,varwidth=TRUE,notch=TRUE,boxwex=0.5,data=d0)
  dev.off()

  bx$conf  # CI reported in Sec. 5.1

# Tab. 4: Security issue density by group
  mod0 = betareg(IpLOC ~ as.factor(grp), data=d0)
  summary(mod0)
  save_csv("tab4_security_issue_density_by_group.csv", coef_table_df(mod0))


# --- Sec. 5.2: LOC ------------------------------------------------------------

# Fig. 5: Boxplot LOC
  pdf("outputs/figures/fig5_loc_by_group_layer_sprint.pdf", width=14, height=7)
  par(mar=c(2,4,0,0)+0.2)
      with(d0, boxplot(LOC ~ Was*grp*Runde,col=rep(cgrps,each=2),axes=FALSE))
      axis(1,at=1:12,labels=xlabs,font=2)
      axis(2,las=2);box()
      abline(v=c(4.5,8.5))
      text( 2.5,11700,"Sprint 1",font=2,adj=c(0.5,1),cex=1.6)
      text( 6.5,11700,"Sprint 2",font=2,adj=c(0.5,1),cex=1.6)
      text(10.5,11700,"Sprint 3",font=2,adj=c(0.5,1),cex=1.6)
  dev.off()

# Tab. 5: LOC by group, layer, and sprint (Poisson)
  mod1 = glm(LOC ~ as.factor(Was)*as.factor(grp)*as.factor(Runde), data=d0, family="poisson")
  summary(mod1)
  exp(coef(mod1))
  save_csv("tab5_loc_by_group_layer_sprint.csv", coef_table_df(mod1))


# --- Sec. 5.3: Issues ---------------------------------------------------------

# Fig. 6: Boxplot Issues
  pdf("outputs/figures/fig6_security_issues_by_group_layer_sprint.pdf", width=14, height=7)
  par(mar=c(2,4,0,0)+0.2)
      with(d0, boxplot(issues ~ Was*grp*Runde,col=rep(cgrps,each=2),axes=FALSE,ylim=c(0,800)))
      axis(1,at=1:12,labels=xlabs,font=2)
      axis(2);box()
      abline(v=c(4.5,8.5))
      text( 2.5,770,"Sprint 1",font=2,adj=c(0.5,1),cex=2)
      text( 6.5,770,"Sprint 2",font=2,adj=c(0.5,1),cex=2)
      text(10.5,770,"Sprint 3",font=2,adj=c(0.5,1),cex=2)
  dev.off()

# Tab. 6: Security issues by group, layer, and sprint (Poisson)
  mod2 = glm(issues ~ as.factor(Was)*as.factor(grp)*as.factor(Runde), data=d0, family="poisson")
  summary(mod2)
  save_csv("tab6_security_issues_by_group_layer_sprint.csv", coef_table_df(mod2))


# --- Sec. 5.4: Issue Density Revisited (Issues/LOC) ---------------------------

# Fig. 7
  pdf("outputs/figures/fig7_security_issue_density_by_group_layer_sprint.pdf", width=14, height=7)
  par(mar=c(2,4,0,0)+0.2)
      with(d0, boxplot(IpLOC ~ Was*grp*Runde,col=rep(cgrps,each=2),axes=FALSE))
      axis(1,at=1:12,labels=xlabs,font=2)
      axis(2);box()
      abline(v=c(4.5,8.5))
      text( 2.5,0.4,"Sprint 1",font=2,adj=c(0.5,1),cex=2)
      text( 6.5,0.4,"Sprint 2",font=2,adj=c(0.5,1),cex=2)
      text(10.5,0.4,"Sprint 3",font=2,adj=c(0.5,1),cex=2)
  dev.off()

# Tab. 7: Security issue density by group, layer, and sprint (Beta regression)
  mod3 = betareg(IpLOC ~ as.factor(Was)*as.factor(grp)*as.factor(Runde), data=d0)
  summary(mod3)
  save_csv("tab7_security_issue_density_by_group_layer_sprint.csv", coef_table_df(mod3))


# --- Sec 5.5: The Reward / DeltaQ ---------------------------------------------

# Fig. 8
  pdf("outputs/figures/fig8_relative_change_security_issue_density.pdf", width=14, height=7)
  par(mar=c(2,4,0,0)+0.2)
      boxplot(Q32/Q21 ~grp*was1,col=cgrps,data=d1,ylim=c(0,10),ylab=expression(Q[32] / Q[21]))
      arrows(2,9.2,2,9.8,code=2,length=0.1,angle=12)
      text(2,9,"+ 1 outlier at 24",cex=0.8,font=2)
  dev.off()

# Tab. 8: Relative change in security issue density by group and layer
  mod4 = lm(Q32/Q21 ~ grp*was1, data=d1)
  summary(mod4)
  save_csv("tab8_relative_change_security_issue_density.csv", coef_table_df(mod4))

# Tab. 9: Mean relative change by group and layer
  tab9 = with(d1, round(tapply(Q32/Q21, list(grp, was1), mean), 2))
  tab9
  save_csv("tab9_relative_change_means.csv",
           cbind(Group = rownames(tab9), as.data.frame.matrix(tab9)))
