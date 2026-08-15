#!/usr/bin/env Rscript
#
# Writes one _includes/hreflang-<slug>.html per shared page (index, research,
# software, talks, teaching, people), each holding the four
# <link rel="alternate" hreflang="..."> tags pointing at the EN/ES/ZH editions
# of that page plus x-default. The three editions of a page share the exact
# same slug, so one file, referenced from all three projects' `_quarto.yml`
# via each page's own `include-in-header`, keeps the set byte-identical by
# construction rather than by discipline.
#
# Hrefs are absolute (https://ggvy.cl/...), never root-relative -- see the
# note in R/html.R about '/...' resolving per *project*.
#
# Called from build_pages.R, so it runs everywhere that already runs (the
# root project's pre-render hook, and `make pages`). Output is gitignored
# build artifact, like research/*.qmd and software/*.qmd.

local({
  site <- "https://ggvy.cl"

  # slug -> path segment under each language root ("" for the homepage,
  # which canonicalizes to a bare trailing slash rather than /index.html).
  pages <- c(
    index    = "",
    research = "research.html",
    software = "software.html",
    talks    = "talks.html",
    teaching = "teaching.html",
    people   = "people.html"
  )

  langs <- c(en = "", es = "es/", `zh-Hant` = "zh/")

  dir.create("_includes", showWarnings = FALSE)

  write_if_changed <- function(path, text) {
    if (file.exists(path)) {
      old <- tryCatch(readChar(path, file.info(path)$size, useBytes = TRUE), error = function(e) "")
      if (identical(old, text)) return(FALSE)
    }
    con <- file(path, open = "wb")
    on.exit(close(con))
    writeBin(charToRaw(text), con)
    TRUE
  }

  written <- 0L; unchanged <- 0L
  for (slug in names(pages)) {
    lines <- vapply(names(langs), function(lang) {
      sprintf('<link rel="alternate" hreflang="%s" href="%s/%s%s">', lang, site, langs[[lang]], pages[[slug]])
    }, character(1))
    lines <- c(lines, sprintf('<link rel="alternate" hreflang="x-default" href="%s/%s">', site, pages[[slug]]))

    path <- file.path("_includes", sprintf("hreflang-%s.html", slug))
    if (write_if_changed(path, paste(lines, collapse = "\n"))) written <- written + 1L
    else unchanged <- unchanged + 1L
  }

  message(sprintf("build_hreflang: %d written, %d unchanged", written, unchanged))
})
