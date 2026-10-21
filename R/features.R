# Feature rows: an image beside a short block of prose and a row of links.
#
# Used for the software highlights (software_highlights.yaml) and the books on
# the teaching page (teaching_books.yaml), and their es/ and zh/ copies. Both
# used to be hand-rolled `.columns` markup with inline styles and fixed 20/80
# widths, which squeezed the text to a sliver on phones; the layout now lives
# in assets/css/cards.css (.feature-list) next to the card grid it echoes.
#
# Each YAML entry takes:
#   title        heading text
#   img          site-root-relative path, no leading slash ('img/x.webp');
#                see asset_url() in R/html.R
#   alt          alt text; leave empty for a logo the title already names
#   description  markdown -- emitted as-is, so links and emphasis work
#   links        list of {label, url, icon}; `icon` is a Bootstrap Icons name
#
# Requires R/entries.R (%||%) and R/html.R (esc, asset_url). Sourced from a
# `results: asis` chunk.

feature_link_md <- function(l) {
  icon <- if (nzchar(l$icon %||% "")) {
    sprintf('[]{.bi .bi-%s aria-hidden="true"} ', l$icon)
  } else ""
  sprintf('[%s%s](%s){.feature__link target="_blank" rel="noopener"}',
          icon, l$label, l$url)
}

#' Render a list of feature rows from a YAML file.
#'
#' @param path    YAML file, one named entry per row
#' @param variant "logo" (square marks) or "cover" (portrait book covers)
#' @param root    prefix for image paths; "../" from the es/ and zh/ projects,
#'   derived the same way as site_root() in R/cards.R
render_feature_list <- function(
    path,
    variant = c("logo", "cover"),
    root    = if (file.exists("papers.toml")) "" else "../"
) {
  variant <- match.arg(variant)
  x <- yaml::read_yaml(path)

  cat(sprintf("\n::: {.feature-list .feature-list--%s}\n", variant))
  for (e in x) {
    cat("::: {.feature}\n")
    cat(sprintf(
      '<div class="feature__media"><img src="%s" alt="%s" loading="lazy"></div>\n\n',
      esc(asset_url(e$img, root)), esc(e$alt %||% "")
    ))
    cat("::: {.feature__body}\n")
    cat(sprintf("### %s\n\n", e$title))
    cat(trimws(e$description), "\n\n")
    if (length(e$links)) {
      links <- vapply(e$links, feature_link_md, character(1))
      cat(sprintf("[%s]{.feature__links}\n", paste(links, collapse = " ")))
    }
    cat(":::\n:::\n\n")
  }
  cat(":::\n\n")
  invisible(NULL)
}
