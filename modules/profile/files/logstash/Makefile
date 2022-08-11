# Supports docker and podman
CONTAINER_RUNTIME := $(shell which podman || which docker)

# ENABLE_DIAGNOSTICS default true
# Usage: make -e ENABLE_DIAGNOSTICS=false test-local
ENABLE_DIAGNOSTICS ?= true

all:
	ENABLE_DIAGNOSTICS=$(ENABLE_DIAGNOSTICS) logstash-filter-verifier --keep-env ENABLE_DIAGNOSTICS --diff-command="diff -u --color=always" --sockets tests/ filters/*.conf

test-local:
	${CONTAINER_RUNTIME} run --rm --env ENABLE_DIAGNOSTICS=$(ENABLE_DIAGNOSTICS) --workdir /src -v $$(pwd):/src:Z -v $$(pwd)/templates:/etc/logstash/templates:Z -v $$(pwd)/filter_scripts:/etc/logstash/filter_scripts:Z --entrypoint make docker-registry.wikimedia.org/releng/logstash-filter-verifier:latest

.PHONY: all
