# The card grid behind research.qmd and software.qmd.
#
# One engine, two facet configurations. The two pages used to be near-copies of
# each other -- same markup, same inline script, drifting independently -- so
# everything structural lives here and the differences are data.
#
# Requires R/entries.R, R/html.R and R/i18n.R (see load_grid_deps below).
# The interactive layer is assets/js/item-grid.js, loaded site-wide via
# include-after-body; nothing is inlined here.

# ---------------------------------------------------------------- facets

# Which axes each kind can be filtered on, in display order.
#
# `min_count` is what keeps the UI honest: a facet value that matches a single
# item is a dead end, so topic and venue chips only appear once at least two
# items share them. Groups that end up with fewer than two live values are
# dropped entirely. That means new axes light up on their own as the .toml
# files gain `keywords`, with no code change.
FACET_GROUPS <- list(
  research = list(
    status = list(min_count = 1, order = c("published", "wip")),
    topic  = list(min_count = 2, max_show = 12),
    venue  = list(min_count = 2, max_show = 8),
    year   = list(min_count = 1, order = "desc")
  ),
  software = list(
    status = list(min_count = 1, order = c("active", "maintained", "experimental", "archived")),
    kind   = list(min_count = 2),
    lang   = list(min_count = 2),
    dist   = list(min_count = 2),
    topic  = list(min_count = 2, max_show = 12)
  )
)

# Where a software package can be installed from. Derived rather than stored,
# so it stays right when `cran`/`repo` change.
software_dist <- function(f) {
  out <- character(0)
  if (nzchar(f$cran %||% "") || grepl("cran.r-project.org", f$url %||% "", ignore.case = TRUE)) {
    out <- c(out, "cran")
  }
  if (nzchar(f$pypi %||% "")) out <- c(out, "pypi")
  if (!length(out) && (nzchar(f$repo %||% "") || grepl("github.com", f$url %||% "", ignore.case = TRUE))) {
    out <- c(out, "github")
  }
  out
}

# Facet values for one entry, as a named list of character vectors. A facet may
# hold several values (topics, languages) or none.
entry_facets <- function(e, kind) {
  f <- e$fields
  if (identical(kind, "research")) {
    list(
      status = entry_status(e),
      topic  = entry_topics(e),
      venue  = venue_of(f),
      year   = substr(f$year %||% "", 1, 4)
    )
  } else {
    list(
      status = tolower(f$status %||% "active"),
      kind   = tolower(f$kind %||% "package"),
      lang   = as.character(f$languages %||% character(0)),
      dist   = software_dist(f),
      topic  = entry_topics(e)
    )
  }
}

# Tally facet values across all entries, then apply each group's rules.
# Returns a list of groups, each with an id and its surviving values+counts.
build_facets <- function(entries, kind) {
  spec <- FACET_GROUPS[[kind]]
  all <- lapply(entries, entry_facets, kind = kind)

  groups <- lapply(names(spec), function(id) {
    rule <- spec[[id]]
    # Not `%||%` here: it tests only the first element, so one entry with a
    # blank venue would blank out the whole tally.
    vals <- unlist(lapply(all, function(x) x[[id]]), use.names = FALSE)
    if (is.null(vals)) return(NULL)
    vals <- trimws(as.character(vals))
    vals <- vals[nzchar(vals)]
    if (!length(vals)) return(NULL)

    tab <- table(vals)
    tab <- tab[tab >= (rule$min_count %||% 1)]
    if (length(tab) < 2) return(NULL)   # a lone chip filters nothing

    ord <- if (identical(rule$order, "desc")) {
      order(names(tab), decreasing = TRUE)
    } else if (is.character(rule$order)) {
      # explicit order first, anything else by frequency
      known <- match(names(tab), rule$order)
      order(ifelse(is.na(known), length(rule$order) + 1L, known), -as.integer(tab))
    } else {
      order(-as.integer(tab), names(tab))
    }
    tab <- tab[ord]
    if (!is.null(rule$max_show)) tab <- utils::head(tab, rule$max_show)

    list(id = id, values = names(tab), counts = as.integer(tab))
  })

  Filter(Negate(is.null), groups)
}

