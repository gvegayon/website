#!/usr/bin/env Rscript
# Import talk metadata from a checkout of github.com/gvegayon/talks.
#
#   Rscript R/import_talks.R [path-to-talks-checkout]   # default ../talks
#
# That repository is where the talks themselves live: one folder per talk,
# each with a README.md whose YAML front matter carries the full record --
#
#   repo / title / date / location / host / event / event_url / video /
#   announcement / slides / type / costar
#
# -- of which only title, date, event and (for conference talks) the co-author
# list survived into the presentations-*.toml files. Everything else was folded
# into a single packed `note` string or dropped outright. This script puts it
# back, and keeps it in sync when a new talk is added over there.
#
# It is NOT part of `make build`: the .toml files stay the source of truth for
# the site (see README), and this only tops them up. Nothing is overwritten --
# a field already set in the .toml wins, so hand edits survive a re-import. The
# one exception is a title that the .toml holds a truncated prefix of, which is
# a transcription artefact of the original import rather than an edit.
#
# Reads and writes files; no network.

suppressWarnings(suppressMessages({
  if (!requireNamespace("toml", quietly = TRUE)) {
    stop("the 'toml' package is required; run `make deps`", call. = FALSE)
  }
}))

`%||%` <- function(a, b) if (is.null(a) || !length(a) || !nzchar(trimws(a[1]))) b else a

SELF_NAME <- "Vega Yon, George G."

# Which .toml a talk belongs in, from the front matter's `type`. Same split the
# old README.Rmd in the talks repo used to sort entries into three .bib files.
TARGETS <- list(
  list(file = "presentations-conference.toml", keyword = "conferencetalk", pattern = "conf"),
  list(file = "presentations-invited.toml",    keyword = "invitedtalk",    pattern = "invi"),
  list(file = "presentations-other.toml",      keyword = "othertalk",      pattern = NA)
)

# Written in this order, so a hand edit and a re-import produce the same file.
# Anything not listed keeps its relative position after these.
FIELD_ORDER <- c(
  "entrytype", "title", "author", "year", "month", "date",
  "eventtitle", "eventurl", "host", "location",
  "talktype", "slides", "video", "repo", "announcement",
  "keywords", "source"
)

# ------------------------------------------------------------- front matter

# The headers are flat `key: value` blocks, so this is a deliberate three-line
# parser rather than a YAML dependency. The continuation branch exists for the
# one header whose title is wrapped over two lines (20241027-css-americas) --
# the line-based reader that built the .toml files in the first place dropped
# the tail, which is why one title currently ends mid-sentence at "A large".
# A title is wrapped in double quotes whenever it contains ": ", which YAML
# would otherwise read as a nested key. The quotes are syntax, not text -- and
# one title keeps a pair of its own inside them, so only the outermost pair
# goes.
unquote <- function(x) {
  x <- trimws(x)
  if (nchar(x) > 1L && startsWith(x, '"') && endsWith(x, '"')) {
    x <- substr(x, 2L, nchar(x) - 1L)
  }
  trimws(x)
}

read_front_matter <- function(path) {
  x <- readLines(path, warn = FALSE, encoding = "UTF-8")
  Encoding(x) <- "UTF-8"
  idx <- which(grepl("^---\\s*$", x))
  if (length(idx) < 2) return(NULL)

  out <- list()
  key <- NULL
  for (line in x[(idx[1] + 1):(idx[2] - 1)]) {
    m <- regmatches(line, regexec("^([A-Za-z0-9_ ]+):[ \t]*(.*)$", line))[[1]]
    if (length(m) == 3) {
      key <- trimws(m[2])
      out[[key]] <- unquote(m[3])
    } else if (!is.null(key) && nzchar(trimws(line))) {
      out[[key]] <- trimws(paste(out[[key]], trimws(line)))
    }
  }
  out
}

# ------------------------------------------------------------------- people

