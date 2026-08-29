# Per-item detail pages.
#
# Each entry in papers.toml / software.toml gets its own page at
# /research/<slug>.html or /software/<slug>.html. The pages are generated as
# .qmd so they inherit the navbar, footer, theme, analytics and the
# person-jsonld include for free -- writing HTML straight into public/ would
# mean reimplementing all of that and silently missing every future change to
# _quarto.yml.
#
# The generated files contain no R chunks at all: everything is materialised
# here, so rendering a detail page cannot fail and cannot hit the network.
#
# Requires R/entries.R, R/html.R, R/i18n.R, R/people.R.

# ---------------------------------------------------------------- helpers

# Double-quoted YAML with the two characters that actually break it escaped.
yaml_str <- function(x) {
  x <- gsub("\\", "\\\\", paste(x, collapse = " "), fixed = TRUE)
  x <- gsub('"', '\\"', x, fixed = TRUE)
  x <- gsub("[\r\n]+", " ", x)
  paste0('"', trimws(x), '"')
}

# Quarto renders `description` in the title block, right above the abstract.
# A first sentence reads as a lead; a mid-sentence word truncation reads as a
# bug. Falls back to word truncation when there is no sentence break.
lead_sentence <- function(x, max_words = 45) {
  x <- trimws(gsub("[[:space:]]+", " ", x %||% ""))
  if (!nzchar(x)) return("")
  m <- regexpr("^.{40,}?[.!?](\\s|$)", x, perl = TRUE)
  out <- if (m > 0) trimws(regmatches(x, m)) else x
  truncate_words(out, max_words)
}

truncate_words <- function(x, n = 40) {
  w <- unlist(strsplit(trimws(x %||% ""), "[[:space:]]+"))
  if (length(w) <= n) return(paste(w, collapse = " "))
  paste0(paste(w[seq_len(n)], collapse = " "), "...")
}

# BibTeX is no longer a source format here, so the citation block has to be
# built back up from the TOML fields.
BIBTEX_TYPE <- c(article = "article", manual = "Manual", techreport = "techreport",
                 unpublished = "unpublished", online = "online", misc = "misc",
                 inproceedings = "inproceedings", book = "book")

as_bibtex <- function(e) {
  f <- e$fields
  type <- BIBTEX_TYPE[[tolower(e$type)]] %||% "misc"

  order <- c("title", "author", "editor", "year", "month", "journal", "journaltitle",
             "booktitle", "publisher", "institution", "volume", "number",
             "pages", "doi", "url", "issn", "note", "version")

  lines <- character(0)
  for (k in order) {
    v <- f[[k]]
    if (is.null(v) || !length(v)) next
    v <- if (k %in% c("author", "editor")) {
           # "{Last}, {First}" -- see bibtex_name() for why both halves are braced
           paste(vapply(parse_authors(v), bibtex_name, character(1)), collapse = " and ")
         } else {
           paste(as.character(v), collapse = ", ")
         }
    if (!nzchar(trimws(v))) next
    lines <- c(lines, sprintf("  %s = {%s},", k, v))
  }

  paste0("@", type, "{", e$key, ",\n", paste(lines, collapse = "\n"), "\n}")
}

# The author block on a detail page has room for the affiliation inline,
# unlike the compact card.
author_list_html <- function(f, people) {
  nm <- parse_authors(f$author)
  if (!length(nm)) return("")

  items <- vapply(nm, function(p) {
    if (identical(tolower(p), "others")) {
      return('<li class="author"><span class="author__name">et al.</span></li>')
    }
    is_self <- grepl(SELF, p, fixed = TRUE)
    per   <- if (is_self) people[[person_key(paste0(SELF, ", George"))]] else match_person(p, people)
    label <- if (is_self) paste0(SELF, ", G. G.") else one_author(sub("\\.$", "", p))

    url <- per$url %||% ""
    aff <- per$affiliation %||% ""
    orc <- per$orcid %||% ""

    name_html <- if (nzchar(url)) {
      sprintf('<a href="%s" target="_blank" rel="noopener">%s</a>', esc(url), esc(label))
    } else {
      esc(label)
    }

    sprintf(
      '<li class="author%s">%s<span class="author__info"><span class="author__name">%s</span>%s%s</span></li>',
      if (is_self) " is-self" else "",
      avatar_html(per, DETAIL_ROOT, cls = "avatar avatar--detail"),
      name_html,
      if (nzchar(aff)) sprintf('<span class="author__aff">%s</span>', esc(aff)) else "",
      if (nzchar(orc)) sprintf(
        '<a class="author__orcid" href="https://orcid.org/%s" target="_blank" rel="noopener" aria-label="ORCID">iD</a>',
        esc(orc)) else ""
    )
  }, character(1), USE.NAMES = FALSE)

  paste0('<ol class="author-list">', paste(items, collapse = ""), "</ol>")
}

