# 02_clean_and_eda.R
# Validate data, save a cleaned file, and create exploratory plots.

required <- c("readr", "dplyr", "ggplot2", "lubridate", "tidyr")
missing <- required[!vapply(required, requireNamespace, logical(1), quietly = TRUE)]
if (length(missing)) stop("Install missing packages: ", paste(missing, collapse = ", "))

input_file <- "data/raw/kolkata_daily_rainfall.csv"
if (!file.exists(input_file)) {
  stop("Raw data not found. Run R/01_download_data.R first.")
}

dir.create("data/processed", recursive = TRUE, showWarnings = FALSE)
dir.create("plots", recursive = TRUE, showWarnings = FALSE)
dir.create("results", recursive = TRUE, showWarnings = FALSE)

raw <- readr::read_csv(input_file, show_col_types = FALSE) |>
  dplyr::mutate(date = as.Date(date),
                precipitation_mm = as.numeric(precipitation_mm))

rows_before <- nrow(raw)
duplicate_dates <- sum(duplicated(raw$date))
negative_values <- sum(raw$precipitation_mm < 0, na.rm = TRUE)

# Keep first record per date; negative rainfall values are invalid and set to NA.
clean <- raw |>
  dplyr::arrange(date) |>
  dplyr::distinct(date, .keep_all = TRUE) |>
  dplyr::mutate(
    precipitation_mm = dplyr::if_else(
      !is.na(precipitation_mm) & precipitation_mm < 0,
      NA_real_, precipitation_mm
    ),
    year = lubridate::year(date),
    month = lubridate::month(date, label = TRUE, abbr = TRUE),
    month_number = lubridate::month(date)
  )

# Fill missing calendar dates with NA rainfall rather than inventing observations.
calendar <- data.frame(date = seq(min(clean$date), max(clean$date), by = "day"))
clean <- calendar |>
  dplyr::left_join(clean, by = "date") |>
  dplyr::mutate(
    year = lubridate::year(date),
    month = lubridate::month(date, label = TRUE, abbr = TRUE),
    month_number = lubridate::month(date)
  )

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
if (nrow(observed) < 365) {
  warning("Less than one year of observed values; seasonal interpretation may be limited.")
}

monthly <- observed |>
  dplyr::mutate(month_number = lubridate::month(date),
                year = lubridate::year(date)) |>
  dplyr::group_by(year, month_number) |>
  dplyr::summarise(monthly_rainfall_mm = sum(precipitation_mm), .groups = "drop")
readr::write_csv(monthly, "results/monthly_rainfall_summary.csv")

p1 <- ggplot2::ggplot(observed, ggplot2::aes(date, precipitation_mm)) +
  ggplot2::geom_line(linewidth = 0.25) +
  ggplot2::labs(title = "Daily Rainfall in Kolkata", x = "Date",
                y = "Precipitation (mm/day)") +
  ggplot2::theme_minimal()
ggplot2::ggsave("plots/daily_rainfall.png", p1, width = 10, height = 5, dpi = 150)

p2 <- observed |>
  dplyr::mutate(month = factor(lubridate::month(date, label = TRUE, abbr = TRUE),
                               levels = month.abb)) |>
  ggplot2::ggplot(ggplot2::aes(month, precipitation_mm)) +
  ggplot2::geom_boxplot(outlier.alpha = 0.25) +
  ggplot2::labs(title = "Daily Rainfall Distribution by Month",
                x = "Month", y = "Precipitation (mm/day)") +
  ggplot2::theme_minimal()
ggplot2::ggsave("plots/rainfall_by_month.png", p2, width = 9, height = 5, dpi = 150)

p3 <- ggplot2::ggplot(observed, ggplot2::aes(precipitation_mm)) +
  ggplot2::geom_histogram(bins = 40) +
  ggplot2::labs(title = "Distribution of Daily Rainfall",
                x = "Precipitation (mm/day)", y = "Number of days") +
  ggplot2::theme_minimal()
ggplot2::ggsave("plots/rainfall_distribution.png", p3, width = 9, height = 5, dpi = 150)

p4 <- clean |>
  dplyr::mutate(missing = is.na(precipitation_mm)) |>
  ggplot2::ggplot(ggplot2::aes(date, as.integer(missing))) +
  ggplot2::geom_point(size = 0.4) +
  ggplot2::scale_y_continuous(breaks = c(0, 1), labels = c("Observed", "Missing")) +
  ggplot2::labs(title = "Missing Rainfall Observations", x = "Date", y = "Status") +
  ggplot2::theme_minimal()
ggplot2::ggsave("plots/missingness.png", p4, width = 10, height = 3.5, dpi = 150)

summary_stats <- observed |>
  dplyr::summarise(
    observed_days = dplyr::n(),
    mean_mm = mean(precipitation_mm),
    median_mm = median(precipitation_mm),
    sd_mm = sd(precipitation_mm),
    max_mm = max(precipitation_mm),
    zero_rain_days = sum(precipitation_mm == 0),
    zero_rain_percent = 100 * mean(precipitation_mm == 0)
  )
readr::write_csv(summary_stats, "results/descriptive_statistics.csv")

message("Cleaning and EDA complete. Review plots/ and results/.")
