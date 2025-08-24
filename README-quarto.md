# George G. Vega Yon - Quarto Website

This is the source code for my personal website built with Quarto.

## Structure

- `index.qmd` - Homepage with bio and social links
- `talks.qmd` - Automatically fetches talks from [gvegayon/talks](https://github.com/gvegayon/talks) repository
- `publications.qmd` - Links to Google Scholar profile and research overview
- `software.qmd` - Automatically fetches software list from [gvegayon/resume](https://github.com/gvegayon/resume/blob/master/software.bib)
- `_quarto.yml` - Main configuration file
- `styles.css` / `custom.scss` - Custom styling

## Automatic Updates

The website is configured to automatically update weekly via GitHub Actions, fetching the latest:
- Talks from the talks repository
- Software from the resume repository  
- Publications metadata

## Building Locally

To build the website locally:

1. Install [Quarto](https://quarto.org/docs/get-started/)
2. Install required R packages: `httr`, `rvest`, `stringr`, `rmarkdown`, `knitr`
3. Run `quarto render`

## Deployment

The website is automatically built and deployed using GitHub Actions with the `rocker/tidyverse:4.5.1` container, which includes Quarto and all necessary R packages.

## Original Website

The original HTML website is preserved in the `public` directory and serves as the baseline for the new Quarto version.