# Optional `image` / `image_caption`: one figure for the entry -- a key result,
# a hex sticker, a screenshot. Paths are site-root relative in the .toml
# ('img/papers/x.webp'); detail pages render one directory deeper, hence the
# fixed '../'. The caption doubles as the alt text when there is one, because a
# figure with a caption and an empty alt is worse than no image at all.
DETAIL_ROOT <- "../"

figure_html <- function(f) {
  src <- asset_url(f$image %||% "", DETAIL_ROOT)
  if (!nzchar(src)) return("")
  cap <- trimws(f$image_caption %||% "")
  alt <- if (nzchar(cap)) cap else f$title %||% ""
  sprintf(
    '<figure class="item-figure"><img src="%s" alt="%s" loading="lazy">%s</figure>',
    esc(src), esc(alt),
    if (nzchar(cap)) sprintf("<figcaption>%s</figcaption>", esc(cap)) else ""
  )
}

links_row_html <- function(e, kind, i18n) {
  f <- e$fields
  links <- if (identical(kind, "research")) {
    c(if (nzchar(f$doi %||% "")) safe_link(paste0("https://doi.org/", f$doi), "DOI") else "",
      safe_link(f$url %||% "", i18n$link_publisher),
      if (nzchar(f$eprint %||% "")) safe_link(paste0("https://arxiv.org/abs/", f$eprint), "arXiv") else "",
      safe_link(f$pdf %||% "", "PDF"),
      safe_link(f$code %||% "", "Code"),
      safe_link(f$data %||% "", "Data"),
      safe_link(f$slides %||% "", "Slides"))
  } else {
    c(safe_link(f$url %||% "", if (nzchar(f$cran %||% "")) "CRAN" else "Link"),
      safe_link(f$docs %||% "", "Docs"),
      safe_link(f$repo %||% "", "Repository"),
      if (nzchar(f$doi %||% "")) safe_link(paste0("https://doi.org/", f$doi), "DOI") else "")
  }
  links <- links[nzchar(links)]
  if (!length(links)) return("")
  paste0('<p class="item-links">', paste(links, collapse = '<span class="sep">&bull;</span>'), "</p>")
}

# Cross-links declared with `software = [...]` on a paper or `paper = '...'` on
# a package. Silently skips keys that do not resolve, so a typo degrades to a
# missing bullet rather than a broken link.
related_html <- function(e, kind, index, i18n) {
  f <- e$fields
  want <- if (identical(kind, "research")) {
    lapply(as.character(f$software %||% character(0)), function(k) list(k = k, kind = "software"))
  } else {
    lapply(as.character(f$paper %||% character(0)), function(k) list(k = k, kind = "research"))
  }
  if (!length(want)) return("")

  bullets <- character(0)
  for (w in want) {
    other <- index[[paste0(w$kind, ":", w$k)]]
    if (is.null(other)) next
    label <- if (identical(w$kind, "software")) sub(":.*$", "", other$fields$title %||% w$k)
             else (other$fields$title %||% w$k)
    bullets <- c(bullets, sprintf(
      '<li><a href="/%s/%s.html">%s</a></li>', w$kind, entry_slug(other), esc(label)
    ))
  }
  if (!length(bullets)) return("")
  paste0("\n## ", i18n$related, "\n\n```{=html}\n<ul class=\"related-list\">",
         paste(bullets, collapse = ""), "</ul>\n```\n")
}


