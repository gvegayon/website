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
# distinguishes a poster from a workshop from a plain talk -- is the entry's
# `talktype` field (see the talks section of R/entries.R); older entries that
# packed it into `note` are read by the same accessor. An entry whose type is
# missing or misspelt falls back to the coarse keyword, so a typo degrades
# rather than crashes.
TALK_TYPES <- list(
  list(token = "invited talk",        slug = "invited-talk",        class = "is-invited"),
  list(token = "conference workshop", slug = "conference-workshop", class = "is-workshop"),
  list(token = "conference poster",   slug = "conference-poster",   class = "is-poster"),
  list(token = "conference talk",     slug = "conference-talk",     class = "is-conference"),
  list(token = "workshop",            slug = "workshop",            class = "is-workshop"),
  list(token = "talk",                slug = "talk",                class = "is-talk")
)

talk_type_for_token <- function(token) {
  for (t in TALK_TYPES) if (identical(t$token, token)) return(t)
  NULL
}

KEYWORD_FALLBACK <- list(
  invitedtalk    = list(token = "invited talk",   slug = "invited-talk",   class = "is-invited"),
  conferencetalk = list(token = "conference talk", slug = "conference-talk", class = "is-conference"),
  othertalk      = list(token = "talk",           slug = "talk",           class = "is-talk")
)

# The type to badge, with the keyword as a safety net.
talk_type <- function(e) {
  type <- talk_type_for_token(talk_type_token(e$fields))
  if (!is.null(type)) return(type)
  kw <- entry_keywords(e)
  for (k in names(KEYWORD_FALLBACK)) if (k %in% kw) return(KEYWORD_FALLBACK[[k]])
  list(token = "talk", slug = "talk", class = "is-talk")
}

# ---------------------------------------------------------------- rendering

# The footnote mark on a talk someone else gave. Decorative: the same fact is
# spelled out in words on the card's byline right below it, so screen readers
# get it from there rather than from a dagger with a tooltip.
PROXY_MARK <- "\u2020"

talk_month_abbr <- function(month, months_abb) {
  n <- suppressWarnings(as.integer(gsub("\\D", "", month %||% "")))
  if (is.na(n) || n < 1L || n > 12L) return("")
  months_abb[n]
}

# "Jul 26" / "26 jul" / "7月26日" -- the day only when the entry records one.
# The order is a language's, not a fact about the date, so it comes from i18n.
talk_date_label <- function(f, i18n) {
  mon <- talk_month_abbr(f$month %||% "", i18n$months_abb %||% month.abb)
  if (!nzchar(mon)) return("")
  day <- talk_day(f)
  if (!day) return(mon)
  tpl <- i18n$date_fmt %||% "{month} {day}"
  gsub("{day}", day, gsub("{month}", mon, tpl, fixed = TRUE), fixed = TRUE)
}

# The event, linked to its own page when the entry names one.
talk_venue_html <- function(f) {
  venue <- trimws(f$eventtitle %||% "")
  if (!nzchar(venue)) return("")
  url <- trimws(f$eventurl %||% "")
  inner <- if (nzchar(url)) safe_link(url, esc(venue)) else esc(venue)
  sprintf('<em class="talk__venue">%s</em>', inner)
}

talk_card_html <- function(e, i18n) {
  f <- e$fields
  type <- talk_type(e)
  links <- talk_links(f)

  title <- esc(f$title %||% i18n$untitled)
  href <- if ("slides" %in% names(links)) links[["slides"]] else ""
  title_html <- if (nzchar(href)) {
    sprintf('<a href="%s" target="_blank" rel="noopener">%s <span aria-hidden="true">↗</span></a>', esc(href), title)
  } else {
    title
  }

  # Who else was on it, and -- when it was not the site owner who stood up --
  # who gave it. A quarter of these talks are joint work and the old site said
  # so; the .toml dropped the co-authors on everything but the conference
  # entries, so nothing downstream could show them.
  proxy <- talk_by_proxy(f)
  speaker <- if (proxy) talk_speaker_label(f) else ""
  with <- talk_coauthors(f, drop = if (proxy) talk_speaker(f) else character(0))

  # Each label is a template with one slot, so a language can put the name
  # wherever its grammar wants it.
  byline <- function(tpl, slot, value, cls) {
    gsub(slot, sprintf('<span class="%s">%s</span>', cls, esc(value)), esc(tpl), fixed = TRUE)
  }
  byline_bits <- c(
    if (nzchar(speaker)) {
      byline(i18n$talk_presented_by %||% "Presented by {name}", "{name}", speaker, "talk__speaker")
    },
    if (nzchar(with)) {
      byline(i18n$talk_with %||% "with {names}", "{names}", with, "talk__coauthors")
    }
  )
  with_html <- if (length(byline_bits)) {
    sprintf('<p class="talk__with">%s</p>',
            paste(byline_bits, collapse = '<span class="sep">·</span>'))
  } else ""

  meta_bits <- c(
    talk_venue_html(f),
    { h <- talk_host(f); if (nzchar(h)) sprintf('<span class="talk__host">%s</span>', esc(h)) else NULL },
    { l <- trimws(f$location %||% ""); if (nzchar(l)) sprintf('<span class="talk__place">%s</span>', esc(l)) else NULL },
    { d <- talk_date_label(f, i18n); if (nzchar(d)) sprintf('<span class="talk__date">%s</span>', esc(d)) else NULL }
  )
  meta_bits <- meta_bits[nzchar(meta_bits)]
  meta_html <- if (length(meta_bits)) {
    sprintf('<p class="talk__meta">%s</p>', paste(meta_bits, collapse = '<span class="sep">·</span>'))
  } else ""

  # The title already carries the slides link when there is one, so this row
  # repeats slides only for an entry with no title link to hang it off.
  labels <- c(slides = i18n$slides %||% "Slides", video = i18n$video %||% "Video",
              repo = i18n$materials %||% "Materials",
              announcement = i18n$announcement %||% "Announcement")
  shown <- links[setdiff(names(links), if (nzchar(href)) "slides" else character(0))]
  link_bits <- unname(mapply(
    function(url, nm) safe_link(url, esc(labels[[nm]])),
    shown, names(shown), USE.NAMES = FALSE
  ))
  links_html <- if (length(link_bits)) {
    sprintf('<p class="talk__links">%s</p>', paste(link_bits, collapse = '<span class="sep">·</span>'))
  } else ""

  badge_label <- i18n_value(i18n, type$slug)

  mark_html <- if (proxy) {
    sprintf('<sup class="talk__proxy" aria-hidden="true">%s</sup>', PROXY_MARK)
  } else ""

  paste0(
    sprintf('<li class="talk%s">', if (proxy) " talk--proxy" else ""),
    sprintf('<span class="tag tag--talktype %s">%s</span>', type$class, esc(badge_label)),
    sprintf('<h3 class="talk__title">%s%s</h3>', title_html, mark_html),
    with_html,
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

  # Only when there is something to explain -- a legend for a mark that does
  # not appear on the page would be noise.
  if (any(vapply(es, function(e) talk_by_proxy(e$fields), logical(1)))) {
    cat(sprintf(
      '<p class="talks__note"><span class="talk__proxy" aria-hidden="true">%s</span> %s</p>',
      PROXY_MARK, esc(i18n$talks_proxy_note %||% "Presented by a co-author, not by me.")))
  }

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
