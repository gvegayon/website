# The year-rail timeline behind talks.qmd.
#
# One engine, no facets, no JavaScript: this page is a chronology, not a
# filterable grid, and deliberately does not reuse render_item_grid() (see
# R/cards.R) so it doesn't just look like a third card kind.
#
# Requires R/entries.R, R/html.R and R/i18n.R.
#
# It reads nothing and writes nothing -- like R/cards.R, its functions take
# entries (from read_entries()) and return/print strings.

# ---------------------------------------------------------------- type vocab

# The coarse category lives in `keywords` (invitedtalk / conferencetalk /
# othertalk -- one per source file). The finer type -- what actually
# distinguishes a poster from a workshop from a plain talk -- is not a field;
# it is the first parenthesised token of `note`, e.g.
# "(conference workshop, [slides](...)/[video](...))". All 63 current entries
# match one of the six tokens below; an entry whose note doesn't match falls
# back to the coarse keyword so a future typo degrades rather than crashes.
TALK_TYPES <- list(
  list(token = "invited talk",        slug = "invited-talk",        class = "is-invited"),
  list(token = "conference workshop", slug = "conference-workshop", class = "is-workshop"),
  list(token = "conference poster",   slug = "conference-poster",   class = "is-poster"),
  list(token = "conference talk",     slug = "conference-talk",     class = "is-conference"),
  list(token = "workshop",            slug = "workshop",            class = "is-workshop"),
  list(token = "talk",                slug = "talk",                class = "is-talk")
)

# Order matters: "conference talk" must be tried before the bare "talk" it
# contains, and the two "conference ..." compounds before the plain
# "conference talk". TALK_TYPES is already in the right order for that.
talk_type_for_token <- function(token) {
  for (t in TALK_TYPES) if (identical(t$token, token)) return(t)
  NULL
}

KEYWORD_FALLBACK <- list(
  invitedtalk    = list(token = "invited talk",   slug = "invited-talk",   class = "is-invited"),
  conferencetalk = list(token = "conference talk", slug = "conference-talk", class = "is-conference"),
  othertalk      = list(token = "talk",           slug = "talk",           class = "is-talk")
)

# note -> list(type = <TALK_TYPES entry>, slides = url|"", video = url|"").
# A few slides URLs in the source data carry a trailing space
# ("...uai-ds )") -- trimws() so they still resolve.
parse_note <- function(note) {
  note <- trimws(note %||% "")
  tok <- sub("^\\(([^,)]+)[,)].*$", "\\1", note)
  type <- talk_type_for_token(trimws(tok))

  slides <- sub(".*\\[slides\\]\\(([^)]*)\\).*", "\\1", note)
  if (identical(slides, note)) slides <- ""
  video <- sub(".*\\[video\\]\\(([^)]*)\\).*", "\\1", note)
  if (identical(video, note)) video <- ""

  list(type = type, slides = trimws(slides), video = trimws(video))
}

# The type to badge, with the keyword as a safety net if `note` doesn't parse.
talk_type <- function(e) {
  parsed <- parse_note(e$fields$note)
  if (!is.null(parsed$type)) return(parsed$type)
  kw <- entry_keywords(e)
  for (k in names(KEYWORD_FALLBACK)) if (k %in% kw) return(KEYWORD_FALLBACK[[k]])
  list(token = "talk", slug = "talk", class = "is-talk")
}

# ---------------------------------------------------------------- rendering

talk_month_abbr <- function(month, months_abb) {
  n <- suppressWarnings(as.integer(gsub("\\D", "", month %||% "")))
  if (is.na(n) || n < 1L || n > 12L) return("")
  months_abb[n]
}