# ---------------------------------------------------------------- cards

# Everything the client-side filter needs, as data attributes. Facet values are
# pipe-delimited slugs so the JS can do an exact token test rather than a
# substring match (which would let "r" match "rust").
card_data_attrs <- function(e, kind, sort_title, search_blob) {
  fac <- entry_facets(e, kind)
  attrs <- vapply(names(fac), function(id) {
    v <- unique(slugify(fac[[id]]))
    v <- v[nzchar(v)]
    if (!length(v)) return("")
    sprintf(' data-%s="%s"', id, esc(paste(v, collapse = "|")))
  }, character(1))

  cites <- if (identical(kind, "research")) metric_citations(GRID_METRICS, kind, e$key)
           else metric_software_citations(GRID_METRICS, e$fields)

  paste0(
    paste(attrs[nzchar(attrs)], collapse = ""),
    sprintf(' data-sort-title="%s"', esc(sort_title)),
    if (!is.null(cites)) sprintf(' data-citations="%d"', cites) else "",
    sprintf(' data-search="%s"', esc(search_blob))
  )
}

# Author lists are rendered by R/people.R::authors_html(), which adds roster
# links and affiliation tooltips. The roster is read once per page rather than
# once per card.
GRID_PEOPLE <- NULL
GRID_METRICS <- list()

# Detail pages exist in English only, so non-English pages say so on the link
# rather than surprising the reader.
GRID_LANG <- "en"

# Quarto rewrites site-root-relative paths ("/research/x.html") relative to
# each *project* root, and es/ and zh/ are separate projects one level deeper.
# A bare "/..." there resolves to public/es/research/... which does not exist,
# so the prefix has to be explicit. Derived the same way the source paths are.
site_root <- function() if (file.exists("papers.toml")) "" else "../"

detail_hint <- function(i18n) {
  if (identical(GRID_LANG, "en")) "" else sprintf(' title="%s"', esc(i18n$detail_in_english))
}

research_card <- function(e, i18n) {
  f <- e$fields
  title    <- esc(f$title %||% i18n$untitled)
  year     <- esc(substr(f$year %||% "", 1, 4))
  if (!nzchar(year)) year <- esc(i18n$no_date)
  venue    <- esc(f$venue_short %||% venue_of(f))
  abstract <- esc(f$abstract %||% "")
  status   <- entry_status(e)
  topics   <- entry_topics(e)

  doi   <- f$doi %||% ""
  url   <- f$url %||% ""
  arxiv <- f$eprint %||% ""
  # Detail pages are generated in English only; es/ and zh/ cards link to the
  # same page (root-relative, so it resolves from any subdirectory).
  href  <- paste0(site_root(), "research/", entry_slug(e), ".html")

  links <- c(
    if (nzchar(doi)) safe_link(paste0("https://doi.org/", doi), "DOI") else "",
    safe_link(url, i18n$link_publisher),
    if (nzchar(arxiv)) safe_link(paste0("https://arxiv.org/abs/", arxiv), "arXiv") else ""
  )
  links <- links[nzchar(links)]

  paste0(
    '<article class="card">',
    '<div class="card__head">',
      tag_html(year, "tag--year"),
      tag_html(i18n_value(i18n, status), paste0("tag--status is-", status)),
      local({
        n <- metric_citations(GRID_METRICS, "research", e$key)
        if (is.null(n) || n == 0L) "" else
          badge_html(i18n$cited_by, as.character(n),
                     paste0(i18n$cited_by, ": ", n, " (OpenAlex, ", i18n$as_of, " ",
                            metrics_stamp(GRID_METRICS), ")"))
      }),
    '</div>',
    '<h3 class="card__title">',
      sprintf('<a href="%s"%s>%s</a>', esc(href), detail_hint(i18n), title),
    '</h3>',
    sprintf('<p class="card__authors">%s</p>', authors_html(f, GRID_PEOPLE)),
    if (nzchar(venue)) sprintf('<p class="card__venue"><em>%s</em></p>', venue) else "",
    if (length(topics)) sprintf(
      '<p class="card__tags">%s</p>',
      paste(vapply(topics, tag_html, character(1), cls = "tag--topic"), collapse = "")
    ) else "",
    sprintf(
      '<p class="card__links">%s</p>',
      if (length(links)) paste(links, collapse = '<span class="sep">&bull;</span>')
      else sprintf('<span class="muted">%s</span>', i18n$no_link)
    ),
    if (nzchar(abstract)) sprintf(
      '<details class="card__abstract"><summary>%s</summary><p>%s</p></details>',
      i18n$abstract_label, abstract
    ) else "",
    '</article>'
  )
}

