# The People page, rendered from people.toml rather than three hand-written,
# hand-translated bullet lists that quietly drifted from the roster (the
# 2026-08 audit found half a dozen mentees on people.qmd who were not in
# people.toml at all).
#
# A person appears here only when their table carries a `group` of "current"
# or "past" -- an entry that exists solely for author-link resolution (a
# frequent coauthor, a distant mentor covered by the page's own hand-written
# prose) stays off the generated list. File order is preserved within each
# group, so the roster author still controls display order directly.
#
# Requires R/entries.R (%||%, split_name), R/html.R (esc, asset_url), R/i18n.R
# (get_i18n). Sourced from a `results: asis` chunk in people.qmd and its es/
# and zh/ counterparts, in place of the bullet lists those files used to
# carry by hand; the intro paragraph, "My own mentors", and "Working with me"
# sections stay hand-written markdown around the chunk.

person_display_name <- function(p) {
  if (nzchar(p$display %||% "")) return(p$display)
  s <- split_name(p$name %||% "")
  trimws(paste(s$given, s$last))
}

# "2024" + no end -> "2024-present" (i18n'd); a single-year stay ("2023"/
# "2023") -> "2023"; anything else -> "2024-2025". `&ndash;` rather than a
# literal en dash keeps the source ASCII-safe like the rest of this codebase.
person_years_html <- function(p, i18n) {
  start <- as.character(p$start %||% "")
  end   <- as.character(p$end %||% "")
  if (!nzchar(start)) return("")
  if (!nzchar(end)) return(sprintf("%s&ndash;%s", esc(start), esc(i18n$people_present)))
  if (identical(start, end)) return(esc(start))
  sprintf("%s&ndash;%s", esc(start), esc(end))
}

# Photo when people.toml has an approved one; otherwise the same
# deterministic-hue monogram fallback used for software hex logos
# (R/cards.R::software_card(), .card__hex--mono in cards.css) so a photo-less
# entry still looks designed rather than broken.
person_avatar_html <- function(p, root) {
  src <- asset_url(p$photo %||% "", root)
  if (nzchar(src)) {
    return(sprintf('<img class="avatar--lg" src="%s" alt="" loading="lazy" width="56" height="56">', esc(src)))
  }
  name <- person_display_name(p)
  hue <- sum(utf8ToInt(tolower(p$name %||% name))) %% 360L
  sprintf('<span class="avatar--lg-mono" style="background:hsl(%d 45%% 42%%)" aria-hidden="true">%s</span>',
          hue, esc(toupper(substr(name, 1, 1))))
}

# `bio_es` / `bio_zh` are optional per-language overrides; `bio` (English) is
# the fallback, matching the "English fills any gap" rule get_i18n() uses.
person_bio_html <- function(p, language) {
  bio <- p[[paste0("bio_", tolower(language))]] %||% p$bio %||% ""
  if (!nzchar(bio)) return("")
  sprintf('<p class="person__bio">%s</p>', esc(bio))
}

person_html <- function(p, language, root, i18n) {
  name  <- esc(person_display_name(p))
  url   <- p$url %||% ""
  years <- person_years_html(p, i18n)

  name_html <- if (nzchar(url)) {
    sprintf('<a href="%s" target="_blank" rel="noopener">%s</a>', esc(url), name)
  } else {
    name
  }

  sprintf(
    '<li class="person">%s<span class="person__info"><span class="person__name">%s%s</span>%s</span></li>',
    person_avatar_html(p, root),
    name_html,
    if (nzchar(years)) sprintf(' <span class="person__years">(%s)</span>', years) else "",
    person_bio_html(p, language)
  )
}

#' Render the Current/Past roster sections of the People page as markdown +
#' raw HTML, `results: asis`-style (mirrors related_html() in R/detail.R:
#' a `##` heading followed by a `{=html}` block, so the heading gets the same
#' anchor/TOC treatment as every other heading on the page).
render_people_page <- function(language = "en", path = NULL) {
  if (is.null(path)) path <- if (file.exists("people.toml")) "people.toml" else "../people.toml"
  root <- if (file.exists("people.toml")) "" else "../"
  i18n <- get_i18n(language)

  if (!file.exists(path) || !requireNamespace("toml", quietly = TRUE)) {
    cat(sprintf("\n```{=html}\n<p>%s</p>\n```\n", esc(i18n$people_unavailable)))
    return(invisible(NULL))
  }

  data <- toml::read_toml(path)

  for (grp in c("current", "past")) {
    slugs <- Filter(function(s) identical(tolower(data[[s]]$group %||% ""), grp), names(data))
    if (!length(slugs)) next

    heading <- if (identical(grp, "current")) i18n$people_current else i18n$people_past
    cat(sprintf("\n## %s\n\n", heading))
    cat('```{=html}\n<ul class="people-list">')
    for (s in slugs) cat(person_html(data[[s]], language, root, i18n))
    cat("</ul>\n```\n")
  }

  invisible(NULL)
}
