build:
	quarto render .

update-cv:
	cp ../resume/resume.pdf public/.; cp ../resume/resume.docx public/.
