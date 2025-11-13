build:
	quarto render .
	quarto render es
	quarto render zh

update-cv:
	cp ../resume/resume.pdf public/.; cp ../resume/resume.docx public/.
