# == Define: prometheus::jmx_exporter_instance
#
# Dummy define to instruct Prometheus to poll $hostname:$port for metrics exporter
# by jmx_exporter. Note that the $hostname:$port identifies a Prometheus target,
# to which metrics will be associated, so hardcoding the $hostname puppet variable
# was not working for use cases like Cassandra or Kafka (on which multiple JVMs
# are working and publishing metrics).
#
define prometheus::jmx_exporter_instance (
    $hostname,
    $port
) {
}
