all:
	logstash-filter-verifier --diff-command="diff -u --color=always" --sockets tests/ filters/*.conf

podman-test-local:
	podman run --rm --workdir /src -v $$(pwd):/src:Z -v $$(pwd)/templates:/etc/logstash/templates:Z -v $$(pwd)/filter_scripts:/etc/logstash/filter_scripts:Z --entrypoint make docker-registry.wikimedia.org/releng/logstash-filter-verifier:latest

.PHONY: all
