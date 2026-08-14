`%||%` <- function(a, b) {
  if (is.null(a) || length(a) == 0) {
    return(b)
  }

  if (length(a) == 1) {
    if (is.atomic(a) && is.na(a)) {
      return(b)
    }

    if (is.character(a) && !nzchar(trimws(a))) {
      return(b)
    }
  }

  a
}

# Field values are plain text in the .toml files, so the only job left is
# escaping them for the HTML they are about to be pasted into.
esc <- function(x) {
  x <- trimws(gsub("\\s+", " ", paste(x, collapse = ", "), perl = TRUE))
  x <- gsub("&", "&amp;", x, fixed = TRUE)
  x <- gsub('"', "&quot;", x, fixed = TRUE)
  x <- gsub("<", "&lt;", x, fixed = TRUE)
  gsub(">", "&gt;", x, fixed = TRUE)
}

# One TOML table per entry, keyed by citation key. `author` and `keywords`
# arrive as arrays. A missing `toml` package is an error rather than an empty
# list: silently rendering a publications page with no publications is the
# worst outcome.
parse_toml <- function(path) {
  if (!requireNamespace("toml", quietly = TRUE)) {
    stop("the 'toml' package is required to read ", path, call. = FALSE)
  }
  data <- toml::read_toml(path)

  lapply(names(data), function(key) {
    f <- data[[key]]
    list(type = f$entrytype %||% "misc", key = key, fields = f)
  })
}

safe_link <- function(url, label) {
  if (!nzchar(url)) return("")
  sprintf('<a href="%s" target="_blank" rel="noopener">%s</a>', url, label)
}

entry_status <- function(fields) {
  kw <- tolower(as.character(fields$keywords %||% character(0)))
  if (any(grepl("wip|preprint|working", kw))) return("wip")
  "published"
}

get_research_i18n <- function(language = "en") {
  language <- tolower(language)

  lookup <- list(
    en = list(
      unavailable = "Publication list temporarily unavailable.",
      search_placeholder = "Search title, author, year, journal...",
      search_label = "Search publications",
      filter_group = "Filter publications",
      all = "All",
      published = "Published",
      wip = "Work in progress",
      no_link = "No external link listed",
      abstract_label = "Abstract",
      abstract_unavailable = "Abstract unavailable.",
      untitled = "Untitled",
      no_date = "n.d.",
      link_publisher = "Publisher / Preprint",
      software_unavailable = "Software list temporarily unavailable.",
      search_software = "Search software...",
      search_software_label = "Search software",
      details = "Details"
    ),
    es = list(
      unavailable = "La lista de publicaciones no esta disponible temporalmente.",
      search_placeholder = "Buscar por titulo, autor, ano, revista...",
      search_label = "Buscar publicaciones",
      filter_group = "Filtrar publicaciones",
      all = "Todas",
      published = "Publicadas",
      wip = "En progreso",
      no_link = "No hay enlace externo registrado",
      abstract_label = "Resumen",
      abstract_unavailable = "Resumen no disponible.",
      untitled = "Sin titulo",
      no_date = "s.f.",
      link_publisher = "Editorial / Preprint",
      software_unavailable = "La lista de software no esta disponible temporalmente.",
      search_software = "Buscar software...",
      search_software_label = "Buscar software",
      details = "Detalles"
    ),
    zh = list(
      unavailable = "出版列表暂时不可用。",
      search_placeholder = "按标题、作者、年份、期刊搜索...",
      search_label = "搜索出版物",
      filter_group = "筛选出版物",
      all = "全部",
      published = "已发表",
      wip = "进行中",
      no_link = "暂无外部链接",
      abstract_label = "摘要",
      abstract_unavailable = "暂无摘要。",
      untitled = "无标题",
      no_date = "无日期",
      link_publisher = "期刊 / 预印本",
      software_unavailable = "软件列表暂时不可用。",
      search_software = "搜索软件...",
      search_software_label = "搜索软件",
      details = "详情"
    )
  )

  lookup[[language]] %||% lookup$en
}