# `costar` is BibTeX-flavoured LaTeX: names joined by " and ", written "First
# Last", with the author's own name bolded -- "{\bf George G.} {\bf Vega Yon}
# and Kayla de la Haye". The .toml wants "Vega Yon, George G.; de la Haye,
# Kayla", so the surname has to be identified, not guessed.

# Lowercase name particles belong to the surname: "de la Haye" -> "de la Haye",
# not "Haye". Matched case-sensitively -- a capitalised "Van" is a given name.
PARTICLES <- c("de", "del", "de la", "da", "das", "dos", "di", "du", "la", "le",
               "van", "von", "der", "den", "ter", "bin", "ibn", "al")

split_person <- function(p) {
  p <- trimws(p)

  # {\bf George G.} {\bf Vega Yon} / \textbf{George G.} \textbf{Vega Yon}:
  # the braces already mark where the given names end, which is exactly the
  # information a "First Last" string does not carry. Use it.
  braced <- gsub("\\\\(?:text)?bf\\s*\\{", "{", p, perl = TRUE)  # \textbf{X} -> {X}
  braced <- gsub("\\{\\s*\\\\bf\\s*", "{", braced, perl = TRUE)  # {\bf X}    -> {X}
  groups <- regmatches(braced, gregexpr("\\{[^{}]*\\}", braced, perl = TRUE))[[1]]
  leftover <- trimws(gsub("\\{[^{}]*\\}", "", braced, perl = TRUE))
  if (length(groups) == 2L && !nzchar(leftover)) {
    inner <- trimws(gsub("^\\{|\\}$", "", groups))
    return(list(given = inner[1], family = inner[2]))
  }

  plain <- trimws(gsub("[{}]", "", gsub("\\\\(?:text)?bf\\s*", "", p, perl = TRUE)))
  toks <- unlist(strsplit(plain, "[[:space:]]+"))
  toks <- toks[nzchar(toks)]
  if (!length(toks)) return(list(given = "", family = ""))
  if (length(toks) == 1L) return(list(given = "", family = toks))

  start <- length(toks)
  while (start > 1L && tolower(toks[start - 1L]) %in% PARTICLES) start <- start - 1L
  list(
    given  = paste(toks[seq_len(start - 1L)], collapse = " "),
    family = paste(toks[start:length(toks)], collapse = " ")
  )
}

# "{\bf George G.} {\bf Vega Yon} and Kayla de la Haye"
#   -> "Vega Yon, George G.; de la Haye, Kayla"
costar_to_author <- function(costar) {
  costar <- trimws(costar %||% "")
  if (!nzchar(costar)) return("")
  people <- trimws(unlist(strsplit(costar, "\\s+and\\s+", perl = TRUE)))
  people <- people[nzchar(people)]
  out <- vapply(people, function(p) {
    n <- split_person(p)
    if (!nzchar(n$given)) n$family else paste0(n$family, ", ", n$given)
  }, character(1), USE.NAMES = FALSE)
  paste(out[nzchar(out)], collapse = "; ")
}

# ---------------------------------------------------------------- the note

# The packed string the .toml files carry today, e.g.
#   (conference workshop, [slides](https://...)/[video](https://...))
# Unpacking it is what lets the three entries with no folder in the talks repo
# -- the most recent ones -- gain the same explicit fields as the rest.
parse_note <- function(note) {
  note <- trimws(note %||% "")
  out <- list(talktype = "", slides = "", video = "", announcement = "")
  if (!nzchar(note)) return(out)

  tok <- sub("^\\(([^,)]+)[,)].*$", "\\1", note)
  if (!identical(tok, note)) out$talktype <- trimws(tok)

  m <- regmatches(note, gregexpr("\\[[^]]+\\]\\([^)]*\\)", note, perl = TRUE))[[1]]
  for (link in m) {
    label <- tolower(sub("^\\[([^]]+)\\].*$", "\\1", link))
    url <- trimws(sub("^.*\\(([^)]*)\\)$", "\\1", link))
    if (label %in% names(out) && !nzchar(out[[label]])) out[[label]] <- url
  }
  out
}

