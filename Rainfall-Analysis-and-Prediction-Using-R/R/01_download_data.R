# 01_download_data.R
# Download daily precipitation data from Open-Meteo's historical API.

required <- c("httr2", "jsonlite", "readr", "dplyr")
missing <- required[!vapply(required, requireNamespace, logical(1), quietly = TRUE)]
if (length(missing)) {
  stop("Install missing packages first: install.packages(c(",
       paste(sprintf('"%s"', missing), collapse = ", "), "))")
}

dir.create("data/raw", recursive = TRUE, showWarnings = FALSE)
dir.create("results", recursive = TRUE, showWarnings = FALSE)

# Project settings: edit these if you want another location or date range.
latitude <- 22.5726
longitude <- 88.3639
location_name <- "Kolkata, India"
start_date <- "2016-01-01"
end_date <- "2025-12-31"

endpoint <- "https://archive-api.open-meteo.com/v1/archive"
request_url <- paste0(
  endpoint, "?latitude=", latitude,
  "&longitude=", longitude,
  "&start_date=", start_date,
  "&end_date=", end_date,
  "&daily=precipitation_sum",
  "&timezone=Asia%2FKolkata"
)

message("Requesting daily precipitation for ", location_name, " ...")
response <- httr2::request(request_url) |>
  httr2::req_user_agent("RainfallAnalysisRStudentProject/1.0") |>
  httr2::req_timeout(60) |>
  httr2::req_perform()

if (httr2::resp_status(response) != 200) {
  stop("API request failed with HTTP status ", httr2::resp_status(response),
       ". Check internet access, dates, and API documentation.")
}

payload <- httr2::resp_body_json(response, simplifyVector = TRUE)
if (is.null(payload$daily$time) || is.null(payload$daily$precipitation_sum)) {
  stop("Expected daily time and precipitation_sum fields were not returned.")
}

rain <- data.frame(
  date = as.Date(payload$daily$time),
  precipitation_mm = as.numeric(payload$daily$precipitation_sum)
)

if (!nrow(rain)) stop("The API returned no observations.")

readr::write_csv(rain, "data/raw/kolkata_daily_rainfall.csv", na = "")
metadata <- data.frame(
  location = location_name,
  latitude = latitude,
  longitude = longitude,
  start_date_requested = start_date,
  end_date_requested = end_date,
  retrieval_date = as.character(Sys.Date()),
  source = endpoint,
  variable = "precipitation_sum (mm/day)"
)
readr::write_csv(metadata, "results/data_source_metadata.csv")

message("Saved ", nrow(rain), " rows to data/raw/kolkata_daily_rainfall.csv")
message("Data range returned: ", min(rain$date), " to ", max(rain$date))
message("Source metadata saved to results/data_source_metadata.csv")
