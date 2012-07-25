# Makefile heavily based on the git project /Documentation/Makefile

# AsciiDoc toolchain manager
A2X=a2x
A2X_EXTRA=

ASCIIDOCS_DIR=asciidoc
OUT_DIR=man

RM ?= rm -f
#SHELL += -x

# List source files per sections
# Ignore any asciidoc file not begining with a letter such as _
MAN1_TXT= $(filter-out _%.txt,$(wildcard $(ASCIIDOCS_DIR)/[a-zA-Z]*.txt))

# man files
DOC_MAN1=$(patsubst $(ASCIIDOCS_DIR)/%.txt,$(OUT_DIR)/%.1,$(MAN1_TXT))
DOC_MAN=$(DOC_MAN1)

ifdef VERBOSE
A2X_EXTRA += --verbose
endif

all: man

clean: ; $(RM) $(OUT_DIR)/*.1

clean-all: clean all

man: prechecks $(DOC_MAN)

# Conversion rule
$(OUT_DIR)/%.1 : $(ASCIIDOCS_DIR)/%.txt
	@if test -s $<; then \
		echo "Converting '$<' to '$@'"; \
	$(A2X) $(A2X_EXTRA) --destination-dir $(OUT_DIR) --doctype manpage --format manpage $<; fi

prechecks: has_a2x
	@echo "DOCMAN $(DOC_MAN)"
	@echo "ASCIIDOCS_DIR: $(ASCIIDOCS_DIR)"

has_a2x:
	@echo "Checking if we have '$(A2X)'...\c"
ifeq ("$(shell which $(A2X))","")
	@echo "no"
	@echo "\nRequires Asciidoc ($(A2X) not found). See README.\n" \
	&& exit 1
else
	@echo "ok"
endif


