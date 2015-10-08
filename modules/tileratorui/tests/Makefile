# Test automator
MANIFESTS=$(wildcard *.pp)
OBJS=$(MANIFESTS:.pp=.po)
TESTS_DIR=$(dir $(CURDIR))
MODULE_DIR=$(TESTS_DIR:/=)
MODULES_DIR=$(dir $(MODULE_DIR))

all:    test

test:   $(OBJS)

%.po:   %.pp
	puppet parser validate $<
	puppet apply --noop --modulepath $(MODULES_DIR) $<
