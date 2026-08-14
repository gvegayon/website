# Generate CV entries directly from the .bib files.
#
# This replaces biblatex: instead of letting a bibliography engine format the
# entries, we parse the .bib ourselves and emit markdown. That buys us the
# three things biblatex was doing that Typst cannot do natively -- bolding the
# author's own name, filtering sections by `keywords`, and the year/month
# descending sort -- without depending on any bibliography engine.

`%||%` <- function(a, b) if (is.null(a) || !length(a) || !nzchar(trimws(a[1]))) b else a

# ---------------------------------------------------------------- parsing

# Accented characters are stored as literal UTF-8 in the .bib files, so there
# is no accent post-processing here. This guard keeps it that way: if a LaTeX
# accent macro ever creeps back in (e.g. pasted from a publisher's export), the
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
    stop("LaTeX accent macros found in .bib -- replace them with UTF-8:\n",
         paste(bad, collapse = "\n"), call. = FALSE)
  }
  invisible(TRUE)
}

# Strip the LaTeX markup that appears inside .bib field values. Note we drop
# \textbf/\bf entirely: the author's name is re-bolded later by matching on the
# name itself, which is more reliable than the (inconsistent) markup.
clean_tex <- function(x) {
  x <- gsub("\\\\href\\{([^}]*)\\}\\{([^}]*)\\}", "[\\2](\\1)", x)
  x <- gsub("\\\\url\\{([^}]*)\\}", "<\\1>", x)
  x <- gsub("\\\\textbf\\{", "{", x)
  x <- gsub("\\\\textit\\{|\\\\emph\\{", "{", x)
  x <- gsub("\\\\color\\{[^}]*\\}", "", x)
  x <- gsub("\\\\bf\\b\\s*", "", x)
  x <- gsub("``", "“", x); x <- gsub("''", "”", x)
  x <- gsub("---", "—", x); x <- gsub("--", "–", x)
  x <- gsub("\\\\&", "&", x)
  x <- gsub("\\\\%", "%", x)
  x <- gsub("\\\\_", "_", x)
  x <- gsub("\\\\#", "#", x)
  x <- gsub("[{}]", "", x)
  x <- gsub("\\s+", " ", x)
  trimws(x)
}

# Split on a separator only at brace depth 0.
split_depth0 <- function(s, sep) {
  chars <- strsplit(s, "")[[1]]
  out <- character(0); cur <- ""; depth <- 0L; i <- 1L
  n <- length(chars); k <- nchar(sep)
  while (i <= n) {
    ch <- chars[i]
    if (ch == "{") depth <- depth + 1L
    if (ch == "}") depth <- depth - 1L
    if (depth == 0L && i + k - 1L <= n &&
        paste(chars[i:(i + k - 1L)], collapse = "") == sep) {
      out <- c(out, cur); cur <- ""; i <- i + k; next
    }
    cur <- paste0(cur, ch); i <- i + 1L
  }
  c(out, cur)
}

parse_bib <- function(path) {
  txt <- paste(readLines(path, warn = FALSE, encoding = "UTF-8"), collapse = "\n")
  # drop whole-line comments; BibTeX ignores them but they confuse field splitting
  txt <- paste(grep("^\\s*%", strsplit(txt, "\n")[[1]], value = TRUE, invert = TRUE),
               collapse = "\n")

  # tolerate indented entry headers -- software.bib has at least one "@Manual"
  # that is not flush left, and anchoring on "^@" silently drops it
  starts <- gregexpr("(?m)^[ \t]*@[[:alpha:]]+\\s*\\{", txt, perl = TRUE)[[1]]
  if (length(starts) == 1L && starts[1] == -1L) return(list())

  lapply(seq_along(starts), function(j) {
    s <- starts[j]
    e <- if (j < length(starts)) starts[j + 1L] - 1L else nchar(txt)
    chunk <- trimws(substr(txt, s, e))

    hdr <- regmatches(chunk, regexec("^@([[:alpha:]]+)\\s*\\{([^,]+),", chunk))[[1]]
    body <- sub("^@[[:alpha:]]+\\s*\\{[^,]+,", "", chunk)
    body <- sub("\\}\\s*$", "", trimws(body))

    fields <- list()
    for (part in split_depth0(body, ",")) {
      if (!grepl("=", part, fixed = TRUE)) next
      nm  <- tolower(trimws(sub("=.*$", "", part)))
      val <- trimws(sub("^[^=]*=", "", part))
      val <- sub('^\\{(.*)\\}$', "\\1", trimws(val))
      val <- sub('^"(.*)"$', "\\1", trimws(val))
      if (!nzchar(nm)) next
      # keep the first occurrence, matching biber's behaviour on duplicates
      if (is.null(fields[[nm]])) fields[[nm]] <- val
    }
    list(type = tolower(hdr[2]), key = hdr[3], fields = fields)
  })
}

