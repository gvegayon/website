# Shared reader for the .toml entry files.
#
# `papers.toml`, `software.toml` and the three `presentations-*.toml` files are
# the source of truth (see README) -- nothing regenerates them. This module
# reads them and provides the handful of derived values that both consumers
# need: formatted author lists, the venue, the canonical link, keyword tests
# and the year/month sort.
#
# Sourced by:
#   - cv/cv.qmd            (via ../R/entries.R) for the Typst CV
#   - research.qmd, software.qmd and their es/ and zh/ counterparts
#
# It reads files and nothing else: no network, no writes. Keep it that way --
# a render that silently depends on the network is the trap the .bib downloads
# used to be.

`%||%` <- function(a, b) if (is.null(a) || !length(a) || !nzchar(trimws(a[1]))) b else a

# ---------------------------------------------------------------- parsing

# Accented characters are stored as literal UTF-8, so there is no accent
# post-processing anywhere downstream. This guard keeps it that way: if a LaTeX
# accent macro ever creeps back in (e.g. pasted from a publisher's BibTeX
# export), the render fails loudly rather than silently printing "Cesantia".
assert_no_accent_macros <- function(...) {
  pat <- "\\\\[`'\"^~][{\\\\a-zA-Z]|\\\\(ss|aa|oe|ae)\\b"
  bad <- character(0)
  for (path in c(...)) {
    ln <- readLines(path, warn = FALSE, encoding = "UTF-8")
    hit <- grep(pat, ln, perl = TRUE)
    if (length(hit)) bad <- c(bad, sprintf("%s:%d: %s", path, hit, trimws(ln[hit])))
  }
  if (length(bad)) {
    stop("LaTeX accent macros found -- replace them with UTF-8:\n",
         paste(bad, collapse = "\n"), call. = FALSE)
  }
  invisible(TRUE)
}

# One TOML table per entry, keyed by citation key. `keywords` arrives as an
# array, `author`/`editor` as one semicolon-separated string (see
# parse_authors); everything else is a string. A missing `toml` package is an
# error rather than an empty list: silently rendering a publications page with
# no publications is the worst outcome.
read_entries <- function(...) {
  if (!requireNamespace("toml", quietly = TRUE)) {
    stop("the 'toml' package is required to read the entry files", call. = FALSE)
  }

  paths <- c(...)
  unlist(lapply(paths, function(path) {
    data <- toml::read_toml(path)
    lapply(names(data), function(key) {
      f <- data[[key]]
      list(type = f$entrytype %||% "misc", key = key, fields = f)
    })
  }), recursive = FALSE)
}

# ---------------------------------------------------------------- authors

# `author` and `editor` hold one string, with the authors in order separated by
# semicolons and each written "Last, First M.":
#
#   author = 'Vega Yon, George G.; de la Haye, Kayla'
#
# The semicolon is what makes the comma unambiguous, which is the whole point:
# a surname of more than one word ("Vega Yon", "de la Haye") cannot be guessed
# from "First Last" and has to be marked by the author. Legacy arrays are still
# accepted so an old file, or a hand edit that reverts to `['A', 'B']`, keeps
# rendering.
parse_authors <- function(x) {
  x <- trimws(as.character(x %||% character(0)))
  if (!length(x)) return(character(0))
  out <- trimws(unlist(strsplit(x, ";", fixed = TRUE)))
  out[nzchar(out)]
}

initials <- function(given) {
  parts <- unlist(strsplit(trimws(given), "[ .]+"))
  parts <- parts[nzchar(parts)]
  if (!length(parts)) return("")
  paste(paste0(toupper(substr(parts, 1, 1)), "."), collapse = " ")
}

# One name into its two halves. "Last, First M." is the documented form; the
# fallback for a comma-less name assumes a one-word surname, which is exactly
# the guess the new format exists to avoid having to make.
split_name <- function(a) {
  a <- trimws(a %||% "")
  if (grepl(",", a, fixed = TRUE)) {
    bits <- strsplit(a, ",")[[1]]
    return(list(last = trimws(bits[1]), given = trimws(paste(bits[-1], collapse = " "))))
  }
  toks <- unlist(strsplit(a, "[[:space:]]+"))
  toks <- toks[nzchar(toks)]
  if (!length(toks)) return(list(last = "", given = ""))
  list(last = toks[length(toks)], given = paste(toks[-length(toks)], collapse = " "))
}

# "Last, First M." -> "Last, F. M."
one_author <- function(a) {
  a <- trimws(a)
  if (!nzchar(a)) return("")
  if (identical(tolower(a), "others")) return("et al.")
  p <- split_name(a)
  if (!nzchar(p$given)) return(p$last)
  paste0(p$last, ", ", initials(p$given))
}

