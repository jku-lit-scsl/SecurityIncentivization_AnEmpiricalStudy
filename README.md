# Security Incentivization Replication Package

This repository is the replication package for the statistical analyses in our paper *Security Incentivization: An Empirical Study of how Micropayments Impact Code Security*. It reproduces the reported figures and tables from the derived analysis data.

## Requirements

- R 4.6.0
- R package `betareg` 3.2.4

We verified the package against the versions above. Install `betareg` if needed:

```r
install.packages("betareg", repos = "https://cloud.r-project.org")
```

## Quick start

Regenerate the analysis outputs:

```sh
Rscript reproduce_results.R
```

Run the verification checks:

```sh
Rscript verify_results.R
```

Expected verification output:

```text
analysis reproduction checks passed
```

## Repository layout

- `data/security_issue_density_by_sprint.csv`, `data/security_issue_density_change.csv` — derived analysis datasets.
- `data/codebook.md` — column definitions and derivation formulas for both datasets.
- `outputs/figures/` — regenerated Figures 4-8.
- `outputs/tables/` — regenerated Tables 3-9 as CSVs.
- `reproduce_results.R` — reruns the analysis and regenerates the figures and tables.
- `verify_results.R` — checks the regenerated outputs against the paper's reported results.

## Scope

The package reproduces the statistical results from the derived data shipped here. It does not re-run Bearer, Detekt, or mobsfscan against the original student repositories, and it does not recompute LOC from raw sources. Passing verification therefore confirms the derived analysis, not the raw measurements behind it. We document the measurement protocol below so the derived data are interpretable on their own.

## Measurement protocol

We assessed each team at sprint boundaries `t1`, `t2`, and `t3`. Each team maintained two repositories: an Android client (front-end) and a server (back-end). The sprint-level dataset therefore contains one observation per team, layer, and sprint.

### Scanner versions

- Bearer 1.49.0
- Detekt 1.23.8
- mobsfscan 0.4.5

### Scanner commands

We invoked the scanners as follows:

```sh
podman run --rm -v .\:/temp/scan bearer/bearer:1.49.0 scan /temp/scan --format sarif --output /temp/scan/bearer.sarif --exit-code 0
wget -N https://github.com/detekt/detekt/releases/download/v1.23.8/detekt-cli-1.23.8-all.jar
java -jar detekt-cli-1.23.8-all.jar -i $(pwd) -r sarif:detekt.sarif --max-issues 600
podman run --rm -v ./:/src opensecurity/mobsfscan:0.4.5 /src --no-fail --sarif -o /src/mobsf.sarif
```

### Issue counting

We counted findings per scanner as the number of entries in the SARIF results array, and then summed across the three scanners:

```text
issues = length(bearer.runs[0].results)
       + length(detekt.runs[0].results)
       + length(mobsfscan.runs[0].results)
```

If a scanner produced no findings, it contributed zero to the sum. This covers both an empty SARIF results array and an informational non-SARIF message in place of a report. We kept duplicate findings across scanners, in line with the paper's argument that repeated detections plausibly carry additional weight.

After each scan, we performed the manual checks described in the paper.

### LOC counting

We count LOC over scanner-relevant source files: `.java`, `.kt`, and `AndroidManifest.xml`. We exclude line and block comments.

## Anonymization

We withhold raw study artifacts that could re-identify student teams. The withheld artifacts are:

- Raw student repositories.
- Repository URLs and project-name lists.
- Raw SARIF scanner reports.

The included CSV files contain numeric analysis data and team identifiers only.