talk_card_html <- function(e, i18n) {
  f <- e$fields
  parsed <- parse_note(f$note)
  type <- talk_type(e)

  title <- esc(f$title %||% i18n$untitled)
  href <- parsed$slides
  title_html <- if (nzchar(href)) {
    sprintf('<a href="%s" target="_blank" rel="noopener">%s <span aria-hidden="true">↗</span></a>', esc(href), title)
  } else {
    title
  }

  venue <- esc(f$eventtitle %||% "")
  month_lbl <- talk_month_abbr(f$month, i18n$months_abb %||% month.abb)
  meta_bits <- c(
    if (nzchar(venue)) sprintf('<em class="talk__venue">%s</em>', venue) else NULL,
    if (nzchar(month_lbl)) sprintf('<span class="talk__date">%s</span>', esc(month_lbl)) else NULL
  )
  meta_html <- if (length(meta_bits)) {
    sprintf('<p class="talk__meta">%s</p>', paste(meta_bits, collapse = '<span class="sep">·</span>'))
  } else ""

  # The title already carries the slides link (when there is one), so this
  # row only needs to surface a video link, plus slides for the rare entry
  # that has no title link to hang it off (title itself has no href).
  link_bits <- c(
    if (nzchar(parsed$slides) && !nzchar(href)) safe_link(parsed$slides, i18n$slides %||% "Slides") else NULL,
    if (nzchar(parsed$video)) safe_link(parsed$video, i18n$video %||% "Video") else NULL
  )
  links_html <- if (length(link_bits)) {
    sprintf('<p class="talk__links">%s</p>', paste(link_bits, collapse = '<span class="sep">·</span>'))
  } else ""

  badge_label <- i18n_value(i18n, type$slug)

  paste0(
    '<li class="talk">',
    sprintf('<span class="tag tag--talktype %s">%s</span>', type$class, esc(badge_label)),
    sprintf('<h3 class="talk__title">%s</h3>', title_html),
    meta_html,
    links_html,
    '</li>'
  )
}

# entries -> the full <section class="talks">...</section> block, printed as
# a raw-HTML chunk (same convention as render_item_grid() in R/cards.R).
render_talk_timeline <- function(entries, language = "en") {
  i18n <- get_i18n(language)

  cat("\n```{=html}\n")

  if (!length(entries)) {
    cat(sprintf('<p class="talks__empty">%s</p>', esc(i18n$talks_unavailable %||% "Talk list unavailable.")))
    cat("\n```\n")
    return(invisible(NULL))
  }

  es <- sort_entries(entries)
  years <- vapply(es, function(e) e$fields$year %||% "", character(1))
  year_order <- unique(years)  # already year-desc from sort_entries(); no re-sort

  n_total <- length(es)
  n_invited <- sum(vapply(es, has_kw, logical(1), kw = "invitedtalk"))
  n_conf    <- sum(vapply(es, has_kw, logical(1), kw = "conferencetalk"))
  n_other   <- sum(vapply(es, has_kw, logical(1), kw = "othertalk"))
  yr_num <- suppressWarnings(as.integer(gsub("\\D", "", years)))
  yr_num <- yr_num[!is.na(yr_num)]
  span <- if (length(yr_num)) sprintf("%d–%d", min(yr_num), max(yr_num)) else ""

  summary_tpl <- i18n$talks_summary %||% "{n} talks · {span}"
  summary <- gsub("{n}", n_total, gsub("{span}", span, summary_tpl, fixed = TRUE), fixed = TRUE)
  breakdown_tpl <- i18n$talks_breakdown %||% "{invited} invited · {conference} conference · {other} other"
  breakdown <- breakdown_tpl
  breakdown <- gsub("{invited}", n_invited, breakdown, fixed = TRUE)
  breakdown <- gsub("{conference}", n_conf, breakdown, fixed = TRUE)
  breakdown <- gsub("{other}", n_other, breakdown, fixed = TRUE)

  cat('<section class="talks">')
  cat(sprintf('<p class="talks__summary">%s<br><span class="muted">%s</span></p>', esc(summary), esc(breakdown)))

  cat(sprintf('<nav class="talks__years" aria-label="%s">', esc(i18n$jump_to_year %||% "Jump to year")))
  for (yr in year_order) cat(sprintf('<a href="#y%s">%s</a>', esc(yr), esc(yr)))
  cat('</nav>')

  cat('<ol class="talks__timeline">')
  for (yr in year_order) {
    group <- Filter(function(e) identical(e$fields$year %||% "", yr), es)
    cat(sprintf('<li class="talks__year" id="y%s">', esc(yr)))
    cat('<div class="talks__rail">')
    cat(sprintf('<span class="talks__yearnum">%s</span>', esc(yr)))
    cat(sprintf('<span class="talks__yearcount">%d</span>', length(group)))
    cat('</div>')
    cat('<ul class="talks__items">')
    for (e in group) cat(talk_card_html(e, i18n))
    cat('</ul>')
    cat('</li>')
  }
  cat('</ol>')
  cat('</section>')

  cat("\n```\n")
  invisible(NULL)
}