# "{Last}, {First}" for the .bib block on the detail pages.
#
# The braces make each half one unsplittable unit, which is what protects a
# two-word surname: anything that re-tokenises the name on spaces -- a
# reference manager's importer, a style that applies its own von/Last rule,
# `\citeauthor` in a template someone wrote themselves -- cannot turn
# "Vega Yon" into "Yon" or demote "de la Haye" to a particle. They also protect
# the capitalisation, which some styles otherwise lowercase.
#
# The cost is that an abbreviating style (plain, abbrv) reads "{George G.}" as
# a single token and prints "G." rather than "G. G.". Drop the braces around
# p$given below if the middle initial matters more.
#
# `others` is BibTeX's own "et al." marker and must stay bare.
bibtex_name <- function(a) {
  a <- trimws(a)
  if (!nzchar(a)) return("")
  if (identical(tolower(a), "others")) return("others")
  p <- split_name(a)
  if (!nzchar(p$given)) return(sprintf("{%s}", p$last))
  sprintf("{%s}, {%s}", p$last, p$given)
}

SELF <- "Vega Yon"

# `emphasis` wraps the author's own name. The CV wants markdown bold; the
# website wants a <span> it can style. Everything else is identical, so the
# canonicalisation lives here once.
fmt_authors <- function(people, self = SELF, emphasis = function(x) paste0("**", x, "**")) {
  people <- parse_authors(people)
  if (!length(people)) return("")

  out <- vapply(people, function(p) {
    if (grepl(self, p, fixed = TRUE)) {
      # canonicalise: the source spells this name a half-dozen different ways
      emphasis(paste0(self, ", G. G."))
    } else {
      one_author(sub("\\.$", "", p))
    }
  }, character(1), USE.NAMES = FALSE)

  out <- out[nzchar(out)]
  n <- length(out)
  if (n == 0L) return("")
  if (n == 1L) return(out)
  if (identical(out[n], "et al.")) return(paste0(paste(out[-n], collapse = ", "), ", et al."))
  paste0(paste(out[-n], collapse = ", "), ", & ", out[n])
}

# ---------------------------------------------------------------- fields

venue_of <- function(f) {
  f$journal %||% f$journaltitle %||% f$booktitle %||% f$eventtitle %||%
    f$publisher %||% f$institution %||% ""
}

# Returns a ready-made markdown link, or "". Built here (rather than escaped
# later) so the link syntax survives md_escape().
link_of <- function(f) {
  doi <- f$doi %||% ""
  url <- f$url %||% ""
  ep  <- f$eprint %||% ""
  if (nzchar(doi)) return(sprintf("[doi:%s](https://doi.org/%s)", doi, doi))
  if (nzchar(ep))  return(sprintf("[arXiv:%s](https://arxiv.org/abs/%s)", ep, ep))
  if (nzchar(url)) return(sprintf("[%s](%s)", sub("^https?://(www\\.)?", "", url), url))
  ""
}

# ---------------------------------------------------------------- keywords

entry_keywords <- function(e) {
  tolower(trimws(as.character(e$fields$keywords %||% character(0))))
}

has_kw <- function(e, kw) kw %in% entry_keywords(e)

# `keywords` does double duty: `published`/`wip` are the status (and select the
# CV sections), everything else is a topic tag.
STATUS_KEYWORDS <- c("published", "wip", "preprint", "working")

entry_topics <- function(e) {
  kws <- trimws(as.character(e$fields$keywords %||% character(0)))
  kws[!tolower(kws) %in% STATUS_KEYWORDS]
}

entry_status <- function(e) {
  if (any(entry_keywords(e) %in% c("wip", "preprint", "working"))) "wip" else "published"
}

# ---------------------------------------------------------------- sorting

# year desc, then month desc -- the `ndymdt` sort from cv.tex
sort_entries <- function(es) {
  num <- function(x) suppressWarnings(as.integer(gsub("\\D", "", x %||% "")))
  mon <- function(x) {
    x <- tolower(x %||% "")
    m <- match(substr(x, 1, 3), tolower(month.abb))
    if (!is.na(m)) return(m)
    v <- num(x); if (is.na(v)) 0L else v
  }
  y <- vapply(es, function(e) {
    v <- num(e$fields$year %||% e$fields$date); if (is.na(v)) 0L else v
  }, integer(1))
  m <- vapply(es, function(e) mon(e$fields$month), integer(1))
  es[order(-y, -m)]
}

# ---------------------------------------------------------------- slugs

# Detail-page permalinks derive from the citation key. Keys are stable because
# the .toml files are hand-maintained, so no lock file is needed -- but an
# entry can still pin its own `slug` if the key is ugly. Two keys in the
# current data need sanitising: 'RePEc:sdp:sdpwps:57' and 'multigroup.vaccine'.
entry_slug <- function(e) {
  explicit <- e$fields$slug %||% ""
  if (nzchar(explicit)) return(explicit)
  s <- tolower(e$key)
  s <- gsub("[^a-z0-9]+", "-", s)
  gsub("^-+|-+$", "", s)
}
