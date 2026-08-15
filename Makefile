# `deps` is defined first for readability, so name the real default explicitly.
# Without this, a bare `make` -- which is what CI runs -- installs the toml
# package and stops, never rendering the site.
.DEFAULT_GOAL := build

QUARTO  ?= quarto
RSCRIPT ?= Rscript

.PHONY: deps pages build clean-generated refresh update-cv

# papers.toml/software.toml are read with toml::read_toml(); the CI container
# (rocker/tidyverse) does not ship it.
deps:
	$(RSCRIPT) -e 'if (!requireNamespace("toml", quietly = TRUE)) install.packages("toml", repos = "https://cloud.r-project.org")'

# One .qmd per entry into research/ and software/. Both are gitignored build
# output; the data stays in papers.toml / software.toml. Idempotent -- writes
# are content-compared, so a second run changes nothing.
pages: deps
	$(RSCRIPT) R/build_pages.R

# Explicit globs, never `rm -rf software`, which sits one keystroke away from
# deleting software.qmd. Clearing the rendered dirs too stops a removed entry
# from lingering in the deployed site.
clean-generated:
	rm -f research/*.qmd software/*.qmd
	rm -rf public/research public/software

# The root project's render glob recurses, so it also claims es/*.qmd and
# zh/*.qmd and renders them with the English navbar. That is why the order
# below matters: the per-language renders come last and overwrite it. Excluding
# es/ and zh/ from the root render instead is NOT a fix -- Quarto then deletes
# public/es and public/zh as orphaned output. See the note in _quarto.yml.
build: clean-generated pages
	$(QUARTO) render .
	$(QUARTO) render es
	$(QUARTO) render zh

# NETWORK. The only target that reaches the internet -- run from the weekly
# cron and by hand, never from a render. The leading `-` means a failed
# refresh can never fail the build; metrics.toml keeps its previous values.
refresh: deps
	-$(RSCRIPT) R/fetch_metrics.R

update-cv:
	cp ../resume/resume.pdf public/.; cp ../resume/resume.docx public/.
