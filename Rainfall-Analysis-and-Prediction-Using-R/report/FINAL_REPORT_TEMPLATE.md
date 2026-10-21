# Rainfall Trend Analysis and Prediction Using R

## Abstract
Summarize the study area, data period, methods, key measured findings, and limitations after running the scripts.

## 1. Introduction
Explain why rainfall patterns matter and state the research question.

## 2. Objectives
- Describe historical rainfall patterns.
- Assess data quality and missingness.
- Compare baseline monthly rainfall forecasts.

## 3. Data Source
- Provider and exact endpoint:
- Location:
- Period returned:
- Retrieval date:
- Variable and units:
- Known coverage or data limitations:

## 4. Methodology
Describe cleaning, EDA, monthly aggregation, chronological split, seasonal-naive benchmark, ETS model, and metrics.

## 5. Results
Insert charts from `plots/` and metrics from `results/model_metrics.csv`. Do not invent or copy example results; use the output from your own run.

## 6. Discussion
Explain seasonality, zero-rainfall days, forecast errors, and whether either model improved on the baseline.

## 7. Risks and Limitations
Discuss missing data, source limitations, short evaluation period, model uncertainty, and why this is not an operational weather forecast.

## 8. Conclusion and Future Work
Summarize the evidence and propose next steps such as rolling-origin evaluation, comparison across locations, or additional predictors.

## References
- Open-Meteo Historical Weather API: https://open-meteo.com/en/docs/historical-weather-api
- Hyndman, R. J. and Athanasopoulos, G. *Forecasting: Principles and Practice*: https://otexts.com/fpp3/
- R Project: https://www.r-project.org/
