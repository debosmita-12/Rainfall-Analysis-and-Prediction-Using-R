# Week 2 GitHub Upload Files

These are the Week 2 files for the Rainfall Analysis and Prediction Using R project.

## Included
- `R/02_clean_and_eda.R`: cleans the downloaded rainfall data, computes descriptive statistics, and generates five PNG plots.
- `report/Week_2_EDA_and_Visualization_Rainfall_Analysis.docx`: editable report template with code, explanations, and placeholders for actual outputs.
- `plots/`, `data/processed/`, and `results/`: destination folders for generated outputs.

## Before running
1. Install R and RStudio Desktop.
2. Open the repository root folder in RStudio.
3. Install required packages:
   ```r
   install.packages(c("httr2", "jsonlite", "readr", "dplyr", "ggplot2", "lubridate", "tidyr", "forecast"))
   ```
4. Run the download script first:
   ```r
   source("R/01_download_data.R")
   ```
5. Replace the repository's existing `R/02_clean_and_eda.R` with this file, then run:
   ```r
   source("R/02_clean_and_eda.R")
   ```

## Expected generated files
- `plots/daily_rainfall.png`
- `plots/rainfall_distribution.png`
- `plots/rainfall_by_month.png`
- `plots/rainfall_boxplot.png`
- `plots/missingness.png`
- `data/processed/kolkata_daily_rainfall_clean.csv`
- `results/data_quality_summary.csv`
- `results/descriptive_statistics.csv`
- `results/monthly_rainfall_summary.csv`

The ZIP does not contain fabricated graphs or rainfall results. These files are created from the actual API data when you run the code. Insert the generated graphs and verified statistics into the Word report before submitting.
