# Read-only access to metrics.toml.
#
# This file NEVER touches the network. metrics.toml is written by
# R/fetch_metrics.R (`make refresh`, run from the weekly cron) and committed,
# so the render is a pure function of the repo.
#
# Every accessor degrades to "nothing to show" rather than erroring: a missing
# or partial cache must cost you the badges and nothing else.

read_metrics <- function(path = NULL) {
  if (is.null(path)) path <- if (file.exists("metrics.toml")) "metrics.toml" else "../metrics.toml"
  if (!file.exists(path)) return(list())
  if (!requireNamespace("toml", quietly = TRUE)) return(list())
  tryCatch(toml::read_toml(path), error = function(e) list())
}

metrics_for <- function(metrics, kind, key) {
  section <- if (identical(kind, "research")) "papers" else "software"
  m <- metrics[[section]]
  if (is.null(m)) return(NULL)
  m[[key]]
}

# Whole-cache timestamp, for the "as of" line under the controls.
metrics_stamp <- function(metrics) {
  substr(metrics$fetched_at %||% "", 1, 10)
}

metric_citations <- function(metrics, kind, key) {
  m <- metrics_for(metrics, kind, key)
  n <- suppressWarnings(as.integer(m$citations %||% NA))
  if (is.na(n)) NULL else n
}

# A package's citation count is its companion paper's -- CRAN DOIs are barely
# cited and would understate the work.
metric_software_citations <- function(metrics, f) {
  paper <- f$paper %||% ""
  if (!nzchar(paper)) return(NULL)
  metric_citations(metrics, "research", paper)
}

metric_num <- function(metrics, kind, key, field) {
  m <- metrics_for(metrics, kind, key)
  n <- suppressWarnings(as.integer(m[[field]] %||% NA))
  if (is.na(n)) NULL else n
}

metric_chr <- function(metrics, kind, key, field) {
  m <- metrics_for(metrics, kind, key)
  v <- m[[field]] %||% ""
  if (nzchar(v)) v else NULL
}

# Big download counts are noise at full precision on a card.
fmt_count <- function(n) {
  if (is.null(n)) return("")
  if (n >= 1e6) return(paste0(round(n / 1e6, 1), "M"))
  if (n >= 1e4) return(paste0(round(n / 1e3), "k"))
  if (n >= 1e3) return(paste0(round(n / 1e3, 1), "k"))
  as.character(n)
}
