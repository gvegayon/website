#!/usr/bin/env Rscript
#
# Generates one .qmd per entry into research/ and software/, which Quarto then
# renders like any other page. Run by `make pages` (and declared as the root
# project's pre-render hook so `quarto preview` works too).
#
# Both directories are gitignored: they are build output, not data. The data
# stays where it belongs, one file per collection, in papers.toml and
# software.toml.
#
# Writes are content-compared, so running this twice costs a few file reads and
# leaves every mtime alone.

local({
  root <- if (file.exists("papers.toml")) "." else ".."
  for (f in c("entries.R", "html.R", "i18n.R", "people.R", "metrics.R", "cards.R", "detail.R")) {
    source(file.path(root, "R", f))
  }

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

  i18n   <- get_i18n("en")          # detail pages are English only, by design
  people <- read_people(file.path(root, "people.toml"))

  collections <- list(
    research = read_entries(file.path(root, "papers.toml")),
    software = read_entries(file.path(root, "software.toml"))
  )

  # Flat key -> entry index so cross-links can resolve across collections.
  index <- list()
  for (kind in names(collections)) {
    for (e in collections[[kind]]) index[[paste0(kind, ":", e$key)]] <- e
  }

  written <- 0L; unchanged <- 0L
  for (kind in names(collections)) {
    dir <- file.path(root, kind)
    dir.create(dir, showWarnings = FALSE)

    seen <- character(0)
    for (e in collections[[kind]]) {
      slug <- entry_slug(e)
      if (slug %in% seen) {
        warning(sprintf("duplicate slug '%s' in %s -- set an explicit `slug` on one of them", slug, kind))
        next
      }
      seen <- c(seen, slug)

      txt <- detail_qmd_text(e, kind, index, people, i18n)
      if (write_if_changed(file.path(dir, paste0(slug, ".qmd")), txt)) written <- written + 1L
      else unchanged <- unchanged + 1L
    }

    # Drop pages for entries that no longer exist, so a removed item does not
    # linger as a stale URL.
    existing <- list.files(dir, pattern = "\\.qmd$")
    stale <- setdiff(existing, paste0(seen, ".qmd"))
    for (s in stale) unlink(file.path(dir, s))
    if (length(stale)) message(sprintf("removed %d stale %s page(s)", length(stale), kind))
  }

  message(sprintf("build_pages: %d written, %d unchanged", written, unchanged))
})
