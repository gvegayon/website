build:
	Rscript -e 'if (!requireNamespace("toml", quietly = TRUE)) install.packages("toml", repos="https://cloud.r-project.org")'
	quarto render .
	quarto render es
	quarto render zh

update-cv:
	cp ../resume/resume.pdf public/.; cp ../resume/resume.docx public/.
