# SPDX-License-Identifier: Apache-2.0
# Supports docker and podman
CONTAINER_RUNTIME := $(shell which podman || which docker)

# ENABLE_DIAGNOSTICS default true
# Usage: make -e ENABLE_DIAGNOSTICS=false test-local
ENABLE_DIAGNOSTICS ?= true

# TARGET default "all"
# Usage: make -e TARGET=config-check test-local
TARGET ?= all

all:
	ENABLE_DIAGNOSTICS=$(ENABLE_DIAGNOSTICS) logstash-filter-verifier --keep-env ENABLE_DIAGNOSTICS --diff-command="diff -u --color=always" --sockets tests/ filters/*.conf

config-check:
	/usr/share/logstash/bin/logstash --config.test_and_exit --log.level=debug --path.config ./filters --path.logs /tmp/logstash.log --path.settings /etc/logstash --path.data /tmp

test-local:
	${CONTAINER_RUNTIME} run --rm --env ENABLE_DIAGNOSTICS=$(ENABLE_DIAGNOSTICS) --workdir /src -v $$(pwd):/src:Z -v $$(pwd)/templates:/etc/logstash/templates:Z -v $$(pwd)/filter_scripts:/etc/logstash/filter_scripts:Z --entrypoint make docker-registry.wikimedia.org/releng/logstash-filter-verifier:latest $(TARGET)

.PHONY: all config-check
