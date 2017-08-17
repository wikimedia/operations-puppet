# Dummy define to instruct Prometheus to poll $title:$port for metrics exporter
# by jmx_exporter
define prometheus::jmx_exporter_instance (
    $address,
    $port
) {
}
