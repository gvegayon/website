# Small HTML helpers shared by the card renderers.
#
# Everything here returns a string; nothing prints. Values coming out of the
# .toml files are plain text, so the only job is escaping them for the markup
# they are about to be pasted into.

# Collapses vectors (author/keyword arrays) and escapes for element content or
# a double-quoted attribute.
esc <- function(x, sep = ", ") {
  x <- trimws(gsub("\\s+", " ", paste(x, collapse = sep), perl = TRUE))
  x <- gsub("&", "&amp;", x, fixed = TRUE)
  x <- gsub('"', "&quot;", x, fixed = TRUE)
  x <- gsub("<", "&lt;", x, fixed = TRUE)
  gsub(">", "&gt;", x, fixed = TRUE)
}

# esc() collapses runs of whitespace, which is right for inline text and wrong
# for anything inside <pre>. This escapes the same characters but leaves the
# line structure alone.
esc_pre <- function(x) {
  x <- paste(x, collapse = "\n")
  x <- gsub("&", "&amp;", x, fixed = TRUE)
  x <- gsub("<", "&lt;", x, fixed = TRUE)
  gsub(">", "&gt;", x, fixed = TRUE)
}

safe_link <- function(url, label, cls = NULL) {
  if (!nzchar(url %||% "")) return("")
  sprintf(
    '<a %shref="%s" target="_blank" rel="noopener">%s</a>',
    if (is.null(cls)) "" else sprintf('class="%s" ', cls),
    esc(url), label
  )
}

# Facet values become both a visible label and a machine token. The token has
# to survive being stuffed into a pipe-delimited data attribute, so it loses
# everything that is not alphanumeric.
slugify <- function(x) {
  x <- tolower(trimws(as.character(x)))
  x <- gsub("[^a-z0-9]+", "-", x)
  gsub("^-+|-+$", "", x)
}

# A shields.io-style badge rendered locally: no third-party request, no layout
# shift, and the value is exactly as fresh as the page around it.
badge_html <- function(key, value, label = NULL, cls = "") {
  if (!nzchar(value %||% "")) return("")
  sprintf(
    '<span class="badge %s"%s><span class="badge__k">%s</span><span class="badge__v">%s</span></span>',
    esc(cls),
    if (is.null(label)) "" else sprintf(' aria-label="%s"', esc(label)),
    esc(key), esc(value)
  )
}

# A standalone pill (status, type, year) with no key/value split.
tag_html <- function(text, cls = "") {
  if (!nzchar(text %||% "")) return("")
  sprintf('<span class="tag %s">%s</span>', esc(cls), esc(text))
}
