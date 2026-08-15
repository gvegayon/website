# George G. Vega Yon - Quarto Website

This is the source code for my personal website built with Quarto.

## Structure

- `index.qmd` - Homepage with bio and social links
- `talks.qmd` - Automatically fetches talks from [gvegayon/talks](https://github.com/gvegayon/talks) repository
- `publications.qmd` - Links to Google Scholar profile and research overview
- `software.qmd` - Software list, rendered from `software.toml`
- `research.qmd` - Publication list, rendered from `papers.toml`
- `cv/cv.qmd` - Typst CV, rendered from all five `.toml` files
- `_quarto.yml` - Main configuration file
- `styles.css` / `custom.scss` - Custom styling

## Publication and software data

Publications, software and talks live in TOML, and these files are the source
of truth -- nothing regenerates them:

| File | Feeds |
| --- | --- |
| `papers.toml` | `research.qmd`, CV publications |
| `software.toml` | `software.qmd`, CV software |
| `presentations-conference.toml` | CV conference talks |
| `presentations-invited.toml` | CV invited talks |
| `presentations-other.toml` | CV other talks |

One table per entry, keyed by citation key. `keywords` is an array; everything
else, `author` and `editor` included, is a string. Values are plain text (or
markdown, for links) -- **not** LaTeX:

```toml
[vegayon2020aphylo]
entrytype = 'article'
title = 'Bayesian parameter estimation for automatic annotation of gene functions'
author = 'Vega Yon, George G.; Thomas, Duncan C.; Marjoram, Paul'
year = '2021'
month = '02'
journal = 'PLOS Computational Biology'
doi = '10.1371/journal.pcbi.1007948'
keywords = ['published']
image = 'img/papers/aphylo-tree.webp'
image_caption = 'Posterior annotation probabilities on a phylogeny.'
```

Because TOML is not tied to BibTeX's fixed field set, entries can carry any
extra fields you like; unrecognised ones are simply ignored by the renderers.

### Authors

`author` and `editor` hold **one string**: names in order, separated by
**semicolons**, each written **`Last, First M.`**

```toml
author = 'Vega Yon, George G.; de la Haye, Kayla; others'
```

The semicolon is what makes the comma unambiguous, and that matters for every
surname of more than one word -- `Vega Yon`, `de la Haye`, `Bernal Zelaya`.
Written `First Last`, nothing downstream can tell where the surname begins, and
both the website byline and the BibTeX block get it wrong. Write the comma and
neither has to guess.

`others` is BibTeX's own marker for a truncated list and renders as "et al.".
Any name whose surname is "Vega Yon" is bolded automatically, so it needs no
special markup.

The generated BibTeX on each detail page braces both halves --
`author = {{Vega Yon}, {George G.} and ...}` -- so that anything re-splitting
the name on spaces still cites the full two-word surname rather than "Yon".
(Trade-off: an abbreviating style such as `plain` reads `{George G.}` as one
token and prints "G." instead of "G. G."; see `bibtex_name()` in
`R/entries.R`.)

Legacy arrays (`author = ['A, B', 'C, D']`) are still parsed, so an old file
keeps rendering, but new entries should use the string form.

### Images

Two optional fields put one figure on an entry's detail page:

| Field | Meaning |
| --- | --- |
| `image` | path to the image, **relative to the site root, no leading slash** (`img/papers/x.webp`) |
| `image_caption` | caption shown under it; also used as the `alt` text |

The leading slash is omitted on purpose: Quarto resolves `/...` per *project*,
and `es/` and `zh/` are separate projects one level deeper, so a rooted path
breaks only the translated pages. `asset_url()` in `R/html.R` adds the right
prefix. The same applies to `hex` on a software entry.

`keywords` drives what appears where: `published` and `wip` split the
publications, and `conferencetalk` / `invitedtalk` / `othertalk` select the CV
talk sections.

Accented characters must be literal UTF-8 -- `assert_no_accent_macros()` fails
the CV render if a LaTeX accent macro (`\'e`) creeps in from a publisher's
BibTeX export.

Talks on `talks.qmd` are still fetched weekly from the
[gvegayon/talks](https://github.com/gvegayon/talks) repository via GitHub
Actions.

## Building Locally

To build the website locally:

1. Install [Quarto](https://quarto.org/docs/get-started/)
2. Install required R packages: `toml`, `httr`, `rvest`, `stringr`, `rmarkdown`, `knitr`
3. Run `make` -- **not** a bare `quarto render .`, which overwrites the
   translated `es/` and `zh/` navbars

Or open the repository in the devcontainer (`.devcontainer/`), which already
has Quarto, the CV fonts and the R packages.

## Social share card

`img/og-card.png` is the 1200x630 image Bluesky, LinkedIn, Slack and Mastodon
show when a ggvy.cl link is posted. It is committed as a binary and is **not**
rebuilt by `make` -- regenerate it by hand when the name, title or portrait
changes:

```sh
Rscript R/build_og_card.R
```

All three projects point at the copy served from the apex
(`https://ggvy.cl/img/og-card.png`); `es/` and `zh/` name it absolutely because
Quarto resolves a root-relative image against each project's own `site-url`.

## Deployment

The website is automatically built and deployed using GitHub Actions with the `rocker/tidyverse:4.5.1` container, which includes Quarto and all necessary R packages.

## Original Website

The original HTML website is preserved in the `public` directory and serves as the baseline for the new Quarto version.

And an old version lives here: <https://github.com/gvegayon/website-old>