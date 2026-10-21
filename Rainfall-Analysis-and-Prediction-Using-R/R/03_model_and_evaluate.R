# 03_model_and_evaluate.R
# Compare seasonal-naive and ETS forecasts using a chronological holdout.
required <- c("readr", "dplyr", "lubridate", "forecast", "ggplot2", "tidyr")
missing <- required[!vapply(required, requireNamespace, logical(1), quietly = TRUE)]
if (length(missing)) stop("Install missing packages: ", paste(missing, collapse = ", "))

input_file <- "data/processed/kolkata_daily_rainfall_clean.csv"
if (!file.exists(input_file)) {
  stop("Cleaned data not found. Run R/02_clean_and_eda.R first.")
}
dir.create("plots", recursive = TRUE, showWarnings = FALSE)
dir.create("results", recursive = TRUE, showWarnings = FALSE)

data <- readr::read_csv(input_file, show_col_types = FALSE) |>
  dplyr::mutate(date = as.Date(date)) |>
  dplyr::arrange(date)

# For a robust introductory forecast exercise, aggregate daily totals to monthly totals.
monthly <- data |>
  dplyr::mutate(month_start = as.Date(format(date, "%Y-%m-01"))) |>
  dplyr::group_by(month_start) |>
  dplyr::summarise(
    rainfall_mm = if (all(is.na(precipitation_mm))) NA_real_
                  else sum(precipitation_mm, na.rm = TRUE),
    .groups = "drop"
  )

# Missing entire months are not silently converted to zero; interpolate only for
# model continuity and report the limitation. Partial months with some observations
# are summed, so review the missingness report before interpreting results.
if (anyNA(monthly$rainfall_mm)) {
  message("Some months have no observed values; linearly interpolating missing monthly totals for this prototype.")
  monthly$rainfall_mm <- forecast::na.interp(monthly$rainfall_mm)
}
readr::write_csv(monthly, "results/monthly_series_used_for_model.csv")

n <- nrow(monthly)
if (n < 36) stop("At least 36 monthly observations are recommended for this model comparison.")
test_n <- max(12, ceiling(0.20 * n))
train_n <- n - test_n
if (train_n < 24) stop("Not enough training months after reserving the test period.")

train <- monthly$rainfall_mm[seq_len(train_n)]
test <- monthly$rainfall_mm[(train_n + 1):n]
test_dates <- monthly$month_start[(train_n + 1):n]

# Seasonal-naive benchmark: same month from previous year.
fit_snaive <- forecast::snaive(
  stats::ts(train, frequency = 12),
  h = test_n
)
pred_snaive <- as.numeric(fit_snaive$mean)

# ETS model chosen using training data only.
fit_ets <- forecast::ets(stats::ts(train, frequency = 12))
fc_ets <- forecast::forecast(fit_ets, h = test_n)
pred_ets <- as.numeric(fc_ets$mean)

calc_metrics <- function(actual, predicted, model_name) {
  data.frame(
    model = model_name,
    MAE_mm = mean(abs(actual - predicted), na.rm = TRUE),
    RMSE_mm = sqrt(mean((actual - predicted)^2, na.rm = TRUE)),
    mean_error_mm = mean(predicted - actual, na.rm = TRUE)
  )
}
metrics <- dplyr::bind_rows(
  calc_metrics(test, pred_snaive, "Seasonal naive"),
  calc_metrics(test, pred_ets, "ETS")
) |>
  dplyr::arrange(RMSE_mm)
readr::write_csv(metrics, "results/model_metrics.csv")

predictions <- data.frame(
  month_start = test_dates,
  actual_mm = test,
  seasonal_naive_mm = pred_snaive,
  ets_mm = pred_ets
)
readr::write_csv(predictions, "results/test_predictions.csv")

plot_data <- predictions |>
  tidyr::pivot_longer(
    cols = c(actual_mm, seasonal_naive_mm, ets_mm),
    names_to = "series", values_to = "rainfall_mm"
  ) |>
  dplyr::mutate(series = dplyr::recode(
    series,
    actual_mm = "Actual",
    seasonal_naive_mm = "Seasonal naive",
    ets_mm = "ETS"
  ))

p <- ggplot2::ggplot(plot_data, ggplot2::aes(month_start, rainfall_mm, linetype = series)) +
  ggplot2::geom_line(linewidth = 0.7) +
  ggplot2::labs(title = "Monthly Rainfall: Actual vs Forecast",
                subtitle = paste("Chronological test period:", min(test_dates), "to", max(test_dates)),
                x = "Month", y = "Rainfall (mm)", linetype = "Series") +
  ggplot2::theme_minimal()
ggplot2::ggsave("plots/forecast_comparison.png", p, width = 10, height = 5.5, dpi = 150)

best <- metrics$model[1]
summary_lines <- c(
  "Rainfall Analysis and Prediction Using R — Model Evaluation",
  paste("Generated:", Sys.Date()),
  paste("Monthly observations:", n),
  paste("Training months:", train_n),
  paste("Test months:", test_n),
  paste("Test start:", min(test_dates)),
  paste("Test end:", max(test_dates)),
  paste("Lowest-RMSE model on this holdout:", best),
  "",
  "Metrics (lower MAE/RMSE is better):",
  capture.output(print(metrics, row.names = FALSE)),
  "",
  "Caution: a single chronological holdout is not proof of general forecasting skill.",
  "Review missingness and source metadata before interpreting the results."
)
writeLines(summary_lines, "results/model_evaluation_summary.txt")
print(metrics)
message("Model evaluation complete. Results saved in results/ and plots/.")