render_research_cards <- function(toml_path, language = "en") {
  i18n <- get_research_i18n(language)
  entries <- parse_toml(toml_path)

  cat("\n```{=html}\n")

  if (!length(entries)) {
    cat(sprintf("<p>%s</p>", i18n$unavailable))
    cat("\n```\n")
    return(invisible(NULL))
  }

  years <- sapply(entries, function(e) as.integer(gsub("[^0-9]", "", e$fields$year %||% "0")))
  years[is.na(years)] <- 0
  entries <- entries[order(years, decreasing = TRUE)]

  cat('<div class="research-shell">')
  cat('<div class="research-controls">')
  cat(sprintf(
    '<input id="pub-search" class="pub-search" type="search" placeholder="%s" aria-label="%s">',
    i18n$search_placeholder,
    i18n$search_label
  ))
  cat(sprintf('<div class="pub-filter-group" role="group" aria-label="%s">', i18n$filter_group))
  cat(sprintf('<button class="pub-filter is-active" data-filter="all" type="button">%s</button>', i18n$all))
  cat(sprintf('<button class="pub-filter" data-filter="published" type="button">%s</button>', i18n$published))
  cat(sprintf('<button class="pub-filter" data-filter="wip" type="button">%s</button>', i18n$wip))
  cat('</div></div>')
  cat('<div id="pub-list" class="pub-list">')

  for (e in entries) {
    f <- e$fields
    authors <- esc(f$author %||% "")
    title <- esc(f$title %||% i18n$untitled)
    year <- esc(f$year %||% i18n$no_date)
    venue <- esc(f$journal %||% f$booktitle %||% f$publisher %||% f$institution %||% "")
    abstract <- esc(f$abstract %||% "")
    status <- entry_status(f)

    doi <- esc(f$doi %||% "")
    url <- esc(f$url %||% f$URL %||% "")
    arxiv <- esc(f$eprint %||% "")

    doi_url <- if (nzchar(doi)) paste0("https://doi.org/", doi) else ""
    links <- c(
      safe_link(doi_url, "DOI"),
      safe_link(url, i18n$link_publisher),
      if (nzchar(arxiv)) safe_link(paste0("https://arxiv.org/abs/", arxiv), "arXiv") else ""
    )
    links <- links[nzchar(links)]

    link_block <- if (length(links)) {
      paste(links, collapse = '<span class="sep">•</span>')
    } else {
      sprintf('<span class="muted">%s</span>', i18n$no_link)
    }

    abstract_html <- if (nzchar(abstract)) {
      sprintf('<details class="pub-abstract"><summary>%s</summary><p>%s</p></details>', i18n$abstract_label, abstract)
    } else {
      sprintf('<p class="muted abstract-missing">%s</p>', i18n$abstract_unavailable)
    }

    cat(sprintf(
      '<article class="pub-card" data-status="%s" data-search="%s %s %s %s">\n<h3>%s</h3>\n<p class="pub-meta">%s (%s)%s%s</p>\n<p class="pub-links">%s</p>\n%s\n</article>',
      status,
      tolower(paste(title, authors, year, venue)),
      tolower(status),
      tolower(esc(f$keywords %||% "")),
      tolower(e$key),
      title,
      authors,
      year,
      if (nzchar(venue)) ". " else "",
      if (nzchar(venue)) venue else "",
      link_block,
      abstract_html
    ))
  }

  cat('</div></div>')

  cat('<script>(() => { const search = document.getElementById("pub-search"); const cards = Array.from(document.querySelectorAll(".pub-card")); const filters = Array.from(document.querySelectorAll(".pub-filter")); let mode = "all"; function update() { const q = (search && search.value || "").trim().toLowerCase(); cards.forEach((card) => { const matchesText = !q || card.dataset.search.includes(q); const matchesMode = mode === "all" || card.dataset.status === mode; card.style.display = matchesText && matchesMode ? "block" : "none"; }); } if (search) search.addEventListener("input", update); filters.forEach((btn) => { btn.addEventListener("click", () => { filters.forEach((b) => b.classList.remove("is-active")); btn.classList.add("is-active"); mode = btn.dataset.filter; update(); }); }); update(); })();</script>')

  cat("\n```\n")
  invisible(NULL)
}