# `note` is free text ("R package version 0.1.1.99, https://...") so pull the
# first version-shaped token out of it rather than everything after "version".
software_version <- function(f) {
  v <- f$version %||% ""
  if (nzchar(v)) return(sub("^v", "", v))
  m <- regmatches(f$note %||% "", regexpr("[0-9]+[0-9.-]*[0-9]", f$note %||% ""))
  if (length(m)) m[1] else ""
}

software_card <- function(e, i18n) {
  f <- e$fields
  title <- esc(f$title %||% i18n$untitled)
  # "pkgname: Description" -- split so the name can carry the visual weight
  name  <- esc(sub(":.*$", "", f$title %||% e$key))
  blurb <- esc(f$tagline %||% sub("^[^:]*:\\s*", "", f$title %||% ""))
  abstract <- esc(f$abstract %||% "")
  year  <- esc(substr(f$year %||% "", 1, 4))
  note  <- esc(f$note %||% "")
  status <- tolower(f$status %||% "active")
  kind_v <- tolower(f$kind %||% "package")
  topics <- entry_topics(e)

  repo <- f$repo %||% (if (grepl("github.com", f$url %||% "", ignore.case = TRUE)) f$url else "")
  links <- c(
    safe_link(f$url %||% "", if (nzchar(f$cran %||% "") || grepl("cran", f$url %||% "", ignore.case = TRUE)) "CRAN" else "Link"),
    safe_link(f$docs %||% "", "Docs"),
    safe_link(repo, "Repo"),
    if (nzchar(f$doi %||% "")) safe_link(paste0("https://doi.org/", f$doi), "DOI") else ""
  )
  links <- links[nzchar(links)]

  hex <- asset_url(f$hex %||% "", site_root())
  media <- if (nzchar(hex)) {
    sprintf('<img class="card__hex" src="%s" alt="" loading="lazy">', esc(hex))
  } else {
    # Only three packages have a hex logo, so most cards fall back to a
    # monogram. A hue derived from the key keeps them from all looking like
    # the same orange square -- stable across builds, no image needed.
    hue <- sum(utf8ToInt(tolower(e$key))) %% 360L
    sprintf(
      '<span class="card__hex card__hex--mono" style="background:hsl(%d 45%% 42%%)" aria-hidden="true">%s</span>',
      hue, esc(toupper(substr(name, 1, 1)))
    )
  }

  paste0(
    '<article class="card card--software">',
    '<div class="card__head">',
      media,
      '<div class="card__headmeta">',
        tag_html(i18n_value(i18n, kind_v), "tag--kind"),
        tag_html(i18n_value(i18n, status), paste0("tag--status is-", status)),
        tag_html(year, "tag--year"),
      '</div>',
    '</div>',
    sprintf('<h3 class="card__title"><a href="%ssoftware/%s.html"%s>%s</a></h3>',
            esc(site_root()), esc(entry_slug(e)), detail_hint(i18n), name),
    if (nzchar(blurb)) sprintf('<p class="card__blurb">%s</p>', blurb) else "",
    sprintf('<p class="card__authors">%s</p>', authors_html(f, GRID_PEOPLE)),
    local({
      ver <- software_version(f)
      bits <- c(
        if (nzchar(ver)) badge_html(if (nzchar(f$cran %||% "")) "CRAN" else "version", ver, note) else "",
        local({
          n <- metric_num(GRID_METRICS, "software", e$key, "cran_downloads")
          if (is.null(n)) "" else badge_html("downloads", fmt_count(n), paste0(n, " CRAN downloads"))
        }),
        local({
          n <- metric_num(GRID_METRICS, "software", e$key, "stars")
          if (is.null(n) || n == 0L) "" else badge_html("stars", fmt_count(n), paste0(n, " GitHub stars"))
        }),
        local({
          n <- metric_software_citations(GRID_METRICS, f)
          if (is.null(n) || n == 0L) "" else badge_html(i18n$cited_by, as.character(n), i18n$cited_via_paper)
        })
      )
      bits <- bits[nzchar(bits)]
      if (length(bits)) sprintf('<p class="card__badges">%s</p>', paste(bits, collapse = "")) else ""
    }),
    if (length(topics)) sprintf(
      '<p class="card__tags">%s</p>',
      paste(vapply(topics, tag_html, character(1), cls = "tag--topic"), collapse = "")
    ) else "",
    sprintf(
      '<p class="card__links">%s</p>',
      if (length(links)) paste(links, collapse = '<span class="sep">&bull;</span>')
      else sprintf('<span class="muted">%s</span>', i18n$no_link)
    ),
    if (nzchar(abstract)) sprintf(
      '<details class="card__abstract"><summary>%s</summary><p>%s</p></details>',
      i18n$about_label, abstract
    ) else "",
    '</article>'
  )
}

