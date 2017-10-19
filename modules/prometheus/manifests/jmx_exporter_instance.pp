# == Define: prometheus::jmx_exporter_instance
#
# Dummy define to instruct Prometheus to poll $hostname:$port for metrics exporter
# by jmx_exporter
#
define prometheus::jmx_exporter_instance (
    $address,
    $port
) {
}