render_software_cards <- function(toml_path, language = "en") {
  i18n <- get_research_i18n(language)
  entries <- parse_toml(toml_path)

  cat("\n```{=html}\n")

  if (!length(entries)) {
    cat(sprintf("<p>%s</p>", i18n$software_unavailable))
    cat("\n```\n")
    return(invisible(NULL))
  }

  years <- sapply(entries, function(e) as.integer(gsub("[^0-9]", "", e$fields$year %||% "0")))
  years[is.na(years)] <- 0
  entries <- entries[order(years, decreasing = TRUE)]

  cat('<div class="research-shell">')
  cat('<div class="research-controls">')
  cat(sprintf(
    '<input id="pub-search" class="pub-search" type="search" placeholder="%s" aria-label="%s">',
    i18n$search_software,
    i18n$search_software_label
  ))
  cat('</div>')
  cat('<div id="pub-list" class="pub-list">')

  for (e in entries) {
    f <- e$fields
    authors <- esc(f$author %||% "")
    title <- esc(f$title %||% i18n$untitled)
    year <- esc(f$year %||% i18n$no_date)
    abstract <- esc(f$abstract %||% f$note %||% "")

    url <- esc(f$url %||% "")

    links <- c()
    github_badges <- ""

    if (nzchar(url)) {
      links <- c(links, safe_link(url, "Link"))

      # Badges are built from the owner/repo pair alone -- shields.io renders
      # them client side, so nothing is fetched at render time.
      gh_match <- regmatches(url, regexec("github\\.com/([^/]+)/([^/?#]+)", url))[[1]]
      if (length(gh_match) >= 3) {
        owner <- gh_match[2]
        repo <- sub("\\.git$", "", gh_match[3])
        github_badges <- sprintf(
          paste0(
            '<a href="%s" target="_blank" rel="noopener"><img src="https://img.shields.io/github/stars/%s/%s.svg?style=social&amp;label=Stars" alt="GitHub stars" style="vertical-align: middle; margin-left: 10px;"></a>',
            '<a href="%s/releases" target="_blank" rel="noopener"><img src="https://img.shields.io/github/downloads/%s/%s/total.svg?style=social&amp;label=Downloads" alt="GitHub downloads" style="vertical-align: middle; margin-left: 10px;"></a>'
          ),
          url, owner, repo, url, owner, repo
        )
      }
    }

    link_block <- if (length(links)) {
      paste(links, collapse = '<span class="sep">•</span>')
    } else {
      sprintf('<span class="muted">%s</span>', i18n$no_link)
    }

    abstract_html <- if (nzchar(abstract)) {
      sprintf('<details class="pub-abstract"><summary>%s</summary><p>%s</p></details>', i18n$details, abstract)
    } else {
      ''
    }

    cat(sprintf(
      '<article class="pub-card" data-status="published" data-search="%s">\n<h3>%s</h3>\n<p class="pub-meta">%s (%s)</p>\n<p class="pub-links">%s%s</p>\n%s\n</article>',
      tolower(paste(title, authors, year, abstract)),
      title,
      authors,
      year,
      link_block,
      github_badges,
      abstract_html
    ))
  }

  cat('</div></div>')

  cat('<script>(() => { const search = document.getElementById("pub-search"); const cards = Array.from(document.querySelectorAll(".pub-card")); function update() { const q = (search && search.value || "").trim().toLowerCase(); cards.forEach((card) => { const matchesText = !q || card.dataset.search.includes(q); card.style.display = matchesText ? "block" : "none"; }); } if (search) search.addEventListener("input", update); update(); })();</script>')

  cat("\n```\n")
  invisible(NULL)
}