# ------------------------------------------------------------------- fields

# Front matter -> .toml fields. Empty values are dropped rather than written as
# '' so that an absent field means "not recorded" everywhere.
fields_from_source <- function(fm, dir) {
  date <- normalize_date(fm$date %||% "")
  costar <- costar_to_author(fm$costar %||% "")

  out <- list(
    title        = fm$title %||% "",
    # A solo talk still names its speaker: the old .bib defaulted to it, and an
    # explicit author is what lets the site tell "with X" from "on my own".
    author       = if (nzchar(costar)) costar else SELF_NAME,
    year         = substr(date, 1, 4),
    month        = sub("^0", "", substr(date, 6, 7)),
    date         = date,
    eventtitle   = fm$event %||% "",
    eventurl     = fm$event_url %||% "",
    host         = fm$host %||% "",
    location     = fm$location %||% "",
    talktype     = fm$type %||% "",
    slides       = fm$slides %||% "",
    video        = fm$video %||% "",
    repo         = fm$repo %||% "",
    announcement = fm$announcement %||% "",
    source       = dir
  )
  out[nzchar(unlist(lapply(out, function(v) trimws(v %||% ""))))]
}

# 2023-8-09 -> 2023-08-09. One header writes the month unpadded.
normalize_date <- function(x) {
  x <- trimws(x %||% "")
  m <- regmatches(x, regexec("^(\\d{4})-(\\d{1,2})-(\\d{1,2})", x))[[1]]
  if (length(m) != 4) return(x)
  sprintf("%04d-%02d-%02d", as.integer(m[2]), as.integer(m[3]), as.integer(m[4]))
}

# -------------------------------------------------------------------- TOML

# Literal strings ('...') unless the value contains one, in which case a basic
# string ("...") with the two escapes TOML requires there.
toml_string <- function(x) {
  x <- as.character(x)[1]
  if (!grepl("'", x, fixed = TRUE)) return(sprintf("'%s'", x))
  x <- gsub("\\", "\\\\", x, fixed = TRUE)
  x <- gsub('"', '\\"', x, fixed = TRUE)
  sprintf('"%s"', x)
}

toml_value <- function(v) {
  if (length(v) > 1L || is.list(v)) {
    return(sprintf("[%s]", paste(vapply(unlist(v), toml_string, character(1)), collapse = ", ")))
  }
  # `keywords` is an array of one in every current entry; keep it an array.
  toml_string(v)
}

write_toml <- function(entries, path) {
  lines <- character(0)
  for (key in names(entries)) {
    if (length(lines)) lines <- c(lines, "")
    lines <- c(lines, sprintf("[%s]", key))
    f <- entries[[key]]
    ordered <- c(intersect(FIELD_ORDER, names(f)), setdiff(names(f), FIELD_ORDER))
    for (nm in ordered) {
      v <- if (identical(nm, "keywords")) list(f[[nm]]) else f[[nm]]
      lines <- c(lines, sprintf("%s = %s", nm, toml_value(v)))
    }
  }

  # Bytes, not text. Handed a UTF-8 string it cannot represent, a text
  # connection in a non-UTF-8 locale writes the escape "<U+00F3>" rather than
  # "\u00f3" -- silently turning every accent in the data into seven ASCII
  # characters. The accents are literal UTF-8 by policy (see
  # assert_no_accent_macros() in R/entries.R), so write them as such whatever
  # locale this happens to run in.
  con <- file(path, open = "wb")
  on.exit(close(con))
  writeLines(enc2utf8(lines), con, useBytes = TRUE)
}

# ------------------------------------------------------------------ matching

