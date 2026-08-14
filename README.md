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

One table per entry, keyed by citation key. `author`, `editor` and `keywords`
are arrays; everything else is a string. Values are plain text (or markdown,
for links) -- **not** LaTeX:

```toml
[vegayon2020aphylo]
entrytype = 'article'
title = 'Bayesian parameter estimation for automatic annotation of gene functions'
author = ['Vega Yon, George G.', 'Thomas, Duncan C.', 'Marjoram, Paul']
year = '2021'
month = '02'
journal = 'PLOS Computational Biology'
doi = '10.1371/journal.pcbi.1007948'
keywords = ['published']
```

Because TOML is not tied to BibTeX's fixed field set, entries can carry any
extra fields you like; unrecognised ones are simply ignored by the renderers.

`keywords` drives what appears where: `published` and `wip` split the
publications, and `conferencetalk` / `invitedtalk` / `othertalk` select the CV
talk sections. Names are written `Last, First M.`; any name containing
"Vega Yon" is bolded automatically, so it does not need special markup.

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

## Deployment

The website is automatically built and deployed using GitHub Actions with the `rocker/tidyverse:4.5.1` container, which includes Quarto and all necessary R packages.

## Original Website

The original HTML website is preserved in the `public` directory and serves as the baseline for the new Quarto version.

And an old version lives here: <https://github.com/gvegayon/website-old>