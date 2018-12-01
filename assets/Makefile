readme_example.svg: readme_example_trimmed.pdf
	pdf2svg $< $@

readme_example_trimmed.pdf: readme_example.pdf
	pdftrimwhite $< $@

readme_example.html: readme_example.jl
	julia --project=@. $<

readme_example.pdf: readme_example.html
	wkhtmltopdf $< $@
