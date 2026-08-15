#!/usr/bin/env Rscript
#
# Refreshes metrics.toml from OpenAlex, CRAN and GitHub. Run by `make refresh`
# -- never by a render. This is the only script in the repo allowed to open a
# socket; everything else reads the committed cache.
#
# Contract:
#   * always exits 0. A refresh failing must never fail a build.
#   * a failed lookup keeps the previous value rather than blanking it.
#   * a total failure writes nothing at all.
#
# Why OpenAlex and not Google Scholar: Scholar has no public API and blocks
# automated requests with a CAPTCHA, so a scheduled job against it would fail
# intermittently and silently. OpenAlex is free, keyless, matches on DOI, and
# additionally reports each author's institution.
#
# Usage: Rscript R/fetch_metrics.R [--force]

local({

root <- if (file.exists("papers.toml")) "." else ".."
source(file.path(root, "R", "entries.R"))

FORCE       <- "--force" %in% commandArgs(TRUE)
MAX_AGE     <- 7    # days before a hit is re-checked
MISS_MAX    <- 30   # days before a miss is retried
MAILTO      <- Sys.getenv("OPENALEX_MAILTO", "g.vegayon@gmail.com")
OUT         <- file.path(root, "metrics.toml")
NOW         <- format(Sys.time(), "%Y-%m-%dT%H:%M:%SZ", tz = "UTC")
TODAY       <- as.Date(NOW)

say <- function(...) message(sprintf(...))

# ------------------------------------------------------------------ http

gh_token <- function() {
  tok <- Sys.getenv("GITHUB_TOKEN", "")
  if (nzchar(tok)) return(tok)
  # locally, borrow the gh CLI's token; 60 req/hr unauthenticated is not
  # enough for 23 repos on a shared runner IP
  tryCatch(trimws(system2("gh", c("auth", "token"), stdout = TRUE, stderr = NULL)[1]),
           error = function(e) "", warning = function(w) "")
}

get_json <- function(url, headers = character(0)) {
  tryCatch({
    h <- curl::new_handle()
    hdr <- c("User-Agent" = paste0("ggvy-website (", MAILTO, ")"), headers)
    curl::handle_setheaders(h, .list = as.list(hdr))
    resp <- curl::curl_fetch_memory(url, handle = h)
    if (resp$status_code >= 400) {
      say("  ! HTTP %d for %s", resp$status_code, substr(url, 1, 90))
      return(NULL)
    }
    jsonlite::fromJSON(rawToChar(resp$content), simplifyVector = FALSE)
  }, error = function(e) {
    say("  ! %s", conditionMessage(e))
    NULL
  })
}

stale <- function(entry, max_days) {
  if (FORCE || is.null(entry)) return(TRUE)
  d <- suppressWarnings(as.Date(substr(entry$checked_at %||% "", 1, 10)))
  is.na(d) || as.numeric(TODAY - d) >= max_days
}

# ------------------------------------------------------------------ load

papers   <- read_entries(file.path(root, "papers.toml"))
software <- read_entries(file.path(root, "software.toml"))

old <- list()
if (file.exists(OUT) && requireNamespace("toml", quietly = TRUE)) {
  old <- tryCatch(toml::read_toml(OUT), error = function(e) list())
}
res_papers <- old$papers %||% list()
res_soft   <- old$software %||% list()

# --------------------------------------------------------------- openalex

SELECT <- "id,doi,title,publication_year,cited_by_count,authorships,best_oa_location"

norm_title <- function(x) tolower(gsub("[^a-z0-9 ]", "", tolower(trimws(x))))

# Only the entries that are actually due, so the weekly cron is cheap.
due <- Filter(function(e) stale(res_papers[[e$key]], MAX_AGE), papers)
say("openalex: %d of %d papers due", length(due), length(papers))

by_doi <- Filter(function(e) nzchar(e$fields$doi %||% ""), due)
if (length(by_doi)) {
  dois <- vapply(by_doi, function(e) e$fields$doi, character(1))
  # One request per 50 DOIs rather than one per paper.
  for (chunk in split(dois, ceiling(seq_along(dois) / 50))) {
    url <- sprintf("https://api.openalex.org/works?filter=doi:%s&per-page=50&select=%s&mailto=%s",
                   paste(utils::URLencode(chunk, reserved = TRUE), collapse = "|"),
                   SELECT, utils::URLencode(MAILTO, reserved = TRUE))
    js <- get_json(url)
    if (is.null(js)) next

    for (w in js$results %||% list()) {
      hit_doi <- sub("^https?://doi.org/", "", tolower(w$doi %||% ""))
      key <- NULL
      for (e in by_doi) if (identical(tolower(e$fields$doi), hit_doi)) { key <- e$key; break }
      if (is.null(key)) next
      res_papers[[key]] <- list(
        openalex   = sub("^https?://openalex.org/", "", w$id %||% ""),
        citations  = as.integer(w$cited_by_count %||% 0L),
        matched_by = "doi",
        checked_at = NOW
      )
    }
    Sys.sleep(0.25)
  }
}

# Title fallback, for entries with no DOI. Deliberately strict: a wrong
# citation count is worse than a missing one.
no_doi <- Filter(function(e) !nzchar(e$fields$doi %||% ""), due)
for (e in no_doi) {
  prev <- res_papers[[e$key]]
  if (!is.null(prev$miss) && !stale(prev, MISS_MAX)) next

  ttl <- e$fields$title %||% ""
  if (!nzchar(ttl)) next
  # `,` `|` and `:` are filter syntax to OpenAlex, so a title containing them
  # returns a 400 rather than a match. Search on the words alone.
  q <- trimws(gsub("[[:space:]]+", " ", gsub("[^[:alnum:] ]", " ", ttl)))
  if (!nzchar(q)) next
  js <- get_json(sprintf(
    "https://api.openalex.org/works?filter=title.search:%s&per-page=5&select=%s&mailto=%s",
    utils::URLencode(q, reserved = TRUE), SELECT, utils::URLencode(MAILTO, reserved = TRUE)))
  Sys.sleep(0.25)

  yr <- suppressWarnings(as.integer(substr(e$fields$year %||% "", 1, 4)))
  best <- NULL
  for (w in (js$results %||% list())) {
    a <- norm_title(ttl); b <- norm_title(w$title %||% "")
    if (!nchar(a) || !nchar(b)) next
    sim <- 1 - (utils::adist(a, b)[1, 1] / max(nchar(a), nchar(b)))
    yok <- is.na(yr) || is.null(w$publication_year) ||
           abs(as.integer(w$publication_year) - yr) <= 1
    if (sim >= 0.9 && yok) { best <- w; break }
  }

  if (is.null(best)) {
    res_papers[[e$key]] <- list(miss = "no-doi-no-title-match", checked_at = NOW)
  } else {
    res_papers[[e$key]] <- list(
      openalex   = sub("^https?://openalex.org/", "", best$id %||% ""),
      citations  = as.integer(best$cited_by_count %||% 0L),
      matched_by = "title",
      checked_at = NOW
    )
  }
}

# ------------------------------------------------------------------ cran

cran_pkgs <- unique(unlist(lapply(software, function(e) e$fields$cran %||% NULL)))
cran_pkgs <- cran_pkgs[nzchar(cran_pkgs)]

dl <- list()
if (length(cran_pkgs)) {
  js <- get_json(sprintf("https://cranlogs.r-pkg.org/downloads/total/2012-10-01:%s/%s",
                         format(TODAY), paste(cran_pkgs, collapse = ",")))
  for (row in (js %||% list())) dl[[row$package %||% ""]] <- as.integer(row$downloads %||% 0L)
  say("cran: downloads for %d packages", length(dl))
}

# ---------------------------------------------------------------- github

TOKEN <- gh_token()
if (!nzchar(TOKEN)) say("github: no token (GITHUB_TOKEN or `gh auth token`) -- 60 req/hr limit applies")
gh_headers <- if (nzchar(TOKEN)) c(Authorization = paste("Bearer", TOKEN)) else character(0)

for (e in software) {
  f <- e$fields
  prev <- res_soft[[e$key]] %||% list()
  cur  <- prev

  pkg <- f$cran %||% ""
  if (nzchar(pkg)) {
    if (!is.null(dl[[pkg]])) cur$cran_downloads <- dl[[pkg]]
    if (stale(prev, MAX_AGE)) {
      js <- get_json(paste0("https://crandb.r-pkg.org/", pkg))
      if (!is.null(js)) {
        cur$cran_version <- js$Version %||% cur$cran_version %||% ""
        cur$license      <- js$License %||% cur$license %||% ""
      }
    }
  }

  repo <- sub("^https?://github.com/", "", f$repo %||% "")
  repo <- sub("/+$", "", repo)
  if (nzchar(repo) && stale(prev, MAX_AGE)) {
    js <- get_json(paste0("https://api.github.com/repos/", repo), gh_headers)
    if (!is.null(js)) {
      cur$stars    <- as.integer(js$stargazers_count %||% 0L)
      cur$pushed_at <- substr(js$pushed_at %||% "", 1, 10)
      cur$archived <- isTRUE(js$archived)
    }
  }

  if (length(cur)) {
    cur$checked_at <- NOW
    res_soft[[e$key]] <- cur
  }
}

# ----------------------------------------------------------------- write

# Hand-rolled TOML writer: the `toml` package reads but does not write, and
# the output stays in the repo's idiom so `git diff metrics.toml` is the audit
# trail for every number on the site.
esc_toml <- function(x) gsub("'", "", as.character(x), fixed = TRUE)

fmt_val <- function(v) {
  if (is.logical(v)) return(if (isTRUE(v)) "true" else "false")
  if (is.numeric(v)) return(format(v, scientific = FALSE))
  paste0("'", esc_toml(v), "'")
}

emit <- function(section, tbl) {
  out <- character(0)
  for (key in sort(names(tbl))) {
    vals <- tbl[[key]]
    if (!length(vals)) next
    # bare keys only where TOML allows them
    hdr <- if (grepl("^[A-Za-z0-9_-]+$", key)) key else paste0("'", key, "'")
    out <- c(out, sprintf("[%s.%s]", section, hdr))
    for (n in names(vals)) out <- c(out, sprintf("%s = %s", n, fmt_val(vals[[n]])))
    out <- c(out, "")
  }
  out
}

if (!length(res_papers) && !length(res_soft)) {
  say("nothing fetched and no previous cache -- leaving %s untouched", OUT)
} else {
  lines <- c(
    "# Generated by R/fetch_metrics.R (`make refresh`) -- do not edit by hand.",
    "#",
    "# Citation counts come from OpenAlex, downloads and versions from CRAN,",
    "# stars from GitHub. Everything here is a number the site displays with an",
    "# \"as of\" date; nothing here overrides papers.toml or software.toml.",
    "",
    sprintf("fetched_at = '%s'", NOW),
    "",
    emit("papers", res_papers),
    emit("software", res_soft)
  )
  writeLines(lines, OUT, useBytes = TRUE)
  say("wrote %s: %d papers, %d software", OUT, length(res_papers), length(res_soft))
}

})

invisible(quit(status = 0))
