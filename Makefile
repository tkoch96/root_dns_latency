# NB: By default fetch the paper from Google docs every time
# use "make recompile" to avoid the extra fetch

NAME=paper
TARGET=$(NAME).pdf

# Change the line below to contain an export URL.
# Make sure the sharing mode on the Doc is set to "anyone with link can view"
#DOCS_LINK=https://docs.google.com/document/d/1jp_z1cL3vtCdYa0ZPz6TR2JOtLi87Ur29O0nCSwJ3qA/export?format=txt
DOCS_LINK=https://docs.google.com/document/d/15FTvu4qH-Bp4T7e3wgyfyBXLf4WyX05WUG5vb4JJ4To/export?format=txt

# This line should not change; however, you can customize the template.tex for the conference
#
# We use "--tab-stop 3" as Google Docs indents nested lists with three spaces
# (for markup, it's normally 4)
PANDOC_FLAGS=-s -N --template=template.tex -f markdown+yaml_metadata_block+footnotes -t latex --tab-stop 3

# Customize the line below to change the bib file and the csl file (either ieee or acm)
# and to use pandoc-citeproc or biblatex (the latter is the default)
# BIBLIO_FLAGS=--bibliography=mybib.bib --csl=acm.csl
BIBLIO_FLAGS=--bibliography=bib.bib --natbib

.SUFFIXES:
.SUFFIXES: .stamp .tex .pdf

UNAME_S := $(shell uname -s)
ifeq ($(UNAME_S),Darwin)
	SED_REGEXP_FLAGS += -E
else
	SED_REGEXP_FLAGS += -e
endif

ifeq ($(MODE),"batch")
  PDFLATEX_FLAGS += --interaction=batchmode
else
  PDFLATEX_FLAGS += --halt-on-error
endif

top: all

recompile: $(TARGET)

all: trigger $(TARGET)

clean:
	rm -f $(NAME).aux $(NAME).bbl $(NAME).blg $(NAME).log $(NAME).pdf $(NAME).md $(NAME).mdg $(NAME).mdt $(NAME).md-r $(NAME).out $(NAME).trig $(NAME).run.xml $(NAME)-blx.bib
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
	# Add new lines before and after lines containing \iffalse and \fi to avoid issues with pandoc conversion
	#
	# Examples:
	#  - If \fi appears in a line immediately following a list, it will be inserted as the last element in
	#    the list by pandoc before the list is closed, resulting in a compilation error.
	sed -i -r $(SED_REGEXP_FLAGS) '/^\\\iffalse/{x;p;x;G;}' $(NAME).md
	sed -i -r $(SED_REGEXP_FLAGS) '/^\\\fi/{x;p;x;G;}' $(NAME).md
	# rm $(NAME).mdt
	pandoc $(PANDOC_FLAGS) $(BIBLIO_FLAGS) $(NAME).md > $(NAME).tex

# Iterate on latex until cross references don't change
$(NAME).pdf: $(NAME).tex
	pdflatex $(PDFLATEX_FLAGS) $(NAME)
	pdflatex $(PDFLATEX_FLAGS) $(NAME)
	bibtex $(NAME)
	pdflatex $(PDFLATEX_FLAGS) $(NAME)
	pdflatex $(PDFLATEX_FLAGS) $(NAME)

spell: $(NAME).tex
	cat $(NAME).tex | aspell list | sort -u | aspell -a