# Per-item structured data. The site-wide _includes/person-jsonld.html
# describes the person; this describes the work, with its real author list.
# (Quarto's own `citation:` front matter was tried here and rejected: it
# rendered a second, worse BibTeX appendix below ours -- empty author, wrong
# key -- and adding `author:` to fix it duplicated the byline as well.)
jsonld_html <- function(e, kind, f, venue, year) {
  jstr <- function(x) {
    x <- gsub("\\\\", "\\\\\\\\", paste(x, collapse = " "))
    x <- gsub('"', '\\\\"', x)
    x <- gsub("[\r\n\t]+", " ", x)
    paste0('"', trimws(x), '"')
  }
  authors <- parse_authors(f$author)
  authors <- authors[tolower(authors) != "others"]
  auth_json <- paste(sprintf('{"@type":"Person","name":%s}', vapply(authors, jstr, character(1))),
                     collapse = ",")

  bits <- c(
    sprintf('"@context":"https://schema.org"'),
    sprintf('"@type":%s', if (identical(kind, "research")) '"ScholarlyArticle"' else '"SoftwareSourceCode"'),
    sprintf('"name":%s', jstr(f$title %||% "")),
    if (length(authors)) sprintf('"author":[%s]', auth_json),
    if (nzchar(year)) sprintf('"datePublished":%s', jstr(year)),
    if (nzchar(f$doi %||% "")) sprintf('"identifier":%s', jstr(paste0("https://doi.org/", f$doi))),
    if (nzchar(f$url %||% "")) sprintf('"url":%s', jstr(f$url)),
    if (identical(kind, "research") && nzchar(venue)) sprintf('"isPartOf":{"@type":"Periodical","name":%s}', jstr(venue)),
    if (identical(kind, "software") && nzchar(f$repo %||% "")) sprintf('"codeRepository":%s', jstr(f$repo)),
    if (identical(kind, "software") && length(f$languages)) sprintf('"programmingLanguage":%s', jstr(paste(f$languages, collapse = ", "))),
    if (nzchar(f$abstract %||% "")) sprintf('"abstract":%s', jstr(f$abstract))
  )
  bits <- bits[!vapply(bits, is.null, logical(1))]
  paste0('<script type="application/ld+json">{', paste(bits, collapse = ","), '}</script>')
}

# ---------------------------------------------------------------- page

