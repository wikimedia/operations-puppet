# Makefile heavily based on the git project /Documentation/Makefile

# AsciiDoc toolchain manager
A2X=a2x

RM ?= rm -f

# List source files per sections
MAN1_TXT= $(filter-out _%.txt,$(wildcard *.txt))

# man files
DOC_MAN1=$(patsubst %.txt,%.1,$(MAN1_TXT))
DOC_MAN=$(DOC_MAN1)

all: man

clean: ; $(RM) *.1

man: prechecks $(DOC_MAN)

# Conversion rule
%.1 : %.txt
	@if test -s $<; then \
		echo "Converting '$<' to '$@'"; \
	$(A2X) --doctype manpage --format manpage $<; fi


prechecks: has_a2x

has_a2x:
	@echo "Checking if we have '$(A2X)'...\c"
ifeq ("$(shell which $(A2X))","")
	@echo "no"
	@echo "\nRequires Asciidoc ($(A2X) not found). See README.\n" \
	&& exit 1
else
	@echo "ok"
endif