# papers.toml / software.toml hold one table per entry, keyed by citation key
# (see tools/bib2toml.R). Field values keep their LaTeX markup, exactly as the
# .bib had it, so everything downstream of here is unchanged.
parse_toml <- function(path) {
  if (!requireNamespace("toml", quietly = TRUE)) {
    stop("the 'toml' package is required to read ", path, call. = FALSE)
  }
  data <- toml::read_toml(path)

  lapply(names(data), function(key) {
    f <- data[[key]]
    list(type = f$ENTRYTYPE %||% "misc", key = key, fields = f)
  })
}

read_bibs <- function(...) {
  lapply(c(...), function(path) {
    if (grepl("\\.toml$", path, ignore.case = TRUE)) {
      parse_toml(path)
    } else {
      parse_bib(path)
    }
  }) |> unlist(recursive = FALSE)
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

fmt_authors <- function(raw, self = SELF) {
  raw <- clean_tex(raw %||% "")
  if (!nzchar(raw)) return("")
  people <- split_depth0(raw, " and ")
  people <- trimws(people[nzchar(trimws(people))])

  out <- vapply(people, function(p) {
    if (grepl(self, p, fixed = TRUE)) {
      # canonicalise: the .bib spells this name a half-dozen different ways
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
  clean_tex(f$journal %||% f$journaltitle %||% f$booktitle %||% f$eventtitle %||%
            f$publisher %||% f$institution %||% "")
}

# Returns a ready-made markdown link, or "". Built here (rather than escaped
# later) so the link syntax survives md_escape().
link_of <- function(f) {
  doi <- clean_tex(f$doi %||% "")
  url <- clean_tex(f$url %||% "")
  ep  <- clean_tex(f$eprint %||% "")
  if (nzchar(doi)) return(sprintf("[doi:%s](https://doi.org/%s)", doi, doi))
  if (nzchar(ep))  return(sprintf("[arXiv:%s](https://arxiv.org/abs/%s)", ep, ep))
  if (nzchar(url)) return(sprintf("[%s](%s)", sub("^https?://(www\\.)?", "", url), url))
  ""
}

fmt_pub <- function(e) {
  f <- e$fields
  au <- md_escape(fmt_authors(f$author))
  ti <- md_escape(clean_tex(f$title %||% ""))
  yr <- sub("^(\\d{4}).*$", "\\1", clean_tex(f$year %||% f$date %||% "n.d."))
  ve <- md_escape(venue_of(f))

  bits <- character(0)
  if (nzchar(au)) bits <- c(bits, paste0(au, " "))
  bits <- c(bits, paste0("(", yr, "). "), ti, ". ")
  if (nzchar(ve)) {
    det <- clean_tex(f$volume %||% "")
    if (nzchar(clean_tex(f$number %||% ""))) det <- paste0(det, "(", clean_tex(f$number), ")")
    pg <- clean_tex(f$pages %||% "")   # clean_tex already makes "--" an en dash
    tail <- paste(c(det, pg)[nzchar(c(det, pg))], collapse = ", ")
    bits <- c(bits, paste0("*", ve, "*", if (nzchar(tail)) paste0(", ", tail) else "", ". "))
  }
  lk <- link_of(f)
  if (nzchar(lk)) bits <- c(bits, lk)
  paste0(bits, collapse = "")
}

fmt_talk <- function(e) {
  f <- e$fields
  ti <- clean_tex(f$title %||% "")
  yr <- sub("^(\\d{4}).*$", "\\1", clean_tex(f$year %||% ""))
  ev <- clean_tex(f$eventtitle %||% "")
  nt <- clean_tex(f$note %||% "")
  paste0(md_escape(ti), ". ", if (nzchar(ev)) paste0("*", md_escape(ev), "*. ") else "",
         "(", yr, ") ", md_escape(nt))
}

fmt_software <- function(e) {
  f <- e$fields
  au <- md_escape(fmt_authors(f$author))
  ti <- md_escape(clean_tex(f$title %||% ""))
  yr <- sub("^(\\d{4}).*$", "\\1", clean_tex(f$year %||% ""))
  nt <- md_escape(clean_tex(f$note %||% ""))
  lk <- link_of(f)
  paste0(au, " *", ti, "* (", yr, ").",
         if (nzchar(nt)) paste0(" ", nt, ".") else "",
         if (nzchar(lk)) paste0(" ", lk) else "")
}

# ---------------------------------------------------------------- sections

has_kw <- function(e, kw) {
  k <- tolower(clean_tex(e$fields$keywords %||% ""))
  kw %in% trimws(strsplit(k, ",")[[1]])
}

# year desc, then month desc -- the `ndymdt` sort from cv.tex
sort_entries <- function(es) {
  num <- function(x) suppressWarnings(as.integer(gsub("\\D", "", x %||% "")))
  mon <- function(x) {
    x <- tolower(clean_tex(x %||% ""))
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
