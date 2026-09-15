# CV-specific formatters for the .toml entries.
#
# This replaces biblatex: instead of letting a bibliography engine format the
# entries, we read the data ourselves and emit markdown. That buys us the
# three things biblatex was doing that Typst cannot do natively -- bolding the
# author's own name, filtering sections by `keywords`, and the year/month
# descending sort -- without depending on any bibliography engine.
#
# Requires ../R/entries.R, which holds everything shared with the website
# (read_entries, fmt_authors, venue_of, link_of, has_kw, sort_entries).
# cv.qmd sources both, in that order.

md_escape <- function(x) gsub("([<>])", "\\\\\\1", x)

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

# The parenthesised tail used to be a single `note` string in the .toml, pasted
# through as-is. It is now composed from the entry's own fields (talktype,
# slides, video, repo, announcement -- see R/entries.R), which is what lets the
# line also carry the co-authors and the venue that the note never held.
TALK_LINK_LABELS <- c(slides = "slides", video = "video",
                      repo = "materials", announcement = "announcement")

fmt_talk <- function(e) {
  f <- e$fields
  ti <- md_escape(f$title %||% "")
  yr <- sub("^(\\d{4}).*$", "\\1", f$year %||% "")
  ev <- md_escape(venue_of(f))
  loc <- md_escape(f$location %||% "")

  # Said in words rather than marked with a symbol: a CV is read once, out of
  # context, and a dagger needing a legend at the top of the section is a worse
  # bargain there than four extra words on the line.
  proxy <- talk_by_proxy(f)
  speaker <- if (proxy) md_escape(talk_speaker_label(f)) else ""
  with <- md_escape(talk_coauthors(f, drop = if (proxy) talk_speaker(f) else character(0)))
  credit <- paste(c(
    if (nzchar(speaker)) sprintf("presented by %s", speaker),
    if (nzchar(with)) sprintf("with %s", with)
  ), collapse = "; ")

  links <- talk_links(f)
  urls <- paste(sprintf("[%s](%s)", TALK_LINK_LABELS[names(links)], links), collapse = "/")
  type <- talk_type_token(f)
  note <- if (nzchar(type) || nzchar(urls)) {
    sprintf("(%s%s%s)", type, if (nzchar(type) && nzchar(urls)) ", " else "", urls)
  } else ""

  paste0(
    ti,
    if (nzchar(credit)) sprintf(" (%s)", credit) else "",
    ". ",
    if (nzchar(ev)) paste0("*", ev, "*", if (nzchar(loc)) paste0(", ", loc) else "", ". ") else "",
    "(", yr, ") ", note
  )
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