detail_qmd_text <- function(e, kind, index, people, i18n) {
  f <- e$fields
  slug  <- entry_slug(e)
  title <- f$title %||% i18n$untitled
  year  <- substr(f$year %||% "", 1, 4)
  venue <- f$venue_short %||% venue_of(f)

  if (identical(kind, "research")) {
    status  <- entry_status(e)
    heading <- title
    blurb   <- f$summary %||% lead_sentence(f$abstract %||% "")
  } else {
    status  <- tolower(f$status %||% "active")
    heading <- sub(":.*$", "", title)
    blurb   <- f$tagline %||% sub("^[^:]*:[[:space:]]*", "", title)
  }

  subtitle <- paste(c(venue, year)[nzchar(c(venue, year))], collapse = " · ")

  # A software blurb is the noun phrase trailing the package title ("Beautiful
  # graph drawing"), which reads thin as a meta description. The abstract holds
  # the DESCRIPTION prose, so lead with its first sentence when there is one.
  meta_desc <- if (identical(kind, "software") && nzchar(f$abstract %||% "")) {
    lead_sentence(f$abstract)
  } else {
    blurb
  }

  # --- front matter
  fm <- c("---",
          paste0("title: ", yaml_str(heading)),
          if (nzchar(subtitle)) paste0("subtitle: ", yaml_str(subtitle)),
          paste0("description: ", yaml_str(truncate_words(meta_desc, 45))),
          if (nzchar(f$image %||% "")) paste0("image: ", yaml_str(asset_url(f$image, DETAIL_ROOT))),
          if (nzchar(f$image_caption %||% "")) paste0("image-alt: ", yaml_str(f$image_caption)),
          "toc: false",
          "page-layout: article")

  topics <- entry_topics(e)
  if (length(topics)) {
    fm <- c(fm, paste0("categories: [", paste(vapply(topics, yaml_str, character(1)), collapse = ", "), "]"))
  }

  fm <- c(fm, "---")

  # --- body
  metrics <- read_metrics()
  stamp   <- metrics_stamp(metrics)
  cites   <- if (identical(kind, "research")) metric_citations(metrics, "research", e$key)
             else metric_software_citations(metrics, f)

  badges <- paste0(
    '<p class="item-badges">',
    tag_html(i18n_value(i18n, status), paste0("tag--status is-", status)),
    if (identical(kind, "software")) tag_html(i18n_value(i18n, tolower(f$kind %||% "package")), "tag--kind") else "",
    if (nzchar(year)) tag_html(year, "tag--year") else "",
    if (identical(kind, "software")) local({
      v <- software_version(f)
      if (nzchar(v)) badge_html(if (nzchar(f$cran %||% "")) "CRAN" else "version", v) else ""
    }) else "",
    if (identical(kind, "software")) local({
      n <- metric_num(metrics, "software", e$key, "cran_downloads")
      if (is.null(n)) "" else badge_html("downloads", fmt_count(n), paste0(n, " CRAN downloads"))
    }) else "",
    if (identical(kind, "software")) local({
      n <- metric_num(metrics, "software", e$key, "stars")
      if (is.null(n) || n == 0L) "" else badge_html("stars", fmt_count(n), paste0(n, " GitHub stars"))
    }) else "",
    if (!is.null(cites) && cites > 0L)
      badge_html(i18n$cited_by, as.character(cites),
                 paste0(i18n$cited_by, ": ", cites, " (OpenAlex, ", i18n$as_of, " ", stamp, ")"))
    else "",
    "</p>",
    if (!is.null(cites) && cites > 0L && nzchar(stamp))
      sprintf('<p class="item-stamp">%s</p>', esc(sprintf(i18n$metrics_note, stamp))) else ""
  )

  header_html <- paste0(
    "\n```{=html}\n",
    jsonld_html(e, kind, f, venue, year),
    '<div class="item-detail">',
    badges,
    author_list_html(f, people),
    links_row_html(e, kind, i18n),
    figure_html(f),
    "</div>\n```\n"
  )

  # Software keeps the blurb as a one-line lead and puts the longer prose under
  # its own heading -- "About" rather than "Abstract", which belongs to papers.
  abstract <- f$abstract %||% ""
  abstract_md <- if (identical(kind, "research")) {
    if (nzchar(abstract)) paste0("\n## ", i18n$abstract_label, "\n\n", abstract, "\n") else ""
  } else {
    paste0(
      if (nzchar(blurb)) paste0("\n", blurb, "\n") else "",
      if (nzchar(abstract)) paste0("\n## ", i18n$about_label, "\n\n", abstract, "\n") else ""
    )
  }

  cite_md <- paste0(
    "\n## ", i18n$cite_this, "\n\n",
    "```{=html}\n",
    sprintf('<div class="cite-block"><button class="cite-copy" type="button" data-target="bib-%s">%s</button>',
            esc(slug), esc(i18n$copy)),
    sprintf('<pre id="bib-%s"><code>%s</code></pre></div>\n', esc(slug), esc_pre(as_bibtex(e))),
    "```\n"
  )

  back <- sprintf("\n```{=html}\n<p class=\"back-link\"><a href=\"/%s.html\">&larr; %s</a></p>\n```\n",
                  kind, esc(if (identical(kind, "software")) i18n$back_to_software else i18n$back_to_list))

  paste0(paste(fm[!vapply(fm, is.null, logical(1))], collapse = "\n"), "\n",
         header_html, abstract_md,
         related_html(e, kind, index, i18n),
         cite_md, back)
}
