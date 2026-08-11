# Typst/Quarto CV. Convenience target for iterating on the CV alone -- the
# site build (../Makefile) already renders cv.qmd, since it is one of the
# Quarto project's inputs.
#
# Needs Quarto (Typst is bundled), R, and the Open Sans font. The font is
# installed in .devcontainer/Containerfile and in the CI workflow; on a bare
# macOS host Typst will warn and fall back to its default.

BIBS = ../papers.toml ../software.toml ../presentations-conference.bib \
       ../presentations-invited.bib ../presentations-other.bib

# cv.qmd sits inside the website project, so Quarto writes the PDF to the
# project's output-dir rather than next to the source.
OUT = ../public/cv/cv.pdf

$(OUT): cv.qmd R/bib.R R/downloads.R $(BIBS)
	quarto render cv.qmd --to typst

# Refresh the CRAN download cache. Deliberately NOT a dependency of the PDF:
# the render must never depend on the network.
downloads:
	Rscript -e 'source("R/bib.R"); source("R/downloads.R"); fetch_downloads()'

# Page images, handy for eyeballing changes.
preview: cv.qmd
	quarto render cv.qmd --to typst -M keep-typ:true
	quarto typst compile cv.typ "page{0p}.png" --format png --ppi 100

clean:
	rm -f cv.typ page*.png

.PHONY: downloads preview clean
