# CRAN download counts for the software section.
#
# Reads the committed metrics.toml -- the same cache the website badges use,
# refreshed by R/fetch_metrics.R from the weekly cron (update-metrics.yml).
#
# The CV used to keep a second cache of its own, data/downloads.csv, filled by
# a `make downloads` target that only ever ran by hand. Nothing in CI called
# it, so the PDF served numbers frozen at whenever it was last run while the
# website moved on. One cache, one refresh, one "as of" date.
#
# Still no network at render time: metrics.toml is committed, so the render
# stays a pure function of the repo.

# Named integer vector: software.toml key -> total CRAN downloads.
#
# Keyed by the software.toml section name, which is both what metrics.toml is
# keyed by and what read_entries() hands back as `key` -- so the lookup is an
# exact key match rather than the old guess at the package name from the title.
# Entries with no cran_downloads (C++ libraries, Python packages, anything not
# on CRAN) simply drop out and get no badge.
read_downloads <- function(metrics = read_metrics()) {
  m <- metrics$software
  if (is.null(m) || !length(m)) return(stats::setNames(integer(0), character(0)))
  n <- vapply(m, function(x) suppressWarnings(as.integer(x$cran_downloads %||% NA)),
              integer(1))
  n[!is.na(n) & n > 0]
}

# The date the counts were fetched, as "YYYY-MM-DD", for the "as of" line.
#
# Taken from metrics.toml's own fetched_at rather than the cache file's mtime:
# a git checkout rewrites mtime to the build time, so the old CV stamped
# whatever month it was built in onto however old the numbers happened to be.
downloads_stamp <- function(metrics = read_metrics()) {
  substr(metrics$fetched_at %||% "", 1, 10)
}

# Inline raw-Typst badge; `#dlbadge` is defined in the cv.qmd header.
dl_badge <- function(pkg, counts) {
  if (!length(pkg) || !nzchar(pkg) || !(pkg %in% names(counts))) return("")
  n <- counts[[pkg]]
  if (is.na(n)) return("")
  sprintf(" `#dlbadge(\"%s\")`{=typst}", format(n, big.mark = ","))
}