# ---------------------------------------------------------------- shell

facet_bar_html <- function(groups, i18n) {
  if (!length(groups)) return("")

  chips <- vapply(groups, function(g) {
    buttons <- vapply(seq_along(g$values), function(i) {
      v <- g$values[i]
      sprintf(
        paste0('<button class="ig-chip" type="button" role="switch" aria-pressed="false"',
               ' data-facet="%s" data-value="%s">%s<span class="ig-count">%d</span></button>'),
        esc(g$id), esc(slugify(v)), esc(i18n_value(i18n, v)), g$counts[i]
      )
    }, character(1))

    sprintf(
      '<div class="ig-facet"><span class="ig-facet__label">%s</span><div class="ig-chips">%s</div></div>',
      esc(i18n[[paste0("facet_", g$id)]] %||% g$id),
      paste(buttons, collapse = "")
    )
  }, character(1))

  sprintf(
    '<div class="ig-facets" role="group" aria-label="%s">%s<button class="ig-clear" type="button" hidden>%s</button></div>',
    esc(i18n$facet_status), paste(chips, collapse = ""), esc(i18n$clear_filters)
  )
}

sort_select_html <- function(kind, i18n, has_citations = FALSE) {
  opts <- c("year-desc" = i18n$sort_year_desc,
            "year-asc"  = i18n$sort_year_asc,
            "title-asc" = i18n$sort_title)
  if (has_citations) opts <- c(opts, "citations-desc" = i18n$sort_citations)
  sprintf(
    '<label class="ig-sort">%s<select class="ig-sort-select">%s</select></label>',
    esc(i18n$sort_by),
    paste(sprintf('<option value="%s">%s</option>', names(opts), vapply(opts, esc, character(1))), collapse = "")
  )
}

