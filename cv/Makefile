# Typst/Quarto CV. Convenience target for iterating on the CV alone -- the
# site build (../Makefile) already renders cv.qmd, since it is one of the
# Quarto project's inputs.
#
# Needs Quarto (Typst is bundled), R, and the Open Sans font. The font is
# installed in .devcontainer/Containerfile and in the CI workflow; on a bare
# macOS host Typst will warn and fall back to its default.

SRC = ../papers.toml ../software.toml ../presentations-conference.toml \
      ../presentations-invited.toml ../presentations-other.toml ../metrics.toml

# cv.qmd sits inside the website project, so Quarto writes the PDF to the
# project's output-dir rather than next to the source.
OUT = ../public/cv/cv.pdf
PUBLISHED_OUT = ../public/cv/cv-published.pdf

$(OUT): cv.qmd R/bib.R R/downloads.R $(SRC)
	quarto render cv.qmd --to typst

# A publication-only CV generated from cv.qmd. The source bibliography remains
# the single source of truth; this only sets its documented render parameter.
$(PUBLISHED_OUT): cv.qmd R/bib.R R/downloads.R $(SRC)
	quarto render cv.qmd --to typst --output cv-published.pdf -P published_only:true

published-only: $(PUBLISHED_OUT)

# There is no CRAN-download target here any more. The badges read ../metrics.toml,
# which `make refresh` in the parent Makefile rewrites from the weekly cron --
# the render itself still never touches the network.

# Page images, handy for eyeballing changes.
preview: cv.qmd
	quarto render cv.qmd --to typst -M keep-typ:true
	quarto typst compile cv.typ "page{0p}.png" --format png --ppi 100

clean:
	rm -f cv.typ page*.png

.PHONY: published-only preview clean
