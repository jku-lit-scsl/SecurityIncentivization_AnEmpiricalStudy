# --- preps for eval

  library(betareg)

  cgrps = c("sienna2","green3")
  xlabs = c("B-CON-1","F-CON-1","B-SEC-1","F-SEC-1",
            "B-CON-2","F-CON-2","B-SEC-2","F-SEC-2",
            "B-CON-3","F-CON-3","B-SEC-3","F-SEC-3")

  dir.create("outputs/figures", recursive = TRUE, showWarnings = FALSE)

# --- read data

  d0 = read.csv("data/security_issue_density_by_sprint.csv")
  d1 = read.csv("data/security_issue_density_change.csv")

# --- Sec. 5: Results ----------------------------------------------------------

# Tab. 3: Agreement language & what
  with(d1, addmargins(table(was1,lng1)))


# --- Sec. 5.1: Global Effect --------------------------------------------------

# Fig. 4: Boxplots of Issues/LOC
  pdf("outputs/figures/fig4_security_issue_density_by_group.pdf", width=8, height=5)
  par(mar=c(2,2,0,0)+0.2)
      bx = boxplot(IpLOC ~ as.factor(grp),
                   col=cgrps,varwidth=TRUE,notch=TRUE,boxwex=0.5,data=d0)
  dev.off()

  bx$conf  # CI reported in Sec. 5.1

# Tab. 4: Issues/LOC by CON/SEC
  mod0 = betareg(IpLOC ~ as.factor(grp), data=d0)
  summary(mod0)


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


# Tab. 5: Issues by what, group, & sprint (poisson)
  mod1 = glm(LOC ~ as.factor(Was)*as.factor(grp)*as.factor(Runde),data=d0,family="poisson")
  summary(mod1)    # Tab 5 -- poisson
  exp(coef(mod1))



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

# Tab. 6
  mod2 = glm(issues ~ as.factor(Was)*as.factor(grp)*as.factor(Runde),data=d0,family='poisson')
  summary(mod2)

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

# Tab. 7
  mod3 = betareg(IpLOC ~ as.factor(Was)*as.factor(grp)*as.factor(Runde),data=d0)
  summary(mod3)


# --- Sec 5.5: The Reward / DeltaQ ---------------------------------------------

# Fig. 8
  pdf("outputs/figures/fig8_relative_change_security_issue_density.pdf", width=14, height=7)
  par(mar=c(2,4,0,0)+0.2)
      boxplot(Q32/Q21 ~grp*was1,col=cgrps,data=d1,ylim=c(0,10),ylab=expression(Q[32] / Q[21]))
      arrows(2,9.2,2,9.8,code=2,length=0.1,angle=12)
      text(2,9,"+ 1 outlier at 24",cex=0.8,font=2)
  dev.off()

# Tab. 8
  mod4 = lm(Q32/Q21 ~grp*was1, data=d1)
  summary(mod4)

# Tab. 9
  with(d1, round(tapply(Q32/Q21, list(grp,was1), mean),2))