norm_title <- function(x) {
  x <- tolower(trimws(x %||% ""))
  x <- gsub("[^[:alnum:]]+", " ", x, perl = TRUE)
  trimws(gsub("\\s+", " ", x, perl = TRUE))
}

# Does a source folder's `type` belong to this .toml file?
keyword_of_type <- function(type) {
  type <- tolower(trimws(type %||% ""))
  for (t in TARGETS) {
    if (is.na(t$pattern)) return(t$keyword)
    if (grepl(t$pattern, type)) return(t$keyword)
  }
  "othertalk"
}

# An entry's folder in the talks repo, or "".
#
# `source` pins it once it has been written, so a re-import never re-guesses.
# Without one: same title, same year, then -- for the handful of talks given
# twice in a year -- the section keyword, the month, and the type token, in
# that order. Anything still ambiguous is reported, not guessed.
find_source <- function(entry, key, sources, taken) {
  pinned <- trimws(entry$source %||% "")
  if (nzchar(pinned)) {
    if (!pinned %in% names(sources)) {
      warning(sprintf("[%s] source '%s' is not a folder in the talks checkout", key, pinned),
              call. = FALSE, immediate. = TRUE)
      return("")
    }
    return(pinned)
  }

  free <- setdiff(names(sources), taken)
  want <- norm_title(entry$title)
  cand <- Filter(function(d) identical(norm_title(sources[[d]]$title), want), free)
  # A .toml title that is a prefix of the folder's is the truncation described
  # above, not a different talk -- match it, then merge_entry() repairs it.
  if (!length(cand) && nzchar(want)) {
    cand <- Filter(function(d) startsWith(norm_title(sources[[d]]$title), want), free)
  }
  if (!length(cand)) return("")

  narrow <- function(cand, keep) if (length(cand) > 1L && sum(keep) >= 1L) cand[keep] else cand

  yr <- trimws(entry$year %||% "")
  cand <- narrow(cand, vapply(cand, function(d) {
    identical(substr(normalize_date(sources[[d]]$date), 1, 4), yr)
  }, logical(1)))

  kw <- tolower(as.character(entry$keywords %||% ""))
  cand <- narrow(cand, vapply(cand, function(d) {
    keyword_of_type(sources[[d]]$type) %in% kw
  }, logical(1)))

  mo <- sub("^0", "", trimws(entry$month %||% ""))
  cand <- narrow(cand, vapply(cand, function(d) {
    identical(sub("^0", "", substr(normalize_date(sources[[d]]$date), 6, 7)), mo)
  }, logical(1)))

  tok <- parse_note(entry$note)$talktype
  cand <- narrow(cand, vapply(cand, function(d) {
    identical(tolower(trimws(sources[[d]]$type %||% "")), tolower(tok))
  }, logical(1)))

  if (length(cand) > 1L) {
    warning(sprintf("[%s] matches %d folders (%s) -- set `source` by hand", key,
                    length(cand), paste(cand, collapse = ", ")),
            call. = FALSE, immediate. = TRUE)
    return("")
  }
  cand[1]
}

# ------------------------------------------------------------------- merging

# The .toml wins on every field it already fills. The exception is a title the
# .toml truncated: the original import read the header line by line and cut the
# one title that wraps, so a source title that merely continues the stored one
# is a repair, not an overwrite.
merge_entry <- function(entry, incoming, key, log) {
  for (nm in names(incoming)) {
    new <- trimws(incoming[[nm]])
    old <- trimws(as.character(entry[[nm]] %||% ""))
    if (!nzchar(new)) next

    if (!nzchar(old)) {
      entry[[nm]] <- new
      log$added <- c(log$added, nm)
      next
    }
    squash <- function(v) gsub("\\s+", " ", v, perl = TRUE)
    if (identical(squash(old), squash(new))) next

    if (identical(nm, "title") && startsWith(new, old)) {
      message(sprintf("  [%s] title completed: '%s' -> '%s'", key, old, new))
      entry[[nm]] <- new
      log$fixed <- c(log$fixed, nm)
      next
    }
    log$kept <- c(log$kept, sprintf("%s (toml: %s | talks: %s)", nm, old, new))
  }
  list(entry = entry, log = log)
}

