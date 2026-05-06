# Data Codebook

Both datasets are CSV exports from R. The leading column `X` is the exported row name and has no analytical meaning.

## `security_issue_density_by_sprint.csv`

The dataset has 84 rows, one for each combination of team, repository layer, and sprint assessment point (14 × 2 × 3).

| Column | Definition |
|---|---|
| `ID` | Team identifier. |
| `Language` | Implementation language at the assessment point: `Java` or `Kotlin`. |
| `LOC` | Non-comment lines of code over `.java` and `.kt` files. |
| `issues` | Total scanner findings (Bearer + Detekt + mobsfscan). |
| `IpLOC` | Security issue density, computed as `issues / LOC`. |
| `grp` | Experimental condition: `CON` (control) or `SEC` (security-incentivized). |
| `Was` | Repository layer: `Backend` or `Frontend`. |
| `Runde` | Sprint assessment point: `1`, `2`, or `3`. |

## `security_issue_density_change.csv`

The dataset has 28 rows, one for each combination of team and repository layer (14 × 2). Each row summarizes the sprint-to-sprint change in security issue density.

| Column | Definition |
|---|---|
| `IDX` | Compact team/layer identifier. The suffix `B` marks back-end and `F` marks front-end. |
| `grp` | Experimental condition: `CON` or `SEC`. |
| `lng1` | Implementation language at sprint 1. |
| `was1` | Repository layer at sprint 1: `Backend` or `Frontend`. |
| `Q21` | `IpLOC_sprint2 / IpLOC_sprint1`. |
| `Q32` | `IpLOC_sprint3 / IpLOC_sprint2`. |

The analysis script uses `Q32 / Q21` for Figure 8 and Tables 8-9.