view_toggle_html <- function(i18n) {
  sprintf(
    paste0('<div class="ig-view" role="group" aria-label="%s">',
           '<button type="button" data-view="grid" aria-pressed="true">%s</button>',
           '<button type="button" data-view="compact" aria-pressed="false">%s</button></div>'),
    esc(i18n$view_label), esc(i18n$view_grid), esc(i18n$view_compact)
  )
}

#' Render the filterable card grid for one collection.
#'
#' @param entries list from read_entries()
#' @param kind    "research" or "software"
#' @param language "en", "es" or "zh"
render_item_grid <- function(entries, kind = c("research", "software"), language = "en") {
  kind <- match.arg(kind)
  i18n <- get_i18n(language)
  GRID_PEOPLE  <<- read_people()
  GRID_METRICS <<- read_metrics()
  GRID_LANG   <<- tolower(language)

  cat("\n```{=html}\n")

  if (!length(entries)) {
    cat(sprintf('<p>%s</p>', if (kind == "research") i18n$unavailable else i18n$software_unavailable))
    cat("\n```\n")
    return(invisible(NULL))
  }

  entries <- sort_entries(entries)
  groups  <- build_facets(entries, kind)

  cat(sprintf('<section class="item-grid" data-kind="%s" data-i18n-showing="%s" data-i18n-empty="%s">',
              kind, esc(i18n$showing), esc(i18n$no_matches)))

  # Controls start hidden and are revealed by the script, so a reader without
  # JS sees the full list rather than widgets that do nothing.
  cat('<div class="ig-controls" hidden>')
  cat(sprintf(
    '<input class="ig-search" type="search" placeholder="%s" aria-label="%s">',
    esc(if (kind == "research") i18n$search_placeholder else i18n$search_software),
    esc(if (kind == "research") i18n$search_label else i18n$search_software_label)
  ))
  has_cites <- any(vapply(entries, function(e) {
    n <- if (identical(kind, "research")) metric_citations(GRID_METRICS, kind, e$key)
         else metric_software_citations(GRID_METRICS, e$fields)
    !is.null(n) && n > 0L
  }, logical(1)))
  cat(sprintf('<div class="ig-tools">%s%s</div>',
              sort_select_html(kind, i18n, has_cites), view_toggle_html(i18n)))
  cat(facet_bar_html(groups, i18n))
  cat('</div>')

  cat(sprintf('<p class="ig-status" role="status" aria-live="polite" hidden></p>'))

  # The date is the honest signal: show the numbers even when the cache is old,
  # and say when they were last refreshed rather than hiding a stale cron.
  stamp <- metrics_stamp(GRID_METRICS)
  if (has_cites && nzchar(stamp)) {
    cat(sprintf('<p class="ig-stamp">%s</p>', esc(sprintf(i18n$metrics_note, stamp))))
  }
  cat('<ul class="ig-list" data-view="grid">')

  for (e in entries) {
    f <- e$fields
    sort_title <- tolower(gsub("^[^a-z0-9]+", "", tolower(f$title %||% "")))
    # The software box offers to search descriptions, and no entry carries a
    # `tagline`, so the abstract is what makes that promise true. Research
    # abstracts stay out: their placeholder never offers them, and folding 30
    # of them in would duplicate ~38KB of card text into data attributes.
    blob <- tolower(paste(
      f$title %||% "", paste(parse_authors(f$author), collapse = " "), f$year %||% "",
      venue_of(f), paste(f$keywords %||% "", collapse = " "), f$note %||% "",
      f$tagline %||% "", if (identical(kind, "software")) f$abstract %||% "" else "", e$key
    ))

    cat(sprintf('<li class="ig-card"%s>', card_data_attrs(e, kind, sort_title, blob)))
    cat(if (kind == "research") research_card(e, i18n) else software_card(e, i18n))
    cat('</li>')
  }

  cat('</ul>')
  cat(sprintf('<p class="ig-empty" hidden>%s</p>', esc(i18n$no_matches)))
  cat('</section>')

  cat("\n```\n")
  invisible(NULL)
}
