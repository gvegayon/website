# Resolving author names to the collaborator roster in people.toml.
#
# The .toml entries write authors as "Last, First M." but the roster is a
# separate file, so the two can still disagree on middle initials or on a
# lingering "First Last" spelling. Names are matched on a key built from the
# surname plus first initial, which is stable across all of those.
#
# Requires R/entries.R (one_author, SELF, %||%) and R/html.R (esc).

read_people <- function(path = NULL) {
  if (is.null(path)) path <- if (file.exists("people.toml")) "people.toml" else "../people.toml"
  if (!file.exists(path)) return(list())
  if (!requireNamespace("toml", quietly = TRUE)) return(list())

  data <- toml::read_toml(path)

  # index every spelling -- the canonical `name` plus any `aka` variants
  idx <- list()
  for (slug in names(data)) {
    p <- data[[slug]]
    p$slug <- slug
    for (nm in c(p$name, as.character(p$aka %||% character(0)))) {
      k <- person_key(nm)
      if (nzchar(k)) idx[[k]] <- p
    }
  }
  idx
}

# "Last, First M." and "First M. Last" both collapse to "last|f".
person_key <- function(name) {
  name <- trimws(name %||% "")
  if (!nzchar(name)) return("")
  p <- split_name(name)
  if (!nzchar(p$last)) return("")
  first <- substr(p$given, 1, 1)
  paste0(tolower(gsub("[^[:alnum:] ]", "", p$last)), "|", tolower(first))
}

match_person <- function(name, people) {
  if (!length(people)) return(NULL)
  people[[person_key(name)]]
}

# Rebuilds the "A, B, & C" / "et al." join that fmt_authors() produces, but on
# pre-rendered HTML fragments so each name can carry its own link.
join_authors <- function(parts) {
  parts <- parts[nzchar(parts)]
  n <- length(parts)
  if (n == 0L) return("")
  if (n == 1L) return(parts)
  if (identical(parts[n], "et al.")) {
    return(paste0(paste(parts[-n], collapse = ", "), ", et al."))
  }
  paste0(paste(parts[-n], collapse = ", "), ", &amp; ", parts[n])
}

#' Author list as HTML, with roster links and affiliation tooltips.
#'
#' Falls back to the plain formatted name whenever a person is not in the
#' roster, so a half-filled people.toml renders exactly like today.
authors_html <- function(f, people = list()) {
  nm <- parse_authors(f$author)
  if (!length(nm)) return("")

  parts <- vapply(nm, function(p) {
    if (grepl(SELF, p, fixed = TRUE)) {
      return(sprintf('<span class="is-self">%s</span>', esc(paste0(SELF, ", G. G."))))
    }
    label <- one_author(sub("\\.$", "", p))
    if (identical(label, "et al.")) return(label)

    per <- match_person(p, people)
    if (is.null(per)) return(esc(label))

    aff <- per$affiliation %||% ""
    url <- per$url %||% ""
    if (nzchar(url)) {
      sprintf('<a class="author-link" href="%s" target="_blank" rel="noopener"%s>%s</a>',
              esc(url), if (nzchar(aff)) sprintf(' title="%s"', esc(aff)) else "", esc(label))
    } else if (nzchar(aff)) {
      sprintf('<span class="author-aff" title="%s">%s</span>', esc(aff), esc(label))
    } else {
      esc(label)
    }
  }, character(1), USE.NAMES = FALSE)

  join_authors(parts)
}
