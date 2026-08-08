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

clean_text <- function(x) {
  x <- gsub("\\\\textbf\\{([^}]*)\\}", "\\1", x)
  x <- gsub("\\\\textit\\{([^}]*)\\}", "\\1", x)
  x <- gsub("\\\\emph\\{([^}]*)\\}", "\\1", x)
  x <- gsub("\\\\color\\{[^}]*\\}", "", x)
  x <- gsub("\\\\bf\\b\\s*", "", x)
  x <- gsub("\\\\&", "&", x)
  x <- gsub("\\\\%", "%", x)
  x <- gsub("\\\\_", "_", x)
  x <- gsub("\\\\#", "#", x)
  x <- gsub("[{}]", "", x)
  x <- gsub("\n+", " ", x)
  x <- gsub("\\s+", " ", x)
  trimws(x)
}

parse_value <- function(chars, i) {
  n <- length(chars)
  while (i <= n && grepl("\\s", chars[i])) i <- i + 1
  if (i > n) return(list(value = "", next_i = i))

  if (chars[i] == "{") {
    depth <- 1
    i <- i + 1
    start <- i
    while (i <= n && depth > 0) {
      if (chars[i] == "{") depth <- depth + 1
      if (chars[i] == "}") depth <- depth - 1
      i <- i + 1
    }
    val <- paste(chars[start:(i - 2)], collapse = "")
    return(list(value = clean_text(val), next_i = i))
  }

  if (chars[i] == '"') {
    i <- i + 1
    start <- i
    while (i <= n && chars[i] != '"') i <- i + 1
    val <- paste(chars[start:(i - 1)], collapse = "")
    i <- i + 1
    return(list(value = clean_text(val), next_i = i))
  }

  start <- i
  while (i <= n && chars[i] != ',') i <- i + 1
  val <- paste(chars[start:(i - 1)], collapse = "")
  list(value = clean_text(val), next_i = i)
}

parse_entry <- function(entry) {
  m <- regexec("^@([[:alpha:]]+)\\s*\\{([^,]+),", entry)
  reg <- regmatches(entry, m)[[1]]
  if (length(reg) < 3) return(NULL)

  type <- tolower(reg[2])
  key <- reg[3]
  body <- sub("^@[[:alpha:]]+\\s*\\{[^,]+,", "", entry)
  body <- sub("\\}\\s*$", "", body)

  chars <- strsplit(body, "")[[1]]
  n <- length(chars)
  i <- 1
  fields <- list()

  while (i <= n) {
    while (i <= n && (grepl("\\s", chars[i]) || chars[i] == ",")) i <- i + 1
    if (i > n) break

    start <- i
    while (i <= n && chars[i] != '=') i <- i + 1
    if (i > n) break

    fname <- tolower(trimws(paste(chars[start:(i - 1)], collapse = "")))
    i <- i + 1
    parsed <- parse_value(chars, i)
    fields[[fname]] <- parsed$value
    i <- parsed$next_i
  }

  list(type = type, key = key, fields = fields)
}

parse_bib <- function(path) {
  txt <- paste(readLines(path, warn = FALSE), collapse = "\n")
  starts <- gregexpr("@[[:alpha:]]+\\s*\\{", txt, perl = TRUE)[[1]]
  if (length(starts) == 1 && starts[1] == -1) return(list())

  entries <- list()
  for (j in seq_along(starts)) {
    s <- starts[j]
    e <- if (j < length(starts)) starts[j + 1] - 1 else nchar(txt)
    chunk <- trimws(substr(txt, s, e))
    parsed <- parse_entry(chunk)
    if (!is.null(parsed)) entries[[length(entries) + 1]] <- parsed
  }

  entries
}

safe_link <- function(url, label) {
  if (!nzchar(url)) return("")
  sprintf('<a href="%s" target="_blank" rel="noopener">%s</a>', url, label)
}

entry_status <- function(fields) {
  key <- tolower(fields$keywords %||% "")
  if (grepl("wip|preprint|working", key)) return("wip")
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
      link_publisher = "Publisher / Preprint"
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
      link_publisher = "Editorial / Preprint"
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
      link_publisher = "期刊 / 预印本"
    )
  )

  lookup[[language]] %||% lookup$en
}

sync_papers_bib <- function(output_path, file_url = "https://raw.githubusercontent.com/gvegayon/resume/refs/heads/master/papers.bib") {
  tmp <- tempfile(fileext = ".bib")
  ans <- tryCatch(
    download.file(url = file_url, destfile = tmp, quiet = TRUE),
    error = function(e) 1
  )

  if (identical(ans, 0L)) {
    invisible(file.copy(from = tmp, to = output_path, overwrite = TRUE))
  }
}

render_research_cards <- function(bib_path, language = "en") {
  i18n <- get_research_i18n(language)
  entries <- parse_bib(bib_path)

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
    authors <- clean_text(f$author %||% "")
    title <- clean_text(f$title %||% i18n$untitled)
    year <- clean_text(f$year %||% i18n$no_date)
    venue <- clean_text(f$journal %||% f$booktitle %||% f$publisher %||% f$institution %||% "")
    abstract <- clean_text(f$abstract %||% "")
    status <- entry_status(f)

    doi <- clean_text(f$doi %||% "")
    url <- clean_text(f$url %||% f$URL %||% "")
    arxiv <- clean_text(f$eprint %||% "")

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
      tolower(f$keywords %||% ""),
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
