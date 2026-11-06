# Digital Divide and Income Inequality — Replication Package

<p align="center">
  <img src="cover.png" alt="Digital Divide and Income Inequality research illustration" width="860">
</p>

Research article: **Digital divide and income inequality: causal evidence from Italian provinces**

**Published article:** https://link.springer.com/article/10.1007/s00168-025-01440-z

**DOI:** https://doi.org/10.1007/s00168-025-01440-z

**Repository:** https://github.com/gmonturano/digital_divide_income_ineq

## Overview

The project studies the relationship between broadband expansion and provincial income inequality. The first metadata sheet (TOTALE) defines the TWFE model specifications. The provided processed database is the RData panel referenced in the original income-inequality analysis.

This repository provides the principal econometric source file, the metadata needed to identify the main specifications, the associated data material where redistribution is permitted, and a representative cover figure. Additional auxiliary scripts may be obtained from the authors on request.

## Main estimation design

**Two-way fixed-effects models specified in the TOTALE metadata sheet.** The selected worksheet is copied from the original author-provided metadata workbook. The original worksheet name is preserved. No robustness or auxiliary worksheet is included.

## Replication workflow

```mermaid
flowchart TD
    A[Analysis panel] --> C[Load data]
    B[Selected metadata worksheet] --> D[Read model specifications]
    C --> E[Principal estimation block]
    D --> E
    E --> F[Model estimates and status report]
    F --> G[Compare with published article]
```

## Repository structure

```text
README.md
cover.png
code/
  00_functions.R
  01_main_estimation.R
  meta_fusco.xlsx
db/
  db_finale.RData
```

## Data and metadata

- **Database:** `db/db_finale.RData`. Provincial panel with income-inequality and broadband indicators, supplied by the author.
- **Metadata:** `code/meta_fusco.xlsx`, containing only the worksheet **TOTALE**.

The selected metadata specifications can be evaluated against the supplied processed panel; any missing variables and failed models are reported in `results/model_status.csv`. This package does not claim to reconstruct the entire original preprocessing pipeline.

## Main R scripts

- `code/01_main_estimation.R`: principal documented estimation entry point.
- `code/00_functions.R`: shared metadata parsing, variable checks, estimation, and machine-readable export.

## How to run

From the project root in R or RStudio, install the required R packages and execute:

```r
source("code/01_main_estimation.R")
```

Dependencies: **readxl, plm** (plus base R).

## Outputs

When estimation is feasible, scripts write CSV outputs to `results/`. For metadata-based TWFE models, an accompanying `model_status.csv` indicates which specifications were estimated and which could not be run using the supplied inputs.

Published coefficients and standard errors are documented in the article; they are not guaranteed to be reconstructed from public demonstration inputs.

## Figure

`cover.png` is the representative illustration supplied for this paper. It is displayed at the beginning of this README using a repository-relative path.

## Code availability

The main publicly shareable source files are included here. **The full set of coding files and supplementary implementation details is available from the authors upon reasonable request**, subject to applicable confidentiality and data-sharing restrictions.

## Citation

Please cite the published article when using these materials:

**Digital divide and income inequality: causal evidence from Italian provinces**. https://doi.org/10.1007/s00168-025-01440-z
