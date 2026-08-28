#!/usr/bin/env Rscript
#
# Renders candidates.toml into review.html: one row per candidate photo, with
# the original next to the make_avatar.sh crop, the source URL, the S1-S6
# identity-verification signals with their evidence notes, and the computed
# confidence. This is the mandatory human-review gate -- nothing in
# candidates.toml may be copied into ../../img/people/, added to
# ../../people.toml, or recorded in ../../img/people/MANIFEST.toml until
# George has looked at this page and approved it, photo by photo. See
# README.md in this directory for the full sourcing + scoring workflow.
#
# Usage: Rscript review.R   (run from tools/people-photos/)

`%||%` <- function(a, b) if (is.null(a) || !length(a) || !nzchar(trimws(a[1]))) b else a

esc <- function(x) {
  x <- as.character(x %||% "")
  x <- gsub("&", "&amp;", x, fixed = TRUE)
  x <- gsub("<", "&lt;", x, fixed = TRUE)
  gsub(">", "&gt;", x, fixed = TRUE)
}

if (!file.exists("candidates.toml")) {
  stop("candidates.toml not found -- run this from tools/people-photos/, ",
       "and see README.md for how candidates.toml is populated.", call. = FALSE)
}
if (!requireNamespace("toml", quietly = TRUE)) {
  stop("the 'toml' package is required", call. = FALSE)
}

data <- toml::read_toml("candidates.toml")
cands <- data$candidate %||% list()
if (!length(cands)) stop("candidates.toml has no [[candidate]] entries", call. = FALSE)

signal_label <- c(
  s1 = "S1 Name match", s2 = "S2 Affiliation/role match", s3 = "S3 Institutional page",
  s4 = "S4 Cross-source facial consistency", s5 = "S5 Name-collision check", s6 = "S6 Recency & quality"
)

signal_row <- function(c) {
  paste(vapply(names(signal_label), function(k) {
    val <- isTRUE(c[[k]])
    sprintf('<tr><td>%s</td><td class="%s">%s</td></tr>',
            esc(signal_label[[k]]), if (val) "yes" else "no", if (val) "yes" else "no")
  }, character(1)), collapse = "")
}

card_html <- function(c) {
  conf <- tolower(c$confidence %||% "low")
  sprintf(
    '<section class="cand conf-%s">
      <h2>%s <span class="badge">%s confidence</span></h2>
      <div class="imgs">
        <figure><img src="%s" alt=""><figcaption>original</figcaption></figure>
        <figure><img src="%s" alt=""><figcaption>240x240 crop (make_avatar.sh)</figcaption></figure>
      </div>
      <p><a href="%s" target="_blank" rel="noopener">%s</a></p>
      <table>%s</table>
      <p class="notes"><strong>Notes:</strong> %s</p>
      <p class="approve">Approved? &nbsp; [ ] yes &nbsp; [ ] no &nbsp; (tell George which slugs to commit)</p>
    </section>',
    esc(conf), esc(c$slug %||% "?"), esc(conf),
    esc(c$file %||% ""), esc(c$crop %||% c$file %||% ""),
    esc(c$source_url %||% "#"), esc(c$page_title %||% c$source_url %||% ""),
    signal_row(c), esc(c$notes %||% "")
  )
}

body <- paste(vapply(cands, card_html, character(1)), collapse = "\n")

html <- sprintf('<!doctype html>
<html><head><meta charset="utf-8"><title>Photo review</title>
<style>
body { font-family: -apple-system, sans-serif; max-width: 900px; margin: 2rem auto; padding: 0 1rem; color: #222; }
.cand { border: 1px solid #ddd; border-radius: 10px; padding: 1rem 1.2rem; margin-bottom: 1.5rem; }
.cand.conf-low { border-color: #d33; background: #fff5f5; }
.cand.conf-medium { border-color: #c90; background: #fffaf0; }
.cand.conf-high { border-color: #2a2; background: #f4fff4; }
.badge { font-size: 0.7rem; font-weight: 700; text-transform: uppercase; padding: 0.15rem 0.5rem; border-radius: 999px; background: #eee; }
.imgs { display: flex; gap: 1rem; margin: 0.7rem 0; }
.imgs img { width: 140px; height: 140px; object-fit: cover; border-radius: 8px; border: 1px solid #ccc; }
.imgs figcaption { font-size: 0.75rem; color: #666; text-align: center; }
table { border-collapse: collapse; font-size: 0.85rem; margin: 0.6rem 0; }
td { padding: 0.15rem 0.6rem; border-bottom: 1px solid #eee; }
td.yes { color: #2a2; font-weight: 700; }
td.no { color: #999; }
.notes { font-size: 0.85rem; color: #444; }
.approve { font-weight: 700; }
</style></head><body>
<h1>Coauthor/mentee photo candidates</h1>
<p>LOW confidence candidates are highlighted red and should not be approved --
ask the person directly for a headshot instead. Nothing here is live on the
site; approving a row here just tells the agent it may copy that crop into
img/people/, add <code>photo = ...</code> to people.toml, and record it in
img/people/MANIFEST.toml.</p>
%s
</body></html>', body)

writeLines(html, "review.html")
cat(sprintf("wrote review.html (%d candidate%s)\n", length(cands), if (length(cands) == 1) "" else "s"))
