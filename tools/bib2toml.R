# Convert a .bib file into the flat TOML layout used by papers.toml /
# software.toml.
#
# The upstream source of truth is still BibTeX (gvegayon/resume publishes
# .bib), so this is the bridge: one table per entry, keyed by the citation
# key, with every field carried over verbatim plus ENTRYTYPE.
#
# Field values are written as TOML basic strings and are NOT cleaned -- the
# LaTeX markup is stripped later by clean_text()/clean_tex() at render time,
# which is what lets the CV re-bold the author's own name.
#
# Usage:  Rscript tools/bib2toml.R papers.bib papers.toml

# Reuse the brace-depth-aware parser the CV already relies on. It is sourced
# into its own environment so the helpers it defines (%||%, clean_tex, ...)
# do not leak into the caller.
bib_env <- local({
  e <- new.env(parent = globalenv())
  here <- c("cv/R/bib.R", "../cv/R/bib.R", "R/bib.R")
  path <- here[file.exists(here)][1]
  if (is.na(path)) stop("cannot locate cv/R/bib.R from ", getwd(), call. = FALSE)
  sys.source(path, envir = e)
  e
})

# Values are emitted as TOML *literal* strings (single quotes), which have no
# escape processing at all. That matters here: the fields are full of LaTeX
# (\textbf{...}, \%, \&), and backslash escaping in basic strings is exactly
# the sort of thing that round-trips differently between TOML parsers.
#
# Line wrapping inside a .bib value carries no meaning -- every consumer
# (clean_text(), clean_tex()) collapses whitespace anyway -- so newlines are
# folded to single spaces before quoting.
toml_value <- function(x) {
  x <- gsub("\\s+", " ", x, perl = TRUE)
  if (!grepl("'", x, fixed = TRUE)) return(paste0("'", x, "'"))
  # A handful of titles/abstracts quote a word ("A Lightweight Wrapper for
  # 'Slurm'"), which a literal string cannot hold. Those fall back to a basic
  # string; tools/bib2toml.R is round-trip tested, so the escaping is checked.
  x <- gsub("\\", "\\\\", x, fixed = TRUE)
  x <- gsub('"', '\\"', x, fixed = TRUE)
  paste0('"', x, '"')
}

# Bare keys may only hold [A-Za-z0-9_-]; anything else has to be quoted
# (e.g. 'RePEc:sdp:sdpwps:57', 'multigroup.vaccine').
toml_key <- function(k) {
  if (grepl("^[A-Za-z0-9_-]+$", k)) k else paste0("'", k, "'")
}

bib_to_toml <- function(bib_path, toml_path) {
  entries <- bib_env$parse_bib(bib_path)
  if (!length(entries)) stop("no entries parsed from ", bib_path, call. = FALSE)

  out <- character(0)
  for (e in entries) {
    out <- c(out, sprintf("[%s]", toml_key(e$key)))
    for (nm in names(e$fields)) {
      out <- c(out, sprintf("%s = %s", toml_key(nm), toml_value(e$fields[[nm]])))
    }
    out <- c(out, sprintf("ENTRYTYPE = %s", toml_value(e$type)))
    out <- c(out, sprintf("ID = %s", toml_value(e$key)))
    out <- c(out, "")
  }

  con <- file(toml_path, open = "wb", encoding = "UTF-8")
  on.exit(close(con))
  writeLines(out, con, useBytes = FALSE)
  invisible(length(entries))
}

if (sys.nframe() == 0L) {
  args <- commandArgs(trailingOnly = TRUE)
  if (length(args) != 2L) stop("usage: Rscript tools/bib2toml.R <in.bib> <out.toml>")
  n <- bib_to_toml(args[1], args[2])
  message(sprintf("%s -> %s (%d entries)", args[1], args[2], n))
}
