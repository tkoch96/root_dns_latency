# NB: By default fetch the paper from Google docs every time
# use "make recompile" to avoid the extra fetch

NAME=root_dns_latency
TARGET=$(NAME).pdf

# Change the line below to contain an export URL.
# Make sure the sharing mode on the Doc is set to "anyone with link can view"
DOCS_LINK=https://docs.google.com/document/d/15FTvu4qH-Bp4T7e3wgyfyBXLf4WyX05WUG5vb4JJ4To/export?format=txt

# This line should not change; however, you can customize the template.tex for the conference
#
# We use "--tab-stop 3" as Google Docs indents nested lists with three spaces
# (for markup, it's normally 4)
PANDOC_FLAGS=-s -N --template=template.tex -f markdown+yaml_metadata_block+footnotes -t latex --tab-stop 3

# Customize the line below to change the bib file and the csl file (either ieee or acm)
# and to use pandoc-citeproc or biblatex (the latter is the default)
# BIBLIO_FLAGS=--bibliography=mybib.bib --csl=acm.csl
BIBLIO_FLAGS=--bibliography=mybib.bib --natbib

.SUFFIXES:
.SUFFIXES: .stamp .tex .pdf

UNAME_S := $(shell uname -s)
ifeq ($(UNAME_S),Darwin)
	SED_REGEXP_FLAGS += -E
endif

top: all

recompile: $(TARGET)

all: trigger $(TARGET)

clean:
	rm -f $(NAME).aux $(NAME).bbl $(NAME).blg $(NAME).log $(NAME).pdf $(NAME).md $(NAME).mdg $(NAME).mdt $(NAME).md-r $(NAME).out $(NAME).trig $(NAME).run.xml $(NAME)-blx.bib authors.aux
	rm -f $(NAME).tex  # CAUTION remove if source is moved from Google docs

trigger $(NAME).trig:
	touch $(NAME).trig

# This fetches the shared source from Google docs
$(NAME).tex: $(NAME).trig
	wget --no-check-certificate -O$(NAME).mdt $(DOCS_LINK)
	# `awk '{if (/^#/) print ""; print $0}'` adds a new line before any
	#  section heading (begins with #)
	iconv -c -t ASCII//TRANSLIT $(NAME).mdt | awk '{if (/^#/) print ""; print $0}' > $(NAME).md
	# Footnote support for Google Docs
	#   - `s/\[([0-9]+)\]/\[^\1\]/g` adds a `^` to the beginning of
	#      Google Docs footnote marks ([1] -> [^1])
	#   - `s/^(\[\^[0-9]+\])/\1:/g` adds a `:` after the closing bracket
	#      for footnote marks at the beginning of the line, which is used
	#      when defining the footnote's text at the end of the textfile
	#      exported from Google Docs
	#   - `s/^_{16}//` trims the ______________ that appears before
	#      the footnotes in Google Docs text export
	sed -i -r $(SED_REGEXP_FLAGS) 's/\[([0-9]+)\]/\[^\1\]/g; s/^(\[\^[0-9]+\])/\1:/g; s/^_{16}//' $(NAME).md
	rm $(NAME).mdt
	pandoc $(PANDOC_FLAGS) $(BIBLIO_FLAGS) $(NAME).md > $(NAME).tex~
	# refs go before appendix, not after.  fix Hackily fix that here.
	{ < $(NAME).tex~ sed '/^\\appendix/,$$d'; \
	  < $(NAME).tex~ grep '\\bibliography{'; \
	  < $(NAME).tex~ grep '^\\appendix'; \
	  < $(NAME).tex~ sed '1,/^\\appendix/d'; \
	} > $(NAME).tex
	# Google docs now include comments inside of [letter], so remove that.
	sed -i'orig' 's/[{][[][}][a-z].*[{][]][}]//g' $(NAME).tex

# Iterate on latex until cross references don't change
$(NAME).pdf: $(NAME).tex
	pdflatex $(NAME)
	bibtex $(NAME)
	pdflatex $(NAME)
	pdflatex $(NAME)

spell: $(NAME).tex
	cat $(NAME).tex | aspell list | sort -u | aspell -a