# `note` is dropped once its contents are in fields of their own -- two places
# to edit the same fact is how they drift apart. Unpack it first, for the
# entries with no folder in the talks repo.
fields_from_note <- function(entry) {
  p <- parse_note(entry$note)
  p[nzchar(unlist(p))]
}

# ---------------------------------------------------------------------- main

main <- function(args) {
  talks_dir <- if (length(args)) args[1] else "../talks"
  if (!dir.exists(talks_dir)) {
    stop(sprintf("no talks checkout at '%s' -- clone github.com/gvegayon/talks there ",
                 talks_dir), "or pass the path as an argument", call. = FALSE)
  }

  readmes <- Sys.glob(file.path(talks_dir, "*", "README.md"))
  sources <- list()
  for (path in readmes) {
    fm <- read_front_matter(path)
    if (is.null(fm) || !nzchar(fm$title %||% "")) next
    sources[[basename(dirname(path))]] <- fm
  }
  message(sprintf("Read %d talk folders from %s", length(sources), talks_dir))

  taken <- character(0)
  n_added <- 0L

  for (target in TARGETS) {
    if (!file.exists(target$file)) next
    entries <- toml::read_toml(target$file)
    message(sprintf("\n%s (%d entries)", target$file, length(entries)))

    for (key in names(entries)) {
      entry <- entries[[key]]
      log <- list(added = character(0), fixed = character(0), kept = character(0))

      merged <- merge_entry(entry, fields_from_note(entry), key, log)
      entry <- merged$entry; log <- merged$log

      dir <- find_source(entry, key, sources, taken)
      if (nzchar(dir)) {
        taken <- c(taken, dir)
        merged <- merge_entry(entry, fields_from_source(sources[[dir]], dir), key, log)
        entry <- merged$entry; log <- merged$log
      } else {
        message(sprintf("  [%s] no folder in the talks repo; kept as is", key))
      }

      # A talk with no co-authors still has a speaker. The old .bib defaulted
      # the author to the site owner and the .toml import turned that into an
      # empty string; without it the site cannot tell a solo talk from one it
      # simply knows nothing about.
      if (!nzchar(trimws(as.character(entry$author %||% "")))) entry$author <- SELF_NAME

      entry$note <- NULL
      entries[[key]] <- entry

      if (length(log$added)) {
        message(sprintf("  [%s] + %s", key, paste(unique(log$added), collapse = ", ")))
      }
      for (k in log$kept) message(sprintf("  [%s] kept %s", key, k))
    }

    # Talks added to the other repo since the last import.
    new_dirs <- setdiff(names(sources), taken)
    new_dirs <- Filter(function(d) identical(keyword_of_type(sources[[d]]$type), target$keyword), new_dirs)
    if (length(new_dirs)) {
      n <- length(entries)
      suffix <- gsub("^presentations-|\\.toml$", "", target$file)
      for (d in new_dirs) {
        n <- n + 1L
        key <- sprintf("talk-%d-%s", n, suffix)
        entries[[key]] <- c(
          list(entrytype = "inproceedings"),
          fields_from_source(sources[[d]], d),
          list(keywords = target$keyword)
        )
        taken <- c(taken, d)
        n_added <- n_added + 1L
        message(sprintf("  [%s] NEW from %s", key, d))
      }
    }

    write_toml(entries, target$file)
  }

  orphans <- setdiff(names(sources), taken)
  if (length(orphans)) {
    message("\nFolders not linked to any entry: ", paste(orphans, collapse = ", "))
  }
  message(sprintf("\nDone. %d new entries.", n_added))
  invisible(NULL)
}

main(commandArgs(trailingOnly = TRUE))
