# Generate CV entries directly from the .toml files.
#
# This replaces biblatex: instead of letting a bibliography engine format the
# entries, we read the data ourselves and emit markdown. That buys us the
# three things biblatex was doing that Typst cannot do natively -- bolding the
# author's own name, filtering sections by `keywords`, and the year/month
# descending sort -- without depending on any bibliography engine.
#
# The .toml files are the source of truth (see the repo README): `author` and
# `keywords` are arrays, and values are plain text/markdown, not LaTeX.

`%||%` <- function(a, b) if (is.null(a) || !length(a) || !nzchar(trimws(a[1]))) b else a

# ---------------------------------------------------------------- parsing

# Accented characters are stored as literal UTF-8, so there is no accent
# post-processing here. This guard keeps it that way: if a LaTeX accent macro
# ever creeps back in (e.g. pasted from a publisher's BibTeX export), the
# render fails loudly rather than silently printing "Cesantia".
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

# One TOML table per entry, keyed by citation key. `author`/`editor` and
# `keywords` arrive as arrays; everything else is a string.
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

initials <- function(given) {
  parts <- unlist(strsplit(trimws(given), "[ .]+"))
  parts <- parts[nzchar(parts)]
  if (!length(parts)) return("")
  paste(paste0(toupper(substr(parts, 1, 1)), "."), collapse = " ")
}

# "Last, First M." or "First M. Last" -> "Last, F. M."
one_author <- function(a) {
  a <- trimws(a)
  if (!nzchar(a)) return("")
  if (identical(tolower(a), "others")) return("et al.")
  if (grepl(",", a, fixed = TRUE)) {
    bits  <- strsplit(a, ",")[[1]]
    last  <- trimws(bits[1])
    given <- trimws(paste(bits[-1], collapse = " "))
  } else {
    toks  <- unlist(strsplit(a, "\\s+"))
    last  <- toks[length(toks)]
    given <- paste(toks[-length(toks)], collapse = " ")
  }
  if (!nzchar(given)) return(last)
  paste0(last, ", ", initials(given))
}

SELF <- "Vega Yon"

fmt_authors <- function(people, self = SELF) {
  people <- trimws(as.character(people %||% character(0)))
  people <- people[nzchar(people)]
  if (!length(people)) return("")

  out <- vapply(people, function(p) {
    if (grepl(self, p, fixed = TRUE)) {
      # canonicalise: the source spells this name a half-dozen different ways
      paste0("**", self, ", G. G.**")
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

# ---------------------------------------------------------------- entries

md_escape <- function(x) gsub("([<>])", "\\\\\\1", x)

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

fmt_pub <- function(e) {
  f <- e$fields
  au <- md_escape(fmt_authors(f$author))
  ti <- md_escape(f$title %||% "")
  yr <- sub("^(\\d{4}).*$", "\\1", f$year %||% f$date %||% "n.d.")
  ve <- md_escape(venue_of(f))

  bits <- character(0)
  if (nzchar(au)) bits <- c(bits, paste0(au, " "))
  bits <- c(bits, paste0("(", yr, "). "), ti, ". ")
  if (nzchar(ve)) {
    det <- f$volume %||% ""
    if (nzchar(f$number %||% "")) det <- paste0(det, "(", f$number, ")")
    pg <- f$pages %||% ""            # already an en dash in the source data
    tail <- paste(c(det, pg)[nzchar(c(det, pg))], collapse = ", ")
    bits <- c(bits, paste0("*", ve, "*", if (nzchar(tail)) paste0(", ", tail) else "", ". "))
  }
  lk <- link_of(f)
  if (nzchar(lk)) bits <- c(bits, lk)
  paste0(bits, collapse = "")
}

fmt_talk <- function(e) {
  f <- e$fields
  ti <- f$title %||% ""
  yr <- sub("^(\\d{4}).*$", "\\1", f$year %||% "")
  ev <- f$eventtitle %||% ""
  nt <- f$note %||% ""
  paste0(md_escape(ti), ". ", if (nzchar(ev)) paste0("*", md_escape(ev), "*. ") else "",
         "(", yr, ") ", md_escape(nt))
}

fmt_software <- function(e) {
  f <- e$fields
  au <- md_escape(fmt_authors(f$author))
  ti <- md_escape(f$title %||% "")
  yr <- sub("^(\\d{4}).*$", "\\1", f$year %||% "")
  nt <- md_escape(f$note %||% "")
  lk <- link_of(f)
  paste0(au, " *", ti, "* (", yr, ").",
         if (nzchar(nt)) paste0(" ", nt, ".") else "",
         if (nzchar(lk)) paste0(" ", lk) else "")
}

# ---------------------------------------------------------------- sections

has_kw <- function(e, kw) {
  kw %in% tolower(trimws(as.character(e$fields$keywords %||% character(0))))
}

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

emit_section <- function(entries, kw, fmt, numbered = TRUE) {
  es <- sort_entries(Filter(function(e) has_kw(e, kw), entries))
  if (!length(es)) {
    cat("_No entries._\n\n"); return(invisible(0L))
  }
  for (i in seq_along(es)) {
    cat(if (numbered) sprintf("%d. ", i) else "- ", fmt(es[[i]]), "\n\n", sep = "")
  }
  invisible(length(es))
}
