# CRAN download counts for the software section.
#
# Deliberately cached to disk rather than fetched at render time: a render that
# silently depends on the network is the same trap as sync_papers_bib(). Run
# `make downloads` to refresh; the render only ever reads the cache, and simply
# omits the badges if it is missing.

CRAN_EPOCH <- "2012-10-01"   # start of cranlogs coverage

# Package name = the token before the first ":" in the bib title
# ("rgexf: Build, Import and Export GEXF Graph Files" -> "rgexf").
pkg_name <- function(e) trimws(sub(":.*$", "", clean_tex(e$fields$title %||% "")))

fetch_downloads <- function(bib = "../software.bib", out = "data/downloads.csv") {
  stopifnot(requireNamespace("jsonlite", quietly = TRUE))
  pkgs <- unique(Filter(nzchar, vapply(parse_bib(bib), pkg_name, character(1))))

  url <- sprintf("https://cranlogs.r-pkg.org/downloads/total/%s:%s/%s",
                 CRAN_EPOCH, Sys.Date(), paste(pkgs, collapse = ","))

  res <- tryCatch(jsonlite::fromJSON(url), error = function(e) {
    message("cranlogs unreachable: ", conditionMessage(e)); NULL
  })
  if (is.null(res) || !nrow(res)) return(invisible(NULL))

  df <- data.frame(package = res$package,
                   downloads = as.integer(res$downloads),
                   stringsAsFactors = FALSE)
  # Packages that are not on CRAN come back as 0; drop them so the renderer
  # can distinguish "no badge" from "zero downloads".
  df <- df[!is.na(df$downloads) & df$downloads > 0, ]
  df <- df[order(-df$downloads), ]

  dir.create(dirname(out), showWarnings = FALSE, recursive = TRUE)
  utils::write.csv(df, out, row.names = FALSE)
  message(sprintf("wrote %s (%d of %d packages on CRAN, %s total downloads)",
                  out, nrow(df), length(pkgs),
                  format(sum(df$downloads), big.mark = ",")))
  invisible(df)
}

read_downloads <- function(path = "data/downloads.csv") {
  if (!file.exists(path)) return(stats::setNames(integer(0), character(0)))
  d <- utils::read.csv(path, stringsAsFactors = FALSE)
  stats::setNames(as.integer(d$downloads), d$package)
}

# Inline raw-Typst badge; `#dlbadge` is defined in the cv.qmd header.
dl_badge <- function(pkg, counts) {
  if (!length(pkg) || !nzchar(pkg) || !(pkg %in% names(counts))) return("")
  n <- counts[[pkg]]
  if (is.na(n)) return("")
  sprintf(" `#dlbadge(\"%s\")`{=typst}", format(n, big.mark = ","))
}
