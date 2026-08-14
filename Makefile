# papers.toml/software.toml are read with toml::read_toml(); the CI container
# (rocker/tidyverse) does not ship it.
deps:
	Rscript -e 'if (!requireNamespace("toml", quietly = TRUE)) install.packages("toml", repos = "https://cloud.r-project.org")'

build: deps
	quarto render .
	quarto render es
	quarto render zh

update-cv:
	cp ../resume/resume.pdf public/.; cp ../resume/resume.docx public/.
