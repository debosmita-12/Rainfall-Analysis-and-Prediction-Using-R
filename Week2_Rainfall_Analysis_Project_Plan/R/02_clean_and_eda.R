# 02_clean_and_eda.R
# Week 2: data cleaning, descriptive statistics, and EDA visualizations.
# Run from the repository root after running R/01_download_data.R.

required <- c("readr", "dplyr", "ggplot2", "lubridate", "tidyr")
missing <- required[!vapply(required, requireNamespace, logical(1), quietly = TRUE)]
if (length(missing)) {
  stop("Install missing packages first: install.packages(c(",
       paste(sprintf('"%s"', missing), collapse = ", "), "))")
}

input_file <- "data/raw/kolkata_daily_rainfall.csv"
if (!file.exists(input_file)) {
  stop("Raw data not found. Run R/01_download_data.R first.")
}

dir.create("data/processed", recursive = TRUE, showWarnings = FALSE)
dir.create("plots", recursive = TRUE, showWarnings = FALSE)
dir.create("results", recursive = TRUE, showWarnings = FALSE)

raw <- readr::read_csv(input_file, show_col_types = FALSE)
if (!all(c("date", "precipitation_mm") %in% names(raw))) {
  stop("Expected columns 'date' and 'precipitation_mm' were not found.")
}

raw <- raw |>
  dplyr::mutate(date = as.Date(date),
                precipitation_mm = as.numeric(precipitation_mm)) |>
  dplyr::filter(!is.na(date)) |>
  dplyr::arrange(date)

rows_before <- nrow(raw)
duplicate_dates <- sum(duplicated(raw$date))
negative_values <- sum(raw$precipitation_mm < 0, na.rm = TRUE)

# Keep one record per date. Negative precipitation is treated as invalid/missing.
clean <- raw |>
  dplyr::distinct(date, .keep_all = TRUE) |>
  dplyr::mutate(
    precipitation_mm = dplyr::if_else(
      !is.na(precipitation_mm) & precipitation_mm < 0,
      NA_real_, precipitation_mm
    )
  )

# Complete the daily calendar, but do not invent rainfall values for missing days.
calendar <- data.frame(date = seq(min(clean$date), max(clean$date), by = "day"))
clean <- calendar |>
  dplyr::left_join(clean, by = "date") |>
  dplyr::mutate(
    year = lubridate::year(date),
    month = factor(lubridate::month(date, label = TRUE, abbr = TRUE),
                   levels = month.abb),
    month_number = lubridate::month(date)
  ) |>
  dplyr::arrange(date)

readr::write_csv(clean, "data/processed/kolkata_daily_rainfall_clean.csv", na = "")

quality <- data.frame(
  check = c("Rows in downloaded file", "Duplicate dates found",
            "Negative values found", "Rows after calendar completion",
            "Missing rainfall values after cleaning"),
  value = c(rows_before, duplicate_dates, negative_values, nrow(clean),
            sum(is.na(clean$precipitation_mm)))
)
readr::write_csv(quality, "results/data_quality_summary.csv")

observed <- clean |> dplyr::filter(!is.na(precipitation_mm))
if (nrow(observed) == 0) stop("No valid precipitation observations remain after cleaning.")

# Descriptive statistics
summary_stats <- observed |>
  dplyr::summarise(
    observed_days = dplyr::n(),
    mean_mm = mean(precipitation_mm),
    median_mm = median(precipitation_mm),
    sd_mm = sd(precipitation_mm),
    minimum_mm = min(precipitation_mm),
    q1_mm = as.numeric(stats::quantile(precipitation_mm, 0.25)),
    q3_mm = as.numeric(stats::quantile(precipitation_mm, 0.75)),
    maximum_mm = max(precipitation_mm),
    zero_rain_days = sum(precipitation_mm == 0),
    zero_rain_percent = 100 * mean(precipitation_mm == 0)
  )
readr::write_csv(summary_stats, "results/descriptive_statistics.csv")

# Figure 1: daily rainfall time series
p1 <- ggplot2::ggplot(observed, ggplot2::aes(x = date, y = precipitation_mm)) +
  ggplot2::geom_line(linewidth = 0.25) +
  ggplot2::labs(title = "Daily Rainfall in Kolkata",
                x = "Date", y = "Precipitation (mm/day)") +
  ggplot2::theme_minimal()
ggplot2::ggsave("plots/daily_rainfall.png", p1, width = 10, height = 5, dpi = 150)

# Figure 2: histogram of daily rainfall
p2 <- ggplot2::ggplot(observed, ggplot2::aes(x = precipitation_mm)) +
  ggplot2::geom_histogram(bins = 40, na.rm = TRUE) +
  ggplot2::labs(title = "Distribution of Daily Rainfall",
                x = "Precipitation (mm/day)", y = "Number of days") +
  ggplot2::theme_minimal()
ggplot2::ggsave("plots/rainfall_distribution.png", p2, width = 9, height = 5, dpi = 150)

# Figure 3: monthly rainfall totals (calendar month within each year)
monthly <- observed |>
  dplyr::mutate(month_start = lubridate::floor_date(date, "month")) |>
  dplyr::group_by(month_start) |>
  dplyr::summarise(
    monthly_rainfall_mm = sum(precipitation_mm),
    valid_days = dplyr::n(),
    .groups = "drop"
  )
readr::write_csv(monthly, "results/monthly_rainfall_summary.csv")

p3 <- ggplot2::ggplot(monthly, ggplot2::aes(x = month_start, y = monthly_rainfall_mm)) +
  ggplot2::geom_col() +
  ggplot2::labs(title = "Monthly Rainfall Totals in Kolkata",
                x = "Month", y = "Total precipitation (mm)") +
  ggplot2::theme_minimal()
ggplot2::ggsave("plots/rainfall_by_month.png", p3, width = 10, height = 5, dpi = 150)

# Figure 4: daily rainfall distribution by calendar month
p4 <- ggplot2::ggplot(observed, ggplot2::aes(x = month, y = precipitation_mm)) +
  ggplot2::geom_boxplot(outlier.alpha = 0.25, na.rm = TRUE) +
  ggplot2::labs(title = "Daily Rainfall Distribution by Calendar Month",
                x = "Calendar month", y = "Precipitation (mm/day)") +
  ggplot2::theme_minimal()
ggplot2::ggsave("plots/rainfall_boxplot.png", p4, width = 9, height = 5, dpi = 150)

# Figure 5: missing observations across the daily calendar
p5 <- clean |>
  dplyr::mutate(status = ifelse(is.na(precipitation_mm), "Missing", "Observed")) |>
  ggplot2::ggplot(ggplot2::aes(x = date, y = status)) +
  ggplot2::geom_point(size = 0.5) +
  ggplot2::labs(title = "Missing Rainfall Observations",
                x = "Date", y = "Observation status") +
  ggplot2::theme_minimal()
ggplot2::ggsave("plots/missingness.png", p5, width = 10, height = 3.5, dpi = 150)

message("Week 2 EDA complete. Check plots/, data/processed/, and results/.")
message("Review the generated CSV summaries before writing conclusions.")
